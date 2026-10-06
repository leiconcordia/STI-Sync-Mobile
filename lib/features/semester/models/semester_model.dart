import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';

/// Represents an academic semester document from `/semesters/{semesterId}`.
class SemesterModel {
  final String id;
  final String academicYear; // e.g. "2026-2027"
  final String semester;     // e.g. "1st Semester", "2nd Semester"
  final String status;       // "ACTIVE", "UPCOMING", "COMPLETED", "INACTIVE"
  final bool isCurrent;
  final String? academicLevel; // "COLLEGE" | "SHS" | "TERTIARY"
  final DateTime? reenrollDeadline;
  final DateTime? startDate;
  final DateTime? endDate;

  const SemesterModel({
    required this.id,
    required this.academicYear,
    required this.semester,
    required this.status,
    required this.isCurrent,
    this.academicLevel,
    this.reenrollDeadline,
    this.startDate,
    this.endDate,
  });

  bool get isActive =>
      status.toUpperCase() == 'ACTIVE' || isCurrent == true;

  /// True if this academic period belongs to Senior High School (Trimester system or SHS level).
  bool get isShs {
    final lvl = (academicLevel ?? '').trim().toUpperCase();
    if (lvl == 'SHS' || lvl.contains('SENIOR')) return true;
    if (lvl == 'COLLEGE' || lvl == 'TERTIARY') return false;
    return semester.toLowerCase().contains('trimester') ||
        id.toLowerCase().contains('shs');
  }

  /// True if this academic period belongs to College / Tertiary (Semester system).
  bool get isCollege => !isShs;

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

  bool get isReEnrollmentDeadlinePassed {
    if (reenrollDeadline == null) return false;
    return DateTime.now().isAfter(reenrollDeadline!);
  }

  SemesterModel copyWith({
    String? id,
    String? academicYear,
    String? semester,
    String? status,
    bool? isCurrent,
    String? academicLevel,
    DateTime? reenrollDeadline,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return SemesterModel(
      id: id ?? this.id,
      academicYear: academicYear ?? this.academicYear,
      semester: semester ?? this.semester,
      status: status ?? this.status,
      isCurrent: isCurrent ?? this.isCurrent,
      academicLevel: academicLevel ?? this.academicLevel,
      reenrollDeadline: reenrollDeadline ?? this.reenrollDeadline,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  /// Returns a cohort-adapted copy of this semester model matching the student's cohort.
  /// If student is College, converts any "Trimester" to "Semester" (e.g. "2nd Trimester" -> "2nd Semester").
  /// If student is SHS, converts any "Semester" to "Trimester" (e.g. "2nd Semester" -> "2nd Trimester").
  SemesterModel forCohort({required bool isShs}) {
    if (isShs) {
      if (this.isShs) return this;
      final convertedSem = semester.replaceAll(RegExp(r'Semester', caseSensitive: false), 'Trimester');
      return copyWith(
        semester: convertedSem.contains('Trimester') ? convertedSem : '$semester (Trimester)',
        academicLevel: 'SHS',
      );
    } else {
      if (isCollege && !semester.toLowerCase().contains('trimester')) return this;
      final convertedSem = semester.replaceAll(RegExp(r'Trimester', caseSensitive: false), 'Semester');
      return copyWith(
        semester: convertedSem.contains('Semester') ? convertedSem : '$semester (Semester)',
        academicLevel: 'COLLEGE',
      );
    }
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

    final acaLevel = (d['academicLevel'] as String?) ??
        (d['level'] as String?) ??
        (d['targetAcademicLevel'] as String?);

    return SemesterModel(
      id: id,
      academicYear: sy.trim(),
      semester: sem.trim(),
      status: rawStatus.trim().toUpperCase(),
      isCurrent: d['isCurrent'] == true || d['isActive'] == true || rawStatus.trim().toUpperCase() == 'ACTIVE',
      academicLevel: acaLevel?.trim().toUpperCase(),
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
        if (academicLevel != null) 'academicLevel': academicLevel,
        if (reenrollDeadline != null) 'reenrollDeadline': Timestamp.fromDate(reenrollDeadline!),
        if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
        if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      };
}
