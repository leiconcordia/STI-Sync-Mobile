import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  EventRepository(this._firestore, this._appDatabase, this._connectivityService);

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
        .map((snap) => snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList())
        .doOnData((events) => _cacheEventsSilently(events));

    final localEventsStream = _appDatabase.eventsDao.watchAllEvents().map((cachedList) {
      return cachedList.map((cached) {
        try {
          return EventModel.fromMap(cached.id, jsonDecode(cached.eventJson));
        } catch (_) {
          return null;
        }
      }).whereType<EventModel>().toList();
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

        // Deduplicate by event title to prevent accidental duplicates
        final uniqueEvents = <String, EventModel>{};
        for (var event in filtered) {
          uniqueEvents[event.title.toLowerCase().trim()] = event;
        }

        final deduplicatedList = uniqueEvents.values.toList();
        deduplicatedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return deduplicatedList;
      },
    ).handleError((e) {
      if (e is FirebaseException) {
        throw AppException(code: e.code, message: e.message ?? 'Firestore error');
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

  Future<void> _cacheEventsSilently(List<EventModel> events) async {
    try {
      final companions = events.map((event) {
        int expiresAt = DateTime.now().millisecondsSinceEpoch + const Duration(hours: 24).inMilliseconds;
        
        if (event.sessions.isNotEmpty) {
           try {
             final lastSession = event.sessions.last;
             final dateTimeStr = '${lastSession.date} ${lastSession.endTime}:00';
             final dt = DateTime.parse(dateTimeStr);
             expiresAt = dt.millisecondsSinceEpoch + const Duration(hours: 24).inMilliseconds;
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
