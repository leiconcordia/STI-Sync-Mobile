import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';
import '../models/scanner_assignment_model.dart';
import '../../../core/local/daos/scanner_dao.dart';
import '../../../core/constants/firestore_paths.dart';

/// Repository for all scanner-related Firestore and local database operations.
///
/// Firestore access: reads from `/events` collection via `scannerUserIds` field.
/// Local access: read/write to Drift `scanner_assignments` table.
class ScannerRepository {
  final FirebaseFirestore _firestore;
  final ScannerDao _scannerDao;

  ScannerRepository({
    required FirebaseFirestore firestore,
    required ScannerDao scannerDao,
  })  : _firestore = firestore,
        _scannerDao = scannerDao;

  /// Live stream of organization_officers document IDs for a given student Auth UID or direct Officer ID.
  ///
  /// Step 1: Resolves member document IDs from `/organization_members` (where studentId == inputId).
  /// Step 2: Queries `/organization_officers` matching member IDs or student Auth UID directly.
  /// Step 3: Includes inputId itself (in case inputId is passed directly as an officer ID).
  /// Live stream of organization_officers document IDs and custom 'id' fields for a given student Auth UID or direct Officer ID.
  Stream<List<String>> watchOfficerIdsForStudent(String inputId) {
    if (inputId.isEmpty) return Stream.value([]);

    // Stream student document to resolve studentId number (e.g. "02000108642")
    final studentDocStream = _firestore
        .collection(FirestorePaths.students)
        .doc(inputId)
        .snapshots();

    return studentDocStream.switchMap((studentDoc) {
      final studentData = studentDoc.data() ?? {};
      final officialStudentId = (studentData['studentId'] as String?) ??
          (studentData['student_id'] as String?) ??
          '';

      final initialStudentIds = <String>{inputId};
      if (officialStudentId.isNotEmpty) {
        initialStudentIds.add(officialStudentId);
      }

      final queryStreams = <Stream<QuerySnapshot>>[];

      for (final sId in initialStudentIds) {
        queryStreams.add(
          _firestore
              .collection(FirestorePaths.organizationMembers)
              .where('studentAuthUid', isEqualTo: sId)
              .snapshots(),
        );
        queryStreams.add(
          _firestore
              .collection(FirestorePaths.organizationMembers)
              .where('studentId', isEqualTo: sId)
              .snapshots(),
        );
        queryStreams.add(
          _firestore
              .collection(FirestorePaths.organizationMembers)
              .where('student_id', isEqualTo: sId)
              .snapshots(),
        );
      }

      return Rx.combineLatest<QuerySnapshot, Map<String, dynamic>>(
        queryStreams,
        (memberSnapshots) {
          final memberIds = <String>{};
          final orgIds = <String>{};
          final studentIds = Set<String>.from(initialStudentIds);

          for (final snap in memberSnapshots) {
            for (final doc in snap.docs) {
              memberIds.add(doc.id);
              final data = doc.data() as Map<String, dynamic>? ?? {};
              final orgId = (data['organizationId'] as String?) ??
                  (data['organization_id'] as String?);
              if (orgId != null && orgId.isNotEmpty) orgIds.add(orgId);

              final sId = (data['studentId'] as String?) ??
                  (data['student_id'] as String?);
              if (sId != null && sId.isNotEmpty) studentIds.add(sId);
            }
          }

          return {
            'memberIds': memberIds.toList(),
            'orgIds': orgIds.toList(),
            'studentIds': studentIds.toList(),
          };
        },
      ).switchMap((meta) {
        final memberIds = meta['memberIds'] as List<String>;
        final orgIds = meta['orgIds'] as List<String>;
        final studentIds = meta['studentIds'] as List<String>;

        final officerStreams = <Stream<QuerySnapshot>>[];

        for (final sId in studentIds) {
          officerStreams.add(
            _firestore
                .collection(FirestorePaths.organizationOfficers)
                .where('studentAuthUid', isEqualTo: sId)
                .snapshots(),
          );
          officerStreams.add(
            _firestore
                .collection(FirestorePaths.organizationOfficers)
                .where('studentId', isEqualTo: sId)
                .snapshots(),
          );
          officerStreams.add(
            _firestore
                .collection(FirestorePaths.organizationOfficers)
                .where('student_id', isEqualTo: sId)
                .snapshots(),
          );
        }

        if (memberIds.isNotEmpty) {
          for (var i = 0; i < memberIds.length; i += 10) {
            final chunk = memberIds.sublist(
              i,
              i + 10 > memberIds.length ? memberIds.length : i + 10,
            );
            officerStreams.add(
              _firestore
                  .collection(FirestorePaths.organizationOfficers)
                  .where('memberId', whereIn: chunk)
                  .snapshots(),
            );
            officerStreams.add(
              _firestore
                  .collection(FirestorePaths.organizationOfficers)
                  .where('member_id', whereIn: chunk)
                  .snapshots(),
            );
          }
        }

        if (orgIds.isNotEmpty) {
          for (var i = 0; i < orgIds.length; i += 10) {
            final chunk = orgIds.sublist(
              i,
              i + 10 > orgIds.length ? orgIds.length : i + 10,
            );
            officerStreams.add(
              _firestore
                  .collection(FirestorePaths.organizationOfficers)
                  .where('organizationId', whereIn: chunk)
                  .snapshots(),
            );
            officerStreams.add(
              _firestore
                  .collection(FirestorePaths.organizationOfficers)
                  .where('organization_id', whereIn: chunk)
                  .snapshots(),
            );
          }
        }

        return Rx.combineLatest<QuerySnapshot, List<String>>(
          officerStreams,
          (snapshots) {
            final officerDocIds = <String>{};

            // Include student's official STI student numbers & Auth UIDs
            for (final sId in studentIds) {
              if (sId.isNotEmpty) officerDocIds.add(sId);
            }

            for (final snap in snapshots) {
              for (final doc in snap.docs) {
                final data = doc.data() as Map<String, dynamic>? ?? {};

                // Extract Firestore Document ID
                officerDocIds.add(doc.id);

                // Extract custom "id" field if present in web admin doc
                final customId = data['id'] as String?;
                if (customId != null && customId.isNotEmpty) {
                  officerDocIds.add(customId);
                }

                final officerId = (data['officerId'] as String?) ??
                    (data['officer_id'] as String?);
                if (officerId != null && officerId.isNotEmpty) {
                  officerDocIds.add(officerId);
                }

                final studentId = (data['studentId'] as String?) ??
                    (data['student_id'] as String?);
                if (studentId != null && studentId.isNotEmpty) {
                  officerDocIds.add(studentId);
                }

                final studentAuthUid = data['studentAuthUid'] as String?;
                if (studentAuthUid != null && studentAuthUid.isNotEmpty) {
                  officerDocIds.add(studentAuthUid);
                }
              }
            }

            // Include inputId itself in case inputId is directly an officer doc ID or student ID
            officerDocIds.add(inputId);

            final resolvedList =
                officerDocIds.where((id) => id.isNotEmpty).toList();
            debugPrint(
                'ScannerRepository: Resolved officer IDs for input "$inputId": $resolvedList');
            return resolvedList;
          },
        );
      });
    });
  }

  /// Live stream of events where any of [targetOfficerIds] is listed as a scanner.
  Stream<List<ScannerAssignmentModel>> watchScannerAssignmentsForIds(
    List<String> targetOfficerIds,
  ) {
    final validIds = targetOfficerIds.where((id) => id.isNotEmpty).toSet().toList();
    if (validIds.isEmpty) return Stream.value([]);

    debugPrint(
        'ScannerRepository: watchScannerAssignmentsForIds started for IDs: $validIds');

    final Query<Map<String, dynamic>> query = validIds.length == 1
        ? _firestore
            .collection(FirestorePaths.events)
            .where('scannerUserIds', arrayContains: validIds.first)
        : _firestore
            .collection(FirestorePaths.events)
            .where('scannerUserIds',
                arrayContainsAny: validIds.take(10).toList());

    return query.snapshots().map((snapshot) {
      debugPrint(
          'ScannerRepository: Snapshot received with ${snapshot.docs.length} docs for IDs $validIds');
      return snapshot.docs.map((doc) {
        try {
          final model =
              ScannerAssignmentModel.fromEventDocForIds(doc, validIds);
          return model;
        } catch (e) {
          debugPrint('ScannerRepository: Failed to parse event ${doc.id}: $e');
          return null;
        }
      }).whereType<ScannerAssignmentModel>().toList();
    });
  }

  /// Live stream of events where any resolved officer ID (or direct officer ID)
  /// is listed as a scanner in `scannerUserIds`.
  Stream<List<ScannerAssignmentModel>> watchScannerAssignments(
    String inputId,
  ) {
    if (inputId.isEmpty) return Stream.value([]);

    return watchOfficerIdsForStudent(inputId).switchMap((officerIds) {
      if (officerIds.isEmpty) {
        debugPrint(
            'ScannerRepository: No valid officer IDs resolved for: $inputId');
        return Stream.value([]);
      }
      return watchScannerAssignmentsForIds(officerIds);
    });
  }

  /// Persists [assignment] to the local Drift database for offline access.
  Future<void> saveAssignmentLocally(ScannerAssignmentModel assignment) async {
    await _scannerDao.saveAssignment(assignment.toCompanion());
  }

  /// Returns all scanner assignments cached locally in Drift.
  Future<List<ScannerAssignmentModel>> getLocalAssignments() async {
    final entities = await _scannerDao.getAllAssignments();
    return entities.map(ScannerAssignmentModel.fromDrift).toList();
  }

  /// Returns true if the event's last session end time is in the past.
  ///
  /// First checks the locally cached `eventEndTime` from the Drift row to
  /// avoid a network round-trip. Falls back to a Firestore fetch if the event
  /// is not cached locally.
  Future<bool> isEventEnded(String eventId) async {
    // Fast path: use locally cached end time
    final cached = await _scannerDao.getAssignment(eventId);
    if (cached != null && cached.eventEndTime > 0) {
      final endTime = DateTime.fromMillisecondsSinceEpoch(cached.eventEndTime)
          .add(const Duration(hours: 12));
      return DateTime.now().isAfter(endTime);
    }

    // Slow path: fetch from Firestore
    try {
      final doc = await _firestore
          .collection(FirestorePaths.events)
          .doc(eventId)
          .get();
      if (!doc.exists) return true;

      final data = doc.data();
      if (data == null) return true;
      final dataMap = data;

      final sessions = dataMap['sessions'] as List<dynamic>? ?? [];
      if (sessions.isEmpty) return true;

      DateTime? latestEndTime;
      for (final session in sessions) {
        final dateStr = (session as Map<String, dynamic>)['date'] as String?;
        final endTimeStr = session['endTime'] as String?;
        if (dateStr != null && endTimeStr != null) {
          try {
            final dt = DateTime.parse('${dateStr}T$endTimeStr:00');
            if (latestEndTime == null || dt.isAfter(latestEndTime)) {
              latestEndTime = dt;
            }
          } catch (_) {}
        }
      }

      return latestEndTime != null
          ? DateTime.now().isAfter(latestEndTime.add(const Duration(hours: 12)))
          : false;
    } catch (_) {
      return false;
    }
  }

  /// Deletes all locally cached assignments whose events have ended.
  ///
  /// Should be called after each Firestore stream emission to keep the local
  /// cache clean. Calls `EventCleanupService.purgeEventData()` for each
  /// expired event once that service is implemented.
  Future<void> removeExpiredAssignments() async {
    final assignments = await _scannerDao.getAllAssignments();

    for (final assignment in assignments) {
      final hasEnded = await isEventEnded(assignment.eventId);
      if (hasEnded) {
        await _scannerDao.deleteAssignment(assignment.eventId);
        // TODO: EventCleanupService.purgeEventData(assignment.eventId)
        // — deletes cached_participants and offline_attendance rows for this event
      }
    }
  }
}
