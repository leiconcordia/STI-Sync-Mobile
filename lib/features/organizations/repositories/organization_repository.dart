import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/models/student_model.dart';
import '../models/organization_member_model.dart';

/// Repository for student organization memberships and officer assignments.
class OrganizationRepository {
  final FirebaseFirestore _firestore;

  OrganizationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Live stream of active & pending organization memberships for a student Auth UID.
  Stream<List<OrganizationMemberModel>> watchStudentOrganizations(
    String studentAuthUid,
  ) {
    if (studentAuthUid.isEmpty) return Stream.value([]);

    // Query organization_members by studentAuthUid, studentId, or student_id
    final query1 = _firestore
        .collection(FirestorePaths.organizationMembers)
        .where('studentAuthUid', isEqualTo: studentAuthUid)
        .snapshots();

    final query2 = _firestore
        .collection(FirestorePaths.organizationMembers)
        .where('studentId', isEqualTo: studentAuthUid)
        .snapshots();

    final query3 = _firestore
        .collection(FirestorePaths.organizationMembers)
        .where('student_id', isEqualTo: studentAuthUid)
        .snapshots();

    return Rx.combineLatest3<QuerySnapshot, QuerySnapshot, QuerySnapshot, List<DocumentSnapshot>>(
      query1,
      query2,
      query3,
      (snap1, snap2, snap3) {
        final docsMap = <String, DocumentSnapshot>{};
        for (final doc in snap1.docs) {
          docsMap[doc.id] = doc;
        }
        for (final doc in snap2.docs) {
          docsMap[doc.id] = doc;
        }
        for (final doc in snap3.docs) {
          docsMap[doc.id] = doc;
        }
        return docsMap.values.toList();
      },
    ).asyncMap((memberDocs) async {
      final results = <OrganizationMemberModel>[];

      for (final doc in memberDocs) {
        try {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final orgId = (data['organizationId'] as String?) ??
              (data['organization_id'] as String?) ??
              '';
          final status = (data['status'] as String?) ?? 'active';

          if (orgId.isEmpty) continue;

          // Fetch organization details
          final orgDoc = await _firestore
              .collection(FirestorePaths.organizations)
              .doc(orgId)
              .get();

          final orgData = orgDoc.data() ?? {};
          final orgName = (orgData['name'] as String?) ??
              (orgData['organizationName'] as String?) ??
              'Organization';
          final orgAcronym = (orgData['acronym'] as String?) ??
              (orgData['code'] as String?) ??
              '';
          final logoUrl = (orgData['logoUrl'] as String?) ??
              (orgData['logo'] as String?);

          // Check if officer record exists for this member or student in this org
          final officerSnap1 = await _firestore
              .collection(FirestorePaths.organizationOfficers)
              .where('memberId', isEqualTo: doc.id)
              .limit(1)
              .get();

          DocumentSnapshot? officerDoc =
              officerSnap1.docs.isNotEmpty ? officerSnap1.docs.first : null;

          if (officerDoc == null) {
            final officerSnap2 = await _firestore
                .collection(FirestorePaths.organizationOfficers)
                .where('studentId', isEqualTo: studentAuthUid)
                .where('organizationId', isEqualTo: orgId)
                .limit(1)
                .get();
            if (officerSnap2.docs.isNotEmpty) {
              officerDoc = officerSnap2.docs.first;
            }
          }

          final isOfficer = officerDoc != null || (data['isOfficer'] as bool? ?? false);
          final officerData = officerDoc?.data() as Map<String, dynamic>? ?? {};
          final position = (officerData['position'] as String?) ??
              (officerData['role'] as String?) ??
              (isOfficer ? 'Officer' : 'Member');

          results.add(
            OrganizationMemberModel(
              id: doc.id,
              organizationId: orgId,
              organizationName: orgName,
              organizationAcronym: orgAcronym,
              logoUrl: logoUrl,
              role: position,
              isOfficer: isOfficer,
              officerId: officerDoc?.id,
              status: status,
            ),
          );
        } catch (e) {
          debugPrint('OrganizationRepository: Error parsing org member ${doc.id}: $e');
        }
      }

      return results;
    });
  }

  /// Fetches all active organizations available to join.
  Future<List<Map<String, dynamic>>> fetchAllOrganizations() async {
    try {
      final snap = await _firestore
          .collection(FirestorePaths.organizations)
          .get();

      return snap.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': (data['name'] as String?) ?? (data['organizationName'] as String?) ?? 'Organization',
          'acronym': (data['acronym'] as String?) ?? (data['code'] as String?) ?? '',
          'logoUrl': (data['logoUrl'] as String?) ?? (data['logo'] as String?),
          'description': (data['description'] as String?) ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('OrganizationRepository: Error fetching organizations: $e');
      return [];
    }
  }

  /// Sends a join request for a student to join an organization.
  /// Writes a new document to `/organization_members` with `status: "pending"`
  /// containing exact web admin schema fields.
  Future<void> joinOrganization({
    required StudentModel student,
    required String organizationId,
  }) async {
    final authUid = student.id;
    final officialStudentId =
        student.studentId.isNotEmpty ? student.studentId : student.id;

    if (authUid.isEmpty || organizationId.isEmpty) {
      throw Exception('Student ID or Organization ID is missing.');
    }

    // Check if membership record already exists
    final existing1 = await _firestore
        .collection(FirestorePaths.organizationMembers)
        .where('organizationId', isEqualTo: organizationId)
        .where('studentAuthUid', isEqualTo: authUid)
        .limit(1)
        .get();

    if (existing1.docs.isNotEmpty) {
      final status = (existing1.docs.first.data()['status'] as String?) ?? 'active';
      if (status == 'pending') {
        throw Exception('Your join request for this organization is pending officer approval.');
      }
      throw Exception('You are already a member of this organization.');
    }

    final existing2 = await _firestore
        .collection(FirestorePaths.organizationMembers)
        .where('organizationId', isEqualTo: organizationId)
        .where('studentId', isEqualTo: officialStudentId)
        .limit(1)
        .get();

    if (existing2.docs.isNotEmpty) {
      final status = (existing2.docs.first.data()['status'] as String?) ?? 'active';
      if (status == 'pending') {
        throw Exception('Your join request for this organization is pending officer approval.');
      }
      throw Exception('You are already a member of this organization.');
    }

    final studentFullName = '${student.firstName} ${student.lastName}'.trim();

    // Write new document with exact web admin schema + status: "pending"
    await _firestore.collection(FirestorePaths.organizationMembers).add({
      'addedBy': 'self',
      'contactNumber': student.contactNumber,
      'course': student.courseCode,
      'createdAt': FieldValue.serverTimestamp(),
      'dateJoined': FieldValue.serverTimestamp(),
      'department': student.departmentName,
      'email': student.email,
      'isOfficer': false,
      'organizationId': organizationId,
      'paymentStatus': 'outstanding',
      'status': 'pending',
      'studentId': officialStudentId,
      'studentAuthUid': authUid,
      'studentName': studentFullName.isNotEmpty ? studentFullName : student.email,
      'updatedAt': FieldValue.serverTimestamp(),
      'year': student.yearLevel,
    });
  }
}
