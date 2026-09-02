import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../../core/local/app_database.dart';
import '../../../core/utils/date_formatter.dart';
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

  /// Event format / Venue string.
  final String eventFormat;

  /// Human-readable venue of the event.
  final String venue;

  /// Venue ID pointing to Firestore `venues/{venueId}`.
  final String venueId;

  /// Custom venue name override if set on the event.
  final String? customVenueName;
  final String? startDate;

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

  /// Late threshold in minutes after start time before time-in closes
  final int? lateThresholdMinutes;

  /// Original Firestore snapshot — available when built from Firestore,
  /// null when restored from local Drift cache.
  final DocumentSnapshot? eventSnapshot;

  const ScannerAssignmentModel({
    required this.eventId,
    required this.eventTitle,
    this.eventFormat = 'Campus Venue',
    this.venue = 'Campus Venue',
    this.venueId = '',
    this.customVenueName,
    this.startDate,
    required this.sessions,
    required this.officerUserId,
    required this.permissions,
    required this.eventEndTime,
    required this.proposalStatus,
    this.gracePeriodMinutes,
    this.lateThresholdMinutes,
    this.dataDownloaded = false,
    this.downloadedAt,
    this.eventSnapshot,
  });

  ScannerAssignmentModel copyWith({
    String? eventId,
    String? eventTitle,
    String? eventFormat,
    String? venue,
    String? venueId,
    String? customVenueName,
    String? startDate,
    List<Map<String, dynamic>>? sessions,
    String? officerUserId,
    Map<String, dynamic>? permissions,
    DateTime? eventEndTime,
    String? proposalStatus,
    int? gracePeriodMinutes,
    int? lateThresholdMinutes,
    bool? dataDownloaded,
    DateTime? downloadedAt,
    DocumentSnapshot? eventSnapshot,
  }) {
    return ScannerAssignmentModel(
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventFormat: eventFormat ?? this.eventFormat,
      venue: venue ?? this.venue,
      venueId: venueId ?? this.venueId,
      customVenueName: customVenueName ?? this.customVenueName,
      startDate: startDate ?? this.startDate,
      sessions: sessions ?? this.sessions,
      officerUserId: officerUserId ?? this.officerUserId,
      permissions: permissions ?? this.permissions,
      eventEndTime: eventEndTime ?? this.eventEndTime,
      proposalStatus: proposalStatus ?? this.proposalStatus,
      gracePeriodMinutes: gracePeriodMinutes ?? this.gracePeriodMinutes,
      lateThresholdMinutes: lateThresholdMinutes ?? this.lateThresholdMinutes,
      dataDownloaded: dataDownloaded ?? this.dataDownloaded,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      eventSnapshot: eventSnapshot ?? this.eventSnapshot,
    );
  }

  // ─── Computed getters ────────────────────────────────────────────────────

  /// Formatted event start date (e.g. "Aug 2, 2026")
  String get formattedStartDate {
    if (startDate != null && startDate!.trim().isNotEmpty) {
      return formatAppDate(startDate);
    }
    if (sessions.isNotEmpty) {
      final firstDate = sessions.first['date'] as String?;
      if (firstDate != null && firstDate.trim().isNotEmpty) {
        return formatAppDate(firstDate);
      }
    }
    return formatAppDate(DateTime.now());
  }

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
  ) =>
      ScannerAssignmentModel.fromEventDocForIds(doc, [officerUserId]);

  /// Build from a live Firestore EventDocument snapshot matching any of [targetOfficerIds]
  /// (e.g. organization_officer document IDs or student auth UID).
  factory ScannerAssignmentModel.fromEventDocForIds(
    DocumentSnapshot doc,
    List<String> targetOfficerIds,
  ) {
    final data = doc.data() as Map<String, dynamic>;

    // Locate this officer's entry in the nested scanners array.
    // Checks against any of the target officer IDs (organization_officers doc IDs or student auth UID).
    final List<dynamic> scanners = data['scanners'] as List<dynamic>? ?? [];
    final scannerData = scanners.firstWhere(
      (s) {
        final sOfficerId =
            (s as Map<String, dynamic>)['officerUserId'] as String?;
        return targetOfficerIds.contains(sOfficerId);
      },
      orElse: () => null,
    ) as Map<String, dynamic>? ?? {};

    final matchedOfficerId = (scannerData['officerUserId'] as String?) ??
        (targetOfficerIds.isNotEmpty ? targetOfficerIds.first : '');

    if (scannerData.isEmpty) {
      debugPrint(
          'ScannerAssignmentModel: Warning: Officer IDs $targetOfficerIds found in scannerUserIds but not in scanners[] array for event ${doc.id}. Defaulting to basic access.');
    }

    final gracePeriod = (data['gracePeriodMinutes'] as num?)?.toInt();
    final lateThreshold = (data['lateThresholdMinutes'] as num?)?.toInt();

    final customVenue = data['customVenueName'] as String?;
    final venueId = data['venueId'] as String? ?? '';
    final rawVenue = (data['venue'] as String?) ?? (data['venueName'] as String?);
    final venue = (customVenue != null && customVenue.isNotEmpty)
        ? customVenue
        : (rawVenue != null && rawVenue.isNotEmpty ? rawVenue : (data['eventFormat'] as String? ?? 'STI Campus'));

    // Extract full sessions array and propagate event-level timing defaults
    final List<dynamic> rawSessions = data['sessions'] as List<dynamic>? ?? [];
    final sessions = rawSessions
        .map((s) {
          final sMap = Map<String, dynamic>.from(s as Map<String, dynamic>);
          if (sMap['gracePeriodMinutes'] == null && gracePeriod != null) {
            sMap['gracePeriodMinutes'] = gracePeriod;
          }
          if (sMap['lateThresholdMinutes'] == null && lateThreshold != null) {
            sMap['lateThresholdMinutes'] = lateThreshold;
          }
          return sMap;
        })
        .toList();

    final eventEndTime = _computeLastEndTime(rawSessions);

    final startDate = (data['startDate'] as String?)?.trim() ??
        (sessions.isNotEmpty ? (sessions.first['date'] as String?)?.trim() : null);

    return ScannerAssignmentModel(
      eventId: doc.id,
      eventTitle: data['title'] as String? ?? 'Unknown Event',
      eventFormat: venue,
      venue: venue,
      venueId: venueId,
      customVenueName: customVenue,
      startDate: startDate,
      sessions: sessions,
      officerUserId: matchedOfficerId,
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
      gracePeriodMinutes: gracePeriod,
      lateThresholdMinutes: lateThreshold,
      dataDownloaded: false,
      downloadedAt: null,
      eventSnapshot: doc,
    );
  }

  /// Restore from a Drift local database row.
  factory ScannerAssignmentModel.fromDrift(ScannerAssignment entity) {
    final parsedSessions = List<Map<String, dynamic>>.from(
      json.decode(entity.sessions) as List<dynamic>,
    );
    int? lateThresh;
    for (final s in parsedSessions) {
      if (s['lateThresholdMinutes'] != null) {
        lateThresh = (s['lateThresholdMinutes'] as num).toInt();
        break;
      }
    }

    final venueStr = entity.eventFormat.isNotEmpty ? entity.eventFormat : 'Campus Venue';
    final parsedStartDate = parsedSessions.isNotEmpty ? parsedSessions.first['date'] as String? : null;

    return ScannerAssignmentModel(
      eventId: entity.eventId,
      eventTitle: entity.eventTitle,
      eventFormat: entity.eventFormat,
      venue: venueStr,
      venueId: '',
      customVenueName: null,
      startDate: parsedStartDate,
      sessions: parsedSessions,
      officerUserId: entity.officerUserId,
      permissions:
          json.decode(entity.permissions) as Map<String, dynamic>,
      eventEndTime: DateTime.fromMillisecondsSinceEpoch(entity.eventEndTime),
      proposalStatus: entity.proposalStatus,
      gracePeriodMinutes: entity.gracePeriodMinutes,
      lateThresholdMinutes: lateThresh,
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
  static DateTime computeLastEndTime(List<dynamic> sessions) => _computeLastEndTime(sessions);

  /// Computes the end DateTime of the last session in the list.
  /// Supports both 24-hour ('17:00') and 12-hour AM/PM ('5:00 PM') formats.
  static DateTime _computeLastEndTime(List<dynamic> sessions) {
    if (sessions.isEmpty) {
      // No sessions → fallback to past date so empty events don't stay active forever
      return DateTime.now().subtract(const Duration(days: 1));
    }

    DateTime? latest;
    for (final s in sessions) {
      if (s is! Map) continue;
      final session = Map<String, dynamic>.from(s);
      final dateStr = (session['date'] as String?)?.trim();
      final endTimeStr = (session['endTime'] as String? ?? session['timeOutClose'] as String?)?.trim();

      if (dateStr != null && dateStr.isNotEmpty) {
        DateTime? dt;
        if (endTimeStr != null && endTimeStr.isNotEmpty) {
          dt = _parseDateTime(dateStr, endTimeStr);
        }
        // Fallback: If no endTime, use end of that day (23:59)
        dt ??= _parseDateTime(dateStr, '23:59');

        if (dt != null) {
          if (latest == null || dt.isAfter(latest)) {
            latest = dt;
          }
        }
      }
    }
    return latest ?? DateTime.now().subtract(const Duration(days: 1));
  }

  static DateTime? _parseDateTime(String dateStr, String timeStr) {
    try {
      final cleanTime = timeStr.trim();
      final cleanDate = dateStr.trim();
      if (cleanTime.toUpperCase().contains('AM') || cleanTime.toUpperCase().contains('PM')) {
        final format = DateFormat('yyyy-MM-dd h:mm a');
        return format.parse('$cleanDate $cleanTime', true).toLocal();
      } else {
        final parts = cleanTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = parts.length > 1 ? int.parse(parts[1].substring(0, 2)) : 0;
        final dateParts = cleanDate.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        return DateTime(year, month, day, hour, minute);
      }
    } catch (_) {
      return null;
    }
  }
}
