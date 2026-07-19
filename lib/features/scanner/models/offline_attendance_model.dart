import 'package:drift/drift.dart' as drift;
import '../../../core/local/app_database.dart';

/// Data class wrapping the Drift-generated [OfflineAttendanceData] row
/// with convenience getters for flagged/manual fields and Firestore mapping.
class OfflineAttendanceModel {
  /// UUID generated offline — primary key in Drift.
  final String localId;

  /// Firestore event document ID.
  final String eventId;

  /// Session ID within the event.
  final String sessionId;

  /// Firebase Auth UID of the student being recorded.
  final String studentId;

  /// Denormalized student display name.
  final String studentName;

  /// 'Time-In' or 'Time-Out'.
  final String gateType;

  /// 'QR' or 'Manual'.
  final String scanMethod;

  /// Firebase Auth UID of the officer who recorded this.
  final String scannedBy;

  /// Unix milliseconds when the scan/record was created.
  final int scannedAt;

  /// 0 = pending upload, 1 = uploaded to Firestore.
  final int synced;

  /// Unix milliseconds when synced, or null if not yet synced.
  final int? syncedAt;

  /// 0 = unresolved, 1 = conflict resolved.
  final int conflictResolved;

  /// 'Present' | 'Late'.
  final String status;

  /// Whether this record is flagged for admin review.
  final bool isFlagged;

  /// Reason for flagging: 'no_phone' | 'payment_pending' | 'not_registered' | 'device_error' | 'other'.
  final String? flagReason;

  /// Optional free-text note from the scanner officer.
  final String? flagNote;

  /// Whether this was a manual entry (not QR scanned).
  final bool isManual;

  const OfflineAttendanceModel({
    required this.localId,
    required this.eventId,
    required this.sessionId,
    required this.studentId,
    required this.studentName,
    required this.gateType,
    required this.scanMethod,
    required this.scannedBy,
    required this.scannedAt,
    required this.synced,
    this.syncedAt,
    required this.conflictResolved,
    required this.status,
    this.isFlagged = false,
    this.flagReason,
    this.flagNote,
    this.isManual = false,
  });

  /// Whether this record has been uploaded to Firestore.
  bool get isSynced => synced == 1;

  /// Whether this record is pending upload.
  bool get isPending => synced == 0;

  /// Human-readable flag reason label.
  String get flagReasonLabel {
    switch (flagReason) {
      case 'no_phone':
        return 'No Phone';
      case 'payment_pending':
        return 'Payment Pending';
      case 'not_registered':
        return 'Not Registered';
      case 'device_error':
        return 'Device Error';
      case 'other':
        return 'Other';
      default:
        return flagReason ?? '';
    }
  }

  // ─── Factories ───────────────────────────────────────────────────────────

  /// Build from a Drift row.
  factory OfflineAttendanceModel.fromDrift(OfflineAttendanceData row) {
    return OfflineAttendanceModel(
      localId: row.localId,
      eventId: row.eventId,
      sessionId: row.sessionId,
      studentId: row.studentId,
      studentName: row.studentName,
      gateType: row.gateType,
      scanMethod: row.scanMethod,
      scannedBy: row.scannedBy,
      scannedAt: row.scannedAt,
      synced: row.synced,
      syncedAt: row.syncedAt,
      conflictResolved: row.conflictResolved,
      status: row.status,
      isFlagged: row.isFlagged == 1,
      flagReason: row.flagReason,
      flagNote: row.flagNote,
      isManual: row.isManual == 1,
    );
  }

  /// Convert to a Drift companion for insert.
  OfflineAttendanceCompanion toCompanion() {
    return OfflineAttendanceCompanion(
      localId: drift.Value(localId),
      eventId: drift.Value(eventId),
      sessionId: drift.Value(sessionId),
      studentId: drift.Value(studentId),
      studentName: drift.Value(studentName),
      gateType: drift.Value(gateType),
      scanMethod: drift.Value(scanMethod),
      scannedBy: drift.Value(scannedBy),
      scannedAt: drift.Value(scannedAt),
      synced: drift.Value(synced),
      syncedAt: drift.Value(syncedAt),
      conflictResolved: drift.Value(conflictResolved),
      status: drift.Value(status),
      isFlagged: drift.Value(isFlagged ? 1 : 0),
      flagReason: drift.Value(flagReason),
      flagNote: drift.Value(flagNote),
      isManual: drift.Value(isManual ? 1 : 0),
    );
  }

  /// Convert to a Firestore-ready map for uploading to `/attendance`.
  ///
  /// Used by [SyncService] when uploading normal (non-flagged) records.
  Map<String, dynamic> toAttendanceMap() {
    return {
      'eventId': eventId,
      'sessionId': sessionId,
      'studentId': studentId,
      'studentName': studentName,
      'gateType': gateType == 'Time-In' ? 'entry' : 'exit',
      'scanMethod': scanMethod.toLowerCase(),
      'scannedBy': scannedBy,
      'scannedAt': DateTime.fromMillisecondsSinceEpoch(scannedAt).toIso8601String(),
      'status': status,
      'localId': localId,
    };
  }

  /// Convert to a Firestore-ready map for uploading to `/flagged_attendance`.
  ///
  /// Used by [SyncService] when uploading flagged/manual records.
  Map<String, dynamic> toFlaggedAttendanceMap({
    required String flaggedByName,
    required String organizationId,
  }) {
    return {
      'eventId': eventId,
      'sessionId': sessionId,
      'organizationId': organizationId,
      'studentId': studentId.isEmpty ? null : studentId,
      'studentName': studentName,
      'studentNumber': null, // populated by sync service from cached data
      'course': null, // populated by sync service from cached data
      'yearLevel': null, // populated by sync service from cached data
      'flagReason': flagReason,
      'flagNote': flagNote,
      'gateType': gateType == 'Time-In' ? 'time_in' : 'time_out',
      'flaggedBy': scannedBy,
      'flaggedByName': flaggedByName,
      'flaggedAt': DateTime.fromMillisecondsSinceEpoch(scannedAt).toIso8601String(),
      'localId': localId,
    };
  }
}
