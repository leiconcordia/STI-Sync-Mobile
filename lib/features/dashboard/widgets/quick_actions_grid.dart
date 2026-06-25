import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(Icons.qr_code_scanner, 'My QR', Colors.blue),
        _buildActionItem(Icons.calendar_month, 'Events', AppColors.primaryDark),
        _buildActionItem(Icons.receipt_long, 'Finance', Colors.orange),
        _buildActionItem(Icons.military_tech, 'Awards', AppColors.success),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, Color iconColor) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(icon, size: 32, color: iconColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
