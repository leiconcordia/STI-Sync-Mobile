import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import '../models/semester_model.dart';

class SemesterRepository {
  final FirebaseFirestore _firestore;

  SemesterRepository(this._firestore);

  /// Streams the currently active academic semester from Firestore.
  Stream<SemesterModel?> watchActiveSemester() {
    return _firestore
        .collection(FirestorePaths.semesters)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;

      final activeDocs = snap.docs.where((doc) {
        final data = doc.data();
        final status = (data['status'] as String?)?.toUpperCase() ?? '';
        final isActive = data['isActive'] == true || data['isCurrent'] == true || data['is_active'] == true;
        return status == 'ACTIVE' || isActive;
      }).toList();

      if (activeDocs.isNotEmpty) {
        return SemesterModel.fromFirestore(activeDocs.first);
      }

      // Fallback to first document if available
      return SemesterModel.fromFirestore(snap.docs.first);
    }).handleError((_) => null);
  }

  /// Fetches the currently active semester once.
  Future<SemesterModel?> getActiveSemester() async {
    try {
      final snap = await _firestore.collection(FirestorePaths.semesters).get();
      if (snap.docs.isEmpty) return null;

      for (var doc in snap.docs) {
        final data = doc.data();
        final status = (data['status'] as String?)?.toUpperCase() ?? '';
        final isActive = data['isActive'] == true || data['isCurrent'] == true || data['is_active'] == true;
        if (status == 'ACTIVE' || isActive) {
          return SemesterModel.fromFirestore(doc);
        }
      }
      return SemesterModel.fromFirestore(snap.docs.first);
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
