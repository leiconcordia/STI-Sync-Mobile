import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import '../../../core/local/app_database.dart';

enum ScanResultType {
  success,
  duplicate,
  notRegistered,
  wrongEvent,
  paymentRequired,
  invalidFormat,
}

class ScanResultOverlay extends StatefulWidget {
  final ScanResultType type;
  final CachedParticipant? participant;
  final String? extraMessage;
  final VoidCallback onDismiss;
  final String? gateType; // 'Time-In' or 'Time-Out'

  const ScanResultOverlay({
    super.key,
    required this.type,
    required this.onDismiss,
    this.participant,
    this.extraMessage,
    this.gateType,
  });

  @override
  State<ScanResultOverlay> createState() => _ScanResultOverlayState();
}

class _ScanResultOverlayState extends State<ScanResultOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    
    _progressController.reverse(from: 1.0).then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    IconData icon;
    String title;
    String subtitle;

    switch (widget.type) {
      case ScanResultType.success:
        bgColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        title = widget.gateType == 'Time-Out' ? 'CHECKED OUT ✓' : 'CHECKED IN ✓';
        subtitle = 'Successfully recorded';
        break;
      case ScanResultType.duplicate:
        bgColor = Colors.amber.shade800;
        icon = Icons.warning_amber_rounded;
        title = 'Duplicate Scan';
        subtitle = widget.extraMessage ?? 'Already scanned for this session.';
        break;
      case ScanResultType.paymentRequired:
        bgColor = AppColors.primaryDark; // Dark navy
        icon = Icons.lock_outline;
        title = 'Payment Required';
        subtitle = widget.extraMessage ?? 'QR ticket is locked due to unpaid fees.';
        break;
      case ScanResultType.wrongEvent:
        bgColor = Colors.red;
        icon = Icons.error_outline;
        title = 'Wrong Event!';
        subtitle = widget.extraMessage ?? 'This QR ticket is for a different event.';
        break;
      case ScanResultType.notRegistered:
        bgColor = Colors.deepOrange.shade600;
        icon = Icons.person_off_outlined;
        title = 'Not Registered';
        subtitle = 'Student is not registered for this event.';
        break;
      case ScanResultType.invalidFormat:
        bgColor = Colors.red;
        icon = Icons.qr_code_scanner;
        title = 'Invalid QR Code!';
        subtitle = widget.extraMessage ?? 'The scanned QR code is not recognized.';
        break;
    }

    return GestureDetector(
      onTap: widget.onDismiss,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: bgColor.withOpacity(0.95),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Icon(icon, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.h1.copyWith(color: Colors.white, fontSize: 28),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  subtitle,
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
              ),
              if (widget.participant != null) ...[
                const SizedBox(height: 48),
                Container(
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppColors.background,
                        backgroundImage: widget.participant!.profilePhotoUrl != null &&
                                widget.participant!.profilePhotoUrl!.isNotEmpty
                            ? NetworkImage(widget.participant!.profilePhotoUrl!)
                            : null,
                        child: widget.participant!.profilePhotoUrl == null ||
                                widget.participant!.profilePhotoUrl!.isEmpty
                            ? const Icon(Icons.person, size: 40, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.participant!.studentName,
                        style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.participant!.studentNumber} • ${widget.participant!.course} ${widget.participant!.yearLevel}',
                        style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
              const Spacer(),
              AnimatedBuilder(
                animation: _progressController,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _progressController.value,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.amber),
                    minHeight: 6,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
