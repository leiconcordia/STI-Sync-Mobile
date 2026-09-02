import 'package:intl/intl.dart';

/// Centralized Date & Time Formatter for STI Sync Mobile.
/// Enforces consistent application standards:
/// - Date: `Aug 9 2005` (Short month, unpadded day, 4-digit year)
/// - Time: `12:49 PM` (12-hour format with AM/PM uppercase, no military 24h)
/// - Combined: `Aug 9 2005 • 12:49 PM`

DateTime? _parseDateTimeSafe(dynamic input) {
  if (input == null) return null;
  if (input is DateTime) return input;
  if (input is int) {
    return DateTime.fromMillisecondsSinceEpoch(
      input > 10000000000 ? input : input * 1000,
    );
  }
  if (input is String) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return DateTime.tryParse(trimmed);
  }
  // Handles objects with toDate() method (such as Cloud Firestore Timestamp)
  try {
    final dynamic d = (input as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {}

  return null;
}

/// Formats a date into `Aug 9, 2026`
String formatAppDate(dynamic date, {String fallback = '—'}) {
  final dt = _parseDateTimeSafe(date);
  if (dt == null) return fallback;
  try {
    return DateFormat('MMM d, yyyy').format(dt);
  } catch (_) {
    return fallback;
  }
}

/// Formats a time into `12:49 PM` (12-hour format, uppercase AM/PM)
String formatAppTime(dynamic time, {String fallback = '—'}) {
  final dt = _parseDateTimeSafe(time);
  if (dt == null) return fallback;
  try {
    return DateFormat('h:mm a').format(dt);
  } catch (_) {
    return fallback;
  }
}

/// Formats combined date and time into `Aug 9, 2026 • 12:49 PM`
String formatAppDateTime(dynamic dateTime, {String fallback = '—', String separator = ' • '}) {
  final dt = _parseDateTimeSafe(dateTime);
  if (dt == null) return fallback;
  try {
    final dateStr = DateFormat('MMM d, yyyy').format(dt);
    final timeStr = DateFormat('h:mm a').format(dt);
    return '$dateStr$separator$timeStr';
  } catch (_) {
    return fallback;
  }
}

/// Formats a date range into `Aug, 9 2026 – Aug, 12 2026`
String formatAppDateRange(dynamic start, dynamic end, {String fallback = '—'}) {
  final dtStart = _parseDateTimeSafe(start);
  final dtEnd = _parseDateTimeSafe(end);

  if (dtStart == null && dtEnd == null) return fallback;
  if (dtStart != null && dtEnd == null) return formatAppDate(dtStart, fallback: fallback);
  if (dtStart == null && dtEnd != null) return formatAppDate(dtEnd, fallback: fallback);

  final startStr = DateFormat('MMM, d yyyy').format(dtStart!);
  final endStr = DateFormat('MMM, d yyyy').format(dtEnd!);

  if (startStr == endStr) return startStr;
  return '$startStr – $endStr';
}
