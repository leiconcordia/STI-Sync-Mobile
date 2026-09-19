import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:drift/drift.dart' as drift;
import 'package:intl/intl.dart';
import '../../../shared/providers/providers.dart';
import '../../../core/local/app_database.dart';
import '../models/scanner_assignment_model.dart';
import '../widgets/scan_result_overlay.dart';

class ScannerCameraScreen extends ConsumerStatefulWidget {
  final String eventId;
  final String sessionId;
  final String gateType;

  const ScannerCameraScreen({
    super.key,
    required this.eventId,
    required this.sessionId,
    required this.gateType,
  });

  @override
  ConsumerState<ScannerCameraScreen> createState() => _ScannerCameraScreenState();
}

class _ScannerCameraScreenState extends ConsumerState<ScannerCameraScreen> {
  late MobileScannerController _cameraController;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: [BarcodeFormat.qrCode],
    );
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _processBarcode(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    
    final barcode = capture.barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null) return;

    setState(() => _isProcessing = true);

    try {
      final payload = jsonDecode(rawValue) as Map<String, dynamic>;
      final qrEventId = payload['eventId'] as String?;
      final studentAuthUid = payload['studentAuthUid'] as String?;
      // final qrStudentId = payload['studentId'] as String?; // Human readable ID

      if (qrEventId == null || studentAuthUid == null) {
        throw const FormatException('Invalid QR payload');
      }

      // VALIDATION 1: Event ID check
      if (qrEventId.trim() != widget.eventId.trim()) {
        await _showOverlay(
          ScanResultType.wrongEvent, 
          null, 
          extraMessage: 'QR Event ID: "${qrEventId.trim()}"\nExpected: "${widget.eventId.trim()}"',
        );
        return;
      }

      // VALIDATION 2: Event Cancellation Check
      final scannerState = ref.read(scannerViewModelProvider);
      final assignment = scannerState.assignments.firstWhere(
        (a) => a.eventId == widget.eventId,
        orElse: () => ScannerAssignmentModel(
          eventId: widget.eventId,
          eventTitle: '',
          eventFormat: '',
          sessions: const [],
          officerUserId: '',
          permissions: const {},
          eventEndTime: DateTime.now(),
          proposalStatus: 'approved',
        ),
      );

      if (assignment.isEffectivelyCancelled) {
        await _showOverlay(
          ScanResultType.eventCancelled,
          null,
          extraMessage: assignment.cancellationReason != null && assignment.cancellationReason!.isNotEmpty
              ? 'Event cancelled: ${assignment.cancellationReason}'
              : 'Attendance scanning is voided because this event has been cancelled.',
        );
        return;
      }

      // VALIDATION 3: Attendance Window & Timing Validation
      final session = assignment.sessions.firstWhere(
        (s) => s['id'] == widget.sessionId,
        orElse: () => <String, dynamic>{},
      );

      final dateStr = session['date'] as String?;
      final startTimeStr = (session['startTime'] as String?) ?? (session['timeInOpen'] as String?);
      final timeInOpenStr = (session['timeInOpen'] as String?) ?? (session['startTime'] as String?);
      final timeInCloseStr = session['timeInClose'] as String?;
      final timeOutOpenStr = session['timeOutOpen'] as String?;
      final timeOutCloseStr = session['timeOutClose'] as String?;

      final gracePeriod = (session['gracePeriodMinutes'] as num?)?.toInt() ?? assignment.gracePeriodMinutes ?? 15;
      final lateThreshold = (session['lateThresholdMinutes'] as num?)?.toInt() ?? assignment.lateThresholdMinutes ?? 60;

      final now = DateTime.now().millisecondsSinceEpoch;
      final scanTime = DateTime.fromMillisecondsSinceEpoch(now);

      final sessionStart = _parseSessionStart(dateStr, startTimeStr);
      final timeInOpen = _parseSessionStart(dateStr, timeInOpenStr);
      final timeInClose = _parseSessionStart(dateStr, timeInCloseStr);
      final timeOutOpen = _parseSessionStart(dateStr, timeOutOpenStr);
      final timeOutClose = _parseSessionStart(dateStr, timeOutCloseStr);

      String scanStatus = 'Present';

      if (widget.gateType == 'Time-In') {
        // Window check: Before Time-In Opens
        if (timeInOpen != null && scanTime.isBefore(timeInOpen)) {
          await _showOverlay(
            ScanResultType.windowNotOpen,
            null,
            extraMessage: 'Time-In is not open yet.\nOpens at: $timeInOpenStr',
          );
          return;
        }

        // Window check: After Time-In Closes / Late Threshold Ends
        final lateThresholdEnd = timeInClose ?? sessionStart?.add(Duration(minutes: lateThreshold));
        if (lateThresholdEnd != null && scanTime.isAfter(lateThresholdEnd)) {
          final closeTimeDisplay = timeInCloseStr ?? DateFormat('h:mm a').format(lateThresholdEnd);
          await _showOverlay(
            ScanResultType.windowClosed,
            null,
            extraMessage: 'Time-In window has closed.\nClosed at: $closeTimeDisplay',
          );
          return;
        }

        // Grace Period Evaluation:
        // Grace period threshold = sessionStart + gracePeriod (e.g. 7:30 AM + 15m = 7:45 AM)
        final graceThreshold = sessionStart?.add(Duration(minutes: gracePeriod)) ??
            timeInOpen?.add(Duration(minutes: gracePeriod));

        if (graceThreshold != null && scanTime.isAfter(graceThreshold)) {
          scanStatus = 'Late';
        } else {
          scanStatus = 'Present';
        }
      } else if (widget.gateType == 'Time-Out') {
        // Window check: Before Time-Out Opens
        if (timeOutOpen != null && scanTime.isBefore(timeOutOpen)) {
          await _showOverlay(
            ScanResultType.windowNotOpen,
            null,
            extraMessage: 'Time-Out is not open yet.\nOpens at: $timeOutOpenStr',
          );
          return;
        }

        // Window check: After Time-Out Closes
        if (timeOutClose != null && scanTime.isAfter(timeOutClose)) {
          await _showOverlay(
            ScanResultType.windowClosed,
            null,
            extraMessage: 'Time-Out window has closed.\nClosed at: $timeOutCloseStr',
          );
          return;
        }

        scanStatus = 'Present';
      }

      final db = ref.read(appDatabaseProvider);

      // VALIDATION 3: Participant check (Drift local database)
      final participant = await db.participantsDao.getParticipantByStudentId(
        studentAuthUid,
        widget.eventId,
      );

      if (participant == null) {
        await _showOverlay(
          ScanResultType.notRegistered,
          null,
          extraMessage: 'Student is not registered for this event.',
        );
        return;
      }

      // VALIDATION 4: Duplicate check
      final existing = await db.attendanceDao.checkDuplicate(
        studentId: studentAuthUid,
        studentNumber: participant.studentNumber,
        eventId: widget.eventId,
        sessionId: widget.sessionId,
        gateType: widget.gateType,
      );

      if (existing != null) {
        if (!mounted) return;
        final timeStr = TimeOfDay.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(existing.scannedAt),
        ).format(context);
        
        await _showOverlay(
          ScanResultType.duplicate,
          participant,
          extraMessage: 'Already scanned for ${widget.gateType} at $timeStr.',
        );
        return;
      }

      // SUCCESS: Write to local database
      final currentUserId = ref.read(authViewModelProvider).student?.id ?? 'Unknown';
      final localId = '${studentAuthUid}_${widget.sessionId}_${widget.gateType}_$now';

      final record = OfflineAttendanceCompanion(
        localId: drift.Value(localId),
        eventId: drift.Value(widget.eventId),
        sessionId: drift.Value(widget.sessionId),
        studentId: drift.Value(studentAuthUid),
        studentName: drift.Value(participant.studentName),
        gateType: drift.Value(widget.gateType),
        scanMethod: const drift.Value('QR'),
        scannedBy: drift.Value(currentUserId),
        scannedAt: drift.Value(now),
        synced: const drift.Value(0),
        conflictResolved: const drift.Value(0),
        status: drift.Value(scanStatus),
      );

      await db.attendanceDao.insertOfflineRecord(record);
      await _showOverlay(
        ScanResultType.success, 
        participant,
        status: scanStatus,
      );

    } catch (e) {
      debugPrint('QR Processing Error: $e');
      await _showOverlay(ScanResultType.invalidFormat, null, extraMessage: 'Invalid QR Code format.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showOverlay(
    ScanResultType type, 
    CachedParticipant? participant, {
    String? extraMessage,
    String? status,
  }) async {
    _cameraController.stop(); // Temporarily stop camera

    if (!mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      builder: (context) => ScanResultOverlay(
        type: type,
        participant: participant,
        extraMessage: extraMessage,
        gateType: widget.gateType,
        status: status,
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );

    if (mounted) {
      _cameraController.start(); // Resume scanning
    }
  }

  @override
  Widget build(BuildContext context) {
    final scannerState = ref.watch(scannerViewModelProvider);
    final assignment = scannerState.assignments.firstWhere(
      (a) => a.eventId == widget.eventId,
      orElse: () => ScannerAssignmentModel(
        eventId: widget.eventId,
        eventTitle: '',
        eventFormat: '',
        sessions: const [],
        officerUserId: '',
        permissions: const {},
        eventEndTime: DateTime.now(),
        proposalStatus: 'approved',
      ),
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            controller: _cameraController,
            onDetect: _processBarcode,
          ),
          
          // Camera Overlay UI
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                widget.gateType == 'Time-Out' ? Icons.logout : Icons.login,
                                color: widget.gateType == 'Time-Out' ? AppColors.error : AppColors.success,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${widget.gateType} SCANNER',
                                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.flash_off, color: Colors.white),
                          onPressed: () => _cameraController.toggleTorch(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (assignment.isEffectivelyCancelled)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade900.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade400),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'EVENT CANCELLED — SCANNING VOIDED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                assignment.cancellationReason != null && assignment.cancellationReason!.isNotEmpty
                                    ? assignment.cancellationReason!
                                    : 'Scanning is disabled because this event has been cancelled.',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                
                const Spacer(),
                
                // Target Box
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.secondary, width: 3),
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                
                const Spacer(),
                
                // Bottom Instructions
                Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.qr_code_scanner, color: Colors.white70),
                      const SizedBox(width: 12),
                      Text(
                        'Align QR Code within frame',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          if (_isProcessing)
            Container(
              color: Colors.black45,
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.secondary),
              ),
            ),
        ],
      ),
    );
  }

  DateTime? _parseSessionStart(String? dateStr, String? timeStr) {
    if (dateStr == null || timeStr == null || timeStr.trim().isEmpty) return null;
    try {
      final cleanTime = timeStr.trim();
      final cleanDate = dateStr.trim();
      if (cleanTime.toUpperCase().contains('AM') || cleanTime.toUpperCase().contains('PM')) {
        final format = DateFormat('yyyy-MM-dd h:mm a');
        return format.parse('$cleanDate $cleanTime', true).toLocal();
      } else {
        final parts = cleanTime.split(':');
        final hour = int.parse(parts[0]);
        final minute = int.parse(parts[1]);
        final dateParts = cleanDate.split('-');
        final year = int.parse(dateParts[0]);
        final month = int.parse(dateParts[1]);
        final day = int.parse(dateParts[2]);
        return DateTime(year, month, day, hour, minute);
      }
    } catch (e) {
      debugPrint('Error parsing session date/time ($dateStr $timeStr): $e');
      return null;
    }
  }
}
