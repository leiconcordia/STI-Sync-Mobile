import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import 'package:sti_sync/features/announcements/models/announcement_model.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';

class AnnouncementsRepository {
  final FirebaseFirestore _firestore;

  AnnouncementsRepository(this._firestore);

  /// Streams real-time announcements from Firestore and filters items relevant to the logged-in student.
  Stream<List<AnnouncementModel>> watchTargetedAnnouncements({
    required StudentModel? student,
    List<String> studentOrgIds = const [],
  }) {
    return _firestore
        .collection(FirestorePaths.announcements)
        .snapshots()
        .map((snapshot) {
      final allAnnouncements = snapshot.docs
          .map((doc) => AnnouncementModel.fromFirestore(doc.data(), doc.id))
          .toList();

      // If no student logged in, return campus-wide items only
      if (student == null) {
        return allAnnouncements
            .where((a) => a.audience == 'campus-wide' || a.audience == 'all-organizations')
            .toList();
      }

      final studentDeptId = student.departmentId.trim().toLowerCase();
      final studentDeptName = student.departmentName.trim().toLowerCase();
      final studentCourseCode = student.courseCode.trim().toLowerCase();
      final studentCourseName = student.courseName.trim().toLowerCase();
      final studentYearStr = student.yearLevel.trim().toLowerCase();

      final filtered = allAnnouncements.where((a) {
        // 0. Author check (author always sees their own announcement)
        if (a.authorUid.isNotEmpty &&
            (a.authorUid == student.id ||
             a.authorUid == student.authUid ||
             a.authorUid == student.studentId)) {
          return true;
        }

        // 1. Campus-wide or all-orgs broadcast
        if (a.audience == 'campus-wide' || a.audience == 'all-organizations') {
          return true;
        }

        // 2. Target Orgs check
        if (a.targetOrgIds.isNotEmpty) {
          final matchesOrg = studentOrgIds.any((orgId) => a.targetOrgIds.contains(orgId));
          if (matchesOrg) return true;
        }

        // 3. Authoring Org check (officer's own org)
        if (a.organizationId != null && 
            a.organizationId!.isNotEmpty && 
            studentOrgIds.contains(a.organizationId)) {
          return true;
        }

        // 4. Target Departments check (handles both Department Names and Course Codes like BSIT)
        if (a.targetDepartments.isNotEmpty) {
          final matchesDept = a.targetDepartments.any((dept) {
            final d = dept.trim().toLowerCase();
            return d == studentDeptId ||
                d == studentDeptName ||
                (studentCourseCode.isNotEmpty &&
                    (d == studentCourseCode ||
                     studentCourseCode.contains(d) ||
                     d.contains(studentCourseCode))) ||
                (studentCourseName.isNotEmpty &&
                    (d == studentCourseName ||
                     studentCourseName.contains(d) ||
                     d.contains(studentCourseName)));
          });
          if (matchesDept) return true;
        }

        // 5. Target Year Levels check
        if (a.targetYearLevels.isNotEmpty) {
          final matchesYear = a.targetYearLevels.any((yr) {
            final y = yr.trim().toLowerCase();
            return y == studentYearStr || studentYearStr.contains(y) || y.contains(studentYearStr);
          });
          if (matchesYear) return true;
        }

        // If audience is targeted but student doesn't match specific criteria
        return false;
      }).toList();

      // Sort: pinned float to top, then by createdAt DESC
      filtered.sort((a, b) {
        if (a.pinned != b.pinned) {
          return a.pinned ? -1 : 1;
        }
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });

      return filtered;
    });
  }
}
