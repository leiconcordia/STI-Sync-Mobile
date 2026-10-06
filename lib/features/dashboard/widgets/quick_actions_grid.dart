import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class QuickActionsGrid extends StatelessWidget {
  const QuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionItem(
          context,
          icon: Icons.qr_code_scanner,
          label: 'My QR',
          iconColor: Colors.blue,
          onTap: () => context.go('/events'),
        ),
        _buildActionItem(
          context,
          icon: Icons.calendar_month,
          label: 'Events',
          iconColor: AppColors.primaryDark,
          onTap: () => context.go('/events'),
        ),
        _buildActionItem(
          context,
          icon: Icons.receipt_long,
          label: 'Finance',
          iconColor: Colors.orange,
          onTap: () => context.go('/payables'),
        ),
        _buildActionItem(
          context,
          icon: Icons.workspace_premium,
          label: 'Certificates',
          iconColor: const Color(0xFFE5A100),
          onTap: () => context.push('/certificates'),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
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
                  color: Colors.black.withValues(alpha: 0.02),
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
      ),
    );
  }
}

