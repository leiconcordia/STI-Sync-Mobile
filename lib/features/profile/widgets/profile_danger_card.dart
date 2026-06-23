import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';

class ProfileDangerCard extends StatelessWidget {
  final VoidCallback onLogOut;
  final VoidCallback onDeactivate;

  const ProfileDangerCard({
    super.key,
    required this.onLogOut,
    required this.onDeactivate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFCDD2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Account',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                Icon(Icons.error_outline, color: AppColors.error, size: 20),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFFFEBEE)),
          _DangerRow(
            icon: Icons.logout,
            label: 'Log Out',
            onTap: onLogOut,
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFFFEBEE)),
          _DangerRow(
            icon: Icons.person_off_outlined,
            label: 'Request Account Deactivation',
            onTap: onDeactivate,
          ),
        ],
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DangerRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.5)),
              ),
              child: Icon(icon, color: AppColors.error, size: 18),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
