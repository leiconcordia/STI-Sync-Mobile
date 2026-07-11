import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import '../models/scanner_assignment_model.dart';

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
    
    // Auto-select gate type if only one permission is granted
    final canCheckIn = widget.assignment.permissions['canCheckIn'] == true;
    final canCheckOut = widget.assignment.permissions['canCheckOut'] == true;
    
    if (canCheckIn && !canCheckOut) {
      _selectedGateType = 'Time-In';
    } else if (!canCheckIn && canCheckOut) {
      _selectedGateType = 'Time-Out';
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = widget.assignment.permissions;
    final canCheckIn = permissions['canCheckIn'] == true;
    
    // Evaluate if the currently selected session actually supports Time-Out
    bool sessionHasTimeOut = false;
    if (_selectedSessionId != null) {
      final selectedSession = widget.assignment.sessions.firstWhere(
        (s) => s['id'] == _selectedSessionId,
        orElse: () => {},
      );
      sessionHasTimeOut = selectedSession['hasTimeOut'] == true;
    }
    
    final canCheckOut = (permissions['canCheckOut'] == true) && sessionHasTimeOut;

    // If we have selected Time-Out but the session doesn't support it, reset it
    if (_selectedGateType == 'Time-Out' && !canCheckOut) {
      // Must schedule setState after build if we're mutating state inside build,
      // but since we're in build we can just act like it's null locally?
      // Better to just set the local variable to null for the UI, 
      // but tapping will reset the state anyway.
    }
    
    // Update local variable for UI
    final activeGateType = (!canCheckOut && _selectedGateType == 'Time-Out') ? null : _selectedGateType;

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
            ...widget.assignment.sessions.map((s) {
              final id = s['id'] as String? ?? '';
              final name = s['title'] as String? ?? 'Unnamed Session';
              final date = s['date'] as String? ?? '';
              final startTime = s['startTime'] as String? ?? '';
              final endTime = s['endTime'] as String? ?? '';
              final isSelected = _selectedSessionId == id;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedSessionId = id),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.secondary : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
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
                                '$date • $startTime - $endTime',
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
            }).toList(),
            
          const SizedBox(height: 24),
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
                  icon: Icons.login,
                  isSelected: activeGateType == 'Time-In',
                  isEnabled: canCheckIn,
                  onTap: () => setState(() => _selectedGateType = 'Time-In'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GateTypeButton(
                  title: 'Time-Out',
                  icon: Icons.logout,
                  isSelected: activeGateType == 'Time-Out',
                  isEnabled: canCheckOut,
                  onTap: () => setState(() => _selectedGateType = 'Time-Out'),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _GateTypeButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  const _GateTypeButton({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? AppColors.secondary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.secondary.withOpacity(0.1) : Colors.transparent,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.secondary : Colors.grey.shade500,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? AppColors.secondary : Colors.grey.shade600,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
