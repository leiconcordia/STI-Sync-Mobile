import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class PaymentOverviewCard extends ConsumerWidget {
  const PaymentOverviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(payablesSummaryProvider);

    final String nextDueText;
    if (summary.nextDue != null) {
      final due = summary.nextDue!;
      final dueDateStr = due.dueDate != null ? ' by ${DateFormat('MMM dd').format(due.dueDate!)}' : '';
      nextDueText = 'Next due: ${due.label} — ₱${due.remainingBalance.toStringAsFixed(0)}$dueDateStr';
    } else {
      nextDueText = 'All clear! No upcoming pending dues.';
    }

    final double widthFactor = summary.paidPercentage.clamp(0.0, 1.0);
    final int percentInt = (widthFactor * 100).round();

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
                    const Icon(Icons.account_balance_wallet_outlined, color: Colors.white70, size: 18),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildColumn('Total Dues', '₱${summary.totalAssigned.toStringAsFixed(0)}', Colors.white),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildColumn('Paid', '₱${summary.totalPaid.toStringAsFixed(0)}', AppColors.success),
                    Container(width: 1, height: 40, color: Colors.white24),
                    _buildColumn('Outstanding', '₱${summary.totalOutstanding.toStringAsFixed(0)}', AppColors.secondary),
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
                      widthFactor: widthFactor > 0 ? widthFactor : 0.0,
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
                    '$percentInt% paid this semester',
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
                    nextDueText,
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
          style: AppTextStyles.h1.copyWith(color: amountColor, fontSize: 22),
        ),
      ],
    );
  }
}
