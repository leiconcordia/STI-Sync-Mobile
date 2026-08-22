import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';

/// Represents an academic semester document from `/semesters/{semesterId}`.
class SemesterModel {
  final String id;
  final String academicYear; // e.g. "2026-2027"
  final String semester;     // e.g. "1st Semester", "2nd Semester"
  final String status;       // "ACTIVE", "UPCOMING", "COMPLETED", "INACTIVE"
  final bool isCurrent;
  final DateTime? reenrollDeadline;
  final DateTime? startDate;
  final DateTime? endDate;

  const SemesterModel({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.status,
    required this.isCurrent,
    this.reenrollDeadline,
    this.startDate,
    this.endDate,
  });

  bool get isActive =>
      status.toUpperCase() == 'ACTIVE' || isCurrent == true;

  String get displayName {
    if (semester.isNotEmpty && academicYear.isNotEmpty) {
      return '$semester · A.Y. $academicYear';
    } else if (semester.isNotEmpty) {
      return semester;
    }
    return academicYear;
  }

  String get formattedDeadline {
    if (reenrollDeadline == null) return 'the designated period';
    return formatAppDate(reenrollDeadline);
  }

  factory SemesterModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return SemesterModel.fromMap(d, doc.id);
  }

  factory SemesterModel.fromMap(Map<String, dynamic> d, String id) {
    final rawStatus = (d['status'] as String?) ??
        ((d['isActive'] == true || d['isCurrent'] == true) ? 'ACTIVE' : 'INACTIVE');
    
    final sem = (d['semester'] as String?) ??
        (d['name'] as String?) ??
        (d['term'] as String?) ??
        '';

    final sy = (d['academicYear'] as String?) ??
        (d['schoolYear'] as String?) ??
        (d['year'] as String?) ??
        '';

    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return SemesterModel(
      id: id,
      academicYear: sy.trim(),
      semester: sem.trim(),
      status: rawStatus.trim().toUpperCase(),
      isCurrent: d['isCurrent'] == true || d['isActive'] == true || rawStatus.trim().toUpperCase() == 'ACTIVE',
      reenrollDeadline: parseDate(d['reenrollDeadline'] ?? d['reEnrollmentDeadline'] ?? d['deadline']),
      startDate: parseDate(d['startDate']),
      endDate: parseDate(d['endDate']),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'academicYear': academicYear,
        'semester': semester,
        'status': status,
        'isCurrent': isCurrent,
        if (reenrollDeadline != null) 'reenrollDeadline': Timestamp.fromDate(reenrollDeadline!),
        if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      };
}
