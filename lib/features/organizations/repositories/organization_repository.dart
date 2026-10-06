import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../../../core/constants/firestore_paths.dart';
import '../../auth/models/student_model.dart';
import '../models/organization_member_model.dart';
import '../models/organization_model.dart';

/// Repository for student organization memberships and officer assignments.
class OrganizationRepository {
  final FirebaseFirestore _firestore;

  OrganizationRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  /// Live stream of active & pending organization memberships for a student Auth UID and/or Student ID Number.
  Stream<List<OrganizationMemberModel>> watchStudentOrganizations(
    String studentAuthUid, {
    String? studentIdNumber,
  }) {
    if (studentAuthUid.isEmpty && (studentIdNumber == null || studentIdNumber.isEmpty)) {
      return Stream.value([]);
    }

    final queryStreams = <Stream<QuerySnapshot>>[];

    void addQueriesForId(String id) {
      if (id.isEmpty) return;
      // organization_members
      queryStreams.add(_firestore
          .collection(FirestorePaths.organizationMembers)
          .where('studentAuthUid', isEqualTo: id)
          .snapshots());
      queryStreams.add(_firestore
          .collection(FirestorePaths.organizationMembers)
          .where('studentId', isEqualTo: id)
          .snapshots());
      queryStreams.add(_firestore
          .collection(FirestorePaths.organizationMembers)
          .where('student_id', isEqualTo: id)
          .snapshots());
      // organization_officers
      queryStreams.add(_firestore
          .collection(FirestorePaths.organizationOfficers)
          .where('studentAuthUid', isEqualTo: id)
          .snapshots());
      queryStreams.add(_firestore
          .collection(FirestorePaths.organizationOfficers)
          .where('studentId', isEqualTo: id)
          .snapshots());
      queryStreams.add(_firestore
          .collection(FirestorePaths.organizationOfficers)
          .where('student_id', isEqualTo: id)
          .snapshots());
    }

    addQueriesForId(studentAuthUid);
    if (studentIdNumber != null && studentIdNumber.isNotEmpty && studentIdNumber != studentAuthUid) {
      addQueriesForId(studentIdNumber);
    }

    return Rx.combineLatest<QuerySnapshot, List<DocumentSnapshot>>(
      queryStreams,
      (snapshots) {
        final docsMap = <String, DocumentSnapshot>{};
        for (final snap in snapshots) {
          for (final doc in snap.docs) {
            docsMap[doc.id] = doc;
          }
        }
        return docsMap.values.toList();
      },
    ).asyncMap((allDocs) async {
      final results = <OrganizationMemberModel>[];
      final memberDocs = <DocumentSnapshot>[];
      final officerDocs = <DocumentSnapshot>[];

      for (final doc in allDocs) {
        if (doc.reference.parent.id == FirestorePaths.organizationOfficers) {
          officerDocs.add(doc);
        } else {
          memberDocs.add(doc);
        }
      }

      final processedOrgIds = <String>{};

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
          DocumentSnapshot? officerDoc;
          final matchingOfficerFromStream = officerDocs.where((d) {
            final od = d.data() as Map<String, dynamic>? ?? {};
            return (od['organizationId'] == orgId || od['organization_id'] == orgId);
          });

          if (matchingOfficerFromStream.isNotEmpty) {
            officerDoc = matchingOfficerFromStream.first;
          }

          if (officerDoc == null) {
            final officerSnap1 = await _firestore
                .collection(FirestorePaths.organizationOfficers)
                .where('memberId', isEqualTo: doc.id)
                .limit(1)
                .get();

            if (officerSnap1.docs.isNotEmpty) {
              officerDoc = officerSnap1.docs.first;
            }
          }

          if (officerDoc == null && studentAuthUid.isNotEmpty) {
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

          if (officerDoc == null && studentIdNumber != null && studentIdNumber.isNotEmpty) {
            final officerSnap3 = await _firestore
                .collection(FirestorePaths.organizationOfficers)
                .where('studentId', isEqualTo: studentIdNumber)
                .where('organizationId', isEqualTo: orgId)
                .limit(1)
                .get();
            if (officerSnap3.docs.isNotEmpty) {
              officerDoc = officerSnap3.docs.first;
            }
          }

          final isOfficer = officerDoc != null || (data['isOfficer'] as bool? ?? false);
          final officerData = officerDoc?.data() as Map<String, dynamic>? ?? {};
          final position = (officerData['position'] as String?) ??
              (officerData['role'] as String?) ??
              (isOfficer ? 'Officer' : 'Member');

          processedOrgIds.add(orgId);
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

      // Also process officers that were added directly to organization_officers without a separate organization_members doc
      for (final offDoc in officerDocs) {
        try {
          final offData = offDoc.data() as Map<String, dynamic>? ?? {};
          final orgId = (offData['organizationId'] as String?) ??
              (offData['organization_id'] as String?) ??
              '';
          if (orgId.isEmpty || processedOrgIds.contains(orgId)) continue;

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
          final position = (offData['position'] as String?) ??
              (offData['role'] as String?) ??
              'Officer';

          processedOrgIds.add(orgId);
          results.add(
            OrganizationMemberModel(
              id: offDoc.id,
              organizationId: orgId,
              organizationName: orgName,
              organizationAcronym: orgAcronym,
              logoUrl: logoUrl,
              role: position,
              isOfficer: true,
              officerId: offDoc.id,
              status: 'active',
            ),
          );
        } catch (e) {
          debugPrint('OrganizationRepository: Error parsing direct officer ${offDoc.id}: $e');
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
        final rawDeptId = (data['departmentId'] as String?) ??
            (data['department'] as String?) ??
            'cross-departmental';
        final rawDeptName = (data['departmentName'] as String?) ??
            (data['department_name'] as String?) ??
            '';
        final rawScope = (data['scope'] as String?) ??
            (rawDeptId.toLowerCase() != 'cross-departmental' ? 'departmental' : 'cross-departmental');

        return {
          'id': doc.id,
          'name': (data['name'] as String?) ?? (data['organizationName'] as String?) ?? 'Organization',
          'acronym': (data['acronym'] as String?) ?? (data['code'] as String?) ?? '',
          'logoUrl': (data['logoUrl'] as String?) ?? (data['logo'] as String?),
          'description': (data['description'] as String?) ?? '',
          'departmentId': rawDeptId,
          'departmentName': rawDeptName,
          'scope': rawScope,
          'allowedDepartmentIds': data['allowedDepartmentIds'] ?? [],
          'allowedCourseIds': data['allowedCourseIds'] ?? [],
          'status': (data['status'] as String?) ?? 'active',
          'memberCount': (data['memberCount'] as num?)?.toInt() ?? 0,
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

    // Verify organization existence and department eligibility
    final orgDoc = await _firestore
        .collection(FirestorePaths.organizations)
        .doc(organizationId)
        .get();

    if (!orgDoc.exists) {
      throw Exception('Organization not found.');
    }

    final org = OrganizationModel.fromFirestore(orgDoc.data() ?? {}, orgDoc.id);

    // Verify department eligibility
    if (!org.isStudentEligible(student.departmentId, student.departmentName)) {
      throw Exception(
        'This organization is restricted to  students.',
      );
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

