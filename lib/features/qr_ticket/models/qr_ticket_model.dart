import 'dart:convert';
import 'package:sti_sync/features/auth/models/student_model.dart';

class QrTicketModel {
  final String eventId;
  final String studentId;
  final String studentAuthUid;
  final String studentName;
  final String eventTitle;
  final String profilePhotoUrl;
  final String courseInfo;
  final DateTime generatedAt;

  const QrTicketModel({
    required this.eventId,
    required this.studentId,
    required this.studentAuthUid,
    required this.studentName,
    required this.eventTitle,
    required this.profilePhotoUrl,
    required this.courseInfo,
    required this.generatedAt,
  });

  /// Generates the JSON payload to be encoded in the QR code.
  /// Per agent.md section 13: { eventId, studentId, studentAuthUid, generatedAt }
  String toQrPayload() {
    return json.encode({
      'eventId': eventId,
      'studentId': studentId,
      'studentAuthUid': studentAuthUid,
      'generatedAt': generatedAt.toIso8601String(),
    });
  }

  /// Constructs a QrTicketModel from a Firestore payable document and student document.
  factory QrTicketModel.fromPayable(
    Map<String, dynamic> payableData,
    StudentModel student,
    String eventTitle,
  ) {
    return QrTicketModel(
      eventId: payableData['eventId'] as String? ?? '',
      studentId: student.studentId,
      studentAuthUid: student.id,
      studentName: '${student.firstName} ${student.lastName}'.trim(),
      eventTitle: eventTitle,
      profilePhotoUrl: student.profilePhotoUrl,
      courseInfo: [
        student.courseCode.isNotEmpty ? student.courseCode : student.courseId,
        student.yearLevel,
        student.section
      ].where((e) => e.isNotEmpty).join(' - '),
      generatedAt: DateTime.now(),
    );
  }

  /// Constructs a QrTicketModel for a free event (no payable document).
  factory QrTicketModel.forFreeEvent({
    required String eventId,
    required String eventTitle,
    required StudentModel student,
  }) {
    return QrTicketModel(
      eventId: eventId,
      studentId: student.studentId,
      studentAuthUid: student.id,
      studentName: '${student.firstName} ${student.lastName}'.trim(),
      eventTitle: eventTitle,
      profilePhotoUrl: student.profilePhotoUrl,
      courseInfo: [
        student.courseCode.isNotEmpty ? student.courseCode : student.courseId,
        student.yearLevel,
        student.section
      ].where((e) => e.isNotEmpty).join(' - '),
      generatedAt: DateTime.now(),
    );
  }
}
