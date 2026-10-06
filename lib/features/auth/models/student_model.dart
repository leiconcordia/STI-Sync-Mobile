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
  final String semester;         // "1st Semester" | "2nd Semester" | "1st Trimester"
  final String? academicLevel;   // "Tertiary" / "COLLEGE" | "SHS"
  final String email;
  final String profilePhotoUrl;  // Cloudinary secure_url, "" if none
  final String schoolIdPhotoUrl; // Cloudinary secure_url, "" if none
  final String status;           // ACTIVE | PENDING | RETURNED | INACTIVE | SUSPENDED | ARCHIVED | PENDING_REENROLLMENT
  final String registrationSource; // "SELF_REGISTER" | "MANUAL"
  final String addedBy;          // "self" for self-registration
  final String? rejectionReason; // Set by admin on RETURNED status only
  final int revisionCount;       // Number of revisions / retries
  final List<Map<String, dynamic>> revisionHistory; // Full history of comments & decisions
  final bool isProfileComplete;  // True if first-login onboarding is finished
  final bool requiresPasswordChange; // True if student is on default temporary password
  final String? defaultPassword; // Default temporary password if still on first-time onboarding
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
    this.academicLevel,
    required this.email,
    required this.profilePhotoUrl,
    required this.schoolIdPhotoUrl,
    required this.status,
    required this.registrationSource,
    required this.addedBy,
    this.rejectionReason,
    this.revisionCount = 0,
    this.revisionHistory = const [],
    this.isProfileComplete = true,
    this.requiresPasswordChange = false,
    this.defaultPassword,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the student is College / Tertiary.
  bool get isCollege {
    if (academicLevel != null && academicLevel!.trim().isNotEmpty) {
      final lvl = academicLevel!.trim().toUpperCase();
      if (lvl == 'TERTIARY' || lvl == 'COLLEGE') return true;
      if (lvl == 'SHS' || lvl.contains('SENIOR')) return false;
    }
    final y = yearLevel.trim().toUpperCase();
    if (y.contains('YEAR') ||
        y.contains('1ST') ||
        y.contains('2ND') ||
        y.contains('3RD') ||
        y.contains('4TH') ||
        y.contains('5TH')) {
      if (!y.contains('GRADE') && !y.contains('G11') && !y.contains('G12')) {
        return true;
      }
    }
    final c = courseCode.trim().toUpperCase();
    if (c == 'BSIT' ||
        c == 'BSCS' ||
        c == 'BSIS' ||
        c == 'ACT' ||
        c == 'DIT' ||
        c == 'BSBA' ||
        c == 'BSHM' ||
        c == 'BSTM' ||
        c == 'BSCPE' ||
        c == 'BSA' ||
        c == 'BSAIS' ||
        c == 'BSED') {
      return true;
    }
    final d = departmentId.trim().toUpperCase();
    final dn = departmentName.trim().toUpperCase();
    if (d.contains('COLLEGE') ||
        dn.contains('COLLEGE') ||
        d.contains('TERTIARY') ||
        dn.contains('TERTIARY') ||
        d.contains('IT') ||
        dn.contains('ICT')) {
      return true;
    }
    return !isShs;
  }

  /// True if the student is Senior High School (Grade 11/12 or SHS strands).
  bool get isShs {
    if (academicLevel != null && academicLevel!.trim().isNotEmpty) {
      final lvl = academicLevel!.trim().toUpperCase();
      if (lvl == 'SHS' || lvl.contains('SENIOR')) return true;
      if (lvl == 'TERTIARY' || lvl == 'COLLEGE') return false;
    }
    final y = yearLevel.trim().toUpperCase();
    if (y.contains('GRADE') ||
        y.contains('G11') ||
        y.contains('G12') ||
        y == '11' ||
        y == '12') {
      return true;
    }
    final c = courseCode.trim().toUpperCase();
    final n = courseName.trim().toUpperCase();
    final d = departmentId.trim().toUpperCase();
    final dn = departmentName.trim().toUpperCase();
    if (c.contains('STEM') ||
        c.contains('ABM') ||
        c.contains('HUMSS') ||
        c.contains('TVL') ||
        c.contains('GAS') ||
        n.contains('SENIOR HIGH') ||
        d.contains('SHS') ||
        dn.contains('SHS')) {
      return true;
    }
    // If yearLevel or courseCode indicates College, definitely NOT SHS
    if (y.contains('YEAR') ||
        c == 'BSIT' ||
        c == 'BSCS' ||
        c == 'BSIS' ||
        c == 'ACT' ||
        c == 'DIT' ||
        c == 'BSBA' ||
        c == 'BSHM' ||
        c == 'BSTM' ||
        c == 'BSCPE' ||
        c == 'BSA') {
      return false;
    }
    return false;
  }

  /// Returns the standardized academic level ('COLLEGE' vs 'SHS').
  String get standardizedAcademicLevel => isShs ? 'SHS' : 'COLLEGE';

  /// Evaluates whether two academic year strings represent the same school year
  /// (e.g. 'A.Y. 2026-2027' vs '2026-2027' or '2026 - 2027').
  static bool areAcademicYearsEquivalent(String sy1, String sy2) {
    final clean1 = sy1.replaceAll(RegExp(r'[^0-9]'), '');
    final clean2 = sy2.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean1.isNotEmpty && clean2.isNotEmpty) {
      return clean1 == clean2;
    }
    return sy1.trim().toLowerCase() == sy2.trim().toLowerCase();
  }

  /// Evaluates whether two semester strings represent the same term index
  /// (e.g. '2nd Semester' vs '2nd Trimester' vs '2nd').
  static bool areSemestersEquivalent(String sem1, String sem2) {
    if (sem1.trim().toLowerCase() == sem2.trim().toLowerCase()) return true;

    int? extractTerm(String s) {
      final lower = s.toLowerCase();
      if (lower.contains('1st') || lower.contains('first') || RegExp(r'\b1\b').hasMatch(lower)) return 1;
      if (lower.contains('2nd') || lower.contains('second') || RegExp(r'\b2\b').hasMatch(lower)) return 2;
      if (lower.contains('3rd') || lower.contains('third') || RegExp(r'\b3\b').hasMatch(lower)) return 3;
      if (lower.contains('summer')) return 4;
      return null;
    }

    final t1 = extractTerm(sem1);
    final t2 = extractTerm(sem2);
    if (t1 != null && t2 != null) {
      return t1 == t2;
    }
    return false;
  }

  /// Evaluates whether the student must complete in-app semester re-enrollment.
  bool isPendingReEnrollment(SemesterModel? activeSemester) {
    final statusUpper = status.trim().toUpperCase();
    if (statusUpper == 'PENDING_REENROLLMENT') return true;
    if (statusUpper != 'ACTIVE') return false;
    if (activeSemester == null) return false;
    if (!activeSemester.isActive) return false;

    // Evaluate only against the active semester dedicated to the student's academic level
    if (isShs && !activeSemester.isShs) return false;
    if (isCollege && !activeSemester.isCollege) return false;

    final syMismatch = activeSemester.academicYear.trim().isNotEmpty &&
        !areAcademicYearsEquivalent(schoolYear, activeSemester.academicYear);
    final semMismatch = activeSemester.semester.trim().isNotEmpty &&
        !areSemestersEquivalent(semester, activeSemester.semester);

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
    String? academicLevel,
    String? email,
    String? profilePhotoUrl,
    String? schoolIdPhotoUrl,
    String? status,
    String? registrationSource,
    String? addedBy,
    String? rejectionReason,
    int? revisionCount,
    List<Map<String, dynamic>>? revisionHistory,
    bool? isProfileComplete,
    bool? requiresPasswordChange,
    String? defaultPassword,
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
      academicLevel: academicLevel ?? this.academicLevel,
      email: email ?? this.email,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      schoolIdPhotoUrl: schoolIdPhotoUrl ?? this.schoolIdPhotoUrl,
      status: status ?? this.status,
      registrationSource: registrationSource ?? this.registrationSource,
      addedBy: addedBy ?? this.addedBy,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      revisionCount: revisionCount ?? this.revisionCount,
      revisionHistory: revisionHistory ?? this.revisionHistory,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      requiresPasswordChange: requiresPasswordChange ?? this.requiresPasswordChange,
      defaultPassword: defaultPassword ?? this.defaultPassword,
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
      academicLevel: d['academicLevel'] as String?,
      email: d['email'] as String? ?? '',
      profilePhotoUrl: d['profilePhotoUrl'] as String? ?? '',
      schoolIdPhotoUrl: d['schoolIdPhotoUrl'] as String? ?? '',
      status: docStatus,
      registrationSource: d['registrationSource'] as String? ?? '',
      addedBy: d['addedBy'] as String? ?? '',
      rejectionReason: rejectionReason,
      revisionCount: (d['revisionCount'] as num?)?.toInt() ?? parsedHistory.length,
      revisionHistory: parsedHistory,
      isProfileComplete: d['isProfileComplete'] as bool? ?? true,
      requiresPasswordChange: d['requiresPasswordChange'] as bool? ?? false,
      defaultPassword: d['defaultPassword'] as String?,
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
        if (academicLevel != null) 'academicLevel': academicLevel,
        'email': email,
        'profilePhotoUrl': profilePhotoUrl,
        'schoolIdPhotoUrl': schoolIdPhotoUrl,
        'status': status,
        if (defaultPassword != null) 'defaultPassword': defaultPassword,
        'registrationSource': registrationSource,
        'addedBy': addedBy,
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
        'revisionCount': revisionCount,
        'revisionHistory': revisionHistory,
        'isProfileComplete': isProfileComplete,
        'requiresPasswordChange': requiresPasswordChange,
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
    bool? isProfileCompleteOverride,
    bool? requiresPasswordChangeOverride,
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
      if (academicLevel != null) 'academicLevel': academicLevel,
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
      'isProfileComplete': isProfileCompleteOverride ?? isProfileComplete,
      'requiresPasswordChange': requiresPasswordChangeOverride ?? requiresPasswordChange,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
