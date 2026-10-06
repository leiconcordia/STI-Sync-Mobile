import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an issued certificate record from Firestore (`/certificates_issued/{id}`).
/// Matches the schema written by the Web Portal when certificates are batch-issued.
class IssuedCertificateModel {
  final String id;
  final String eventId;
  final String eventTitle;
  final String templateId;
  final String templateName;
  final String recipientName;
  final String studentId;
  final String course;
  final DateTime issuedAt;
  final String issuedBy;

  const IssuedCertificateModel({
    required this.id,
    required this.eventId,
    required this.eventTitle,
    required this.templateId,
    required this.templateName,
    required this.recipientName,
    required this.studentId,
    required this.course,
    required this.issuedAt,
    required this.issuedBy,
  });

  factory IssuedCertificateModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return IssuedCertificateModel.fromMap(doc.id, data);
  }

  factory IssuedCertificateModel.fromMap(String docId, Map<String, dynamic> data) {
    DateTime parsedDate = DateTime.now();
    final rawIssuedAt = data['issuedAt'] ?? data['issueDate'] ?? data['createdAt'];
    if (rawIssuedAt is Timestamp) {
      parsedDate = rawIssuedAt.toDate();
    } else if (rawIssuedAt is String && rawIssuedAt.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawIssuedAt) ?? DateTime.now();
    }

    return IssuedCertificateModel(
      id: docId,
      eventId: (data['eventId'] as String?) ?? '',
      eventTitle: (data['eventTitle'] as String?) ?? (data['eventName'] as String?) ?? 'Event Certificate',
      templateId: (data['templateId'] as String?) ?? '',
      templateName: (data['templateName'] as String?) ?? 'Standard Certificate',
      recipientName: (data['recipientName'] as String?) ?? (data['studentName'] as String?) ?? '',
      studentId: (data['studentId'] as String?) ?? '',
      course: (data['course'] as String?) ?? '',
      issuedAt: parsedDate,
      issuedBy: (data['issuedBy'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'eventTitle': eventTitle,
      'templateId': templateId,
      'templateName': templateName,
      'recipientName': recipientName,
      'studentId': studentId,
      'course': course,
      'issuedAt': Timestamp.fromDate(issuedAt),
      'issuedBy': issuedBy,
    };
  }

  IssuedCertificateModel copyWith({
    String? id,
    String? eventId,
    String? eventTitle,
    String? templateId,
    String? templateName,
    String? recipientName,
    String? studentId,
    String? course,
    DateTime? issuedAt,
    String? issuedBy,
  }) {
    return IssuedCertificateModel(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      eventTitle: eventTitle ?? this.eventTitle,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      recipientName: recipientName ?? this.recipientName,
      studentId: studentId ?? this.studentId,
      course: course ?? this.course,
      issuedAt: issuedAt ?? this.issuedAt,
      issuedBy: issuedBy ?? this.issuedBy,
    );
  }
}
