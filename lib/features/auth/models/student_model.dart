import 'package:cloud_firestore/cloud_firestore.dart';
import '../../semester/models/semester_model.dart';

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
  final String status;           // ACTIVE | PENDING | RETURNED | INACTIVE | SUSPENDED | ARCHIVED | PENDING_REENROLLMENT
  final String registrationSource; // "SELF_REGISTER" | "MANUAL"
  final String addedBy;          // "self" for self-registration
  final String? rejectionReason; // Set by admin on RETURNED status only
  final int revisionCount;       // Number of revisions / retries
  final List<Map<String, dynamic>> revisionHistory; // Full history of comments & decisions
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
    this.revisionCount = 0,
    this.revisionHistory = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Evaluates whether the student must complete in-app semester re-enrollment.
  bool isPendingReEnrollment(SemesterModel? activeSemester) {
    final statusUpper = status.trim().toUpperCase();
    if (statusUpper == 'PENDING_REENROLLMENT') return true;
    if (statusUpper != 'ACTIVE') return false;
    if (activeSemester == null) return false;
    if (!activeSemester.isActive) return false;

    final syMismatch = activeSemester.academicYear.isNotEmpty &&
        schoolYear.trim().toLowerCase() != activeSemester.academicYear.trim().toLowerCase();
    final semMismatch = activeSemester.semester.isNotEmpty &&
        semester.trim().toLowerCase() != activeSemester.semester.trim().toLowerCase();

    return syMismatch || semMismatch;
  }

  /// Whether the student is fully re-enrolled and active for the current active semester.
  bool isReEnrolled(SemesterModel? activeSemester) =>
      !isPendingReEnrollment(activeSemester);

  StudentModel copyWith({
    String? id,
    String? authUid,
    String? lastName,
    String? firstName,
    String? middleName,
    String? studentId,
    String? dateOfBirth,
    String? sex,
    String? contactNumber,
    String? courseId,
    String? courseName,
    String? courseCode,
    String? departmentId,
    String? departmentName,
    String? yearLevel,
    String? section,
    String? schoolYear,
    String? semester,
    String? email,
    String? profilePhotoUrl,
    String? schoolIdPhotoUrl,
    String? status,
    String? registrationSource,
    String? addedBy,
    String? rejectionReason,
    int? revisionCount,
    List<Map<String, dynamic>>? revisionHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      authUid: authUid ?? this.authUid,
      lastName: lastName ?? this.lastName,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      studentId: studentId ?? this.studentId,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      contactNumber: contactNumber ?? this.contactNumber,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseCode: courseCode ?? this.courseCode,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      yearLevel: yearLevel ?? this.yearLevel,
      section: section ?? this.section,
      schoolYear: schoolYear ?? this.schoolYear,
      semester: semester ?? this.semester,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      schoolIdPhotoUrl: schoolIdPhotoUrl ?? this.schoolIdPhotoUrl,
      status: status ?? this.status,
      registrationSource: registrationSource ?? this.registrationSource,
      addedBy: addedBy ?? this.addedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      revisionCount: revisionCount ?? this.revisionCount,
      revisionHistory: revisionHistory ?? this.revisionHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final rawHistory = d['revisionHistory'] as List<dynamic>?;
    final parsedHistory = rawHistory != null
        ? rawHistory.map((item) => Map<String, dynamic>.from(item as Map)).toList()
        : <Map<String, dynamic>>[];

    final rejectionReason = d['rejectionReason'] as String?;
    final docStatus = (d['status'] as String? ?? 'PENDING').trim().toUpperCase();

    // If there is no history yet but rejectionReason or RETURNED exists, initialize Revision #1
    if (parsedHistory.isEmpty && ((rejectionReason != null && rejectionReason.isNotEmpty) || docStatus == 'RETURNED')) {
      parsedHistory.add({
        'revisionNumber': 1,
        'status': docStatus == 'RETURNED' ? 'RETURNED' : 'PENDING',
        'reason': (rejectionReason != null && rejectionReason.isNotEmpty)
            ? rejectionReason
            : 'Returned for revision by Adviser / SAO Staff.',
        'reviewedBy': 'Adviser / SAO Staff',
        'timestamp': d['updatedAt'] is Timestamp
            ? (d['updatedAt'] as Timestamp).toDate().toIso8601String()
            : DateTime.now().toIso8601String(),
      });
    } else if (parsedHistory.isNotEmpty && docStatus == 'RETURNED' && rejectionReason != null && rejectionReason.isNotEmpty) {
      // If adviser marked RETURNED and provided/updated a comment, reflect it on the latest revision
      final last = parsedHistory.last;
      if (last['reason'] != rejectionReason || last['status'] != 'RETURNED') {
        last['status'] = 'RETURNED';
        last['reason'] = rejectionReason;
        last['reviewedBy'] = 'Adviser / SAO Staff';
      }
    }

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
      status: docStatus,
      registrationSource: d['registrationSource'] as String? ?? '',
      addedBy: d['addedBy'] as String? ?? '',
      rejectionReason: rejectionReason,
      revisionCount: (d['revisionCount'] as num?)?.toInt() ?? parsedHistory.length,
      revisionHistory: parsedHistory,
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
        'revisionCount': revisionCount,
        'revisionHistory': revisionHistory,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// Builds the Firestore write map with the final UID and Cloudinary URLs
  /// substituted in. Passwords are NEVER written to Firestore.
  Map<String, dynamic> toFirestoreMap({
    required String uid,
    required String profilePhotoUrl,
    required String schoolIdPhotoUrl,
    String? statusOverride,
    String? rejectionReasonOverride,
    int? revisionCountOverride,
    List<Map<String, dynamic>>? revisionHistoryOverride,
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
      'status': statusOverride ?? status,
      'registrationSource': registrationSource,
      'addedBy': addedBy,
      if (rejectionReasonOverride != null || rejectionReason != null)
        'rejectionReason': rejectionReasonOverride ?? rejectionReason,
      'revisionCount': revisionCountOverride ?? revisionCount,
      'revisionHistory': revisionHistoryOverride ?? revisionHistory,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
