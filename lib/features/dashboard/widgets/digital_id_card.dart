import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class DigitalIdCard extends StatelessWidget {
  const DigitalIdCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Yellow bottom strip
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 12,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'YOUR DIGITAL ID',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 40,
                        height: 2,
                        color: AppColors.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Juan M. dela Cruz',
                        style: AppTextStyles.h2.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '2023-0001',
                        style: AppTextStyles.h2.copyWith(
                          color: AppColors.secondary,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'BSIT - BSIT-2A',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              'ACTIVE',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                // QR Code placeholder
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_2, size: 48, color: AppColors.primaryDark),
                        const SizedBox(height: 4),
                        Text(
                          'Tap to scan',
                          style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 10,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
