import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/models/student_model.dart';
import '../models/event_model.dart';
import '../repositories/event_repository.dart';

class EventState {
  final bool isLoading;
  final String? error;
  final List<EventModel> events;

  const EventState({
    this.isLoading = false,
    this.error,
    this.events = const [],
  });

  const EventState.loading() : isLoading = true, error = null, events = const [];
  const EventState.error(this.error) : isLoading = false, events = const [];
  const EventState.success(this.events) : isLoading = false, error = null;
}

class EventViewModel extends StateNotifier<EventState> {
  final EventRepository _repo;

  EventViewModel(this._repo) : super(const EventState.loading());

  Stream<List<EventModel>> watchEligibleEvents({
    String? studentId,
    StudentModel? student,
    List<String> studentOrgIds = const [],
  }) {
    return _repo.watchEligibleEvents(
      studentId: studentId,
      student: student,
      studentOrgIds: studentOrgIds,
    );
  }

  Future<void> cacheEligibleEvents({
    String? studentId,
    StudentModel? student,
    List<String> studentOrgIds = const [],
  }) async {
    try {
      await _repo.cacheEligibleEvents(
        studentId: studentId,
        student: student,
        studentOrgIds: studentOrgIds,
      );
    } catch (e) {
      // Ignored for background operations
    }
  }
}
