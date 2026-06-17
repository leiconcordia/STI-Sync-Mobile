import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a student document from Firestore `students/{uid}`.
///
/// Field names match the shared web+mobile schema exactly — do not rename.
/// Document ID = Firebase Auth UID = [id] = [authUid].
class StudentModel {
  final String id;               // Firebase Auth UID (doc id)
  final String authUid;          // Same as id — kept for explicit read-back
  final String lastName;
  final String firstName;
  final String middleName;       // "" if none
  final String studentId;        // Official STI ID, 11 digits
  final String dateOfBirth;      // ISO YYYY-MM-DD
  final String sex;              // "Male" | "Female"
  final String contactNumber;    // 10 digits starting with 9, no +63
  final String courseId;         // FK → courses
  final String courseName;
  final String courseCode;
  final String departmentId;     // FK → departments
  final String departmentName;
  final String yearLevel;        // "1st Year".."4th Year"
  final String section;
  final String schoolYear;       // e.g. "2026-2027"
  final String semester;         // "1st Semester" | "2nd Semester"
  final String email;
  final String profilePhotoUrl;  // Cloudinary secure_url, "" if none
  final String schoolIdPhotoUrl; // Cloudinary secure_url, "" if none
  final String status;           // ACTIVE | PENDING | RETURNED | INACTIVE | SUSPENDED | ARCHIVED
  final String registrationSource; // "SELF_REGISTER" | "MANUAL"
  final String addedBy;          // "self" for self-registration
  final String? rejectionReason; // Set by admin on RETURNED status only
  final DateTime createdAt;
  final DateTime updatedAt;

  const StudentModel({
    required this.id,
    required this.authUid,
    required this.lastName,
    required this.firstName,
    required this.middleName,
    required this.studentId,
    required this.dateOfBirth,
    required this.sex,
    required this.contactNumber,
    required this.courseId,
    required this.courseName,
    required this.courseCode,
    required this.departmentId,
    required this.departmentName,
    required this.yearLevel,
    required this.section,
    required this.schoolYear,
    required this.semester,
    required this.email,
    required this.profilePhotoUrl,
    required this.schoolIdPhotoUrl,
    required this.status,
    required this.registrationSource,
    required this.addedBy,
    this.rejectionReason,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      authUid: d['authUid'] as String? ?? doc.id,
      lastName: d['lastName'] as String? ?? '',
      firstName: d['firstName'] as String? ?? '',
      middleName: d['middleName'] as String? ?? '',
      studentId: d['studentId'] as String? ?? '',
      dateOfBirth: d['dateOfBirth'] as String? ?? '',
      sex: d['sex'] as String? ?? '',
      contactNumber: d['contactNumber'] as String? ?? '',
      courseId: d['courseId'] as String? ?? '',
      courseName: d['courseName'] as String? ?? '',
      courseCode: d['courseCode'] as String? ?? '',
      departmentId: d['departmentId'] as String? ?? '',
      departmentName: d['departmentName'] as String? ?? '',
      yearLevel: d['yearLevel'] as String? ?? '',
      section: d['section'] as String? ?? '',
      schoolYear: d['schoolYear'] as String? ?? '',
      semester: d['semester'] as String? ?? '',
      email: d['email'] as String? ?? '',
      profilePhotoUrl: d['profilePhotoUrl'] as String? ?? '',
      schoolIdPhotoUrl: d['schoolIdPhotoUrl'] as String? ?? '',
      status: d['status'] as String? ?? 'PENDING',
      registrationSource: d['registrationSource'] as String? ?? '',
      addedBy: d['addedBy'] as String? ?? '',
      rejectionReason: d['rejectionReason'] as String?,
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: d['updatedAt'] is Timestamp
          ? (d['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'authUid': authUid,
        'lastName': lastName,
        'firstName': firstName,
        'middleName': middleName,
        'studentId': studentId,
        'dateOfBirth': dateOfBirth,
        'sex': sex,
        'contactNumber': contactNumber,
        'courseId': courseId,
        'courseName': courseName,
        'courseCode': courseCode,
        'departmentId': departmentId,
        'departmentName': departmentName,
        'yearLevel': yearLevel,
        'section': section,
        'schoolYear': schoolYear,
        'semester': semester,
        'email': email,
        'profilePhotoUrl': profilePhotoUrl,
        'schoolIdPhotoUrl': schoolIdPhotoUrl,
        'status': status,
        'registrationSource': registrationSource,
        'addedBy': addedBy,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Builds the Firestore write map with the final UID and Cloudinary URLs
  /// substituted in. Passwords are NEVER written to Firestore.
  Map<String, dynamic> toFirestoreMap({
    required String uid,
    required String profilePhotoUrl,
    required String schoolIdPhotoUrl,
  }) {
    return {
      'id': uid,
      'authUid': uid,
      'lastName': lastName,
      'firstName': firstName,
      'middleName': middleName,
      'studentId': studentId,
      'dateOfBirth': dateOfBirth,
      'sex': sex,
      'contactNumber': contactNumber,
      'courseId': courseId,
      'courseName': courseName,
      'courseCode': courseCode,
      'departmentId': departmentId,
      'departmentName': departmentName,
      'yearLevel': yearLevel,
      'section': section,
      'schoolYear': schoolYear,
      'semester': semester,
      'email': email,
      'profilePhotoUrl': profilePhotoUrl,
      'schoolIdPhotoUrl': schoolIdPhotoUrl,
      'status': status,
      'registrationSource': registrationSource,
      'addedBy': addedBy,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
