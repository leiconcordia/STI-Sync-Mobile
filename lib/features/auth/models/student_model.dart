import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a registered student user in the mobile app.
class StudentModel {
  final String id; // Firebase Auth UID
  final String studentNumber; // e.g., "2024-00123"
  final String firstName;
  final String lastName;
  final String displayName; // Full name for display
  final String email;
  final String courseCode;
  final String courseName;
  final int yearLevel;
  final String sectionName;
  final String departmentCode;
  final String? avatarUrl;
  final List<String> organizationIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentModel({
    required this.id,
    required this.studentNumber,
    required this.firstName,
    required this.lastName,
    required this.displayName,
    required this.email,
    required this.courseCode,
    required this.courseName,
    required this.yearLevel,
    required this.sectionName,
    required this.departmentCode,
    this.avatarUrl,
    required this.organizationIds,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      studentNumber: data['studentNumber'] as String,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      displayName: data['displayName'] as String,
      email: data['email'] as String,
      courseCode: data['courseCode'] as String,
      courseName: data['courseName'] as String,
      yearLevel: data['yearLevel'] as int,
      sectionName: data['sectionName'] as String,
      departmentCode: data['departmentCode'] as String,
      avatarUrl: data['avatarUrl'] as String?,
      organizationIds: List<String>.from(data['organizationIds'] ?? []),
      isActive: data['isActive'] as bool? ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'studentNumber': studentNumber,
        'firstName': firstName,
        'lastName': lastName,
        'displayName': displayName,
        'email': email,
        'courseCode': courseCode,
        'courseName': courseName,
        'yearLevel': yearLevel,
        'sectionName': sectionName,
        'departmentCode': departmentCode,
        'avatarUrl': avatarUrl,
        'organizationIds': organizationIds,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
