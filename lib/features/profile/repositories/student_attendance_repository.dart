import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_attendance_record.dart';

class StudentAttendanceRepository {
  final FirebaseFirestore _firestore;

  StudentAttendanceRepository(this._firestore);

  /// Streams personal attendance history for a student.
  /// Checks both official student number and Firebase Auth UID.
  Stream<List<StudentAttendanceRecord>> streamStudentAttendance({
    required String studentId,
    String? authUid,
  }) {
    final validIds = <String>{};
    if (studentId.trim().isNotEmpty) {
      validIds.add(studentId.trim());
    }
    if (authUid != null && authUid.trim().isNotEmpty) {
      validIds.add(authUid.trim());
    }

    final idList = validIds.toList();
    if (idList.isEmpty) {
      return Stream.value([]);
    }

    // Try primary attendance_logs collection
    return _firestore
        .collection('attendance_logs')
        .where('studentId', whereIn: idList)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => StudentAttendanceRecord.fromFirestore(doc))
              .toList();
          list.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
          return list;
        })
        .handleError((error) {
          // If attendance_logs errors, fallback to empty list
          return <StudentAttendanceRecord>[];
        });
  }
}
