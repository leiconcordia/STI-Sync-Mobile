import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanner_assignment_model.dart';
import '../repositories/scanner_repository.dart';
import '../repositories/offline_attendance_repository.dart';

/// Immutable UI state for the scanner feature.
class ScannerState {
  /// All active (non-expired, approved) assignments for the current officer.
  final List<ScannerAssignmentModel> assignments;

  /// The eventId the officer has currently selected, if any.
  final String? selectedEventId;

  /// The sessionId the officer has selected within the chosen event.
  final String? selectedSessionId;

  /// Gate type selected by the officer: 'time_in' | 'time_out'.
  final String? gateType;

  /// True while the Firestore stream is being initialized.
  final bool isLoading;

  /// Non-null when a stream or repository error has occurred.
  final String? errorMessage;

  /// The eventId currently being downloaded.
  final String? downloadingEventId;

  /// Progress of the active download (0.0 to 1.0).
  final double downloadProgress;

  /// Error message from a failed download.
  final String? downloadError;

  const ScannerState({
    this.assignments = const [],
    this.selectedEventId,
    this.selectedSessionId,
    this.gateType,
    this.isLoading = false,
    this.errorMessage,
    this.downloadingEventId,
    this.downloadProgress = 0.0,
    this.downloadError,
  });

  /// True if at least one assignment is still within its event window.
  bool get hasActiveAssignments => assignments.any((a) => a.isActive);

  ScannerState copyWith({
    List<ScannerAssignmentModel>? assignments,
    String? selectedEventId,
    String? selectedSessionId,
    String? gateType,
    bool? isLoading,
    String? errorMessage,
    String? downloadingEventId,
    double? downloadProgress,
    String? downloadError,
    bool clearError = false,
    bool clearSelection = false,
    bool clearDownloading = false,
  }) {
    return ScannerState(
      assignments: assignments ?? this.assignments,
      selectedEventId:
          clearSelection ? null : selectedEventId ?? this.selectedEventId,
      selectedSessionId:
          clearSelection ? null : selectedSessionId ?? this.selectedSessionId,
      gateType: clearSelection ? null : gateType ?? this.gateType,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      downloadingEventId: clearDownloading ? null : downloadingEventId ?? this.downloadingEventId,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      downloadError: clearError ? null : downloadError ?? this.downloadError,
    );
  }
}

/// Manages scanner assignment state for the current authenticated officer.
///
/// Subscribes to `ScannerRepository.watchScannerAssignments()` and mirrors
/// the Firestore stream into local state. Also writes each assignment to the
/// Drift cache so they are available offline.
class ScannerViewModel extends StateNotifier<ScannerState> {
  final ScannerRepository _repo;
  final OfflineAttendanceRepository _offlineRepo;
  StreamSubscription<List<ScannerAssignmentModel>>? _subscription;

  ScannerViewModel(this._repo, this._offlineRepo) : super(const ScannerState());

  /// Begins watching Firestore for assignments where this officer is a scanner.
  ///
  /// Cancels any existing subscription first. Each emission saves assignments
  /// locally and prunes any expired ones.
  void loadAssignments(String officerUserId) {
    if (officerUserId.isEmpty) return;

    // Cancel previous subscription if reloading
    _subscription?.cancel();

    state = state.copyWith(isLoading: true, clearError: true);

    // 1. Immediately load locally cached assignments from Drift for instant offline compatibility
    _repo.getLocalAssignments().then((localList) {
      if (localList.isNotEmpty && state.assignments.isEmpty) {
        final sorted = List<ScannerAssignmentModel>.from(localList)
          ..sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));
        state = state.copyWith(
          assignments: sorted,
          isLoading: false,
        );
      }
    }).catchError((e) {
      debugPrint('ScannerViewModel: Error reading local assignments: $e');
    });

    // 2. Watch live Firestore assignments
    _subscription = _repo
        .watchScannerAssignments(officerUserId)
        .listen(
      (assignments) async {
        debugPrint('ScannerViewModel: Received ${assignments.length} assignments from Firestore');

        // Persist all current assignments (including cancelled status) to Drift for offline use
        for (final assignment in assignments) {
          try {
            await _repo.saveAssignmentLocally(assignment);
          } catch (e) {
            debugPrint('ScannerViewModel: Failed to save to Drift: $e');
          }
        }

        // Remove any locally cached assignments whose events have ended
        try {
          await _repo.removeExpiredAssignments();
        } catch (e) {
          debugPrint('ScannerViewModel: Failed to remove expired: $e');
        }

        // Fetch fresh local assignments to get the preserved dataDownloaded flags
        final localAssignments = await _repo.getLocalAssignments();

        // Combine Firestore assignments and local assignments by eventId so no assigned/cached event is lost
        final allMap = <String, ScannerAssignmentModel>{};
        for (final local in localAssignments) {
          allMap[local.eventId] = local;
        }
        for (final a in assignments) {
          final local = allMap[a.eventId];
          final isEffCancelled = a.isEffectivelyCancelled || (local?.isEffectivelyCancelled ?? false);
          allMap[a.eventId] = a.copyWith(
            dataDownloaded: local?.dataDownloaded ?? a.dataDownloaded,
            downloadedAt: local?.downloadedAt ?? a.downloadedAt,
            isCancelled: isEffCancelled,
            status: isEffCancelled ? 'cancelled' : a.status,
            proposalStatus: isEffCancelled ? 'cancelled' : a.proposalStatus,
            cancellationReason: a.cancellationReason ?? local?.cancellationReason,
          );
        }

        // Expose active events PLUS any cancelled events so the cancelled badge and disabled buttons are always visible
        final displayAssignments = allMap.values
            .where((a) => a.isActive || a.isEffectivelyCancelled)
            .toList();

        // Sort by newest first (eventEndTime descending)
        displayAssignments.sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));

        state = state.copyWith(
          assignments: displayAssignments,
          isLoading: false,
          clearError: true,
        );
      },
      onError: (Object error) async {
        // Fallback to local assignments on network error / offline
        final localAssignments = await _repo.getLocalAssignments();
        final sorted = List<ScannerAssignmentModel>.from(localAssignments)
          ..sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));
        state = state.copyWith(
          assignments: sorted,
          isLoading: false,
          errorMessage: 'Offline mode: loaded cached assignments.',
        );
      },
    );
  }

  /// Selects an event from the assignments list.
  ///
  /// Resets session and gate selections when a new event is chosen.
  void selectEvent(String eventId) {
    state = state.copyWith(
      selectedEventId: eventId,
      selectedSessionId: null,
      gateType: null,
    );
  }

  /// Selects a session and gate type within the currently selected event.
  ///
  /// Both values must be set before the scanner camera can open.
  void selectSession(String sessionId, String gateType) {
    state = state.copyWith(
      selectedSessionId: sessionId,
      gateType: gateType,
    );
  }

  /// Sets the currently selected session ID.
  void setSelectedSessionId(String sessionId) {
    state = state.copyWith(selectedSessionId: sessionId);
  }

  /// Initiates an offline participant data download for [eventId].
  Future<void> downloadParticipantData(String eventId) async {
    if (state.downloadingEventId != null) return; // Prevent concurrent downloads

    state = state.copyWith(
      downloadingEventId: eventId,
      downloadProgress: 0.0,
      downloadError: null,
      clearError: true,
    );

    try {
      final result = await _offlineRepo.downloadParticipantsForEvent(
        eventId,
        onProgress: (progress) {
          state = state.copyWith(downloadProgress: progress);
        },
      );

      // Successfully downloaded. Update the local assignments so the UI updates
      // to reflect dataDownloaded = true immediately.
      final localAssignments = await _repo.getLocalAssignments();
      
      // Update our current assignments list with the fresh local ones
      final updatedAssignments = state.assignments.map((a) {
        if (a.eventId == eventId) {
          final local = localAssignments.firstWhere((l) => l.eventId == eventId, orElse: () => a);
          return local;
        }
        return a;
      }).toList();

      state = state.copyWith(
        clearDownloading: true,
        downloadProgress: 1.0,
        assignments: updatedAssignments,
      );

      debugPrint('ScannerViewModel: Downloaded ${result.studentCount} students for $eventId');

    } catch (e) {
      debugPrint('ScannerViewModel: Download failed: $e');
      state = state.copyWith(
        clearDownloading: true,
        downloadProgress: 0.0,
        downloadError: 'Download failed: $e',
      );
    }
  }

  /// Refreshes all offline event data (participants, timing, and remote attendance) when online.
  Future<void> refreshEventData(String eventId) async {
    await downloadParticipantData(eventId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
