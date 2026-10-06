import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/scanner_assignment_model.dart';
import '../repositories/scanner_repository.dart';
import '../repositories/offline_attendance_repository.dart';
import '../../../core/local/daos/attendance_dao.dart';
import '../../sync/models/sync_status_model.dart';
import '../../sync/services/event_cleanup_service.dart';
import '../../sync/services/sync_service.dart';

/// Immutable UI state for the scanner feature.
class ScannerState {
  /// All active (non-expired, approved, or pending upload) assignments for the current officer.
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

  /// True if at least one assignment is valid for display (can scan, cancelled, or has pending unsynced records).
  bool get hasActiveAssignments => assignments.any((a) => a.shouldDisplay);

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
  final AttendanceDao _attendanceDao;
  final EventCleanupService _cleanupService;
  final SyncService _syncService;
  StreamSubscription<List<ScannerAssignmentModel>>? _subscription;
  String? _currentOfficerUserId;

  ScannerViewModel(
    this._repo,
    this._offlineRepo,
    this._attendanceDao,
    this._cleanupService,
    this._syncService,
  ) : super(const ScannerState());

  /// Clears in-memory scanner state, cancels active Firestore subscriptions,
  /// and purges stale local assignments from Drift.
  void clear() {
    _subscription?.cancel();
    _subscription = null;
    _currentOfficerUserId = null;
    state = const ScannerState();
    _repo.clearLocalAssignments().catchError((e) {
      debugPrint('ScannerViewModel: Error clearing local assignments: $e');
    });
  }

  /// Begins watching Firestore for assignments where this officer is a scanner.
  ///
  /// Cancels any existing subscription first. Each emission saves assignments
  /// locally, attaches unsynced attendance counts, and preserves concluded events
  /// that still require attendance uploading.
  void loadAssignments(String officerUserId) {
    if (officerUserId.isEmpty) {
      clear();
      return;
    }

    // Cancel previous subscription if reloading
    _subscription?.cancel();
    _subscription = null;
    _currentOfficerUserId = officerUserId;

    // Reset state to empty loading state so previous account's assignments are not retained
    state = const ScannerState(isLoading: true);

    // 1. Immediately load locally cached assignments from Drift for THIS officer only
    _repo.getLocalAssignments(officerUserId).then((localList) async {
      if (_currentOfficerUserId != officerUserId) return;
      if (localList.isNotEmpty && state.assignments.isEmpty) {
        final pendingRecords = await _attendanceDao.getPendingSyncs();
        final pendingMap = <String, int>{};
        for (final p in pendingRecords) {
          pendingMap[p.eventId] = (pendingMap[p.eventId] ?? 0) + 1;
        }

        final sorted = List<ScannerAssignmentModel>.from(
          localList.map((a) => a.copyWith(
            pendingSyncCount: pendingMap[a.eventId] ?? 0,
          )).where((a) => a.shouldDisplay),
        )..sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));

        state = state.copyWith(
          assignments: sorted,
          isLoading: false,
        );
      } else if (localList.isEmpty && state.assignments.isEmpty) {
        state = state.copyWith(isLoading: false);
      }
    }).catchError((e) {
      debugPrint('ScannerViewModel: Error reading local assignments: $e');
      if (_currentOfficerUserId == officerUserId && state.assignments.isEmpty) {
        state = state.copyWith(isLoading: false);
      }
    });

    // 2. Watch live Firestore assignments
    _subscription = _repo
        .watchScannerAssignments(officerUserId)
        .listen(
      (assignments) async {
        if (_currentOfficerUserId != officerUserId) return;
        debugPrint('ScannerViewModel: Received ${assignments.length} assignments from Firestore');

        // Fetch pending offline sync counts across all local events
        final pendingRecords = await _attendanceDao.getPendingSyncs();
        final pendingMap = <String, int>{};
        for (final p in pendingRecords) {
          pendingMap[p.eventId] = (pendingMap[p.eventId] ?? 0) + 1;
        }

        // 1. Immediately update UI state so assignments and QR nav icon are immediately visible
        final initialDisplay = assignments.map((a) {
          return a.copyWith(pendingSyncCount: pendingMap[a.eventId] ?? 0);
        }).where((a) => a.shouldDisplay).toList();
        initialDisplay.sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));

        state = state.copyWith(
          assignments: initialDisplay,
          isLoading: false,
          clearError: true,
        );

        // 2. Perform Drift local persistence and synchronization in the background
        try {
          // Persist all current assignments (including cancelled/completed status) to Drift for offline use
          for (final assignment in assignments) {
            try {
              await _repo.saveAssignmentLocally(
                assignment.copyWith(
                  officerUserId: assignment.officerUserId.isNotEmpty
                      ? assignment.officerUserId
                      : officerUserId,
                ),
              );
            } catch (e) {
              debugPrint('ScannerViewModel: Failed to save to Drift: $e');
            }
          }

          // Prune any locally cached assignments that are no longer assigned to this user
          // BUT NEVER prune if there are unsynced attendance records in Drift!
          try {
            final firestoreEventIds = assignments.map((a) => a.eventId).toSet();
            final currentLocal = await _repo.getLocalAssignments();
            for (final local in currentLocal) {
              if (!firestoreEventIds.contains(local.eventId)) {
                final pendingCount = pendingMap[local.eventId] ?? 0;
                if (pendingCount > 0) {
                  debugPrint(
                    'ScannerViewModel: Retaining unassigned event ${local.eventId} '
                    'because it has $pendingCount unsynced attendance records.',
                  );
                  continue; // STRICT GUARD: DO NOT DELETE!
                }
                debugPrint('ScannerViewModel: Pruning unassigned event ${local.eventId} from local DB');
                await _repo.deleteLocalAssignment(local.eventId);
              }
            }
          } catch (e) {
            debugPrint('ScannerViewModel: Failed to prune unassigned assignments: $e');
          }

          // Clean up completed assignments that have 0 unsynced attendance
          try {
            await _repo.cleanConcludedAssignments(_attendanceDao);
          } catch (e) {
            debugPrint('ScannerViewModel: Failed to clean concluded assignments: $e');
          }

          // Fetch fresh local assignments to get preserved dataDownloaded flags
          final localAssignments = await _repo.getLocalAssignments();

          final localMap = <String, ScannerAssignmentModel>{};
          for (final local in localAssignments) {
            localMap[local.eventId] = local;
          }

          // Merge Firestore assignments with local flags & pending sync counts
          final displayAssignments = assignments.map((a) {
            final local = localMap[a.eventId];
            final isEffCancelled = a.isEffectivelyCancelled || (local?.isEffectivelyCancelled ?? false);
            final isConcluded = a.isConcluded || (local?.isConcluded ?? false);
            final pendingCount = pendingMap[a.eventId] ?? 0;
            return a.copyWith(
              dataDownloaded: (local?.dataDownloaded ?? false) || a.dataDownloaded,
              downloadedAt: local?.downloadedAt ?? a.downloadedAt,
              pendingSyncCount: pendingCount,
              isCancelled: isEffCancelled,
              status: isEffCancelled ? 'cancelled' : (isConcluded ? 'completed' : a.status),
              proposalStatus: isEffCancelled ? 'cancelled' : (isConcluded ? 'completed' : a.proposalStatus),
              attendanceLocked: isConcluded,
              cancellationReason: a.cancellationReason ?? local?.cancellationReason,
            );
          }).where((a) => a.shouldDisplay).toList();

          // Also keep any local assignments not returned by Firestore that still have pending unsynced records
          for (final local in localAssignments) {
            final pendingCount = pendingMap[local.eventId] ?? 0;
            if (pendingCount > 0 && !displayAssignments.any((a) => a.eventId == local.eventId)) {
              displayAssignments.add(local.copyWith(pendingSyncCount: pendingCount));
            }
          }

          displayAssignments.sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));

          if (_currentOfficerUserId == officerUserId) {
            state = state.copyWith(
              assignments: displayAssignments,
              isLoading: false,
              clearError: true,
            );
          }
        } catch (driftErr) {
          debugPrint('ScannerViewModel: Background Drift error: $driftErr');
        }
      },
      onError: (Object error) async {
        // Fallback to local assignments on network error / offline
        final localAssignments = await _repo.getLocalAssignments();
        final pendingRecords = await _attendanceDao.getPendingSyncs();
        final pendingMap = <String, int>{};
        for (final p in pendingRecords) {
          pendingMap[p.eventId] = (pendingMap[p.eventId] ?? 0) + 1;
        }

        final sorted = List<ScannerAssignmentModel>.from(
          localAssignments.map((a) => a.copyWith(
            pendingSyncCount: pendingMap[a.eventId] ?? 0,
          )).where((a) => a.shouldDisplay),
        )..sort((a, b) => b.eventEndTime.compareTo(a.eventEndTime));

        state = state.copyWith(
          assignments: sorted,
          isLoading: false,
          errorMessage: 'Offline mode: loaded cached assignments.',
        );
      },
    );
  }

  /// Refreshes in-memory assignment list by re-evaluating local SQLite pending sync counts.
  Future<void> refreshAssignments() async {
    final pendingRecords = await _attendanceDao.getPendingSyncs();
    final pendingMap = <String, int>{};
    for (final p in pendingRecords) {
      pendingMap[p.eventId] = (pendingMap[p.eventId] ?? 0) + 1;
    }

    final localAssignments = await _repo.getLocalAssignments();
    final localMap = {for (var l in localAssignments) l.eventId: l};

    final updated = state.assignments.map((a) {
      final local = localMap[a.eventId];
      return a.copyWith(
        dataDownloaded: (local?.dataDownloaded ?? false) || a.dataDownloaded,
        pendingSyncCount: pendingMap[a.eventId] ?? 0,
      );
    }).where((a) => a.shouldDisplay).toList();

    state = state.copyWith(assignments: updated);
  }

  /// Uploads pending attendance records for [eventId].
  /// If the event has concluded and all records are synced, safely cleans up
  /// local database cache and assignment.
  Future<SyncResult> uploadAttendanceAndCleanup(String eventId) async {
    state = state.copyWith(isLoading: true);
    try {
      final result = await _syncService.uploadPendingAttendance();

      // Check if all attendance for this event is now synced
      final remaining = await _attendanceDao.getPendingSyncsForEvent(eventId);
      if (remaining.isEmpty) {
        final target = state.assignments.where((a) => a.eventId == eventId).firstOrNull;
        if (target != null && target.isConcluded) {
          debugPrint('ScannerViewModel: All attendance synced for concluded event $eventId — cleaning up cache...');
          await _cleanupService.purgeEventData(eventId);
        }
      }

      await refreshAssignments();
      return result;
    } catch (e) {
      debugPrint('ScannerViewModel: uploadAttendanceAndCleanup error: $e');
      return SyncResult.error('Upload failed: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
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
          return local.copyWith(dataDownloaded: true, downloadedAt: DateTime.now());
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
