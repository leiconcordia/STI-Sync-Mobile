import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../../core/local/daos/attendance_dao.dart';
import '../../../core/local/daos/participants_dao.dart';
import '../../../core/constants/firestore_paths.dart';
import '../models/sync_status_model.dart';
import '../../auth/models/student_model.dart';
import 'connectivity_service.dart';

/// Handles uploading pending offline attendance records to Firestore.
///
/// Before uploading, checks for duplicate records in Firestore and surfaces
/// conflicts for the user to resolve. Flagged records are routed to
/// `/flagged_attendance` instead of `/attendance`.
class SyncService {
  final FirebaseFirestore _firestore;
  final AttendanceDao _attendanceDao;
  final ParticipantsDao _participantsDao;
  final ConnectivityService _connectivityService;
  final StudentModel? Function() _getCurrentStudent;
  StreamSubscription<bool>? _connectivitySubscription;

  SyncService({
    required FirebaseFirestore firestore,
    required AttendanceDao attendanceDao,
    required ParticipantsDao participantsDao,
    required ConnectivityService connectivityService,
    required StudentModel? Function() getCurrentStudent,
  })  : _firestore = firestore,
        _attendanceDao = attendanceDao,
        _participantsDao = participantsDao,
        _connectivityService = connectivityService,
        _getCurrentStudent = getCurrentStudent;

  /// Auto-sync disabled — sync is strictly manual via Sync button in ScannerLogsScreen.
  void startAutoSync() {
    _connectivitySubscription?.cancel();
  }

  /// Uploads all pending (unsynced) offline attendance records to Firestore.
  ///
  /// Steps:
  /// 1. Fetch all pending records from Drift
  /// 2. For each, check Firestore for duplicates
  /// 3. If conflicts → return [SyncResult.hasConflicts]
  /// 4. If no conflicts → batch write, mark synced, return [SyncResult.success]
  Future<SyncResult> uploadPendingAttendance() async {
    try {
      if (!_connectivityService.isOnline) {
        return SyncResult.error('No internet connection');
      }

      final pending = await _attendanceDao.getPendingSyncs();
      if (pending.isEmpty) {
        return SyncResult.success(0);
      }

      debugPrint('SyncService: ${pending.length} pending records to sync');

      final List<SyncConflict> conflicts = [];
      final List<dynamic> uploadList = []; // OfflineAttendanceData items

      // Check each record for Firestore duplicates across both subcollections (normal and flagged)
      // and checking both Auth UID and 11-digit Student Number.
      for (final record in pending) {
        String? studentNumber;
        if (record.studentId.isNotEmpty) {
          final participant = await _participantsDao.getParticipantByStudentId(
            record.studentId,
            record.eventId,
          );
          studentNumber = participant?.studentNumber;
        }

        final dupDoc = await _findFirestoreDuplicate(
          eventId: record.eventId,
          sessionId: record.sessionId,
          studentId: record.studentId,
          studentNumber: studentNumber,
          gateType: record.gateType,
        );

        if (dupDoc != null) {
          conflicts.add(SyncConflict(
            localRecord: record,
            firestoreRecord: dupDoc.data(),
            firestoreDocId: dupDoc.id,
          ));
        } else {
          uploadList.add(record);
        }
      }

      // If conflicts exist, surface them before uploading anything
      if (conflicts.isNotEmpty) {
        debugPrint('SyncService: ${conflicts.length} conflicts found');
        return SyncResult.hasConflicts(conflicts);
      }

      // No conflicts — batch upload
      int uploaded = 0;
      final batches = _chunk(uploadList, 500);

      for (final batch in batches) {
        final writeBatch = _firestore.batch();

        for (final record in batch) {
          final isFlagged = record.isFlagged == 1;
          final collection = isFlagged
              ? FirestorePaths.eventFlaggedAttendance(record.eventId)
              : FirestorePaths.eventAttendance(record.eventId);

          final docRef = _firestore.collection(collection).doc();

          if (isFlagged) {
            writeBatch.set(docRef, await _buildFlaggedMap(record));
          } else {
            writeBatch.set(docRef, await _buildAttendanceMap(record));
          }
        }

        await writeBatch.commit();

        // Mark each record as synced in Drift
        for (final record in batch) {
          await _attendanceDao.markSynced(record.localId);
          uploaded++;
        }
      }

      debugPrint('SyncService: Successfully uploaded $uploaded records');
      return SyncResult.success(uploaded);
    } catch (e) {
      debugPrint('SyncService: Upload failed: $e');
      return SyncResult.error('Sync failed: $e');
    }
  }

  /// Resolves a single conflict by either skipping or force-uploading.
  ///
  /// [skip]: marks the local record as synced without uploading (keeps existing Firestore doc).
  /// [forceUpload]: replaces the existing Firestore document with the local record.
  Future<void> resolveConflict(String localId, ConflictAction action, {String? firestoreDocId}) async {
    if (action == ConflictAction.skip) {
      await _attendanceDao.markSynced(localId);
      debugPrint('SyncService: Skipped conflict for $localId');
      return;
    }

    // Force upload — replace the existing Firestore document
    final records = await _attendanceDao.getPendingSyncs();
    final record = records.firstWhere(
      (r) => r.localId == localId,
      orElse: () => throw Exception('Record not found: $localId'),
    );

    final isFlagged = record.isFlagged == 1;
    final collection = isFlagged
        ? FirestorePaths.eventFlaggedAttendance(record.eventId)
        : FirestorePaths.eventAttendance(record.eventId);

    if (firestoreDocId != null && firestoreDocId.isNotEmpty) {
      // Replace the existing document
      final docRef = _firestore.collection(collection).doc(firestoreDocId);
      if (isFlagged) {
        await docRef.set(await _buildFlaggedMap(record));
      } else {
        await docRef.set(await _buildAttendanceMap(record));
      }
    } else {
      // No doc ID — create new
      final docRef = _firestore.collection(collection).doc();
      if (isFlagged) {
        await docRef.set(await _buildFlaggedMap(record));
      } else {
        await docRef.set(await _buildAttendanceMap(record));
      }
    }

    await _attendanceDao.markSynced(localId);
    debugPrint('SyncService: Force-uploaded conflict for $localId');
  }

  /// Resolves all pending conflicts with the same action.
  Future<void> resolveAllConflicts(
    List<SyncConflict> conflicts,
    ConflictAction action,
  ) async {
    for (final conflict in conflicts) {
      await resolveConflict(
        conflict.localRecord.localId,
        action,
        firestoreDocId: conflict.firestoreDocId,
      );
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Builds a Firestore map for a normal attendance record.
  Future<Map<String, dynamic>> _buildAttendanceMap(dynamic record) async {
    final currentStudent = _getCurrentStudent();
    String studentNumber = record.studentId;

    if (record.studentId.isNotEmpty) {
      final participant = await _participantsDao.getParticipantByStudentId(
        record.studentId,
        record.eventId,
      );
      if (participant != null && participant.studentNumber != null) {
        studentNumber = participant.studentNumber!;
      }
    }
    
    return {
      'eventId': record.eventId,
      'sessionId': record.sessionId,
      'studentId': studentNumber,
      'studentName': record.studentName,
      'gateType': record.gateType == 'Time-In' ? 'time_in' : 'time_out',
      'scanMethod': record.scanMethod.toString().toLowerCase(),
      'scannedBy': record.scannedBy,
      'scannedByName': currentStudent?.firstName ?? '', 
      'scannedAt': Timestamp.fromMillisecondsSinceEpoch(record.scannedAt),
      'status': record.status,
      'createdAt': FieldValue.serverTimestamp(),
      'serverTimestamp': FieldValue.serverTimestamp(),
      'localId': record.localId,
    };
  }

  /// Builds a Firestore map for a flagged attendance record.
  ///
  /// Enriches with student details from cached participants if available.
  Future<Map<String, dynamic>> _buildFlaggedMap(dynamic record) async {
    String? studentNumber;
    String? course;
    int? yearLevel;

    // Try to enrich from cached participants
    if (record.studentId.isNotEmpty) {
      final participant = await _participantsDao.getParticipantByStudentId(
        record.studentId,
        record.eventId,
      );
      if (participant != null) {
        studentNumber = participant.studentNumber;
        course = participant.course;
        yearLevel = participant.yearLevel;
      }
    }

    final currentStudent = _getCurrentStudent();

    return {
      'eventId': record.eventId,
      'sessionId': record.sessionId,
      'organizationId': '', // Optional, or can be populated if needed
      'studentId': studentNumber ?? (record.studentId.isEmpty ? null : record.studentId),
      'studentName': record.studentName,
      'studentNumber': studentNumber,
      'course': course,
      'yearLevel': yearLevel,
      'flagReason': record.flagReason,
      'flagNote': record.flagNote,
      'gateType': record.gateType == 'Time-In' ? 'time_in' : 'time_out',
      'flaggedBy': record.scannedBy,
      'flaggedByName': currentStudent?.firstName ?? '', 
      'scannedAt': Timestamp.fromMillisecondsSinceEpoch(record.scannedAt),
      'createdAt': FieldValue.serverTimestamp(),
      'localId': record.localId,
    };
  }

  /// Checks both /attendance and /flagged_attendance collections for any existing document
  /// matching eventId, gateType, and studentId (checking both Auth UID and Student Number).
  Future<QueryDocumentSnapshot<Map<String, dynamic>>?> _findFirestoreDuplicate({
    required String eventId,
    required String sessionId,
    required String studentId,
    String? studentNumber,
    required String gateType,
  }) async {
    final collections = [
      FirestorePaths.eventAttendance(eventId),
      FirestorePaths.eventFlaggedAttendance(eventId),
    ];

    final targetStudentIds = <String>{
      if (studentId.isNotEmpty) studentId,
      if (studentNumber != null && studentNumber.isNotEmpty) studentNumber,
    };

    if (targetStudentIds.isEmpty) return null;

    final isTimeIn = gateType == 'Time-In' || gateType == 'time_in';

    for (final collPath in collections) {
      for (final sId in targetStudentIds) {
        try {
          final snap = await _firestore
              .collection(collPath)
              .where('eventId', isEqualTo: eventId)
              .where('studentId', isEqualTo: sId)
              .get();

          for (final doc in snap.docs) {
            final data = doc.data();
            final docSessionId = data['sessionId'] as String? ?? '';
            final docGateType = data['gateType'] as String? ?? '';
            final isDocTimeIn = docGateType == 'time_in' || docGateType == 'Time-In';
            final isDocTimeOut = docGateType == 'time_out' || docGateType == 'Time-Out';

            final gateMatches = isTimeIn ? isDocTimeIn : isDocTimeOut;
            final sessionMatches = sessionId.isEmpty || docSessionId.isEmpty || docSessionId == sessionId;

            if (gateMatches && sessionMatches) {
              return doc;
            }
          }
        } catch (e) {
          debugPrint('SyncService: Error checking duplicates in $collPath for $sId: $e');
        }
      }
    }
    return null;
  }

  /// Splits a list into chunks of [size].
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  /// Cleans up subscriptions.
  void dispose() {
    _connectivitySubscription?.cancel();
  }
}
