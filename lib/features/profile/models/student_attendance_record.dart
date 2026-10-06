import 'package:cloud_firestore/cloud_firestore.dart';

class StudentAttendanceRecord {
  final String id;
  final String eventId;
  final String? eventTitle;
  final String? sessionId;
  final String? sessionTitle;
  final String gateType; // 'Time-In' or 'Time-Out'
  final String status;   // 'Present', 'Late'
  final DateTime scannedAt;
  final String? schoolYear;
  final String? semester;
  final String? semesterId;

  const StudentAttendanceRecord({
    required this.id,
    required this.eventId,
    this.eventTitle,
    this.sessionId,
    this.sessionTitle,
    required this.gateType,
    required this.status,
    required this.scannedAt,
    this.schoolYear,
    this.semester,
    this.semesterId,
  });

  factory StudentAttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    final rawGate = (data['gateType'] ?? data['type'] ?? 'Time-In').toString().toLowerCase();
    final normalizedGate = rawGate.contains('out') ? 'Time-Out' : 'Time-In';

    return StudentAttendanceRecord(
      id: doc.id,
      eventId: (data['eventId'] ?? '') as String,
      eventTitle: (data['eventTitle'] ?? data['title']) as String?,
      sessionId: data['sessionId'] as String?,
      sessionTitle: (data['sessionTitle'] ?? data['sessionName']) as String?,
      gateType: normalizedGate,
      status: (data['status'] ?? 'Present') as String,
      scannedAt: parseDate(data['scannedAt'] ?? data['createdAt'] ?? data['timestamp']),
      schoolYear: (data['schoolYear'] ?? data['academicYear']) as String?,
      semester: data['semester'] as String?,
      semesterId: data['semesterId'] as String?,
    );
  }
}
