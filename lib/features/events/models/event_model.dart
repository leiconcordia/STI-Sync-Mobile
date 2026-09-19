import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../auth/models/student_model.dart';
import '../../../core/utils/date_formatter.dart';

enum MobileEventDisplayStatus {
  upcoming,
  ongoing,
  completed,
  cancelled,
}

class EventModel {
  final String id;
  final String referenceId;
  final String title;
  final String? tagline;
  final String description;
  final List<String> objectives;
  final String? bannerImageUrl;
  final String? thumbnailUrl;

  final bool isVisible;
  final DateTime? visibilityStart;

  final String eventTypeId;
  final String? customEventTypeName;
  final String? customEventTypeColor;
  final String eventCategoryId;
  final String? customEventCategoryName;
  final String hostingOrgId;

  final String semesterId;
  final String schoolYear;
  final String? targetAcademicLevel;

  final List<EventSessionModel> sessions;
  final String venueId;
  final String? customVenueName;
  final String eventFormat;

  final String targetAudienceScope;
  final List<String> targetCourses;
  final List<String> targetYearLevels;
  final List<String> targetSections;
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

  /// The student-facing event fee. This amount is copied to a payable's
  /// amountDue when the event requires payment.
  final double? adminFeeOverride;
  final double? totalExpectedCollection;

  /// Approved event budget supplied by the web event-creation flow.
  final List<BudgetItemModel> budgetItems;
  final double totalApprovedBudget;

  final bool enableQRTickets;
  final bool mandatoryAttendance;
  final bool lockAfterApproval;
  final String scannerActivationCode;
  final List<String> scannerUserIds;

  // ─── Lifecycle & Cancellation ───
  final String status;
  final String proposalStatus;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancelledByName;
  final String? cancellationReason;
  final String? refundPolicy; // 'refund_cash' | 'credit_next_event' | 'no_fees_collected'

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
    this.isVisible = true,
    this.visibilityStart,
    required this.eventTypeId,
    this.customEventTypeName,
    this.customEventTypeColor,
    required this.eventCategoryId,
    this.customEventCategoryName,
    required this.hostingOrgId,
    required this.semesterId,
    required this.schoolYear,
    this.targetAcademicLevel,
    required this.sessions,
    required this.venueId,
    this.customVenueName,
    required this.eventFormat,
    this.targetAudienceScope = 'all',
    this.targetCourses = const [],
    required this.targetYearLevels,
    this.targetSections = const [],
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
    required this.budgetItems,
    required this.totalApprovedBudget,
    required this.enableQRTickets,
    required this.mandatoryAttendance,
    required this.lockAfterApproval,
    required this.scannerActivationCode,
    required this.scannerUserIds,
    this.status = 'approved',
    required this.proposalStatus,
    this.isCancelled = false,
    this.cancelledAt,
    this.cancelledBy,
    this.cancelledByName,
    this.cancellationReason,
    this.refundPolicy,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the event has been officially cancelled (evaluates isCancelled, status, proposalStatus, and cancellationReason).
  bool get isEffectivelyCancelled =>
      isCancelled ||
      status.toLowerCase().contains('cancel') ||
      status.toLowerCase().contains('void') ||
      proposalStatus.toLowerCase().contains('cancel') ||
      proposalStatus.toLowerCase().contains('void') ||
      proposalStatus.toLowerCase().contains('reject') ||
      proposalStatus.toLowerCase().contains('disapprove') ||
      (cancellationReason != null && cancellationReason!.trim().isNotEmpty);

  /// Primary 5-state lifecycle resolution per specification Section 2.1
  MobileEventDisplayStatus get mobileStatus {
    if (isEffectivelyCancelled) {
      return MobileEventDisplayStatus.cancelled;
    }
    if (status.toLowerCase() == 'completed' || proposalStatus.toLowerCase() == 'completed') {
      return MobileEventDisplayStatus.completed;
    }
    if (sessions.isEmpty) return MobileEventDisplayStatus.upcoming;

    final now = DateTime.now();
    bool hasOngoing = false;
    bool allCompleted = true;

    for (final session in sessions) {
      if (session.date.trim().isEmpty) continue;
      final sessionDay = DateTime.tryParse(session.date.trim());
      if (sessionDay == null) continue;

      final startParts = (session.startTime.trim().isNotEmpty ? session.startTime.trim() : '00:00').split(':');
      final endParts = (session.endTime.trim().isNotEmpty ? session.endTime.trim() : '23:59').split(':');
      final startH = int.tryParse(startParts[0]) ?? 0;
      final startM = startParts.length > 1 ? (int.tryParse(startParts[1]) ?? 0) : 0;
      final endH = int.tryParse(endParts[0]) ?? 23;
      final endM = endParts.length > 1 ? (int.tryParse(endParts[1]) ?? 59) : 59;

      final start = DateTime(sessionDay.year, sessionDay.month, sessionDay.day, startH, startM);
      final end = DateTime(sessionDay.year, sessionDay.month, sessionDay.day, endH, endM, 59);

      if ((now.isAfter(start) && now.isBefore(end)) || now.isAtSameMomentAs(start) || now.isAtSameMomentAs(end)) {
        hasOngoing = true;
        allCompleted = false;
        break;
      }
      if (now.isBefore(start)) {
        allCompleted = false;
      }
    }

    if (hasOngoing) return MobileEventDisplayStatus.ongoing;
    if (allCompleted) return MobileEventDisplayStatus.completed;
    return MobileEventDisplayStatus.upcoming;
  }

  /// Checks if the event is set to visible and has reached its scheduled visibility start date/time.
  bool isVisibleNow([DateTime? now]) {
    if (!isVisible) return false;
    if (visibilityStart == null) return true;
    final current = now ?? DateTime.now();
    return current.isAfter(visibilityStart!) || current.isAtSameMomentAs(visibilityStart!);
  }

  /// Determines if a given [StudentModel] matches all target audience criteria for this event.
  bool isStudentEligible(StudentModel? student, {List<String> studentOrgIds = const []}) {
    if (student == null) return false;

    // 1. Check Proposal Status & Cancellation (must be approved, or cancelled if previously approved)
    final pStatus = proposalStatus.toLowerCase();
    final sStatus = status.toLowerCase();
    final isValidLifecycle = pStatus == 'approved' ||
        pStatus == 'cancelled' ||
        sStatus == 'cancelled' ||
        isCancelled;
    if (proposalStatus.isNotEmpty && !isValidLifecycle) {
      return false;
    }

    // 2. Audience Scope & Club Membership
    if (targetAudienceScope == 'members') {
      if (hostingOrgId.isNotEmpty && !studentOrgIds.contains(hostingOrgId)) {
        return false;
      }
    }

    // 3. Academic Level (SHS vs COLLEGE vs BOTH)
    if (targetAcademicLevel != null &&
        targetAcademicLevel!.isNotEmpty &&
        targetAcademicLevel!.toUpperCase() != 'BOTH') {
      final isShs = _isShsCohort(student);
      if (targetAcademicLevel!.toUpperCase() == 'SHS' && !isShs) {
        return false;
      }
      if (targetAcademicLevel!.toUpperCase() == 'COLLEGE' && isShs) {
        return false;
      }
    }

    // 4. Target Courses / Allowed Courses
    if (targetCourses.isNotEmpty) {
      final sCourseId = student.courseId.trim().toLowerCase();
      final sCourseCode = student.courseCode.trim().toLowerCase();
      final sCourseName = student.courseName.trim().toLowerCase();

      final matchesCourse = targetCourses.any((target) {
        final t = target.trim().toLowerCase();
        return t == sCourseId || t == sCourseCode || t == sCourseName;
      });

      if (!matchesCourse) return false;
    }

    // 5. Target Year Levels
    if (targetYearLevels.isNotEmpty) {
      final sYear = student.yearLevel.trim().toLowerCase();
      final sYearDigits = sYear.replaceAll(RegExp(r'[^0-9]'), '');

      final matchesYear = targetYearLevels.any((target) {
        final t = target.trim().toLowerCase();
        if (t == sYear) return true;
        final tDigits = t.replaceAll(RegExp(r'[^0-9]'), '');
        return sYearDigits.isNotEmpty && sYearDigits == tDigits;
      });

      if (!matchesYear) return false;
    }

    // 6. Target Sections
    if (targetSections.isNotEmpty) {
      final sSection = student.section.trim().toLowerCase();
      final matchesSection = targetSections.any((target) {
        final t = target.trim().toLowerCase();
        return t == sSection;
      });

      if (!matchesSection) return false;
    }

    // 7. Target Departments
    if (targetDepartmentIds.isNotEmpty) {
      final sDeptId = student.departmentId.trim().toLowerCase();
      final sDeptName = student.departmentName.trim().toLowerCase();

      final matchesDept = targetDepartmentIds.any((target) {
        final t = target.trim().toLowerCase();
        return t == sDeptId || t == sDeptName;
      });

      if (!matchesDept) return false;
    }

    return true;
  }

  static bool _isShsCohort(StudentModel student) {
    final y = student.yearLevel.toUpperCase();
    final d = student.departmentId.toUpperCase();
    final c = student.courseCode.toUpperCase();
    final n = student.courseName.toUpperCase();
    return y.contains('G11') ||
        y.contains('G12') ||
        y.contains('GRADE 11') ||
        y.contains('GRADE 12') ||
        y == '11' ||
        y == '12' ||
        d.contains('SHS') ||
        c.contains('SHS') ||
        c.contains('STEM') ||
        c.contains('ABM') ||
        c.contains('HUMSS') ||
        c.contains('TVL') ||
        c.contains('GAS') ||
        n.contains('SENIOR HIGH');
  }

  /// True if this event is hosted by STI Administration / Student Affairs Office (SAO)
  /// or does not belong to a specific student club / organization.
  bool get isCampusWide {
    final org = hostingOrgId.trim().toLowerCase();
    return org.isEmpty ||
        org == 'sas' ||
        org == 'sao' ||
        org == 'sas_admin' ||
        org == 'sao_admin' ||
        org == 'admin' ||
        org == 'sti' ||
        org == 'sti_college';
  }

  /// True if this event is hosted by a student club or organization.
  bool get isOrgEvent => !isCampusWide;

  /// Default display label for the organizer.
  String get organizerDisplayName =>
      isCampusWide ? 'STI College / SAO' : 'Student Organization';

  /// Returns the earliest session start date & time for sorting, or falls back to createdAt.
  DateTime get startDateTime {
    if (sessions.isNotEmpty) {
      DateTime? earliest;
      for (final session in sessions) {
        if (session.date.trim().isNotEmpty) {
          final time = session.startTime.trim().isNotEmpty ? session.startTime.trim() : '00:00';
          final dt = DateTime.tryParse('${session.date} $time:00') ??
              DateTime.tryParse(session.date);
          if (dt != null) {
            if (earliest == null || dt.isBefore(earliest)) {
              earliest = dt;
            }
          }
        }
      }
      if (earliest != null) return earliest;
    }
    return createdAt;
  }

  /// Formatted date string for the event display e.g. "Aug, 9 2026"
  String get displayDate {
    if (sessions.isNotEmpty && sessions.first.date.trim().isNotEmpty) {
      return formatAppDate(sessions.first.date, fallback: sessions.first.date);
    }
    return formatAppDate(createdAt, fallback: 'No schedule yet');
  }

  /// Returns true if this event will occur today or in the future (filters out past events).
  bool isUpcomingOrOngoing([DateTime? now]) {
    final current = now ?? DateTime.now();
    final startOfToday = DateTime(current.year, current.month, current.day);

    if (sessions.isNotEmpty) {
      for (final session in sessions) {
        if (session.date.trim().isNotEmpty) {
          final parsedDate = DateTime.tryParse(session.date.trim());
          if (parsedDate != null) {
            final sessionDay = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            // If the session is today or in the future
            if (!sessionDay.isBefore(startOfToday)) {
              return true;
            }
          }
        }
      }
      // All sessions are strictly before today (past event)
      return false;
    }

    return true;
  }

  /// Returns true if this event is in the past (completed before today).
  bool isPast([DateTime? now]) => !isUpcomingOrOngoing(now);

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromMap(doc.id, data);
  }

  factory EventModel.fromMap(String docId, Map<String, dynamic> data) {
    final bool rawVisible = (data['isVisible'] ?? data['visibleToStudents']) as bool? ?? true;

    DateTime? parsedVisibilityStart;
    final rawVisStart = data['visibilityStart'];
    if (rawVisStart is Timestamp) {
      parsedVisibilityStart = rawVisStart.toDate();
    } else if (rawVisStart is String && rawVisStart.trim().isNotEmpty) {
      parsedVisibilityStart = DateTime.tryParse(rawVisStart.trim());
    }

    return EventModel(
      id: docId,
      referenceId: data['referenceId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      tagline: data['tagline'] as String?,
      description: data['description'] as String? ?? '',
      objectives: List<String>.from(data['objectives'] ?? []),
      bannerImageUrl: data['bannerImageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      isVisible: rawVisible,
      visibilityStart: parsedVisibilityStart,
      eventTypeId: data['eventTypeId'] as String? ?? '',
      customEventTypeName: data['customEventTypeName'] as String?,
      customEventTypeColor: data['customEventTypeColor'] as String?,
      eventCategoryId: data['eventCategoryId'] as String? ?? '',
      customEventCategoryName: data['customEventCategoryName'] as String?,
      hostingOrgId: data['hostingOrgId'] as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      schoolYear: data['schoolYear'] as String? ?? '',
      targetAcademicLevel: data['targetAcademicLevel'] as String?,
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((s) => EventSessionModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      venueId: data['venueId'] as String? ?? '',
      customVenueName: data['customVenueName'] as String?,
      eventFormat: data['eventFormat'] as String? ?? '',
      targetAudienceScope: data['targetAudienceScope'] as String? ?? 'all',
      targetCourses: List<String>.from(data['targetCourses'] ?? data['allowedCourses'] ?? []),
      targetYearLevels: List<String>.from(data['targetYearLevels'] ?? []),
      targetSections: List<String>.from(data['targetSections'] ?? []),
      targetDepartmentIds: List<String>.from(data['targetDepartmentIds'] ?? []),
      expectedParticipantCount: data['expectedParticipantCount'] as int? ?? 0,
      attendanceEnabled: data['attendanceEnabled'] as bool? ?? true,
      minAttendancePercent: (data['minAttendancePercent'] as num?)?.toDouble(),
      lateThresholdMinutes: data['lateThresholdMinutes'] as int?,
      gracePeriodMinutes: data['gracePeriodMinutes'] as int?,
      latePenaltyAmount: (data['latePenaltyAmount'] as num?)?.toDouble(),
      certificatesEnabled: data['certificatesEnabled'] as bool? ?? false,
      autoIssueCertificates: data['autoIssueCertificates'] as bool? ?? false,
      certificateSignatory: data['certificateSignatory'] as String?,
      studentPayablesEnabled: data['studentPayablesEnabled'] as bool? ?? false,
      suggestedFeePerStudent:
          (data['suggestedFeePerStudent'] as num?)?.toDouble(),
      adminFeeOverride: (data['adminFeeOverride'] as num?)?.toDouble(),
      totalExpectedCollection:
          (data['totalExpectedCollection'] as num?)?.toDouble(),
      budgetItems: (data['budgetItems'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(BudgetItemModel.fromMap)
              .toList() ??
          const [],
      totalApprovedBudget:
          (data['totalApprovedBudget'] as num?)?.toDouble() ?? 0,
      enableQRTickets: data['enableQRTickets'] as bool? ?? true,
      mandatoryAttendance: data['mandatoryAttendance'] as bool? ?? false,
      lockAfterApproval: data['lockAfterApproval'] as bool? ?? false,
      scannerActivationCode: data['scannerActivationCode'] as String? ?? '',

      scannerUserIds: List<String>.from(data['scannerUserIds'] ?? []),
      status: (data['status'] as String? ?? data['eventStatus'] as String? ?? data['event_status'] as String?) ??
          ((data['isCancelled'] == true ||
                  data['is_cancelled'] == true ||
                  data['isCanceled'] == true ||
                  data['is_canceled'] == true ||
                  (data['proposalStatus'] as String?)?.toLowerCase().contains('cancel') == true ||
                  (data['proposal_status'] as String?)?.toLowerCase().contains('cancel') == true)
              ? 'cancelled'
              : 'approved'),
      proposalStatus: (data['proposalStatus'] ?? data['proposal_status'] ?? data['approvalStatus'] ?? data['approval_status']) as String? ?? '',
      isCancelled: () {
        final rawIsCancelled = data['isCancelled'] == true ||
            data['isCancelled'] == 'true' ||
            data['isCancelled'] == 1 ||
            data['is_cancelled'] == true ||
            data['is_cancelled'] == 'true' ||
            data['is_cancelled'] == 1 ||
            data['isCanceled'] == true ||
            data['isCanceled'] == 'true' ||
            data['isCanceled'] == 1 ||
            data['is_canceled'] == true ||
            data['is_canceled'] == 'true' ||
            data['is_canceled'] == 1 ||
            data['cancelled'] == true ||
            data['canceled'] == true;

        final s = (data['status'] as String? ?? data['eventStatus'] as String? ?? data['event_status'] as String?)?.toLowerCase() ?? '';
        final ps = (data['proposalStatus'] as String? ?? data['proposal_status'] as String? ?? data['approvalStatus'] as String? ?? data['approval_status'] as String?)?.toLowerCase() ?? '';
        final ls = (data['lifecycleStatus'] as String? ?? data['lifecycle_status'] as String?)?.toLowerCase() ?? '';
        final st = (data['state'] as String? ?? data['eventState'] as String? ?? data['event_state'] as String?)?.toLowerCase() ?? '';

        final hasDate = data['cancelledAt'] != null || data['cancelled_at'] != null || data['canceledAt'] != null || data['canceled_at'] != null;
        final reason = (data['cancellationReason'] ?? data['cancellation_reason'] ?? data['canceledReason'] ?? data['canceled_reason'] ?? data['reason']) as String?;
        final hasReason = reason != null && reason.trim().isNotEmpty;

        return rawIsCancelled ||
            s.contains('cancel') ||
            s.contains('void') ||
            ps.contains('cancel') ||
            ps.contains('void') ||
            ps.contains('reject') ||
            ps.contains('disapprove') ||
            ls.contains('cancel') ||
            ls.contains('void') ||
            st.contains('cancel') ||
            st.contains('void') ||
            hasDate ||
            hasReason;
      }(),
      cancelledAt: () {
        final raw = data['cancelledAt'] ?? data['cancelled_at'] ?? data['canceledAt'] ?? data['canceled_at'];
        if (raw is Timestamp) return raw.toDate();
        if (raw is String && raw.trim().isNotEmpty) return DateTime.tryParse(raw.trim());
        if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
        return null;
      }(),
      cancelledBy: (data['cancelledBy'] ?? data['cancelled_by'] ?? data['canceledBy'] ?? data['canceled_by']) as String?,
      cancelledByName: (data['cancelledByName'] ?? data['cancelled_by_name'] ?? data['canceledByName'] ?? data['canceled_by_name']) as String?,
      cancellationReason: (data['cancellationReason'] ?? data['cancellation_reason'] ?? data['canceledReason'] ?? data['canceled_reason'] ?? data['reason']) as String?,
      refundPolicy: data['refundPolicy'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['createdAt'] is String
              ? DateTime.tryParse(data['createdAt']) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['updatedAt'] is String
              ? DateTime.tryParse(data['updatedAt']) ?? DateTime.now()
              : DateTime.now()),
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
      'isVisible': isVisible,
      'visibleToStudents': isVisible,
      'visibilityStart': visibilityStart != null ? Timestamp.fromDate(visibilityStart!) : null,
      'eventTypeId': eventTypeId,
      'customEventTypeName': customEventTypeName,
      'customEventTypeColor': customEventTypeColor,
      'eventCategoryId': eventCategoryId,
      'customEventCategoryName': customEventCategoryName,
      'hostingOrgId': hostingOrgId,
      'semesterId': semesterId,
      'schoolYear': schoolYear,
      'targetAcademicLevel': targetAcademicLevel,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'venueId': venueId,
      'customVenueName': customVenueName,
      'eventFormat': eventFormat,
      'targetAudienceScope': targetAudienceScope,
      'targetCourses': targetCourses,
      'targetYearLevels': targetYearLevels,
      'targetSections': targetSections,
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
      'budgetItems': budgetItems.map((item) => item.toMap()).toList(),
      'totalApprovedBudget': totalApprovedBudget,
      'enableQRTickets': enableQRTickets,
      'mandatoryAttendance': mandatoryAttendance,
      'lockAfterApproval': lockAfterApproval,
      'scannerActivationCode': scannerActivationCode,
      'scannerUserIds': scannerUserIds,
      'status': status,
      'proposalStatus': proposalStatus,
      'isCancelled': isCancelled,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'cancelledBy': cancelledBy,
      'cancelledByName': cancelledByName,
      'cancellationReason': cancellationReason,
      'refundPolicy': refundPolicy,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  String toJson() {
    final map = toMap();
    map['createdAt'] = createdAt.toIso8601String();
    map['updatedAt'] = updatedAt.toIso8601String();
    map['visibilityStart'] = visibilityStart?.toIso8601String();
    if (cancelledAt != null) {
      map['cancelledAt'] = cancelledAt!.toIso8601String();
    }
    return json.encode(map);
  }
}

class BudgetItemModel {
  final String id;
  final String item;
  final String description;
  final double quantity;
  final double unitCost;
  final double approvedAmount;
  final String status;

  const BudgetItemModel({
    required this.id,
    required this.item,
    required this.description,
    required this.quantity,
    required this.unitCost,
    required this.approvedAmount,
    required this.status,
  });

  factory BudgetItemModel.fromMap(Map<String, dynamic> map) {
    return BudgetItemModel(
      id: map['id'] as String? ?? '',
      item: map['item'] as String? ?? '',
      description: map['description'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unitCost: (map['unitCost'] as num?)?.toDouble() ?? 0,
      approvedAmount: (map['approvedAmount'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'item': item,
        'description': description,
        'quantity': quantity,
        'unitCost': unitCost,
        'approvedAmount': approvedAmount,
        'status': status,
      };
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
