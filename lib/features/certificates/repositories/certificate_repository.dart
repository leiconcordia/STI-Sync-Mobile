import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sti_sync/core/constants/firestore_paths.dart';
import 'package:sti_sync/features/certificates/models/issued_certificate_model.dart';
import 'package:sti_sync/features/certificates/models/certificate_template_model.dart';

class CertificateRepository {
  final FirebaseFirestore _firestore;

  CertificateRepository(this._firestore);

  /// Streams certificates issued to the current student in real time.
  /// Checks both official studentId (e.g. 02000213456) and auth UID to guarantee matching.
  Stream<List<IssuedCertificateModel>> streamMyCertificates({
    required String studentId,
    String? authUid,
  }) {
    final validIds = <String>{};
    if (studentId.trim().isNotEmpty) {
      validIds.add(studentId.trim());
    }
    if (authUid != null && authUid.trim().isNotEmpty) {
      validIds.add(authUid.trim());
    }

    final idList = validIds.toList();
    if (idList.isEmpty) {
      return Stream.value([]);
    }

    final Query<Map<String, dynamic>> query = idList.length == 1
        ? _firestore
            .collection(FirestorePaths.certificatesIssued)
            .where('studentId', isEqualTo: idList.first)
        : _firestore
            .collection(FirestorePaths.certificatesIssued)
            .where('studentId', whereIn: idList);

    return query.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => IssuedCertificateModel.fromFirestore(doc))
          .toList();

      // Sort client-side by issuedAt descending (newest first)
      list.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
      return list;
    });
  }

  /// Fetches a specific template by ID, checking `certificates` collection first,
  /// then fallback to `certificate_templates` collection.
  Future<CertificateTemplateModel?> getTemplateById(String templateId) async {
    if (templateId.trim().isEmpty) return null;

    try {
      // 1. Try `certificates` collection
      final certDoc = await _firestore
          .collection(FirestorePaths.certificates)
          .doc(templateId)
          .get();

      if (certDoc.exists && certDoc.data() != null) {
        return CertificateTemplateModel.fromFirestore(certDoc);
      }

      // 2. Fallback to `certificate_templates` collection
      final templateDoc = await _firestore
          .collection(FirestorePaths.certificateTemplates)
          .doc(templateId)
          .get();

      if (templateDoc.exists && templateDoc.data() != null) {
        return CertificateTemplateModel.fromFirestore(templateDoc);
      }
    } catch (e) {
      // Return null on read error / not found
    }
    return null;
  }

  /// Fetches a single issued certificate by its ID.
  Future<IssuedCertificateModel?> getIssuedCertificateById(String certificateId) async {
    if (certificateId.trim().isEmpty) return null;

    try {
      final doc = await _firestore
          .collection(FirestorePaths.certificatesIssued)
          .doc(certificateId)
          .get();

      if (doc.exists && doc.data() != null) {
        return IssuedCertificateModel.fromFirestore(doc);
      }
    } catch (e) {
      // Return null on error
    }
    return null;
  }
}
