import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import '../../../features/sync/services/connectivity_service.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/local/app_database.dart';
import '../../auth/models/student_model.dart';
import '../models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore;
  final AppDatabase _appDatabase;
  final ConnectivityService _connectivityService;

  EventRepository(
      this._firestore, this._appDatabase, this._connectivityService);

  Stream<List<EventModel>> watchEligibleEvents(String studentId) {
    final studentStream = _firestore
        .collection(FirestorePaths.students)
        .doc(studentId)
        .snapshots()
        .map((doc) => doc.exists ? StudentModel.fromFirestore(doc) : null);

    final firestoreEventsStream = _firestore
        .collection(FirestorePaths.events)
        .where('proposalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList());

    final localEventsStream =
        _appDatabase.eventsDao.watchAllEvents().map((cachedList) {
      return cachedList
          .map((cached) {
            try {
              return EventModel.fromMap(
                  cached.id, jsonDecode(cached.eventJson));
            } catch (_) {
              return null;
            }
          })
          .whereType<EventModel>()
          .toList();
    });

    final eventsStream = _connectivityService.connectivityStream
        .startWith(_connectivityService.isOnline)
        .switchMap((isOnline) {
      return isOnline ? firestoreEventsStream : localEventsStream;
    });

    return Rx.combineLatest2<StudentModel?, List<EventModel>, List<EventModel>>(
      studentStream,
      eventsStream,
      (student, events) {
        if (student == null) return [];

        final filtered = events.where((event) {
          final isDeptEligible = event.targetDepartmentIds.isEmpty ||
              event.targetDepartmentIds.contains(student.departmentId);
          final isYearEligible = event.targetYearLevels.isEmpty ||
              event.targetYearLevels.contains(student.yearLevel);

          return isDeptEligible && isYearEligible;
        }).toList();

        // Sort by newest first
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
      },
    ).doOnData((events) {
      _cacheEventsSilently(events);
      if (_connectivityService.isOnline) {
        _cacheTicketStatesSilently(studentId, events);
      }
    }).handleError((e) {
      if (e is FirebaseException) {
        throw AppException(
            code: e.code, message: e.message ?? 'Firestore error');
      }
      throw AppException(code: 'unknown', message: e.toString());
    });
  }

  Future<void> cacheEligibleEvents(String studentId) async {
    try {
      final events = await watchEligibleEvents(studentId).first;
      await _cacheEventsSilently(events);
    } on FirebaseException catch (e) {
      throw AppException(code: e.code, message: e.message ?? 'Firestore error');
    } catch (e) {
      throw AppException(code: 'unknown', message: e.toString());
    }
  }

  /// Streams one event from Firestore while online and the full cached event
  /// document from Drift while offline. This keeps Event Details usable after
  /// the student has loaded the event feed once.
  Stream<EventModel?> watchEventDetail(
    String eventId, {
    String? studentId,
  }) {
    final remote = _firestore
        .collection(FirestorePaths.events)
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists ? EventModel.fromFirestore(doc) : null)
        .doOnData((event) {
      if (event != null) _cacheEventsSilently([event]);
    });

    final local = _appDatabase.eventsDao.watchEvent(eventId).map((cached) {
      if (cached == null) return null;
      try {
        return EventModel.fromMap(cached.id, jsonDecode(cached.eventJson));
      } catch (_) {
        return null;
      }
    });

    return _connectivityService.connectivityStream
        .startWith(_connectivityService.isOnline)
        .switchMap((isOnline) => isOnline ? remote : local)
        .doOnData((event) {
      if (event != null && studentId != null && _connectivityService.isOnline) {
        _cacheTicketStatesSilently(studentId, [event]);
      }
    });
  }

  /// Prepares locally-renderable ticket states for every eligible event in one
  /// payable query, rather than requiring a student to open each ticket first.
  Future<void> cacheTicketStatesForEvents(
    String studentId,
    List<EventModel> events,
  ) async {
    if (events.isEmpty) return;

    final payableSnapshot = await _firestore
        .collection(FirestorePaths.payables)
        .where('studentId', isEqualTo: studentId)
        .get();
    final payablesByEvent =
        <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
      for (final payable in payableSnapshot.docs)
        (payable.data()['eventId'] as String? ?? ''): payable,
    };
    final now = DateTime.now().millisecondsSinceEpoch;

    for (final event in events) {
      final payable = payablesByEvent[event.id];
      final isFree = !event.studentPayablesEnabled;
      final data = payable?.data();
      await _appDatabase.payablesDao.replacePayable(
          CachedPayablesCompanion(
            id: Value('${event.id}_$studentId'),
            eventId: Value(event.id),
            studentId: Value(studentId),
            qrTicketUnlocked:
                Value(isFree || (data?['qrTicketUnlocked'] == true) ? 1 : 0),
            amountDue: Value(
              isFree
                  ? 0
                  : (data?['amountDue'] as num?)?.toDouble() ??
                      (event.adminFeeOverride ?? 0),
            ),
            paymentStatus: Value(
              isFree ? 'free' : data?['paymentStatus'] as String? ?? 'unpaid',
            ),
            cachedAt: Value(now),
            eventTitle: Value(event.title),
          ),
          studentId: studentId,
          eventId: event.id);
    }
  }

  Future<void> _cacheTicketStatesSilently(
    String studentId,
    List<EventModel> events,
  ) async {
    try {
      await cacheTicketStatesForEvents(studentId, events);
    } catch (_) {
      // Event display remains available even if ticket-state prefetch fails.
    }
  }

  Future<void> _cacheEventsSilently(List<EventModel> events) async {
    try {
      final companions = events.map((event) {
        int expiresAt = DateTime.now().millisecondsSinceEpoch +
            const Duration(hours: 24).inMilliseconds;

        if (event.sessions.isNotEmpty) {
          try {
            final lastSession = event.sessions.last;
            final dateTimeStr = '${lastSession.date} ${lastSession.endTime}:00';
            final dt = DateTime.parse(dateTimeStr);
            expiresAt = dt.millisecondsSinceEpoch +
                const Duration(hours: 24).inMilliseconds;
          } catch (_) {}
        }

        return CachedEventsCompanion.insert(
          id: event.id,
          title: event.title,
          eventJson: event.toJson(),
          cachedAt: DateTime.now().millisecondsSinceEpoch,
          expiresAt: expiresAt,
        );
      }).toList();

      await _appDatabase.batch((batch) {
        batch.insertAllOnConflictUpdate(_appDatabase.cachedEvents, companions);
      });
    } catch (_) {
      // Ignore background caching errors
    }
  }
}
