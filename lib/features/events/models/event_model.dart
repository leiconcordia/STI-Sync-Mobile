import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../auth/models/student_model.dart';
import '../../../core/utils/date_formatter.dart';

enum EventLifecycleState {
  draft,
  pending,
  approved,
  ongoing,
  completed,
  cancelled,
  archived,
  deleted,
}

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
  final List<String> mechanics;
  final List<String> organizers;
  final String? bannerImageUrl;
  final String? thumbnailUrl;

  final bool isVisible;
  final bool isPublished;
  final DateTime? visibilityStart;

  final String eventTypeId;
  final String? customEventTypeName;
  final String? customEventTypeColor;
  final String eventCategoryId;
  final String? customEventCategoryName;
  final String hostingOrgId;

  final String semesterId;
  final String schoolYear;
  final String? semester;
  final String? targetAcademicLevel;
  final String? date;
  final String? startTime;
  final String? endTime;
  final String? venueName;

  final List<EventSessionModel> sessions;
  final String venueId;
  final String? customVenueName;
  final String eventFormat;

  final bool allStudents;
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

  // ─── Lifecycle & Closing States ───
  final String status;
  final String proposalStatus;
  final bool isCancelled;
  final DateTime? cancelledAt;
  final String? cancelledBy;
  final String? cancelledByName;
  final String? cancellationReason;
  final String? refundPolicy; // 'refund_cash' | 'credit_next_event' | 'no_fees_collected'

  final bool isArchived;
  final bool isDeleted;
  final DateTime? completedAt;
  final String? completedBy;
  final DateTime? archivedAt;
  final String? archivedBy;
  final bool attendanceLocked;

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
    this.mechanics = const [],
    this.organizers = const [],
    this.bannerImageUrl,
    this.thumbnailUrl,
    this.isVisible = true,
    this.isPublished = false,
    this.visibilityStart,
    required this.eventTypeId,
    this.customEventTypeName,
    this.customEventTypeColor,
    required this.eventCategoryId,
    this.customEventCategoryName,
    required this.hostingOrgId,
    required this.semesterId,
    required this.schoolYear,
    this.semester,
    this.targetAcademicLevel,
    this.date,
    this.startTime,
    this.endTime,
    this.venueName,
    required this.sessions,
    required this.venueId,
    this.customVenueName,
    required this.eventFormat,
    this.allStudents = true,
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
    this.isArchived = false,
    this.isDeleted = false,
    this.completedAt,
    this.completedBy,
    this.archivedAt,
    this.archivedBy,
    this.attendanceLocked = false,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  /// True if the event has been officially completed
  bool get isCompleted =>
      status.toLowerCase() == 'completed' ||
      proposalStatus.toLowerCase() == 'completed' ||
      completedAt != null;

  /// Visual lifecycle state helper per Section 4.1
  EventLifecycleState get lifecycleState {
    if (isDeleted) return EventLifecycleState.deleted;
    if (isArchived) return EventLifecycleState.archived;
    if (isEffectivelyCancelled) return EventLifecycleState.cancelled;
    if (isCompleted) return EventLifecycleState.completed;
    if (status.toLowerCase() == 'ongoing' || mobileStatus == MobileEventDisplayStatus.ongoing) {
      return EventLifecycleState.ongoing;
    }
    if (status.toLowerCase() == 'approved' || proposalStatus.toLowerCase() == 'approved') {
      return EventLifecycleState.approved;
    }
    if (proposalStatus.toLowerCase() == 'pending') {
      return EventLifecycleState.pending;
    }
    return EventLifecycleState.draft;
  }

  /// Whether this event has attendance scanners assigned or an activation PIN configured.
  bool get hasScanners =>
      scannerUserIds.isNotEmpty ||
      (scannerActivationCode.trim().isNotEmpty &&
          scannerActivationCode.trim() != '0');

  /// Whether the event requires student attendance tracking and gate scanning.
  /// If the event does not require scanners (no scanners or PIN assigned),
  /// or if attendance/tickets are explicitly disabled, attendance scanning is not required.
  bool get requiresAttendance =>
      attendanceEnabled != false &&
      enableQRTickets != false &&
      hasScanners;

  /// Whether the student QR ticket is active for gate scanning per Section 4.1
  bool get isGatePassValid {
    if (isDeleted || isArchived || isCompleted || isEffectivelyCancelled || !requiresAttendance) {
      return false;
    }
    return true;
  }

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
    if (isCompleted) {
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
    if (isDeleted) return false;
    if (!isVisible) return false;
    if (visibilityStart == null) return true;
    final current = now ?? DateTime.now();
    return current.isAfter(visibilityStart!) || current.isAtSameMomentAs(visibilityStart!);
  }

  /// Determines if a given [StudentModel] matches the progressive hierarchical target audience criteria for this event.
  bool isStudentEligible(StudentModel? student, {List<String> studentOrgIds = const []}) {
    if (student == null) return false;

    // 0. Manual Publishing Check: Event must be published manually & visible
    if (!isPublished || !isVisible) {
      return false;
    }

    // 1. Check Proposal Status & Cancellation (must be approved, ongoing, completed, or cancelled)
    final pStatus = proposalStatus.toLowerCase();
    final sStatus = status.toLowerCase();
    final isValidLifecycle = pStatus == 'approved' ||
        pStatus == 'published' ||
        pStatus == 'cancelled' ||
        pStatus == 'completed' ||
        pStatus == 'ongoing' ||
        pStatus == 'activated' ||
        pStatus == 'approved_president' ||
        sStatus == 'approved' ||
        sStatus == 'published' ||
        sStatus == 'cancelled' ||
        sStatus == 'completed' ||
        sStatus == 'ongoing' ||
        sStatus == 'activated' ||
        isCancelled;
    if (!isValidLifecycle) {
      return false;
    }

    // 2. Audience Scope & Club Membership
    if (targetAudienceScope.toLowerCase() == 'members') {
      if (hostingOrgId.isNotEmpty && !studentOrgIds.contains(hostingOrgId)) {
        return false;
      }
    }

    // 3. Level 1: "ALL STUDENTS" Rule
    // If allStudents is true or scope is 'all' with no academic level restrictions,
    // and no specific year levels, courses, or sections are specified, then EVERYONE can view.
    final bool hasLevelRestriction = targetAcademicLevel != null &&
        targetAcademicLevel!.trim().isNotEmpty &&
        targetAcademicLevel!.toUpperCase() != 'BOTH' &&
        !(targetAcademicLevel!.toUpperCase().contains('SHS') && targetAcademicLevel!.toUpperCase().contains('COLLEGE'));

    final bool isAllStudentsExplicit = allStudents ||
        (targetAudienceScope.toLowerCase() == 'all' && !hasLevelRestriction);

    // If marked for All Students with no deeper restrictions, instantly eligible!
    if (isAllStudentsExplicit && targetYearLevels.isEmpty && targetCourses.isEmpty && targetSections.isEmpty) {
      return true;
    }

    // 4. Level 2: Academic Division (SHS vs COLLEGE)
    final isShs = _isShsCohort(student);
    if (hasLevelRestriction) {
      final lvl = targetAcademicLevel!.toUpperCase().trim();
      if (lvl == 'SHS' && !isShs) {
        return false;
      }
      if (lvl == 'COLLEGE' && isShs) {
        return false;
      }
    }

    // If only the Academic Level is constrained (e.g. SHS only, or College only),
    // and NO deeper year levels, courses/strands, or sections are restricted:
    // AUTOMATICALLY all students in that academic level qualify!
    if (targetYearLevels.isEmpty && targetCourses.isEmpty && targetSections.isEmpty) {
      return true;
    }

    // 5. Level 3: Target Year Levels (e.g. Grade 11, 1st Year)
    // If targetYearLevels is NOT empty, verify student's year matches.
    // If empty -> wild-card (all year levels in this academic level qualify).
    if (targetYearLevels.isNotEmpty) {
      final sYear = student.yearLevel.trim().toLowerCase();
      final sYearDigits = sYear.replaceAll(RegExp(r'[^0-9]'), '');

      final matchesYear = targetYearLevels.any((target) {
        final t = target.trim().toLowerCase();
        if (t == sYear) return true;

        final tDigits = t.replaceAll(RegExp(r'[^0-9]'), '');
        if (sYearDigits.isNotEmpty && tDigits.isNotEmpty && sYearDigits == tDigits) {
          return true;
        }

        // Match Grade 11 / G11 / 11
        if ((t.contains('11') || t.contains('g11')) && (sYear.contains('11') || sYear.contains('g11'))) {
          return true;
        }
        // Match Grade 12 / G12 / 12
        if ((t.contains('12') || t.contains('g12')) && (sYear.contains('12') || sYear.contains('g12'))) {
          return true;
        }
        // Match 1st Year / 1
        if (t.contains('1st') && (sYear.contains('1st') || sYear == '1')) return true;
        if (t.contains('2nd') && (sYear.contains('2nd') || sYear == '2')) return true;
        if (t.contains('3rd') && (sYear.contains('3rd') || sYear == '3')) return true;
        if (t.contains('4th') && (sYear.contains('4th') || sYear == '4')) return true;

        return false;
      });

      if (!matchesYear) return false;
    }

    // If year level matched (or was wildcard) and NO deeper courses/strands or sections are specified:
    // ALL students of that year level qualify!
    if (targetCourses.isEmpty && targetSections.isEmpty) {
      return true;
    }

    // 6. Level 4: Target Courses / Strands
    // If targetCourses is NOT empty, verify student's course matches.
    // If empty -> wild-card (all strands/courses qualify).
    if (targetCourses.isNotEmpty) {
      // Backward compatibility: If an event has a bloated array containing all known courses,
      // or if targetCourses includes 'all' / 'all students', treat as wildcard
      final bool isBroadCourseList = targetCourses.any((c) {
        final lower = c.trim().toLowerCase();
        return lower == 'all' || lower.contains('all students') || lower.contains('campus-wide');
      });

      if (!isBroadCourseList) {
        final sCourseId = student.courseId.trim().toLowerCase();
        final sCourseCode = student.courseCode.trim().toLowerCase();
        final sCourseName = student.courseName.trim().toLowerCase();

        final matchesCourse = targetCourses.any((target) {
          final t = target.trim().toLowerCase();
          return t == sCourseId ||
              t == sCourseCode ||
              t == sCourseName ||
              (sCourseCode.isNotEmpty && t.contains(sCourseCode)) ||
              (sCourseName.isNotEmpty && (t.contains(sCourseName) || sCourseName.contains(t)));
        });

        if (!matchesCourse) return false;
      }
    }

    // If course/strand matched (or was wildcard) and NO sections are specified:
    // ALL students of that strand qualify!
    if (targetSections.isEmpty) {
      return true;
    }

    // 7. Level 5: Target Sections (Optional finest filter)
    // If targetSections is NOT empty, verify student's section matches.
    // If empty -> wild-card (all sections qualify).
    if (targetSections.isNotEmpty) {
      final sSection = student.section.trim().toLowerCase();
      final sSectionClean = sSection.replaceAll(RegExp(r'[^a-z0-9]'), '');

      final matchesSection = targetSections.any((target) {
        final t = target.trim().toLowerCase();
        if (t == sSection) return true;
        final tClean = t.replaceAll(RegExp(r'[^a-z0-9]'), '');
        if (sSectionClean.isNotEmpty && tClean.isNotEmpty && sSectionClean == tClean) {
          return true;
        }
        return sSection.contains(t) || t.contains(sSection);
      });

      if (!matchesSection) return false;
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
    if (date != null && date!.trim().isNotEmpty) {
      final time = startTime != null && startTime!.trim().isNotEmpty ? startTime!.trim() : '00:00';
      final dt = DateTime.tryParse('$date $time:00') ?? DateTime.tryParse(date!);
      if (dt != null) return dt;
    }
    return createdAt;
  }

  /// Formatted date string for the event display e.g. "Aug, 9 2026"
  String get displayDate {
    if (sessions.isNotEmpty && sessions.first.date.trim().isNotEmpty) {
      return formatAppDate(sessions.first.date, fallback: sessions.first.date);
    }
    if (date != null && date!.trim().isNotEmpty) {
      return formatAppDate(date!, fallback: date!);
    }
    return formatAppDate(createdAt, fallback: 'No schedule yet');
  }

  /// Returns true if this event will occur today or in the future (filters out past events).
  bool isUpcomingOrOngoing([DateTime? now]) {
    if (isDeleted || isArchived || isCompleted || isEffectivelyCancelled) {
      return false;
    }
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
      return false;
    }

    // An approved published activity with no sessions scheduled yet is active/upcoming.
    // The proposal date is only an administrative reference date, not a concluded session.
    return true;
  }

  /// Returns true if this event is in the past (completed before today, or marked completed).
  bool isPast([DateTime? now]) {
    if (isDeleted) return false;
    if (isCompleted) return true;
    return !isUpcomingOrOngoing(now);
  }

  factory EventModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EventModel.fromMap(doc.id, data);
  }

  factory EventModel.fromMap(String docId, Map<String, dynamic> data) {
    final bool rawVisible = (data['isVisible'] ?? data['visibleToStudents']) as bool? ?? true;
    final bool rawPublished = data['isPublished'] == true ||
        data['is_published'] == true ||
        (data['status'] as String?)?.toLowerCase() == 'published' ||
        (data['lifecycleStatus'] as String?)?.toLowerCase() == 'published' ||
        (data['proposalStatus'] as String?)?.toLowerCase() == 'published' ||
        (data['status'] as String?)?.toLowerCase() == 'approved' ||
        (data['proposalStatus'] as String?)?.toLowerCase() == 'approved' ||
        (data['proposalStatus'] as String?)?.toLowerCase() == 'approved_president' ||
        (data['proposalStatus'] as String?)?.toLowerCase() == 'activated';

    DateTime? parsedVisibilityStart;
    final rawVisStart = data['visibilityStart'];
    if (rawVisStart is Timestamp) {
      parsedVisibilityStart = rawVisStart.toDate();
    } else if (rawVisStart is String && rawVisStart.trim().isNotEmpty) {
      parsedVisibilityStart = DateTime.tryParse(rawVisStart.trim());
    }

    DateTime? parseFlexibleDate(dynamic raw) {
      if (raw == null) return null;
      if (raw is Timestamp) return raw.toDate();
      if (raw is String && raw.trim().isNotEmpty) return DateTime.tryParse(raw.trim());
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return null;
    }

    final bool isArchived = data['isArchived'] == true || data['is_archived'] == true;
    final bool isDeleted = data['isDeleted'] == true || data['is_deleted'] == true;
    final String? statusRaw = data['status'] as String? ?? data['eventStatus'] as String? ?? data['event_status'] as String?;
    final bool attendanceLocked = data['attendanceLocked'] == true ||
        data['attendance_locked'] == true ||
        statusRaw?.toLowerCase() == 'completed' ||
        (data['proposalStatus'] as String?)?.toLowerCase() == 'completed';

    return EventModel(
      id: docId,
      referenceId: data['referenceId'] as String? ?? data['referenceNo'] as String? ?? '',
      title: data['title'] as String? ?? '',
      tagline: data['tagline'] as String?,
      description: data['description'] as String? ?? '',
      objectives: List<String>.from(data['objectives'] ?? []),
      mechanics: List<String>.from(data['mechanics'] ?? []),
      organizers: List<String>.from(data['organizers'] ?? []),
      bannerImageUrl: data['bannerImageUrl'] as String?,
      thumbnailUrl: data['thumbnailUrl'] as String?,
      isVisible: rawVisible,
      isPublished: rawPublished,
      visibilityStart: parsedVisibilityStart,
      eventTypeId: data['eventTypeId'] as String? ?? '',
      customEventTypeName: data['customEventTypeName'] as String?,
      customEventTypeColor: data['customEventTypeColor'] as String?,
      eventCategoryId: data['eventCategoryId'] as String? ?? '',
      customEventCategoryName: data['customEventCategoryName'] as String?,
      hostingOrgId: (data['hostingOrgId'] ?? data['organizationId'] ?? data['orgId']) as String? ?? '',
      semesterId: data['semesterId'] as String? ?? '',
      schoolYear: data['schoolYear'] as String? ?? '',
      semester: data['semester'] as String?,
      targetAcademicLevel: (data['targetAcademicLevel'] ?? (data['targetAudience'] is Map ? (data['targetAudience']['academicLevels'] as List?)?.join('/') : null)) as String?,
      date: (data['date'] ?? data['eventDate'] ?? data['startDate']) as String?,
      startTime: data['startTime'] as String?,
      endTime: data['endTime'] as String?,
      venueName: (data['venueName'] ?? data['customVenueName']) as String?,
      sessions: (data['sessions'] as List<dynamic>?)
              ?.map((s) => EventSessionModel.fromMap(s as Map<String, dynamic>))
              .toList() ??
          [],
      venueId: data['venueId'] as String? ?? '',
      customVenueName: (data['customVenueName'] ?? data['venueName']) as String?,
      eventFormat: data['eventFormat'] as String? ?? '',
      allStudents: data['allStudents'] == true ||
          (data['targetAudience'] is Map && data['targetAudience']['allStudents'] == true) ||
          data['targetAudienceScope'] == 'all' ||
          (data['targetAudience'] is Map && data['targetAudience']['scope'] == 'all'),
      targetAudienceScope: data['targetAudienceScope'] as String? ?? 'all',
      targetCourses: () {
        final raw = data['targetCourses'] ??
            data['allowedCourses'] ??
            (data['targetAudience'] is Map ? data['targetAudience']['courseCodes'] : null);
        if (raw is List) {
          return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
        return <String>[];
      }(),
      targetYearLevels: () {
        final raw = data['targetYearLevels'] ??
            (data['targetAudience'] is Map ? data['targetAudience']['yearLevels'] : null);
        if (raw is List) {
          return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
        return <String>[];
      }(),
      targetSections: () {
        final raw = data['targetSections'] ??
            (data['targetAudience'] is Map ? data['targetAudience']['sections'] : null);
        if (raw is List) {
          return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
        return <String>[];
      }(),
      targetDepartmentIds: () {
        final raw = data['targetDepartmentIds'] ??
            (data['targetAudience'] is Map ? data['targetAudience']['departmentIds'] : null);
        if (raw is List) {
          return raw.map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
        }
        return <String>[];
      }(),
      expectedParticipantCount: (data['expectedParticipantCount'] ?? (data['targetAudience'] is Map ? data['targetAudience']['estimatedAttendance'] : null)) as int? ?? 0,
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
      adminFeeOverride: ((data['adminFeeOverride'] ?? data['feeAmount'] ?? data['fee'] ?? data['suggestedFeePerStudent']) as num?)?.toDouble(),
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
      scannerActivationCode: (data['scannerActivationCode'] ?? data['scannerPinCode']) as String? ?? '',

      scannerUserIds: () {
        final rawUserIds = data['scannerUserIds'];
        if (rawUserIds is List && rawUserIds.isNotEmpty) {
          final list = rawUserIds
              .map((e) => e?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
          if (list.isNotEmpty) return list;
        }
        final rawScanners = data['scanners'];
        if (rawScanners is List && rawScanners.isNotEmpty) {
          final list = <String>[];
          for (final s in rawScanners) {
            if (s is Map) {
              final uid = s['officerUserId'] ?? s['userId'] ?? s['id'] ?? s['officerName'];
              if (uid != null && uid.toString().trim().isNotEmpty) {
                list.add(uid.toString().trim());
              }
            } else if (s != null && s.toString().trim().isNotEmpty) {
              list.add(s.toString().trim());
            }
          }
          if (list.isNotEmpty) return list;
        }
        final rawStaff = data['scannerStaffNames'];
        if (rawStaff is List && rawStaff.isNotEmpty) {
          final list = rawStaff
              .map((e) => e?.toString().trim() ?? '')
              .where((s) => s.isNotEmpty)
              .toList();
          if (list.isNotEmpty) return list;
        }
        return <String>[];
      }(),
      status: statusRaw ??
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
      isArchived: isArchived,
      isDeleted: isDeleted,
      completedAt: parseFlexibleDate(data['completedAt'] ?? data['completed_at']),
      completedBy: (data['completedBy'] ?? data['completed_by']) as String?,
      archivedAt: parseFlexibleDate(data['archivedAt'] ?? data['archived_at']),
      archivedBy: (data['archivedBy'] ?? data['archived_by']) as String?,
      attendanceLocked: attendanceLocked,
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
      'mechanics': mechanics,
      'organizers': organizers,
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
      'semester': semester,
      'targetAcademicLevel': targetAcademicLevel,
      'sessions': sessions.map((s) => s.toMap()).toList(),
      'venueId': venueId,
      'customVenueName': customVenueName,
      'eventFormat': eventFormat,
      'allStudents': allStudents,
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
      'isArchived': isArchived,
      'isDeleted': isDeleted,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'completedBy': completedBy,
      'archivedAt': archivedAt != null ? Timestamp.fromDate(archivedAt!) : null,
      'archivedBy': archivedBy,
      'attendanceLocked': attendanceLocked,
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
    if (completedAt != null) {
      map['completedAt'] = completedAt!.toIso8601String();
    }
    if (archivedAt != null) {
      map['archivedAt'] = archivedAt!.toIso8601String();
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
  final bool isLateEnabled;
  final String? markLateAfter;

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
    this.isLateEnabled = false,
    this.markLateAfter,
  });

  factory EventSessionModel.fromMap(Map<String, dynamic> map) {
    return EventSessionModel(
      id: map['id'] as String? ?? '',
      title: (map['title'] ?? map['name'] ?? map['sessionName']) as String? ?? '',
      date: map['date'] as String? ?? '',
      startTime: map['startTime'] as String? ?? '',
      endTime: map['endTime'] as String? ?? '',
      timeInOpen: map['timeInOpen'] as String? ?? '',
      timeInClose: map['timeInClose'] as String? ?? '',
      hasTimeOut: map['hasTimeOut'] as bool? ?? false,
      timeOutOpen: map['timeOutOpen'] as String?,
      timeOutClose: map['timeOutClose'] as String?,
      isLateEnabled: map['isLateEnabled'] as bool? ?? false,
      markLateAfter: map['markLateAfter'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'name': title,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'timeInOpen': timeInOpen,
      'timeInClose': timeInClose,
      'hasTimeOut': hasTimeOut,
      'timeOutOpen': timeOutOpen,
      'timeOutClose': timeOutClose,
      'isLateEnabled': isLateEnabled,
      'markLateAfter': markLateAfter,
    };
  }
}
