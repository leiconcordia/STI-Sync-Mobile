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

  bool get isTicketAvailable => enableQRTickets && attendanceEnabled;

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
    await _payablesDao.replacePayable(
        CachedPayablesCompanion(
          id: Value('${eventId}_$studentId'),
          eventId: Value(eventId),
          studentId: Value(studentId),
          qrTicketUnlocked:
              Value((data['qrTicketUnlocked'] as bool? ?? false) ? 1 : 0),
          amountDue: Value((data['amountDue'] as num?)?.toDouble() ?? 0),
          paymentStatus: Value(data['paymentStatus'] as String? ?? 'unpaid'),
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
    final doc =
        await _firestore.collection(FirestorePaths.events).doc(eventId).get();
    if (!doc.exists) return null;
    return EventTicketConfig.fromEvent(EventModel.fromFirestore(doc));
  }

  Future<EventTicketConfig?> getLocalEventTicketConfig(String eventId) async {
    final cached = await _eventsDao.getEvent(eventId);
    if (cached == null) return null;
    try {
      return EventTicketConfig.fromEvent(
        EventModel.fromMap(cached.id, jsonDecode(cached.eventJson)),
      );
    } catch (_) {
      return null;
    }
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
