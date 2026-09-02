import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../../../core/local/app_database.dart';
import '../../../core/local/daos/participants_dao.dart';
import '../../../core/local/daos/payables_dao.dart';
import '../../../core/local/daos/scanner_dao.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/models/student_model.dart';
import '../../events/models/event_model.dart';
import '../models/scanner_assignment_model.dart';

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

  /// Downloads participants and their payable records for an event, storing
  /// them locally in Drift for 100% offline attendance verification.
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

    final event = EventModel.fromFirestore(eventDoc);
    final bool payablesEnabled = event.studentPayablesEnabled;

    // 1b. Refresh ScannerAssignments in local SQLite with latest session times and venue
    final eventData = eventDoc.data() ?? {};
    final customVenue = eventData['customVenueName'] as String?;
    final venueId = eventData['venueId'] as String? ?? event.venueId;
    final rawVenue = (eventData['venue'] as String?) ?? (eventData['venueName'] as String?);

    String resolvedVenue = (customVenue != null && customVenue.isNotEmpty)
        ? customVenue
        : (rawVenue != null && rawVenue.isNotEmpty ? rawVenue : '');

    if (resolvedVenue.isEmpty && venueId.isNotEmpty) {
      try {
        final vDoc = await _firestore.collection(FirestorePaths.venues).doc(venueId.trim()).get();
        if (vDoc.exists && vDoc.data() != null) {
          final data = vDoc.data()!;
          resolvedVenue = data['name'] as String? ??
              data['venueName'] as String? ??
              data['venue_name'] as String? ??
              data['title'] as String? ??
              data['venue'] as String? ??
              data['location'] as String? ??
              '';
        }
      } catch (_) {}
    }
    if (resolvedVenue.isEmpty) resolvedVenue = 'Campus Venue';
    final venue = resolvedVenue;

    final gracePeriod = (eventData['gracePeriodMinutes'] as num?)?.toInt();
    final lateThreshold = (eventData['lateThresholdMinutes'] as num?)?.toInt();
    final List<dynamic> rawSessions = eventData['sessions'] as List<dynamic>? ?? [];
    final sessions = rawSessions.map((s) {
      final sMap = Map<String, dynamic>.from(s as Map<String, dynamic>);
      if (sMap['gracePeriodMinutes'] == null && gracePeriod != null) {
        sMap['gracePeriodMinutes'] = gracePeriod;
      }
      if (sMap['lateThresholdMinutes'] == null && lateThreshold != null) {
        sMap['lateThresholdMinutes'] = lateThreshold;
      }
      return sMap;
    }).toList();

    final eventEndTime = ScannerAssignmentModel.computeLastEndTime(rawSessions);
    final existingAssignment = await _scannerDao.getAssignment(eventId);

    if (existingAssignment != null) {
      await _scannerDao.saveAssignment(ScannerAssignmentsCompanion(
        eventId: Value(eventId),
        eventTitle: Value(event.title),
        eventFormat: Value(venue),
        sessions: Value(json.encode(sessions)),
        officerUserId: Value(existingAssignment.officerUserId),
        permissions: Value(existingAssignment.permissions),
        eventEndTime: Value(eventEndTime.millisecondsSinceEpoch),
        proposalStatus: Value(eventData['proposalStatus'] as String? ?? 'approved'),
        gracePeriodMinutes: Value(gracePeriod),
        dataDownloaded: const Value(1),
        downloadedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ));
    }

    onProgress?.call(0.2);

    // 2. If Org Members-only event, resolve member student IDs
    final Set<String> memberStudentIds = {};
    if (event.targetAudienceScope == 'members' && event.hostingOrgId.isNotEmpty) {
      final membersSnap = await _firestore
          .collection(FirestorePaths.organizationMembers)
          .where('organizationId', isEqualTo: event.hostingOrgId)
          .get();

      for (var mDoc in membersSnap.docs) {
        final mData = mDoc.data();
        final sId = mData['studentId'] as String?;
        final sAuthUid = mData['studentAuthUid'] as String?;
        final sNum = mData['student_id'] as String?;
        if (sId != null && sId.isNotEmpty) memberStudentIds.add(sId);
        if (sAuthUid != null && sAuthUid.isNotEmpty) memberStudentIds.add(sAuthUid);
        if (sNum != null && sNum.isNotEmpty) memberStudentIds.add(sNum);
      }
    }

    // 3. Query Students with multi-factor audience eligibility filtering
    final List<StudentModel> allStudents = [];

    if (event.targetDepartmentIds.isNotEmpty) {
      final int batchSize = 30;
      for (int i = 0; i < event.targetDepartmentIds.length; i += batchSize) {
        final deptBatch = event.targetDepartmentIds.sublist(
          i,
          i + batchSize > event.targetDepartmentIds.length ? event.targetDepartmentIds.length : i + batchSize,
        );

        final querySnapshot = await _firestore
            .collection(FirestorePaths.students)
            .where('departmentId', whereIn: deptBatch)
            .get();

        for (var doc in querySnapshot.docs) {
          final student = StudentModel.fromFirestore(doc);
          final isStatusActive = student.status.toUpperCase() == 'ACTIVE' || student.status.isEmpty;
          if (isStatusActive) {
            final isMember = memberStudentIds.contains(student.id) ||
                memberStudentIds.contains(student.authUid) ||
                memberStudentIds.contains(student.studentId);
            final studentOrgs = isMember ? [event.hostingOrgId] : const <String>[];
            if (event.isStudentEligible(student, studentOrgIds: studentOrgs)) {
              allStudents.add(student);
            }
          }
        }
      }
    } else {
      // Query ALL departments and filter
      final querySnapshot = await _firestore
          .collection(FirestorePaths.students)
          .get();

      for (var doc in querySnapshot.docs) {
        final student = StudentModel.fromFirestore(doc);
        final isStatusActive = student.status.toUpperCase() == 'ACTIVE' || student.status.isEmpty;
        if (isStatusActive) {
          final isMember = memberStudentIds.contains(student.id) ||
              memberStudentIds.contains(student.authUid) ||
              memberStudentIds.contains(student.studentId);
          final studentOrgs = isMember ? [event.hostingOrgId] : const <String>[];
          if (event.isStudentEligible(student, studentOrgIds: studentOrgs)) {
            allStudents.add(student);
          }
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
      // Set QR ticket unlocked for all eligible participants (scanner trusts unlocked QR passes)
      const int qrTicketUnlocked = 1;

      final studentMap = student.toFirestoreMap(
        uid: student.id,
        profilePhotoUrl: student.profilePhotoUrl,
        schoolIdPhotoUrl: student.schoolIdPhotoUrl,
      );
      studentMap['createdAt'] = student.createdAt.toIso8601String();
      studentMap['updatedAt'] = student.updatedAt.toIso8601String();

      final numericYearStr = student.yearLevel.replaceAll(RegExp(r'[^0-9]'), '');
      final parsedYearLevel = int.tryParse(numericYearStr) ?? 1;

      participantCompanions.add(CachedParticipantsCompanion(
        id: Value(student.id),
        eventId: Value(eventId),
        studentName: Value('${student.firstName} ${student.lastName}'),
        studentNumber: Value(student.studentId),
        course: Value(student.courseCode),
        yearLevel: Value(parsedYearLevel),
        profilePhotoUrl: Value(student.profilePhotoUrl),
        qrTicketUnlocked: Value(qrTicketUnlocked),
        participantJson: Value(json.encode(studentMap)),
        downloadedAt: Value(nowMs),
      ));

      if (payablesEnabled) {
        final payable = payablesMap[student.id];
        if (payable != null) {
          final assigned = (payable['assignedAmount'] as num?)?.toDouble() ?? (payable['amount'] as num?)?.toDouble() ?? 0.0;
          final paid = (payable['paidAmount'] as num?)?.toDouble() ?? 0.0;
          final rawDue = (payable['amountDue'] as num?)?.toDouble() ?? (assigned - paid > 0 ? assigned - paid : 0.0);
          final rawStatus = payable['status'] as String? ?? (payable['paymentStatus'] as String? ?? 'pending');
          final isPaid = rawStatus == 'paid' || rawStatus == 'waived' || (assigned > 0 && paid >= assigned);
          final isUnlocked = (payable['qrTicketUnlocked'] == true) || isPaid;

          payableCompanions.add(CachedPayablesCompanion(
            id: Value(payable['id'] as String),
            eventId: Value(eventId),
            studentId: Value(student.id),
            studentName: Value('${student.firstName} ${student.lastName}'),
            studentSchoolId: Value(student.studentId),
            type: Value(payable['type'] as String? ?? 'event_fee'),
            label: Value(payable['label'] as String? ?? (event.title.isNotEmpty ? event.title : 'Event Fee')),
            description: Value(payable['description'] as String?),
            organizationId: Value(payable['organizationId'] as String?),
            organizationName: Value(payable['organizationName'] as String?),
            semesterId: Value(payable['semesterId'] as String? ?? ''),
            assignedAmount: Value(assigned),
            paidAmount: Value(paid),
            amountDue: Value(isPaid ? 0.0 : rawDue),
            status: Value(rawStatus),
            paymentStatus: Value(payable['paymentStatus'] as String? ?? rawStatus),
            qrTicketUnlocked: Value(isUnlocked ? 1 : 0),
            dueDate: Value((payable['dueDate'] as Timestamp?)?.millisecondsSinceEpoch),
            paidAt: Value((payable['paidAt'] as Timestamp?)?.millisecondsSinceEpoch),
            cachedAt: Value(nowMs),
            studentIdNumber: Value(student.studentId),
            profilePhotoUrl: Value(student.profilePhotoUrl),
            eventTitle: Value(event.title),
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

    // Fetch existing cloud attendance and flagged attendance records into local SQLite
    await fetchAndCacheRemoteAttendance(eventId);
  }

  /// Refreshes all offline event data (student roster, timing, and remote attendance)
  /// when online.
  Future<DownloadResult> refreshEventData(
    String eventId, {
    void Function(double progress)? onProgress,
  }) async {
    return downloadParticipantsForEvent(eventId, onProgress: onProgress);
  }

  /// Fetches existing attendance records from both `/events/{eventId}/attendance`
  /// AND `/events/{eventId}/flagged_attendance` in Firestore and caches them
  /// locally in Drift SQLite database with `synced = 1`.
  Future<void> fetchAndCacheRemoteAttendance(String eventId) async {
    try {
      final attendanceDao = _participantsDao.db.attendanceDao;

      // 0. Delete all previously-synced records for this event so that
      //    records deleted from Firestore are also removed locally.
      await attendanceDao.deleteSyncedForEvent(eventId);

      // 1. Fetch normal attendance subcollection
      final attendanceSnap = await _firestore
          .collection(FirestorePaths.eventAttendance(eventId))
          .get();

      for (final doc in attendanceSnap.docs) {
        final data = doc.data();
        final localId = data['localId'] as String? ?? doc.id;
        final rawGateType = data['gateType'] as String? ?? 'Time-In';
        final normalizedGateType = (rawGateType == 'time_in' || rawGateType == 'Time-In')
            ? 'Time-In'
            : (rawGateType == 'time_out' || rawGateType == 'Time-Out' ? 'Time-Out' : rawGateType);

        final scannedAtTs = data['scannedAt'];
        int scannedAtMs = DateTime.now().millisecondsSinceEpoch;
        if (scannedAtTs is Timestamp) {
          scannedAtMs = scannedAtTs.millisecondsSinceEpoch;
        } else if (scannedAtTs is int) {
          scannedAtMs = scannedAtTs;
        }

        final companion = OfflineAttendanceCompanion(
          localId: Value(localId),
          eventId: Value(eventId),
          sessionId: Value(data['sessionId'] as String? ?? ''),
          studentId: Value(data['studentId'] as String? ?? ''),
          studentName: Value(data['studentName'] as String? ?? ''),
          gateType: Value(normalizedGateType),
          scanMethod: Value(data['scanMethod'] as String? ?? 'QR'),
          scannedBy: Value(data['scannedByName'] as String? ?? data['scannedBy'] as String? ?? ''),
          scannedAt: Value(scannedAtMs),
          synced: const Value(1),
          syncedAt: Value(scannedAtMs),
          conflictResolved: const Value(0),
          status: Value(data['status'] as String? ?? 'Present'),
          isFlagged: Value(data['isFlagged'] == true ? 1 : 0),
          flagReason: Value(data['flagReason'] as String?),
          flagNote: Value(data['flagNote'] as String?),
          isManual: Value(data['isManual'] == true ? 1 : 0),
        );

        await attendanceDao.upsertOfflineRecord(companion);
      }

      // 2. Fetch flagged attendance subcollection
      final flaggedSnap = await _firestore
          .collection(FirestorePaths.eventFlaggedAttendance(eventId))
          .get();

      for (final doc in flaggedSnap.docs) {
        final data = doc.data();
        final localId = data['localId'] as String? ?? doc.id;
        final rawGateType = data['gateType'] as String? ?? 'Time-In';
        final normalizedGateType = (rawGateType == 'time_in' || rawGateType == 'Time-In')
            ? 'Time-In'
            : (rawGateType == 'time_out' || rawGateType == 'Time-Out' ? 'Time-Out' : rawGateType);

        final scannedAtTs = data['scannedAt'];
        int scannedAtMs = DateTime.now().millisecondsSinceEpoch;
        if (scannedAtTs is Timestamp) {
          scannedAtMs = scannedAtTs.millisecondsSinceEpoch;
        } else if (scannedAtTs is int) {
          scannedAtMs = scannedAtTs;
        }

        final companion = OfflineAttendanceCompanion(
          localId: Value(localId),
          eventId: Value(eventId),
          sessionId: Value(data['sessionId'] as String? ?? ''),
          studentId: Value(data['studentId'] as String? ?? ''),
          studentName: Value(data['studentName'] as String? ?? ''),
          gateType: Value(normalizedGateType),
          scanMethod: Value(data['scanMethod'] as String? ?? 'MANUAL'),
          scannedBy: Value(data['flaggedByName'] as String? ?? data['scannedByName'] as String? ?? data['scannedBy'] as String? ?? ''),
          scannedAt: Value(scannedAtMs),
          synced: const Value(1),
          syncedAt: Value(scannedAtMs),
          conflictResolved: const Value(0),
          status: Value(data['status'] as String? ?? 'Present'),
          isFlagged: const Value(1), // Always flagged
          flagReason: Value(data['flagReason'] as String?),
          flagNote: Value(data['flagNote'] as String?),
          isManual: Value(data['isManual'] == true ? 1 : 0),
        );

        await attendanceDao.upsertOfflineRecord(companion);
      }
    } catch (e) {
      debugPrint('OfflineAttendanceRepository: Error fetching remote attendance: $e');
    }
  }

  /// Inserts a flagged/manual attendance record into the local Drift queue.
  ///
  /// The record will be uploaded to `/flagged_attendance` (instead of
  /// `/attendance`) when [SyncService.uploadPendingAttendance] runs.
  Future<void> saveFlaggedRecord(OfflineAttendanceCompanion record) async {
    await _participantsDao.db.attendanceDao.insertOfflineRecord(record);
  }

  /// Searches cached participants by name or student number (offline-capable).
  ///
  /// Returns all participants for [eventId] whose `studentName` or
  /// `studentNumber` contains the [query] string (case-insensitive).
  Future<List<CachedParticipant>> searchParticipants(
    String eventId,
    String query,
  ) async {
    if (query.isEmpty) return [];

    final all = await _participantsDao.getAllForEvent(eventId);
    final lowerQuery = query.toLowerCase();

    return all.where((p) {
      final nameMatch = p.studentName.toLowerCase().contains(lowerQuery);
      final numberMatch =
          p.studentNumber?.toLowerCase().contains(lowerQuery) ?? false;
      return nameMatch || numberMatch;
    }).toList();
  }

  /// Deletes attendance records for a student from both Firestore subcollections
  /// (`/events/{eventId}/attendance` and `/events/{eventId}/flagged_attendance`)
  /// and the local Drift database.
  Future<void> deleteAttendanceRecord({
    required String eventId,
    required String sessionId,
    required String studentId,
    String? studentNumber,
  }) async {
    // 1. Delete from Firestore (both /attendance and /flagged_attendance)
    try {
      final targetStudentIds = <String>{
        if (studentId.isNotEmpty) studentId,
        if (studentNumber != null && studentNumber.isNotEmpty) studentNumber,
      };

      final collections = [
        FirestorePaths.eventAttendance(eventId),
        FirestorePaths.eventFlaggedAttendance(eventId),
      ];

      for (final collPath in collections) {
        for (final sId in targetStudentIds) {
          final snap = await _firestore
              .collection(collPath)
              .where('studentId', isEqualTo: sId)
              .get();

          for (final doc in snap.docs) {
            final data = doc.data();
            final docSessionId = data['sessionId'] as String? ?? '';
            if (sessionId.isEmpty || docSessionId.isEmpty || docSessionId == sessionId) {
              await doc.reference.delete();
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OfflineAttendanceRepository: Error deleting attendance from Firestore: $e');
    }

    // 2. Delete from local Drift database (both normal and flagged)
    await _participantsDao.db.attendanceDao.deleteRecordsForStudent(
      eventId: eventId,
      studentId: studentId,
      studentNumber: studentNumber,
      sessionId: sessionId,
    );
  }
}
