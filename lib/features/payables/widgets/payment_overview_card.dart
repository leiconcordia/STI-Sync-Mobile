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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryDark,
            AppColors.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(22.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'FINANCIAL OVERVIEW',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
                    ),
                    if (summary.pendingCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${summary.pendingCount} Pending',
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'All Settled ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildColumn('Total Dues', '₱${summary.totalAssigned.toStringAsFixed(0)}', Colors.white),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
                    _buildColumn('Total Paid', '₱${summary.totalPaid.toStringAsFixed(0)}', const Color(0xFF4ADE80)),
                    Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2)),
                    _buildColumn('Outstanding', '₱${summary.totalOutstanding.toStringAsFixed(0)}', AppColors.secondary),
                  ],
                ),
                const SizedBox(height: 20),
                Stack(
                  children: [
                    Container(
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: widthFactor > 0 ? widthFactor : 0.0,
                      child: Container(
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF34D399), Color(0xFF10B981)],
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      summary.overdueCount > 0 ? '${summary.overdueCount} overdue obligation' : 'Semester Progress',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: summary.overdueCount > 0 ? Colors.red.shade300 : Colors.white.withValues(alpha: 0.7),
                        fontWeight: summary.overdueCount > 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      '$percentInt% Settled',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule_outlined, color: Colors.white70, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    nextDueText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: AppTextStyles.h2.copyWith(
            color: amountColor,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

