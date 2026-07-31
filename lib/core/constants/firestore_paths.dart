class FirestorePaths {
  static const String students = 'students';
  static const String events = 'events';
  static const String eventSessions = 'event_sessions';
  static const String attendance = 'attendance';
  static const String flaggedAttendance = 'flagged_attendance';
  
  static String eventAttendance(String eventId) => 'events/$eventId/attendance';
  static String eventFlaggedAttendance(String eventId) => 'events/$eventId/flagged_attendance';

  static const String payables = 'payables';
  static const String announcements = 'announcements';
  static const String certificates = 'certificates';
  static const String organizations = 'organizations';
  static const String organizationOfficers = 'organization_officers';
  static const String organizationMembers = 'organization_members';
  static const String courses = 'courses';
  static const String departments = 'departments';
  static const String sections = 'sections';
  static const String semesters = 'semesters';
  static const String venues = 'venues';
  static const String eventCategories = 'event_categories';

  // Event document fields
  static const String targetDepartmentIds = 'targetDepartmentIds';
  static const String targetYearLevels = 'targetYearLevels';
}
