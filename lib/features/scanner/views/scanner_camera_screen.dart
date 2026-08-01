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
      if (qrEventId?.trim() != widget.eventId.trim()) {
        await _showOverlay(
          ScanResultType.wrongEvent, 
          null, 
          extraMessage: 'QR Event ID: "${qrEventId?.trim()}"\nExpected: "${widget.eventId.trim()}"',
        );
        return;
      }

      final db = ref.read(appDatabaseProvider);

      // VALIDATION 2: Participant check (Drift)
      // Note: `id` in cached_participants is the studentAuthUid
      final participant = await db.participantsDao.getParticipantByStudentId(
        studentAuthUid,
        widget.eventId,
      );

      if (participant == null) {
        await _showOverlay(ScanResultType.notRegistered, null);
        return;
      }

      // VALIDATION 2b: Gate Lock Check (MOB-GATE-02)
      if (participant.qrTicketUnlocked == 0) {
        await _showOverlay(
          ScanResultType.paymentRequired,
          participant,
          extraMessage: 'GATE ACCESS DENIED\nUnpaid Event Fee / QR Code Locked',
        );
        return;
      }


      // VALIDATION 3: Duplicate check
      final existing = await db.attendanceDao.checkDuplicate(
        studentId: studentAuthUid,
        studentNumber: participant.studentNumber,
        eventId: widget.eventId,
        sessionId: widget.sessionId,
        gateType: widget.gateType,
      );

      if (existing != null) {
        // Find the friendly time string for the error message
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
      
      // Generate a unique local ID
      final now = DateTime.now().millisecondsSinceEpoch;
      final localId = '${studentAuthUid}_${widget.sessionId}_${widget.gateType}_$now';

      // Evaluate Late Status
      String scanStatus = 'Present';
      
      if (widget.gateType == 'Time-In') {
        try {
          final scannerState = ref.read(scannerViewModelProvider);
          final assignment = scannerState.assignments.firstWhere(
            (a) => a.eventId == widget.eventId,
          );
          
          final session = assignment.sessions.firstWhere(
            (s) => s['id'] == widget.sessionId,
            orElse: () => {},
          );
          
          final timeInOpenStr = (session['timeInOpen'] as String?) ?? (session['startTime'] as String?);
          final dateStr = session['date'] as String?;
          final gracePeriod = assignment.gracePeriodMinutes ?? (session['gracePeriodMinutes'] as num?)?.toInt() ?? 0;
          
          final sessionStart = _parseSessionStart(dateStr, timeInOpenStr);
          if (sessionStart != null) {
            final lateThreshold = sessionStart.add(Duration(minutes: gracePeriod));
            final scanTime = DateTime.fromMillisecondsSinceEpoch(now);
            
            if (scanTime.isAfter(lateThreshold)) {
              scanStatus = 'Late';
            }
          }
        } catch (e) {
          debugPrint('Failed to calculate Late status: $e');
        }
      }

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
      await _showOverlay(ScanResultType.success, participant);

    } catch (e) {
      debugPrint('QR Processing Error: $e');
      await _showOverlay(ScanResultType.invalidFormat, null, extraMessage: 'Invalid QR Code format.');
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showOverlay(ScanResultType type, CachedParticipant? participant, {String? extraMessage}) async {
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
        onDismiss: () => Navigator.of(context).pop(),
      ),
    );

    if (mounted) {
      _cameraController.start(); // Resume scanning
    }
  }

  @override
  Widget build(BuildContext context) {
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
