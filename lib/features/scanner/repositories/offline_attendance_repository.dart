import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../core/local/app_database.dart';
import '../../../core/local/daos/participants_dao.dart';
import '../../../core/local/daos/payables_dao.dart';
import '../../../core/local/daos/scanner_dao.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/models/student_model.dart';

class DownloadResult {
  final int studentCount;
  final DateTime downloadedAt;

  const DownloadResult({
    required this.studentCount,
    required this.downloadedAt,
  });
}

class OfflineAttendanceRepository {
  final FirebaseFirestore _firestore;
  final ParticipantsDao _participantsDao;
  final PayablesDao _payablesDao;
  final ScannerDao _scannerDao;

  OfflineAttendanceRepository({
    required FirebaseFirestore firestore,
    required ParticipantsDao participantsDao,
    required PayablesDao payablesDao,
    required ScannerDao scannerDao,
  })  : _firestore = firestore,
        _participantsDao = participantsDao,
        _payablesDao = payablesDao,
        _scannerDao = scannerDao;

  /// Downloads active students (based on event targets) and their payable records
  /// into the local Drift database to enable offline QR scanning.
  Future<DownloadResult> downloadParticipantsForEvent(
    String eventId, {
    void Function(double progress)? onProgress,
  }) async {
    onProgress?.call(0.1);

    // 1. Fetch Event Document
    final eventDoc = await _firestore.collection(FirestorePaths.events).doc(eventId).get();
    if (!eventDoc.exists) {
      throw Exception('Event not found.');
    }

    final eventData = eventDoc.data()!;
    final List<String> targetDeptIds = List<String>.from(eventData['targetDepartmentIds'] ?? []);
    final List<String> targetYearLevels = List<String>.from(eventData['targetYearLevels'] ?? []);
    final bool payablesEnabled = eventData['studentPayablesEnabled'] ?? false;

    if (targetDeptIds.isEmpty || targetYearLevels.isEmpty) {
      // Event has no target participants
      await _finalizeDownload(eventId, [], []);
      onProgress?.call(1.0);
      return DownloadResult(studentCount: 0, downloadedAt: DateTime.now());
    }

    onProgress?.call(0.2);

    // 2. Query Students in batches (whereIn limit is 30)
    final List<StudentModel> allStudents = [];
    final int batchSize = 30;
    
    // Split department IDs into chunks of 30
    for (int i = 0; i < targetDeptIds.length; i += batchSize) {
      final deptBatch = targetDeptIds.sublist(
        i,
        i + batchSize > targetDeptIds.length ? targetDeptIds.length : i + batchSize,
      );

      final querySnapshot = await _firestore
          .collection(FirestorePaths.students)
          .where('departmentId', whereIn: deptBatch)
          // Note: you can only have one 'whereIn' or 'arrayContainsAny' clause in Firestore.
          // Since yearLevel is also a list, we must filter yearLevel on the client side!
          // We also filter 'status' == 'ACTIVE' on the client side to avoid requiring a composite index.
          .get();

      for (var doc in querySnapshot.docs) {
        final student = StudentModel.fromFirestore(doc);
        // Client-side filter for yearLevel and active status
        if (student.status == 'ACTIVE' && targetYearLevels.contains(student.yearLevel)) {
          allStudents.add(student);
        }
      }
    }

    if (allStudents.isEmpty) {
      await _finalizeDownload(eventId, [], []);
      onProgress?.call(1.0);
      return DownloadResult(studentCount: 0, downloadedAt: DateTime.now());
    }

    onProgress?.call(0.6);

    // 3. Query Payables (optimized: fetch all for the event, instead of per student)
    final Map<String, Map<String, dynamic>> payablesMap = {}; // studentId -> payable doc data
    if (payablesEnabled) {
      final payablesSnapshot = await _firestore
          .collection(FirestorePaths.payables)
          .where('eventId', isEqualTo: eventId)
          .get();

      for (var doc in payablesSnapshot.docs) {
        final data = doc.data();
        final String studentId = data['studentId'] ?? '';
        data['id'] = doc.id; // Inject ID
        payablesMap[studentId] = data;
      }
    }

    onProgress?.call(0.8);

    // 4. Prepare local companions
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final List<CachedParticipantsCompanion> participantCompanions = [];
    final List<CachedPayablesCompanion> payableCompanions = [];

    for (final student in allStudents) {
      // Determine QR ticket unlocked status
      int qrTicketUnlocked = 0; // 0 = false, 1 = true
      
      if (!payablesEnabled) {
        qrTicketUnlocked = 1; // Always unlocked if payables are disabled
      } else {
        final payable = payablesMap[student.id];
        if (payable != null && payable['qrTicketUnlocked'] == true) {
          qrTicketUnlocked = 1;
        }
      }

      final studentMap = student.toFirestoreMap(
        uid: student.id,
        profilePhotoUrl: student.profilePhotoUrl,
        schoolIdPhotoUrl: student.schoolIdPhotoUrl,
      );
      studentMap['createdAt'] = student.createdAt.toIso8601String();
      studentMap['updatedAt'] = student.updatedAt.toIso8601String();

      participantCompanions.add(CachedParticipantsCompanion(
        id: Value(student.id),
        eventId: Value(eventId),
        studentName: Value('${student.firstName} ${student.lastName}'),
        studentNumber: Value(student.studentId),
        course: Value(student.courseCode),
        yearLevel: Value(int.tryParse(student.yearLevel.split(' ').first) ?? 1),
        profilePhotoUrl: Value(student.profilePhotoUrl),
        qrTicketUnlocked: Value(qrTicketUnlocked),
        participantJson: Value(json.encode(studentMap)),
        downloadedAt: Value(nowMs),
      ));

      if (payablesEnabled) {
        final payable = payablesMap[student.id];
        if (payable != null) {
          payableCompanions.add(CachedPayablesCompanion(
            id: Value(payable['id'] as String),
            eventId: Value(eventId),
            studentId: Value(student.id),
            qrTicketUnlocked: Value(payable['qrTicketUnlocked'] == true ? 1 : 0),
            amountDue: Value((payable['amountDue'] as num?)?.toDouble() ?? 0.0),
            paymentStatus: Value(payable['paymentStatus'] as String? ?? 'UNPAID'),
            cachedAt: Value(nowMs),
            studentName: Value('${student.firstName} ${student.lastName}'),
            studentIdNumber: Value(student.studentId),
            profilePhotoUrl: Value(student.profilePhotoUrl),
            eventTitle: Value(eventData['title'] as String? ?? ''),
            courseInfo: Value(student.courseCode),
          ));
        }
      }
    }

    await _finalizeDownload(eventId, participantCompanions, payableCompanions);
    onProgress?.call(1.0);

    return DownloadResult(
      studentCount: allStudents.length,
      downloadedAt: DateTime.now(),
    );
  }

  Future<void> _finalizeDownload(
    String eventId,
    List<CachedParticipantsCompanion> participants,
    List<CachedPayablesCompanion> payables,
  ) async {
    // Purge existing data for this event to avoid stale records
    await _participantsDao.purgeEventParticipants(eventId);
    await _payablesDao.purgeEventPayables(eventId);

    // Insert fresh data
    if (participants.isNotEmpty) {
      await _participantsDao.upsertParticipants(participants);
    }
    for (final p in payables) {
      await _payablesDao.upsertPayable(p);
    }

    // Mark as downloaded
    await _scannerDao.markDataDownloaded(eventId);
  }
}
