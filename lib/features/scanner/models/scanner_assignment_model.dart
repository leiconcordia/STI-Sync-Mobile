import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/local/app_database.dart';
import 'package:drift/drift.dart' as drift;

/// Represents the scanner assignment for a single event.
///
/// Built from a Firestore EventDocument by locating this officer's
/// entry inside the nested `scanners[]` array. Also stored locally
/// in the Drift `scanner_assignments` table for offline access.
class ScannerAssignmentModel {
  /// Firestore eventId (document ID).
  final String eventId;

  /// Human-readable event name (denormalized for offline display).
  final String eventTitle;

  /// Event format: 'On-Campus' | 'Online' | 'Hybrid'.
  final String eventFormat;

  /// All session metadata for this event (used for session selector UI).
  final List<Map<String, dynamic>> sessions;

  /// Firebase Auth UID of the officer who holds this assignment.
  final String officerUserId;

  /// Permissions map extracted from the EventScanner nested object.
  /// Keys: fullAccess, canCheckIn, canCheckOut, canViewList,
  ///       canEditRecords, allowManualAttendance.
  final Map<String, dynamic> permissions;

  /// Whether participant data has been downloaded for offline scanning.
  final bool dataDownloaded;

  /// When participant data was last downloaded (null if never downloaded).
  final DateTime? downloadedAt;

  /// End time of the event's last session — used to determine liveness.
  /// Derived from sessions[last].date + sessions[last].endTime.
  final DateTime eventEndTime;

  /// Firestore proposalStatus of the event ('approved' | 'draft').
  final String proposalStatus;

  /// Grace period in minutes after start time before late threshold
  final int? gracePeriodMinutes;

  /// Original Firestore snapshot — available when built from Firestore,
  /// null when restored from local Drift cache.
  final DocumentSnapshot? eventSnapshot;

  const ScannerAssignmentModel({
    required this.eventId,
    required this.eventTitle,
    required this.eventFormat,
    required this.sessions,
    required this.officerUserId,
    required this.permissions,
    required this.eventEndTime,
    required this.proposalStatus,
    this.gracePeriodMinutes,
    this.dataDownloaded = false,
    this.downloadedAt,
    this.eventSnapshot,
  });

  ScannerAssignmentModel copyWith({
    String? eventId,
    String? eventTitle,
    String? eventFormat,
    List<Map<String, dynamic>>? sessions,
    String? officerUserId,
    Map<String, dynamic>? permissions,
    DateTime? eventEndTime,
    String? proposalStatus,
    int? gracePeriodMinutes,
    bool? dataDownloaded,
    DateTime? downloadedAt,
    DocumentSnapshot? eventSnapshot,
  }) {
    return ScannerAssignmentModel(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventFormat: eventFormat ?? this.eventFormat,
      sessions: sessions ?? this.sessions,
      officerUserId: officerUserId ?? this.officerUserId,
      permissions: permissions ?? this.permissions,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      proposalStatus: proposalStatus ?? this.proposalStatus,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      dataDownloaded: dataDownloaded ?? this.dataDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      eventSnapshot: eventSnapshot ?? this.eventSnapshot,
    );
  }

  // ─── Computed getters ────────────────────────────────────────────────────

  /// True when the event's last session has not yet ended (plus a 12-hour grace period).
  bool get isActive => DateTime.now().isBefore(eventEndTime.add(const Duration(hours: 12)));

  /// True when this assignment is valid for scanning:
  /// event is still active AND in an approved state.
  bool get canScan => isActive && proposalStatus.toLowerCase() == 'approved';

  // ─── Factories ───────────────────────────────────────────────────────────

  /// Build from a live Firestore EventDocument snapshot.
  ///
  /// Finds the matching officer entry in `scanners[]` array.
  /// Throws if the officer is not found in the scanners list.
  factory ScannerAssignmentModel.fromEventDoc(
    DocumentSnapshot doc,
    String officerUserId,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    // Locate this officer's entry in the nested scanners array.
    // If we can't find it (e.g. data mismatch between scannerUserIds and scanners array),
    // we default to basic access to avoid breaking the UI for the scanner.
    final List<dynamic> scanners = data['scanners'] as List<dynamic>? ?? [];
    final scannerData = scanners.firstWhere(
      (s) => (s as Map<String, dynamic>)['officerUserId'] == officerUserId,
      orElse: () => null,
    ) as Map<String, dynamic>? ?? {};

    if (scannerData.isEmpty) {
      debugPrint('ScannerAssignmentModel: Warning: Officer $officerUserId found in scannerUserIds but not in scanners[] array for event ${doc.id}. Defaulting to basic access.');
    }

    // Extract full sessions array
    final List<dynamic> rawSessions = data['sessions'] as List<dynamic>? ?? [];
    final sessions = rawSessions
        .map((s) => s as Map<String, dynamic>)
        .toList();

    final eventEndTime = _computeLastEndTime(rawSessions);

    return ScannerAssignmentModel(
      eventId: doc.id,
      eventTitle: data['title'] as String? ?? 'Unknown Event',
      eventFormat: data['eventFormat'] as String? ?? '',
      sessions: sessions,
      officerUserId: officerUserId,
      permissions: {
        'fullAccess': scannerData['fullAccess'] as bool? ?? false,
        'canCheckIn': scannerData['canCheckIn'] as bool? ?? false,
        'canCheckOut': scannerData['canCheckOut'] as bool? ?? false,
        'canViewList': scannerData['canViewList'] as bool? ?? false,
        'canEditRecords': scannerData['canEditRecords'] as bool? ?? false,
        'allowManualAttendance':
            scannerData['allowManualAttendance'] as bool? ?? false,
      },
      eventEndTime: eventEndTime,
      // Default to 'approved' if missing so legacy/test events still show up
      proposalStatus: data['proposalStatus'] as String? ?? 'approved',
      gracePeriodMinutes: (data['gracePeriodMinutes'] as num?)?.toInt(),
      dataDownloaded: false,
      downloadedAt: null,
      eventSnapshot: doc,
    );
  }

  /// Restore from a Drift local database row.
  factory ScannerAssignmentModel.fromDrift(ScannerAssignment entity) {
    return ScannerAssignmentModel(
      eventId: entity.eventId,
      eventTitle: entity.eventTitle,
      eventFormat: entity.eventFormat,
      sessions: List<Map<String, dynamic>>.from(
        json.decode(entity.sessions) as List<dynamic>,
      ),
      officerUserId: entity.officerUserId,
      permissions:
          json.decode(entity.permissions) as Map<String, dynamic>,
      eventEndTime: DateTime.fromMillisecondsSinceEpoch(entity.eventEndTime),
      proposalStatus: entity.proposalStatus,
      gracePeriodMinutes: entity.gracePeriodMinutes,
      dataDownloaded: entity.dataDownloaded == 1,
      downloadedAt: entity.downloadedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(entity.downloadedAt)
          : null,
    );
  }

  /// Convert to a Drift companion for insert/update.
  ScannerAssignmentsCompanion toCompanion() {
    return ScannerAssignmentsCompanion(
      eventId: drift.Value(eventId),
      eventTitle: drift.Value(eventTitle),
      eventFormat: drift.Value(eventFormat),
      sessions: drift.Value(json.encode(sessions)),
      officerUserId: drift.Value(officerUserId),
      permissions: drift.Value(json.encode(permissions)),
      eventEndTime: drift.Value(eventEndTime.millisecondsSinceEpoch),
      proposalStatus: drift.Value(proposalStatus),
      gracePeriodMinutes: drift.Value(gracePeriodMinutes),
      dataDownloaded: drift.Value(dataDownloaded ? 1 : 0),
      downloadedAt: drift.Value(downloadedAt?.millisecondsSinceEpoch ?? 0),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Computes the end DateTime of the last session in the list.
  /// Returns a far-future date if sessions are empty (keeps assignment active).
  static DateTime _computeLastEndTime(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      // No sessions → treat as ongoing so assignment stays visible
      return DateTime.now().add(const Duration(days: 365));
    }

    DateTime? latest;
    for (final s in sessions) {
      final session = s as Map<String, dynamic>;
      final dateStr = session['date'] as String?;
      final endTimeStr = session['endTime'] as String?;
      if (dateStr != null && endTimeStr != null) {
        try {
          final dt = DateTime.parse('${dateStr}T$endTimeStr:00');
          if (latest == null || dt.isAfter(latest)) latest = dt;
        } catch (_) {
          // Ignore malformed date strings
        }
      }
    }
    return latest ?? DateTime.now().add(const Duration(days: 365));
  }
}
