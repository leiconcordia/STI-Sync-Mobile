import '../../../core/local/app_database.dart';

enum SyncStatus { idle, syncing, success, conflict, error }

/// The outcome of a conflict resolution action.
enum ConflictAction { skip, forceUpload }

/// Result type returned by [SyncService.uploadPendingAttendance].
enum SyncResultType { success, hasConflicts, error }

/// Represents a single conflict between a local offline record and an
/// existing Firestore attendance document.
class SyncConflict {
  /// The local Drift record that has not yet been uploaded.
  final OfflineAttendanceData localRecord;

  /// The existing Firestore document data that conflicts with [localRecord].
  final Map<String, dynamic> firestoreRecord;

  /// Firestore document ID of the conflicting record.
  final String firestoreDocId;

  const SyncConflict({
    required this.localRecord,
    required this.firestoreRecord,
    required this.firestoreDocId,
  });
}

/// Immutable result of a sync attempt.
class SyncResult {
  final SyncResultType type;

  /// Number of records successfully uploaded in this sync run.
  final int uploadedCount;

  /// Conflicts discovered during duplicate detection.
  final List<SyncConflict> conflicts;

  /// Human-readable error message (only for [SyncResultType.error]).
  final String? errorMessage;

  const SyncResult._({
    required this.type,
    this.uploadedCount = 0,
    this.conflicts = const [],
    this.errorMessage,
  });

  factory SyncResult.success(int count) =>
      SyncResult._(type: SyncResultType.success, uploadedCount: count);

  factory SyncResult.hasConflicts(List<SyncConflict> conflicts) =>
      SyncResult._(type: SyncResultType.hasConflicts, conflicts: conflicts);

  factory SyncResult.error(String message) =>
      SyncResult._(type: SyncResultType.error, errorMessage: message);
}

/// Observable UI state for the sync status indicator.
class SyncStatusState {
  final SyncStatus status;
  final int pendingCount;
  final int conflictCount;
  final DateTime? lastSyncAt;

  const SyncStatusState({
    required this.status,
    this.pendingCount = 0,
    this.conflictCount = 0,
    this.lastSyncAt,
  });

  SyncStatusState copyWith({
    SyncStatus? status,
    int? pendingCount,
    int? conflictCount,
    DateTime? lastSyncAt,
  }) {
    return SyncStatusState(
      status: status ?? this.status,
      pendingCount: pendingCount ?? this.pendingCount,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
    );
  }
}
