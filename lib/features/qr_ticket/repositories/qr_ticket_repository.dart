import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import 'package:sti_sync/core/local/daos/events_dao.dart';
import 'package:sti_sync/core/local/daos/payables_dao.dart';
import 'package:sti_sync/core/local/app_database.dart';
import 'package:sti_sync/features/events/models/event_model.dart';
import 'package:sti_sync/features/sync/services/connectivity_service.dart';

class EventTicketConfig {
  final String title;
  final bool enableQRTickets;
  final bool attendanceEnabled;
  final bool studentPayablesEnabled;
  final double eventFee;
  final bool isCancelled;
  final String? cancellationReason;
  final String? refundPolicy;
  final DateTime? cancelledAt;
  final bool isCompleted;
  final bool isArchived;
  final bool isDeleted;
  final bool attendanceLocked;
  final bool certificatesEnabled;

  const EventTicketConfig({
    required this.title,
    required this.enableQRTickets,
    required this.attendanceEnabled,
    required this.studentPayablesEnabled,
    required this.eventFee,
    this.isCancelled = false,
    this.cancellationReason,
    this.refundPolicy,
    this.cancelledAt,
    this.isCompleted = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.attendanceLocked = false,
    this.certificatesEnabled = false,
  });

  bool get isTicketAvailable => enableQRTickets || attendanceEnabled || studentPayablesEnabled;

  factory EventTicketConfig.fromEvent(EventModel event) => EventTicketConfig(
        title: event.title,
        enableQRTickets: event.requiresAttendance,
        attendanceEnabled: event.requiresAttendance,
        studentPayablesEnabled: event.studentPayablesEnabled,
        eventFee: event.adminFeeOverride ?? 0,
        isCancelled: event.isEffectivelyCancelled,
        cancellationReason: event.cancellationReason,
        refundPolicy: event.refundPolicy,
        cancelledAt: event.cancelledAt,
        isCompleted: event.isCompleted,
        isArchived: event.isArchived,
        isDeleted: event.isDeleted,
        attendanceLocked: event.attendanceLocked,
        certificatesEnabled: event.certificatesEnabled,
      );
}

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
  final EventsDao _eventsDao;
  final ConnectivityService _connectivity;

  QrTicketRepository(
    this._firestore,
    this._payablesDao,
    this._eventsDao,
    this._connectivity,
  );

  /// Watches the payable status from Firestore in real-time.
  /// Returns a stream of QrTicketStatus.
  /// If no payable doc exists → free event, always unlocked.
  Stream<QrTicketStatus> watchTicketStatus(
    String studentId,
    String eventId,
    EventTicketConfig config,
  ) {
    return _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) {
        // A missing payable is free only when the event itself has no fee.
        return QrTicketStatus(
          isUnlocked: !config.studentPayablesEnabled,
          amountDue: config.studentPayablesEnabled ? config.eventFee : 0,
          paymentStatus: config.studentPayablesEnabled ? 'unpaid' : 'free',
        );
      }
      final data = snap.docs.first.data();
      final explicitUnlocked = data['qrTicketUnlocked'] as bool? ?? false;
      final rawStatus = data['status'] as String? ?? (data['paymentStatus'] as String? ?? 'unpaid');
      final assigned = (data['assignedAmount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? config.eventFee;
      final paid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final rawDue = (data['amountDue'] as num?)?.toDouble() ?? (assigned - paid > 0 ? assigned - paid : 0.0);
      
      // Strict 100% full settlement policy (Option A)
      final isPaid = rawStatus == 'paid' || rawStatus == 'waived' || (assigned > 0 && paid >= assigned);
      final isUnlocked = explicitUnlocked || isPaid;

      return QrTicketStatus(
        isUnlocked: isUnlocked,
        amountDue: isPaid ? 0.0 : (rawDue > 0 ? rawDue : config.eventFee),
        paymentStatus: rawStatus,
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
    required EventTicketConfig config,
    String? alternateStudentId,
  }) async {
    var snap = await _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty && alternateStudentId != null && alternateStudentId.isNotEmpty) {
      snap = await _firestore
          .collection(FirestorePaths.payables)
          .where('studentId', isEqualTo: alternateStudentId)
          .where('eventId', isEqualTo: eventId)
          .limit(1)
          .get();
    }

    if (snap.docs.isEmpty) {
      final isFree = !config.studentPayablesEnabled;
      final companion = CachedPayablesCompanion(
        id: Value('${eventId}_$studentId'),
        eventId: Value(eventId),
        studentId: Value(studentId),
        studentSchoolId: Value(studentIdNumber),
        qrTicketUnlocked: Value(isFree ? 1 : 0),
        amountDue: Value(isFree ? 0 : config.eventFee),
        paymentStatus: Value(isFree ? 'free' : 'unpaid'),
        cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
        studentName: Value(studentName),
        studentIdNumber: Value(studentIdNumber),
        profilePhotoUrl: Value(profilePhotoUrl),
        eventTitle: Value(eventTitle),
        courseInfo: Value(courseInfo),
      );
      await _payablesDao.replacePayable(
          companion,
          studentId: studentId,
          eventId: eventId);
      if (studentIdNumber != null && studentIdNumber.isNotEmpty && studentIdNumber != studentId) {
        await _payablesDao.replacePayable(
            companion.copyWith(
              id: Value('${eventId}_$studentIdNumber'),
              studentId: Value(studentIdNumber),
            ),
            studentId: studentIdNumber,
            eventId: eventId);
      }
      return;
    }

    final data = snap.docs.first.data();
    final explicitUnlocked = data['qrTicketUnlocked'] as bool? ?? false;
    final rawStatus = data['status'] as String? ?? (data['paymentStatus'] as String? ?? 'unpaid');
    final assigned = (data['assignedAmount'] as num?)?.toDouble() ?? (data['amount'] as num?)?.toDouble() ?? config.eventFee;
    final paid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
    final rawDue = (data['amountDue'] as num?)?.toDouble() ?? (assigned - paid > 0 ? assigned - paid : 0.0);
    
    // Strict Option A: Partial payment does not unlock QR code
    final isPaid = rawStatus == 'paid' || rawStatus == 'waived' || (assigned > 0 && paid >= assigned);
    final isUnlocked = explicitUnlocked || isPaid;

    final companion = CachedPayablesCompanion(
      id: Value(snap.docs.first.id),
      eventId: Value(eventId),
      studentId: Value(studentId),
      studentSchoolId: Value(studentIdNumber),
      type: Value(data['type'] as String? ?? 'event_fee'),
      label: Value(data['label'] as String? ?? (data['title'] as String? ?? 'Event Fee')),
      description: Value(data['description'] as String?),
      organizationId: Value(data['organizationId'] as String?),
      organizationName: Value(data['organizationName'] as String?),
      semesterId: Value(data['semesterId'] as String? ?? ''),
      assignedAmount: Value(assigned),
      paidAmount: Value(paid),
      status: Value(data['status'] as String? ?? 'pending'),
      qrTicketUnlocked: Value(isUnlocked ? 1 : 0),
      amountDue: Value(isPaid ? 0.0 : (rawDue > 0 ? rawDue : config.eventFee)),
      paymentStatus: Value(rawStatus),
      cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
      studentName: Value(studentName),
      studentIdNumber: Value(studentIdNumber),
      profilePhotoUrl: Value(profilePhotoUrl),
      eventTitle: Value(eventTitle),
      courseInfo: Value(courseInfo),
    );

    await _payablesDao.replacePayable(
        companion,
        studentId: studentId,
        eventId: eventId);
    if (studentIdNumber != null && studentIdNumber.isNotEmpty && studentIdNumber != studentId) {
      await _payablesDao.replacePayable(
          companion.copyWith(
            id: Value('${eventId}_$studentIdNumber'),
            studentId: Value(studentIdNumber),
          ),
          studentId: studentIdNumber,
          eventId: eventId);
    }
  }


  Future<EventTicketConfig?> getEventTicketConfig(String eventId, [String? studentId]) async {
    try {
      var doc =
          await _firestore.collection(FirestorePaths.activities).doc(eventId).get();
      if (!doc.exists) {
        doc = await _firestore.collection(FirestorePaths.events).doc(eventId).get();
      }
      if (!doc.exists) return null;
      final event = EventModel.fromFirestore(doc);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresMs = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      await _eventsDao.upsertEvent(
        CachedEventsCompanion.insert(
          id: eventId,
          title: event.title,
          eventJson: event.toJson(),
          cachedAt: nowMs,
          expiresAt: expiresMs,
        ),
      );
      return EventTicketConfig.fromEvent(event);
    } catch (_) {
      return getLocalEventTicketConfig(eventId, studentId);
    }
  }


  Future<EventTicketConfig?> getLocalEventTicketConfig(String eventId, [String? studentId, String? alternateStudentId]) async {
    final cached = await _eventsDao.getEvent(eventId);
    if (cached != null) {
      try {
        final map = jsonDecode(cached.eventJson) as Map<String, dynamic>;
        final event = EventModel.fromMap(cached.id, map);
        return EventTicketConfig.fromEvent(event);
      } catch (_) {}
    }

    var payable = await _payablesDao.getPayableByEvent(eventId, studentId);
    if (payable == null && alternateStudentId != null && alternateStudentId.isNotEmpty) {
      payable = await _payablesDao.getPayableByEvent(eventId, alternateStudentId);
    }
    payable ??= await _payablesDao.getPayableByEvent(eventId);
    if (payable != null) {
      return EventTicketConfig(
        title: payable.eventTitle ?? 'STI Event',
        enableQRTickets: true,
        attendanceEnabled: true,
        studentPayablesEnabled: payable.amountDue > 0 || payable.paymentStatus != 'free',
        eventFee: payable.amountDue,
      );
    }
    return null;
  }


  /// Reads the ticket status from the local Drift cache. Works offline.
  Future<QrTicketStatus?> getLocalTicketStatus(
      String studentId, String eventId, [String? alternateStudentId]) async {
    var cached = await _payablesDao.getPayable(studentId, eventId);
    if (cached == null && alternateStudentId != null && alternateStudentId.isNotEmpty) {
      cached = await _payablesDao.getPayable(alternateStudentId, eventId);
    }
    cached ??= await _payablesDao.getPayableByEvent(eventId, studentId);
    if (cached == null && alternateStudentId != null && alternateStudentId.isNotEmpty) {
      cached = await _payablesDao.getPayableByEvent(eventId, alternateStudentId);
    }
    cached ??= await _payablesDao.getPayableByEvent(eventId);
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
      final doc = await _firestore
          .collection(FirestorePaths.students)
          .doc(studentAuthUid)
          .get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }
    } catch (_) {}
    return null;
  }

  bool get isOnline => _connectivity.isOnline;

  Future<bool> checkOnline() => _connectivity.checkConnectivity();
}
