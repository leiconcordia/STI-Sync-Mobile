import 'package:intl/intl.dart';

/// Centralized Date & Time Formatter for STI Sync Mobile.
/// Enforces consistent application standards:
/// - Date: `Aug, 9 2025` (Short month with comma, unpadded day, 4-digit year)
/// - Time: `12:30 PM` (12-hour format with AM/PM uppercase, unpadded hour, no military 24h)
/// - Combined: `Aug, 9 2025 • 12:30 PM`

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

    // 1. Direct ISO-8601 parsing (e.g. "2026-08-09" or "2026-08-09T12:30:00")
    final isoParsed = DateTime.tryParse(trimmed);
    if (isoParsed != null) return isoParsed;

    // 2. Check if it is a time string (12-hour or 24-hour military)
    try {
      final is12Hour = trimmed.toUpperCase().contains('AM') ||
          trimmed.toUpperCase().contains('PM');
      final today = DateTime.now();
      final todayStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      if (is12Hour) {
        final normalized = trimmed.replaceAllMapped(
          RegExp(r'(\d+:\d+)\s*([AaPp][Mm])'),
          (m) => '${m[1]} ${m[2]!.toUpperCase()}',
        );
        return DateFormat('yyyy-MM-dd h:mm a').parse('$todayStr $normalized');
      } else if (trimmed.contains(':')) {
        final parts = trimmed.split(':');
        if (parts.length >= 2) {
          final hour = int.parse(parts[0].trim());
          final minute = int.parse(parts[1].trim());
          final second = parts.length > 2 ? int.tryParse(parts[2].trim()) ?? 0 : 0;
          return DateTime(today.year, today.month, today.day, hour, minute, second);
        }
      }
    } catch (_) {}

    // 3. Check custom date formats
    for (final pattern in [
      'MMM, d yyyy',
      'MMM d, yyyy',
      'MMM d yyyy',
      'MM/dd/yyyy',
      'yyyy/MM/dd'
    ]) {
      try {
        return DateFormat(pattern).parse(trimmed);
      } catch (_) {}
    }
  }

  // Handles objects with toDate() method (such as Cloud Firestore Timestamp)
  try {
    final dynamic d = (input as dynamic).toDate();
    if (d is DateTime) return d;
  } catch (_) {}

  return null;
}

/// Formats a date into `Aug, 9 2025`
String formatAppDate(dynamic date, {String fallback = '—'}) {
  final dt = _parseDateTimeSafe(date);
  if (dt == null) return fallback;
  try {
    return DateFormat('MMM, d yyyy').format(dt);
  } catch (_) {
    return fallback;
  }
}

/// Formats a time into `12:30 PM` (12-hour format, uppercase AM/PM, no military time)
String formatAppTime(dynamic time, {String fallback = '—'}) {
  final dt = _parseDateTimeSafe(time);
  if (dt == null) {
    if (time is String && time.trim().isNotEmpty) {
      final trimmed = time.trim();
      if (RegExp(r'^\d{1,2}:\d{2}').hasMatch(trimmed)) {
        try {
          final parts = trimmed.split(':');
          final hour = int.parse(parts[0]);
          final minute = int.parse(parts[1].split(' ')[0]);
          final d = DateTime(2026, 1, 1, hour, minute);
          return DateFormat('h:mm a').format(d);
        } catch (_) {}
      }
    }
    return fallback;
  }
  try {
    return DateFormat('h:mm a').format(dt);
  } catch (_) {
    return fallback;
  }
}

/// Formats combined date and time into `Aug, 9 2025 • 12:30 PM`
String formatAppDateTime(dynamic dateTime, {String fallback = '—', String separator = ' • '}) {
  final dt = _parseDateTimeSafe(dateTime);
  if (dt == null) return fallback;
  try {
    final dateStr = DateFormat('MMM, d yyyy').format(dt);
    final timeStr = DateFormat('h:mm a').format(dt);
    return '$dateStr$separator$timeStr';
  } catch (_) {
    return fallback;
  }
}

/// Formats a date range into `Aug, 9 2025 – Aug, 12 2025`
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
