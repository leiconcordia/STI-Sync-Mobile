import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents an announcement in Firestore (`/announcements/{announcementId}`).
class AnnouncementModel {
  final String id;
  final String title;
  final String content;                   // Plain text message content
  final String priority;                  // 'Normal' | 'Important' | 'Urgent'
  final String audience;                  // 'campus-wide' | 'all-organizations' | 'specific' | 'targeted'
  final List<String> targetOrgIds;        // Specific target org IDs
  final List<String> targetOrgNames;      // Denormalized target org names
  final bool pinned;                      // Pinned announcements float to top of feed
  final String semesterId;
  final String schoolYear;
  final String authorName;                // Author display name
  final String authorUid;                 // FK → /sas_admins or /students
  final String? organizationId;          // Authoring Org ID (if officer-authored)
  final String? organizationName;        // Authoring Org Name
  final String? authorRole;              // e.g., "SAO Admin", "IT Guild President"
  final String? linkedEventId;           // Optional FK → /events for navigation
  final String? linkedEventTitle;        // Optional Event Title
  final List<String> targetDepartments;  // Target department names or IDs
  final List<String> targetYearLevels;   // Target year levels e.g. ["1st Year", "2nd Year"]
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.audience,
    required this.targetOrgIds,
    required this.targetOrgNames,
    required this.pinned,
    required this.semesterId,
    required this.schoolYear,
    required this.authorName,
    required this.authorUid,
    this.organizationId,
    this.organizationName,
    this.authorRole,
    this.linkedEventId,
    this.linkedEventTitle,
    required this.targetDepartments,
    required this.targetYearLevels,
    this.createdAt,
    this.updatedAt,
  });

  bool get isUrgent => priority.toLowerCase() == 'urgent';
  bool get isImportant => priority.toLowerCase() == 'important';
  bool get hasLinkedEvent => linkedEventId != null && linkedEventId!.trim().isNotEmpty;

  factory AnnouncementModel.fromFirestore(Map<String, dynamic> data, String docId) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    return AnnouncementModel(
      id: docId,
      title: data['title'] as String? ?? 'Announcement',
      content: data['content'] as String? ?? data['body'] as String? ?? '',
      priority: data['priority'] as String? ?? 'Normal',
      audience: data['audience'] as String? ?? (data['targetAudience'] is String ? data['targetAudience'] as String : 'campus-wide'),
      targetOrgIds: List<String>.from(data['targetOrgIds'] ?? data['targetOrganizationIds'] ?? []),
      targetOrgNames: List<String>.from(data['targetOrgNames'] ?? []),
      pinned: data['pinned'] as bool? ?? false,
      semesterId: data['semesterId'] as String? ?? '',
      schoolYear: data['schoolYear'] as String? ?? '',
      authorName: data['authorName'] as String? ?? 'SAO Admin',
      authorUid: data['authorUid'] as String? ?? '',
      organizationId: data['organizationId'] as String?,
      organizationName: data['organizationName'] as String?,
      authorRole: data['authorRole'] as String? ?? (data['organizationName'] != null ? '${data['organizationName']} Officer' : 'SAO Admin'),
      linkedEventId: data['linkedEventId'] as String?,
      linkedEventTitle: data['linkedEventTitle'] as String?,
      targetDepartments: List<String>.from(data['targetDepartments'] ?? []),
      targetYearLevels: List<String>.from(data['targetYearLevels'] ?? []),
      createdAt: parseDate(data['createdAt'] ?? data['publishedAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }
}
