import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an organization in Firestore (`/organizations/{organizationId}`).
class OrganizationModel {
  final String id;
  final String name;
  final String acronym;
  final String description;
  final String departmentId;           // FK -> /departments or 'cross-departmental'
  final String departmentName;         // Denormalized department title
  final String departmentCode;         // Denormalized department code (e.g., 'CITE', 'CBA')
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
    this.departmentName = '',
    this.departmentCode = '',
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

  bool get isDepartmental =>
      scope.toLowerCase() == 'departmental' ||
      (departmentId.isNotEmpty &&
          departmentId.toLowerCase() != 'cross-departmental' &&
          departmentId.toLowerCase() != 'all');

  bool get isCrossDepartmental => !isDepartmental;

  /// Checks if a student is eligible to join.
  /// If cross-departmental: open to all students.
  /// If departmental: only students belonging to that department can apply/join.
  bool isStudentEligible(String? studentDeptId, String? studentDeptName) {
    if (isCrossDepartmental) return true;

    // 1. Match by departmentId
    if (studentDeptId != null && studentDeptId.isNotEmpty) {
      if (studentDeptId.toLowerCase() == departmentId.toLowerCase() ||
          allowedDepartmentIds.any((id) => id.toLowerCase() == studentDeptId.toLowerCase())) {
        return true;
      }
    }

    // 2. Match by departmentName or departmentCode
    if (studentDeptName != null && studentDeptName.isNotEmpty) {
      final sNorm = studentDeptName.trim().toLowerCase();
      if (departmentName.isNotEmpty) {
        final dNorm = departmentName.trim().toLowerCase();
        if (sNorm == dNorm || sNorm.contains(dNorm) || dNorm.contains(sNorm)) {
          return true;
        }
      }
      if (departmentCode.isNotEmpty) {
        final cNorm = departmentCode.trim().toLowerCase();
        if (sNorm == cNorm || sNorm.contains(cNorm) || cNorm.contains(sNorm)) {
          return true;
        }
      }
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

    final isCrossExplicit = data['isCrossDepartmental'] as bool?;
    final rawDeptId = (data['departmentId'] as String?) ??
        (data['department'] as String?) ??
        'cross-departmental';
    final rawDeptName = (data['departmentName'] as String?) ??
        (data['department_name'] as String?) ??
        (data['department'] as String?) ??
        '';
    final rawDeptCode = (data['departmentCode'] as String?) ??
        (data['department_code'] as String?) ??
        '';
    final rawScope = (data['scope'] as String?) ??
        (isCrossExplicit == true
            ? 'cross-departmental'
            : (rawDeptId.toLowerCase() != 'cross-departmental' ? 'departmental' : 'cross-departmental'));

    return OrganizationModel(
      id: docId,
      name: data['name'] as String? ?? (data['organizationName'] as String?) ?? 'Organization',
      acronym: data['acronym'] as String? ?? (data['code'] as String?) ?? (data['name'] is String && (data['name'] as String).length >= 2 ? (data['name'] as String).substring(0, 2) : 'ORG'),
      description: data['description'] as String? ?? '',
      departmentId: rawDeptId,
      departmentName: rawDeptName,
      departmentCode: rawDeptCode,
      scope: rawScope,
      allowedDepartmentIds: List<String>.from(data['allowedDepartmentIds'] ?? []),
      allowedCourseIds: List<String>.from(data['allowedCourseIds'] ?? []),
      academicYear: data['academicYear'] as String? ?? '',
      semester: data['semester'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      logoUrl: (data['logoUrl'] as String?) ?? (data['logo'] as String?),
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
