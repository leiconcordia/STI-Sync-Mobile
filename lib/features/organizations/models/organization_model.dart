import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an organization in Firestore (`/organizations/{organizationId}`).
class OrganizationModel {
  final String id;
  final String name;
  final String acronym;
  final String description;
  final String departmentId;           // FK → /departments or 'cross-departmental'
  final String scope;                  // 'departmental' | 'cross-departmental'
  final List<String> allowedDepartmentIds; // Target department IDs if scope === 'departmental'
  final List<String> allowedCourseIds;     // Target course IDs if scope === 'departmental'
  final String academicYear;
  final String semester;
  final String status;                 // 'active' | 'inactive' | 'suspended'
  final int memberCount;
  final String? logoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrganizationModel({
    required this.id,
    required this.name,
    required this.acronym,
    required this.description,
    required this.departmentId,
    required this.scope,
    required this.allowedDepartmentIds,
    required this.allowedCourseIds,
    required this.academicYear,
    required this.semester,
    required this.status,
    required this.memberCount,
    this.logoUrl,
    this.createdAt,
    this.updatedAt,
  });

  bool get isDepartmental => scope == 'departmental';
  bool get isCrossDepartmental => scope == 'cross-departmental' || !isDepartmental;

  /// Checks if a student is eligible to join based on student's departmentId/departmentName.
  bool isStudentEligible(String? studentDeptId, String? studentDeptName) {
    if (isCrossDepartmental) return true;
    if (studentDeptId == null || studentDeptId.trim().isEmpty) return true;

    final targetId = studentDeptId.trim().toLowerCase();
    final targetName = (studentDeptName ?? '').trim().toLowerCase();

    if (departmentId.trim().toLowerCase() == targetId || departmentId.trim().toLowerCase() == targetName) {
      return true;
    }

    if (allowedDepartmentIds.isNotEmpty) {
      final matchesAllowed = allowedDepartmentIds.any((d) {
        final lower = d.trim().toLowerCase();
        return lower == targetId || lower == targetName;
      });
      if (matchesAllowed) return true;
    }

    return false;
  }

  factory OrganizationModel.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return OrganizationModel(
      id: docId,
      name: data['name'] as String? ?? 'Organization',
      acronym: data['acronym'] as String? ?? (data['name'] is String && (data['name'] as String).length >= 2 ? (data['name'] as String).substring(0, 2) : 'ORG'),
      description: data['description'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? 'cross-departmental',
      scope: data['scope'] as String? ?? (data['departmentId'] != null && data['departmentId'] != 'cross-departmental' ? 'departmental' : 'cross-departmental'),
      allowedDepartmentIds: List<String>.from(data['allowedDepartmentIds'] ?? []),
      allowedCourseIds: List<String>.from(data['allowedCourseIds'] ?? []),
      academicYear: data['academicYear'] as String? ?? '',
      semester: data['semester'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      logoUrl: data['logoUrl'] as String?,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
