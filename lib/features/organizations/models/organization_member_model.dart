class OrganizationMemberModel {
  final String id; // organization_members document ID
  final String organizationId;
  final String organizationName;
  final String organizationAcronym;
  final String? logoUrl;
  final String role; // "Member", "President", "Secretary", etc.
  final bool isOfficer;
  final String? officerId; // organization_officers document ID if officer
  final String status; // "active" | "pending" | "rejected"

  const OrganizationMemberModel({
    required this.id,
    required this.organizationId,
    required this.organizationName,
    required this.organizationAcronym,
    this.logoUrl,
    required this.role,
    required this.isOfficer,
    this.officerId,
    this.status = 'active',
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isActive => status.toLowerCase() == 'active';

  String get initials {
    if (organizationAcronym.isNotEmpty) {
      return organizationAcronym.length > 2
          ? organizationAcronym.substring(0, 2).toUpperCase()
          : organizationAcronym.toUpperCase();
    }
    if (organizationName.isNotEmpty) {
      final words = organizationName.trim().split(RegExp(r'\s+'));
      if (words.length >= 2) {
        return '${words[0][0]}${words[1][0]}'.toUpperCase();
      }
      return organizationName.substring(0, 2).toUpperCase();
    }
    return 'ORG';
  }
}
