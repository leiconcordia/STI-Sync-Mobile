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

  const EventTicketConfig({
    required this.title,
    required this.enableQRTickets,
    required this.attendanceEnabled,
    required this.studentPayablesEnabled,
    required this.eventFee,
  });

  bool get isTicketAvailable => enableQRTickets || attendanceEnabled || studentPayablesEnabled;

  factory EventTicketConfig.fromEvent(EventModel event) => EventTicketConfig(
        title: event.title,
        enableQRTickets: event.enableQRTickets,
        attendanceEnabled: event.attendanceEnabled,
        studentPayablesEnabled: event.studentPayablesEnabled,
        eventFee: event.adminFeeOverride ?? 0,
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
      final isPaid = rawStatus == 'paid' || rawStatus == 'waived';
      final assigned = (data['assignedAmount'] as num?)?.toDouble() ?? 0.0;
      final paid = (data['paidAmount'] as num?)?.toDouble() ?? 0.0;
      final rawDue = (data['amountDue'] as num?)?.toDouble() ?? (assigned - paid > 0 ? assigned - paid : config.eventFee);

      return QrTicketStatus(
        isUnlocked: explicitUnlocked || isPaid,
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
  }) async {
    final snap = await _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .where('eventId', isEqualTo: eventId)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      final isFree = !config.studentPayablesEnabled;
      await _payablesDao.replacePayable(
          CachedPayablesCompanion(
            id: Value('${eventId}_$studentId'),
            eventId: Value(eventId),
            studentId: Value(studentId),
            qrTicketUnlocked: Value(isFree ? 1 : 0),
            amountDue: Value(isFree ? 0 : config.eventFee),
            paymentStatus: Value(isFree ? 'free' : 'unpaid'),
            cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
            studentName: Value(studentName),
            studentIdNumber: Value(studentIdNumber),
            profilePhotoUrl: Value(profilePhotoUrl),
            eventTitle: Value(eventTitle),
            courseInfo: Value(courseInfo),
          ),
          studentId: studentId,
          eventId: eventId);
      return;
    }

    final data = snap.docs.first.data();
    final rawStatus = data['status'] as String? ?? (data['paymentStatus'] as String? ?? 'unpaid');
    final isPaid = rawStatus == 'paid' || rawStatus == 'waived';
    final explicitUnlocked = data['qrTicketUnlocked'] as bool? ?? false;
    final isUnlocked = explicitUnlocked || isPaid;

    await _payablesDao.replacePayable(
        CachedPayablesCompanion(
          id: Value('${eventId}_$studentId'),
          eventId: Value(eventId),
          studentId: Value(studentId),
          qrTicketUnlocked: Value(isUnlocked ? 1 : 0),
          amountDue: Value(isPaid ? 0.0 : ((data['amountDue'] as num?)?.toDouble() ?? config.eventFee)),
          paymentStatus: Value(rawStatus),
          cachedAt: Value(DateTime.now().millisecondsSinceEpoch),
          studentName: Value(studentName),
          studentIdNumber: Value(studentIdNumber),
          profilePhotoUrl: Value(profilePhotoUrl),
          eventTitle: Value(eventTitle),
          courseInfo: Value(courseInfo),
        ),
        studentId: studentId,
        eventId: eventId);
  }

  Future<EventTicketConfig?> getEventTicketConfig(String eventId) async {
    try {
      final doc =
          await _firestore.collection(FirestorePaths.events).doc(eventId).get();
      if (!doc.exists) return null;
      final event = EventModel.fromFirestore(doc);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final expiresMs = DateTime.now().add(const Duration(days: 30)).millisecondsSinceEpoch;
      await _eventsDao.upsertEvent(
        CachedEventsCompanion.insert(
          id: eventId,
          title: event.title,
          eventJson: jsonEncode(event.toMap()),
          cachedAt: nowMs,
          expiresAt: expiresMs,
        ),
      );
      return EventTicketConfig.fromEvent(event);
    } catch (_) {
      return getLocalEventTicketConfig(eventId);
    }
  }


  Future<EventTicketConfig?> getLocalEventTicketConfig(String eventId) async {
    final cached = await _eventsDao.getEvent(eventId);
    if (cached != null) {
      try {
        final map = jsonDecode(cached.eventJson) as Map<String, dynamic>;
        final event = EventModel.fromMap(cached.id, map);
        return EventTicketConfig.fromEvent(event);
      } catch (_) {}
    }

    final payable = await _payablesDao.getPayableByEvent(eventId);
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
      String studentId, String eventId) async {
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
