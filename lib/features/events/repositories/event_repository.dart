import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../../core/exceptions/app_exception.dart';
import '../../../core/local/app_database.dart';
import '../../auth/models/student_model.dart';
import '../models/event_model.dart';

class EventRepository {
  final FirebaseFirestore _firestore;
  final AppDatabase _appDatabase;

  EventRepository(this._firestore, this._appDatabase);

  Stream<List<EventModel>> watchEligibleEvents(String studentId) {
    final studentStream = _firestore
        .collection(FirestorePaths.students)
        .doc(studentId)
        .snapshots()
        .map((doc) => doc.exists ? StudentModel.fromFirestore(doc) : null);

    final eventsStream = _firestore
        .collection(FirestorePaths.events)
        .where('proposalStatus', isEqualTo: 'approved')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => EventModel.fromFirestore(doc)).toList());

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

        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return filtered;
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
    } on FirebaseException catch (e) {
      throw AppException(code: e.code, message: e.message ?? 'Firestore error');
    } catch (e) {
      throw AppException(code: 'unknown', message: e.toString());
    }
  }
}
