enum SyncStatus { idle, syncing, success, conflict, error }

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
