import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

/// Represents the availability state of a gate scan window.
enum GateWindowStatus {
  /// Window has not reached its opening time yet.
  notStarted,

  /// Window is actively open and accepting scans.
  open,

  /// Window has passed its closing cutoff time.
  closed,

  /// Gate type is not configured or disabled for this session (e.g. hasTimeOut == false).
  disabled,
}

/// Result of evaluating a gate window's timing at a given point in time.
class GateTimingResult {
  final GateWindowStatus status;

  /// User-facing descriptive message or status subtitle (e.g., "Opens at 7:30 AM", "Closed at 9:00 AM").
  final String message;

  /// Expected attendance status if recorded at this moment: 'Present' or 'Late' (null if not open).
  final String? attendanceStatus;

  /// Parsed opening timestamp.
  final DateTime? opensAt;

  /// Parsed closing cutoff timestamp.
  final DateTime? closesAt;

  /// Timestamp after which scans are marked 'Late'.
  final DateTime? lateThresholdStart;

  const GateTimingResult({
    required this.status,
    required this.message,
    this.attendanceStatus,
    this.opensAt,
    this.closesAt,
    this.lateThresholdStart,
  });

  bool get isOpen => status == GateWindowStatus.open;
  bool get isNotStarted => status == GateWindowStatus.notStarted;
  bool get isClosed => status == GateWindowStatus.closed;
  bool get isDisabled => status == GateWindowStatus.disabled;
}

/// Centralized utility for evaluating session timing windows, late tagging, and optional timeout gates.
class SessionTimingEvaluator {
  /// Parses a date string and a time string into a local [DateTime].
  ///
  /// Supports:
  /// - 12-hour AM/PM formats: "8:00 AM", "08:30 pm"
  /// - 24-hour military formats: "08:00", "13:30"
  /// - ISO-like date formats: "2026-08-15"
  static DateTime? parseDateTime(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null) return null;
    final cleanDate = dateStr.trim();
    final cleanTime = timeStr.trim();
    if (cleanDate.isEmpty || cleanTime.isEmpty) return null;

    try {
      // If dateStr contains full ISO timestamp, extract the YYYY-MM-DD portion
      final dateOnly = cleanDate.contains('T')
          ? cleanDate.split('T')[0]
          : (cleanDate.contains(' ') ? cleanDate.split(' ')[0] : cleanDate);

      final is12Hour = cleanTime.toUpperCase().contains('AM') ||
          cleanTime.toUpperCase().contains('PM');

      if (is12Hour) {
        // Standardize spacing (e.g., "8:00AM" -> "8:00 AM")
        final normalizedTime = cleanTime
            .replaceAllMapped(
              RegExp(r'(\d+:\d+)\s*([AaPp][Mm])'),
              (m) => '${m[1]} ${m[2]!.toUpperCase()}',
            );
        final format = DateFormat('yyyy-MM-dd h:mm a');
        return format.parse('$dateOnly $normalizedTime');
      } else {
        final parts = cleanTime.split(':');
        if (parts.length < 2) return null;
        final hour = int.parse(parts[0].trim());
        final minute = int.parse(parts[1].trim());

        final dateParts = dateOnly.split('-');
        if (dateParts.length < 3) return null;
        final year = int.parse(dateParts[0].trim());
        final month = int.parse(dateParts[1].trim());
        final day = int.parse(dateParts[2].trim());

        return DateTime(year, month, day, hour, minute);
      }
    } catch (e) {
      debugPrint('SessionTimingEvaluator: Error parsing ($dateStr, $timeStr): $e');
      return null;
    }
  }

  /// Formats a [DateTime] into a friendly time string (e.g., "8:00 AM").
  static String formatTime(DateTime dt) {
    return DateFormat('h:mm a').format(dt);
  }

  /// Evaluates Time-In status for [session] at [checkTime] (defaults to DateTime.now()).
  static GateTimingResult evaluateTimeIn(
    Map<String, dynamic> session, {
    DateTime? checkTime,
    int? fallbackGrace,
    int? fallbackLateThreshold,
  }) {
    final now = checkTime ?? DateTime.now();
    final dateStr = session['date'] as String?;
    final startTimeStr = (session['startTime'] as String?) ?? (session['timeInOpen'] as String?);
    final timeInOpenStr = (session['timeInOpen'] as String?) ?? (session['startTime'] as String?);
    final timeInCloseStr = session['timeInClose'] as String?;
    final endTimeStr = session['endTime'] as String?;

    final isLateEnabled = session['isLateEnabled'] == true;
    final markLateAfterStr = session['markLateAfter'] as String?;

    final sessionStart = parseDateTime(dateStr, startTimeStr);
    final timeInOpen = parseDateTime(dateStr, timeInOpenStr) ?? sessionStart;
    final explicitClose = parseDateTime(dateStr, timeInCloseStr);
    final sessionEnd = parseDateTime(dateStr, endTimeStr);

    // Cutoff: explicit close -> fallback to sessionEnd
    final timeInCutoff = explicitClose ?? sessionEnd;

    // If unable to parse any timing, default to open as fallback
    if (timeInOpen == null && timeInCutoff == null) {
      return const GateTimingResult(
        status: GateWindowStatus.open,
        message: 'Open for scanning',
        attendanceStatus: 'Present',
      );
    }

    // 1. Check if not started yet
    if (timeInOpen != null && now.isBefore(timeInOpen)) {
      return GateTimingResult(
        status: GateWindowStatus.notStarted,
        message: 'Opens at ${formatTime(timeInOpen)}',
        opensAt: timeInOpen,
        closesAt: timeInCutoff,
      );
    }

    // 2. Check if closed
    if (timeInCutoff != null && now.isAfter(timeInCutoff)) {
      return GateTimingResult(
        status: GateWindowStatus.closed,
        message: 'Closed at ${formatTime(timeInCutoff)}',
        opensAt: timeInOpen,
        closesAt: timeInCutoff,
      );
    }

    // 3. Open — evaluate Late Tagging
    DateTime? lateThreshold;
    if (isLateEnabled && markLateAfterStr != null && markLateAfterStr.trim().isNotEmpty) {
      lateThreshold = parseDateTime(dateStr, markLateAfterStr);
    }

    final isLate = isLateEnabled && lateThreshold != null && now.isAfter(lateThreshold);

    return GateTimingResult(
      status: GateWindowStatus.open,
      message: isLate ? 'Open (Late Arrival)' : 'Open (On-Time)',
      attendanceStatus: isLate ? 'Late' : 'Present',
      opensAt: timeInOpen,
      closesAt: timeInCutoff,
      lateThresholdStart: lateThreshold,
    );
  }

  /// Evaluates Time-Out status for [session] at [checkTime] (defaults to DateTime.now()).
  static GateTimingResult evaluateTimeOut(
    Map<String, dynamic> session, {
    DateTime? checkTime,
    int? fallbackLateThreshold,
  }) {
    if (session['hasTimeOut'] != true) {
      return const GateTimingResult(
        status: GateWindowStatus.disabled,
        message: 'No Time-Out required for this session',
      );
    }

    final now = checkTime ?? DateTime.now();
    final dateStr = session['date'] as String?;
    final timeOutOpenStr = session['timeOutOpen'] as String?;
    final timeOutCloseStr = session['timeOutClose'] as String?;
    final timeInCloseStr = session['timeInClose'] as String?;
    final sessionEnd = parseDateTime(dateStr, session['endTime'] as String?);

    final timeOutOpen = parseDateTime(dateStr, timeOutOpenStr) ??
        parseDateTime(dateStr, timeInCloseStr) ??
        sessionEnd;

    final timeOutClose = parseDateTime(dateStr, timeOutCloseStr) ??
        sessionEnd?.add(const Duration(hours: 2));

    if (timeOutOpen == null && timeOutClose == null) {
      return const GateTimingResult(
        status: GateWindowStatus.open,
        message: 'Open for Time-Out',
        attendanceStatus: 'Present',
      );
    }

    if (timeOutOpen != null && now.isBefore(timeOutOpen)) {
      return GateTimingResult(
        status: GateWindowStatus.notStarted,
        message: 'Opens at ${formatTime(timeOutOpen)}',
        opensAt: timeOutOpen,
        closesAt: timeOutClose,
      );
    }

    if (timeOutClose != null && now.isAfter(timeOutClose)) {
      return GateTimingResult(
        status: GateWindowStatus.closed,
        message: 'Closed at ${formatTime(timeOutClose)}',
        opensAt: timeOutOpen,
        closesAt: timeOutClose,
      );
    }

    return GateTimingResult(
      status: GateWindowStatus.open,
      message: 'Open for Time-Out',
      attendanceStatus: 'Present',
      opensAt: timeOutOpen,
      closesAt: timeOutClose,
    );
  }
}
