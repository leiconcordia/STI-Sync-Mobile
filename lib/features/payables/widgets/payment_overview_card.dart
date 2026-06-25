import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class PaymentOverviewCard extends StatelessWidget {
  const PaymentOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PAYMENT OVERVIEW',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const Icon(Icons.edit_outlined, color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildColumn('Total Dues', '₱800', Colors.white),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildColumn('Paid', '₱650', AppColors.success),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildColumn('Outstanding', '₱150', AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 24),
                Stack(
                  children: [
                    Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.81,
                      child: Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '81% paid this semester',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Next due: Event Fee — ₱150 by Jun 15',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(String label, String amount, Color amountColor) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: Colors.white70),
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: AppTextStyles.h1.copyWith(color: amountColor, fontSize: 24),
        ),
      ],
    );
  }
}
