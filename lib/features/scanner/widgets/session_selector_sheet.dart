import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import '../models/scanner_assignment_model.dart';
import '../utils/session_timing_evaluator.dart';
import '../../../core/utils/date_formatter.dart';

class SessionSelectorSheet extends StatefulWidget {
  final ScannerAssignmentModel assignment;
  final Function(String sessionId, String gateType) onStartScanning;

  const SessionSelectorSheet({
    super.key,
    required this.assignment,
    required this.onStartScanning,
  });

  @override
  State<SessionSelectorSheet> createState() => _SessionSelectorSheetState();
}

class _SessionSelectorSheetState extends State<SessionSelectorSheet> {
  String? _selectedSessionId;
  String? _selectedGateType;

  @override
  void initState() {
    super.initState();
    // Auto-select session if only one exists
    if (widget.assignment.sessions.length == 1) {
      _selectedSessionId = widget.assignment.sessions.first['id'] as String?;
    }
  }

  void _showLockoutReason(String reason) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(reason)),
          ],
        ),
        backgroundColor: AppColors.primaryDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.assignment.permissions;
    final hasCheckInPermission = permissions['canCheckIn'] == true;
    final hasCheckOutPermission = permissions['canCheckOut'] == true;

    // Retrieve currently selected session map
    Map<String, dynamic> selectedSession = {};
    if (_selectedSessionId != null) {
      selectedSession = widget.assignment.sessions.firstWhere(
        (s) => s['id'] == _selectedSessionId,
        orElse: () => {},
      );
    } else if (widget.assignment.sessions.isNotEmpty) {
      selectedSession = widget.assignment.sessions.first;
    }

    final bool sessionHasTimeOut = selectedSession['hasTimeOut'] == true;

    // Timing evaluations
    final timeInTiming = SessionTimingEvaluator.evaluateTimeIn(
      selectedSession,
      fallbackGrace: widget.assignment.gracePeriodMinutes,
      fallbackLateThreshold: widget.assignment.lateThresholdMinutes,
    );

    final timeOutTiming = SessionTimingEvaluator.evaluateTimeOut(
      selectedSession,
      fallbackLateThreshold: widget.assignment.lateThresholdMinutes,
    );

    // Gate availability conditions
    final bool isTimeInAllowed = hasCheckInPermission && timeInTiming.isOpen;
    final bool isTimeOutAllowed =
        hasCheckOutPermission && sessionHasTimeOut && timeOutTiming.isOpen;

    // Determine subtitle & lockout reasons for Time-In
    final String timeInSubtitle;
    final String timeInLockoutReason;
    final Color timeInColor;

    if (!hasCheckInPermission) {
      timeInSubtitle = 'No Permission';
      timeInLockoutReason = 'You do not have permission to scan Time-In.';
      timeInColor = Colors.grey;
    } else if (timeInTiming.isNotStarted) {
      timeInSubtitle = timeInTiming.message;
      timeInLockoutReason = 'Time-In has not started yet. ${timeInTiming.message}.';
      timeInColor = Colors.amber.shade800;
    } else if (timeInTiming.isClosed) {
      timeInSubtitle = timeInTiming.message;
      timeInLockoutReason = 'Time-In window has ended. ${timeInTiming.message}.';
      timeInColor = AppColors.error;
    } else {
      timeInSubtitle = timeInTiming.attendanceStatus == 'Late'
          ? 'Late Threshold'
          : 'Open (On-Time)';
      timeInLockoutReason = '';
      timeInColor = timeInTiming.attendanceStatus == 'Late'
          ? Colors.orange.shade800
          : AppColors.success;
    }

    // Determine subtitle & lockout reasons for Time-Out
    final String timeOutSubtitle;
    final String timeOutLockoutReason;
    final Color timeOutColor;

    if (!sessionHasTimeOut) {
      timeOutSubtitle = 'Not Configured';
      timeOutLockoutReason = 'This session does not require a Time-Out scan.';
      timeOutColor = Colors.grey;
    } else if (!hasCheckOutPermission) {
      timeOutSubtitle = 'No Permission';
      timeOutLockoutReason = 'You do not have permission to scan Time-Out.';
      timeOutColor = Colors.grey;
    } else if (timeOutTiming.isNotStarted) {
      timeOutSubtitle = timeOutTiming.message;
      timeOutLockoutReason = 'Time-Out has not started yet. ${timeOutTiming.message}.';
      timeOutColor = Colors.amber.shade800;
    } else if (timeOutTiming.isClosed) {
      timeOutSubtitle = timeOutTiming.message;
      timeOutLockoutReason = 'Time-Out window has ended. ${timeOutTiming.message}.';
      timeOutColor = AppColors.error;
    } else {
      timeOutSubtitle = 'Open';
      timeOutLockoutReason = '';
      timeOutColor = AppColors.success;
    }

    // Auto-select valid gate if selected is no longer valid
    if (_selectedGateType == 'Time-In' && !isTimeInAllowed) {
      _selectedGateType = isTimeOutAllowed ? 'Time-Out' : null;
    } else if (_selectedGateType == 'Time-Out' && !isTimeOutAllowed) {
      _selectedGateType = isTimeInAllowed ? 'Time-In' : null;
    } else if (_selectedGateType == null) {
      if (isTimeInAllowed && !isTimeOutAllowed) {
        _selectedGateType = 'Time-In';
      } else if (!isTimeInAllowed && isTimeOutAllowed) {
        _selectedGateType = 'Time-Out';
      }
    }

    final activeGateType = _selectedGateType;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Configure Scanner',
                style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 20),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Select Session',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          if (widget.assignment.sessions.isEmpty)
            Text('No sessions available', style: TextStyle(color: Colors.grey.shade500))
          else
            ...widget.assignment.sessions.asMap().entries.map((entry) {
              final index = entry.key;
              final session = entry.value;
              final id = session['id'] as String?;
              final rawTitle = (session['title'] ??
                      session['sessionTitle'] ??
                      session['name'] ??
                      session['sessionName'] ??
                      session['label']) as String?;
              final name = (rawTitle != null && rawTitle.trim().isNotEmpty)
                  ? rawTitle.trim()
                  : 'Session ${index + 1}';
              final date = session['date'] as String? ?? '';
              final startTime = session['startTime'] as String? ?? '';
              final endTime = session['endTime'] as String? ?? '';
              final formattedDate = formatAppDate(date, fallback: date);
              final formattedStart = formatAppTime(startTime, fallback: startTime);
              final formattedEnd = formatAppTime(endTime, fallback: endTime);
              final timeDisplay = (formattedStart.isNotEmpty && formattedEnd.isNotEmpty)
                  ? '$formattedStart - $formattedEnd'
                  : (formattedStart.isNotEmpty ? formattedStart : formattedEnd);
              final isSelected = _selectedSessionId == id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedSessionId = id;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? AppColors.secondary.withValues(alpha: 0.1) : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                          color: isSelected ? AppColors.secondary : Colors.grey.shade400,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                timeDisplay.isNotEmpty
                                    ? '$formattedDate • $timeDisplay'
                                    : formattedDate,
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

          const SizedBox(height: 20),
          Text(
            'Gate Type',
            style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _GateTypeButton(
                  title: 'Time-In',
                  subtitle: timeInSubtitle,
                  subtitleColor: timeInColor,
                  icon: Icons.login,
                  isSelected: activeGateType == 'Time-In',
                  isEnabled: isTimeInAllowed,
                  onTap: () => setState(() => _selectedGateType = 'Time-In'),
                  onDisabledTap: () => _showLockoutReason(timeInLockoutReason),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GateTypeButton(
                  title: 'Time-Out',
                  subtitle: timeOutSubtitle,
                  subtitleColor: timeOutColor,
                  icon: Icons.logout,
                  isSelected: activeGateType == 'Time-Out',
                  isEnabled: isTimeOutAllowed,
                  onTap: () => setState(() => _selectedGateType = 'Time-Out'),
                  onDisabledTap: () => _showLockoutReason(timeOutLockoutReason),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_selectedSessionId != null && activeGateType != null)
                  ? () {
                      Navigator.of(context).pop();
                      widget.onStartScanning(_selectedSessionId!, activeGateType);
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Start Scanning',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _GateTypeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;
  final VoidCallback onDisabledTap;

  const _GateTypeButton({
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
    required this.onDisabledTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isEnabled ? onTap : onDisabledTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? AppColors.secondary
                : (isEnabled ? Colors.grey.shade300 : Colors.grey.shade200),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? AppColors.secondary.withValues(alpha: 0.1)
              : (isEnabled ? Colors.transparent : Colors.grey.shade50),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.secondary
                  : (isEnabled ? AppColors.primaryDark : Colors.grey.shade400),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected
                    ? AppColors.secondary
                    : (isEnabled ? AppColors.primaryDark : Colors.grey.shade500),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: subtitleColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
