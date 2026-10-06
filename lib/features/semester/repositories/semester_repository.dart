import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import '../models/semester_model.dart';

class SemesterRepository {
  final FirebaseFirestore _firestore;

  SemesterRepository(this._firestore);

  /// Streams the currently active academic semester from Firestore.
  /// If [isShs] is provided, prioritizes the active academic period dedicated to that cohort
  /// (Trimester for SHS, Semester for College).
  Stream<SemesterModel?> watchActiveSemester({bool? isShs}) {
    return _firestore
        .collection(FirestorePaths.semesters)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;

      final activeList = <SemesterModel>[];
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['archived'] == true) continue;
        final status = (data['status'] as String?)?.toUpperCase() ?? '';
        final isActive = data['isActive'] == true ||
            data['isCurrent'] == true ||
            data['is_active'] == true;
        if (status == 'ACTIVE' || isActive) {
          activeList.add(SemesterModel.fromFirestore(doc));
        }
      }

      if (activeList.isNotEmpty) {
        if (isShs != null) {
          final matched = activeList.where((s) => isShs ? s.isShs : s.isCollege).toList();
          if (matched.isNotEmpty) return matched.first;
          return activeList.first.forCohort(isShs: isShs);
        }
        return activeList.first;
      }

      // Fallback to first non-archived document if available
      final nonArchived = snap.docs.where((d) => d.data()['archived'] != true).toList();
      if (nonArchived.isNotEmpty) {
        final fallback = SemesterModel.fromFirestore(nonArchived.first);
        return isShs != null ? fallback.forCohort(isShs: isShs) : fallback;
      }
      final fallbackFirst = SemesterModel.fromFirestore(snap.docs.first);
      return isShs != null ? fallbackFirst.forCohort(isShs: isShs) : fallbackFirst;
    }).handleError((_) => null);
  }

  /// Fetches the currently active semester once for a specific academic level.
  Future<SemesterModel?> getActiveSemester({bool? isShs}) async {
    try {
      final snap = await _firestore.collection(FirestorePaths.semesters).get();
      if (snap.docs.isEmpty) return null;

      final activeList = <SemesterModel>[];
      for (var doc in snap.docs) {
        final data = doc.data();
        if (data['archived'] == true) continue;
        final status = (data['status'] as String?)?.toUpperCase() ?? '';
        final isActive = data['isActive'] == true ||
            data['isCurrent'] == true ||
            data['is_active'] == true;
        if (status == 'ACTIVE' || isActive) {
          activeList.add(SemesterModel.fromFirestore(doc));
        }
      }

      if (activeList.isNotEmpty) {
        if (isShs != null) {
          final matched = activeList.where((s) => isShs ? s.isShs : s.isCollege).toList();
          if (matched.isNotEmpty) return matched.first;
          return activeList.first.forCohort(isShs: isShs);
        }
        return activeList.first;
      }

      final nonArchived = snap.docs.where((d) => d.data()['archived'] != true).toList();
      if (nonArchived.isNotEmpty) {
        final fallback = SemesterModel.fromFirestore(nonArchived.first);
        return isShs != null ? fallback.forCohort(isShs: isShs) : fallback;
      }
      final fallbackFirst = SemesterModel.fromFirestore(snap.docs.first);
      return isShs != null ? fallbackFirst.forCohort(isShs: isShs) : fallbackFirst;
    } catch (_) {
      return null;
    }
  }

  /// Fetches sections for a specific course ID or Course Code.
  Future<List<Map<String, dynamic>>> getSectionsForCourse(String courseIdOrCode) async {
    final List<Map<String, dynamic>> results = [];

    // 1. Try subcollection under courses/{courseId}/sections
    try {
      final subSnap = await _firestore
          .collection(FirestorePaths.courses)
          .doc(courseIdOrCode)
          .collection(FirestorePaths.sections)
          .get();
      if (subSnap.docs.isNotEmpty) {
        return subSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (_) {}

    // 2. Try top-level /sections where courseId == courseIdOrCode
    try {
      final snapId = await _firestore
          .collection(FirestorePaths.sections)
          .where('courseId', isEqualTo: courseIdOrCode)
          .get();
      if (snapId.docs.isNotEmpty) {
        return snapId.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (_) {}

    // 3. Fallback to /sections where courseCode == courseIdOrCode
    try {
      final snapCode = await _firestore
          .collection(FirestorePaths.sections)
          .where('courseCode', isEqualTo: courseIdOrCode)
          .get();
      if (snapCode.docs.isNotEmpty) {
        return snapCode.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
      }
    } catch (_) {}

    // 4. Fallback to all sections if none matched
    try {
      final allSnap = await _firestore.collection(FirestorePaths.sections).get();
      return allSnap.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (_) {}

    return results;
  }

  /// Confirms in-app re-enrollment by updating the student's profile.
  Future<void> confirmReEnrollment({
    required String studentUid,
    required String academicYear,
    required String semester,
    required String yearLevel,
    required String section,
  }) async {
    final updates = <String, dynamic>{
      'schoolYear': academicYear,
      'semester': semester,
      'yearLevel': yearLevel,
      'section': section,
      'status': 'ACTIVE',
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await _firestore
        .collection(FirestorePaths.students)
        .doc(studentUid)
        .update(updates);
  }
}
