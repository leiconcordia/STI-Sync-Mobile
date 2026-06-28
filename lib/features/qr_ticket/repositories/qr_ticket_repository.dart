import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import 'package:sti_sync/core/local/daos/payables_dao.dart';
import 'package:sti_sync/core/local/app_database.dart';
import 'package:sti_sync/features/sync/services/connectivity_service.dart';

class QrTicketStatus {
  final bool isUnlocked;
  final double amountDue;
  final String paymentStatus;
  
  // Offline cached fields
  final String? studentName;
  final String? studentIdNumber;
  final String? profilePhotoUrl;
  final String? eventTitle;
  final String? courseInfo;

  const QrTicketStatus({
    required this.isUnlocked,
    required this.amountDue,
    required this.paymentStatus,
    this.studentName,
    this.studentIdNumber,
    this.profilePhotoUrl,
    this.eventTitle,
    this.courseInfo,
  });
}

class QrTicketRepository {
  final FirebaseFirestore _firestore;
  final PayablesDao _payablesDao;
  final ConnectivityService _connectivity;

  QrTicketRepository(this._firestore, this._payablesDao, this._connectivity);

  /// Watches the payable status from Firestore in real-time.
  /// Returns a stream of QrTicketStatus.
  /// If no payable doc exists → free event, always unlocked.
  Stream<QrTicketStatus> watchTicketStatus(String studentId, String eventId) {
    return _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        // No payable = free event
        return const QrTicketStatus(
          isUnlocked: true,
          amountDue: 0,
          paymentStatus: 'free',
        );
      }
      final data = snap.docs.first.data();
      return QrTicketStatus(
        isUnlocked: data['qrTicketUnlocked'] as bool? ?? false,
        amountDue: (data['amountDue'] as num?)?.toDouble() ?? 0,
        paymentStatus: data['paymentStatus'] as String? ?? 'unpaid',
      );
    });
  }

  /// Fetches the payable from Firestore and caches it into the Drift table.
  Future<void> cacheTicketStatus(
    String studentId, 
    String eventId, {
    String? studentName,
    String? studentIdNumber,
    String? profilePhotoUrl,
    String? eventTitle,
    String? courseInfo,
  }) async {
    final snap = await _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      // Cache a "free event" entry so offline knows it's unlocked
      await _payablesDao.upsertPayable(CachedPayablesCompanion(
        id: Value('${eventId}_$studentId'),
        eventId: Value(eventId),
        studentId: Value(studentId),
        qrTicketUnlocked: const Value(1),
        amountDue: const Value(0),
        paymentStatus: const Value('free'),
        cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
        studentName: Value(studentName),
        studentIdNumber: Value(studentIdNumber),
        profilePhotoUrl: Value(profilePhotoUrl),
        eventTitle: Value(eventTitle),
        courseInfo: Value(courseInfo),
      ));
      return;
    }

    final data = snap.docs.first.data();
    await _payablesDao.upsertPayable(CachedPayablesCompanion(
      id: Value(snap.docs.first.id),
      eventId: Value(eventId),
      studentId: Value(studentId),
      qrTicketUnlocked: Value((data['qrTicketUnlocked'] as bool? ?? false) ? 1 : 0),
      amountDue: Value((data['amountDue'] as num?)?.toDouble() ?? 0),
      paymentStatus: Value(data['paymentStatus'] as String? ?? 'unpaid'),
      cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
      studentName: Value(studentName),
      studentIdNumber: Value(studentIdNumber),
      profilePhotoUrl: Value(profilePhotoUrl),
      eventTitle: Value(eventTitle),
      courseInfo: Value(courseInfo),
    ));
  }

  /// Reads the ticket status from the local Drift cache. Works offline.
  Future<QrTicketStatus?> getLocalTicketStatus(String studentId, String eventId) async {
    final cached = await _payablesDao.getPayable(studentId, eventId);
    if (cached == null) return null;
    return QrTicketStatus(
      isUnlocked: cached.qrTicketUnlocked == 1,
      amountDue: cached.amountDue,
      paymentStatus: cached.paymentStatus,
      studentName: cached.studentName,
      studentIdNumber: cached.studentIdNumber,
      profilePhotoUrl: cached.profilePhotoUrl,
      eventTitle: cached.eventTitle,
      courseInfo: cached.courseInfo,
    );
  }

  /// Fetches the student's Firestore document.
  Future<Map<String, dynamic>?> getStudentData(String studentAuthUid) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.students).doc(studentAuthUid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
    } catch (_) {}
    return null;
  }

  /// Fetches the event title from Firestore.
  Future<String> getEventTitle(String eventId) async {
    try {
      final doc = await _firestore.collection(FirestorePaths.events).doc(eventId).get();
      if (doc.exists) {
        return (doc.data() as Map<String, dynamic>)['title'] as String? ?? 'Event';
      }
    } catch (_) {}
    return 'Event';
  }

  bool get isOnline => _connectivity.isOnline;
}
