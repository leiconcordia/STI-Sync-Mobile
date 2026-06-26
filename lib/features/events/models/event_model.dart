import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class EventModel {
  final String id;
  final String referenceId;
  final String title;
  final String? tagline;
  final String description;
  final List<String> objectives;
  final String? bannerImageUrl;
  final String? thumbnailUrl;

  final String eventTypeId;
  final String eventCategoryId;
  final String hostingOrgId;

  final String semesterId;
  final String schoolYear;

  final List<EventSessionModel> sessions;
  final String venueId;
  final String eventFormat;

  final List<String> targetYearLevels;
  final List<String> targetDepartmentIds;
  final int expectedParticipantCount;

  final bool attendanceEnabled;
  final double? minAttendancePercent;
  final int? lateThresholdMinutes;
  final int? gracePeriodMinutes;
  final double? latePenaltyAmount;

  final bool certificatesEnabled;
  final bool autoIssueCertificates;
  final String? certificateSignatory;

  final bool studentPayablesEnabled;
  final double? suggestedFeePerStudent;
  final double? adminFeeOverride;
  final double? totalExpectedCollection;

  final bool enableQRTickets;
  final bool mandatoryAttendance;
  final bool lockAfterApproval;
  final String scannerActivationCode;

  final String proposalStatus;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const EventModel({
    required this.id,
    required this.referenceId,
    required this.title,
    this.tagline,
    required this.description,
    required this.objectives,
    this.bannerImageUrl,
    this.thumbnailUrl,
    required this.eventTypeId,
    required this.eventCategoryId,
    required this.hostingOrgId,
    required this.semesterId,
    required this.schoolYear,
    required this.sessions,
    required this.venueId,
    required this.eventFormat,
    required this.targetYearLevels,
    required this.targetDepartmentIds,
    required this.expectedParticipantCount,
    required this.attendanceEnabled,
    this.minAttendancePercent,
    this.lateThresholdMinutes,
    this.gracePeriodMinutes,
    this.latePenaltyAmount,
    required this.certificatesEnabled,
    required this.autoIssueCertificates,
    this.certificateSignatory,
    required this.studentPayablesEnabled,
    this.suggestedFeePerStudent,
    this.adminFeeOverride,
    this.totalExpectedCollection,
    required this.enableQRTickets,
    required this.mandatoryAttendance,
    required this.lockAfterApproval,
    required this.scannerActivationCode,
    required this.proposalStatus,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromMap(doc.id, data);
  }

  factory EventModel.fromMap(String docId, Map<String, dynamic> data) {
    return EventModel(
      id: docId,
      referenceId: data['referenceId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      tagline: data['tagline'] as String?,
      description: data['description'] as String? ?? '',
      objectives: List<String>.from(data['objectives'] ?? []),
      bannerImageUrl: data['bannerImageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      eventTypeId: data['eventTypeId'] as String? ?? '',
      eventCategoryId: data['eventCategoryId'] as String? ?? '',
      hostingOrgId: data['hostingOrgId'] as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      schoolYear: data['schoolYear'] as String? ?? '',
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((s) => EventSessionModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      venueId: data['venueId'] as String? ?? '',
      eventFormat: data['eventFormat'] as String? ?? '',
      targetYearLevels: List<String>.from(data['targetYearLevels'] ?? []),
      targetDepartmentIds: List<String>.from(data['targetDepartmentIds'] ?? []),
      expectedParticipantCount: data['expectedParticipantCount'] as int? ?? 0,
      attendanceEnabled: data['attendanceEnabled'] as bool? ?? false,
      minAttendancePercent: (data['minAttendancePercent'] as num?)?.toDouble(),
      lateThresholdMinutes: data['lateThresholdMinutes'] as int?,
      gracePeriodMinutes: data['gracePeriodMinutes'] as int?,
      latePenaltyAmount: (data['latePenaltyAmount'] as num?)?.toDouble(),
      certificatesEnabled: data['certificatesEnabled'] as bool? ?? false,
      autoIssueCertificates: data['autoIssueCertificates'] as bool? ?? false,
      certificateSignatory: data['certificateSignatory'] as String?,
      studentPayablesEnabled: data['studentPayablesEnabled'] as bool? ?? false,
      suggestedFeePerStudent: (data['suggestedFeePerStudent'] as num?)?.toDouble(),
      adminFeeOverride: (data['adminFeeOverride'] as num?)?.toDouble(),
      totalExpectedCollection: (data['totalExpectedCollection'] as num?)?.toDouble(),
      enableQRTickets: data['enableQRTickets'] as bool? ?? false,
      mandatoryAttendance: data['mandatoryAttendance'] as bool? ?? false,
      lockAfterApproval: data['lockAfterApproval'] as bool? ?? false,
      scannerActivationCode: data['scannerActivationCode'] as String? ?? '',
      proposalStatus: data['proposalStatus'] as String? ?? '',
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'title': title,
      'tagline': tagline,
      'description': description,
      'objectives': objectives,
      'bannerImageUrl': bannerImageUrl,
      'thumbnailUrl': thumbnailUrl,
      'eventTypeId': eventTypeId,
      'eventCategoryId': eventCategoryId,
      'hostingOrgId': hostingOrgId,
      'semesterId': semesterId,
      'schoolYear': schoolYear,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'venueId': venueId,
      'eventFormat': eventFormat,
      'targetYearLevels': targetYearLevels,
      'targetDepartmentIds': targetDepartmentIds,
      'expectedParticipantCount': expectedParticipantCount,
      'attendanceEnabled': attendanceEnabled,
      'minAttendancePercent': minAttendancePercent,
      'lateThresholdMinutes': lateThresholdMinutes,
      'gracePeriodMinutes': gracePeriodMinutes,
      'latePenaltyAmount': latePenaltyAmount,
      'certificatesEnabled': certificatesEnabled,
      'autoIssueCertificates': autoIssueCertificates,
      'certificateSignatory': certificateSignatory,
      'studentPayablesEnabled': studentPayablesEnabled,
      'suggestedFeePerStudent': suggestedFeePerStudent,
      'adminFeeOverride': adminFeeOverride,
      'totalExpectedCollection': totalExpectedCollection,
      'enableQRTickets': enableQRTickets,
      'mandatoryAttendance': mandatoryAttendance,
      'lockAfterApproval': lockAfterApproval,
      'scannerActivationCode': scannerActivationCode,
      'proposalStatus': proposalStatus,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String toJson() => json.encode(toMap());
}

class EventSessionModel {
  final String id;
  final String title;
  final String date;
  final String startTime;
  final String endTime;
  final String timeInOpen;
  final String timeInClose;
  final bool hasTimeOut;
  final String? timeOutOpen;
  final String? timeOutClose;

  const EventSessionModel({
    required this.id,
    required this.title,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.timeInOpen,
    required this.timeInClose,
    required this.hasTimeOut,
    this.timeOutOpen,
    this.timeOutClose,
  });

  factory EventSessionModel.fromMap(Map<String, dynamic> map) {
    return EventSessionModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      date: map['date'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      timeInOpen: map['timeInOpen'] as String? ?? '',
      timeInClose: map['timeInClose'] as String? ?? '',
      hasTimeOut: map['hasTimeOut'] as bool? ?? false,
      timeOutOpen: map['timeOutOpen'] as String?,
      timeOutClose: map['timeOutClose'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'timeInOpen': timeInOpen,
      'timeInClose': timeInClose,
      'hasTimeOut': hasTimeOut,
      'timeOutOpen': timeOutOpen,
      'timeOutClose': timeOutClose,
    };
  }
}
