import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class HistoryListView extends ConsumerWidget {
  const HistoryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);

    return payablesAsync.when(
      data: (payables) {
        final paidHistory = payables.where((p) => p.paidAmount > 0 || p.isPaid).toList();

        if (paidHistory.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                const Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                const SizedBox(height: 12),
                Text(
                  'No Payment History',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your payment transactions and receipts will appear here once settled.',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Completed Payments & Receipts',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 16),
                ),
                Text(
                  '${paidHistory.length} record(s)',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...paidHistory.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildHistoryCard(item),
            )),
          ],
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, stack) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Failed to load history: $err',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(PayableModel item) {
    final dateStr = item.paidAt != null 
        ? DateFormat('MMM dd, yyyy').format(item.paidAt!) 
        : (item.createdAt != null ? DateFormat('MMM dd, yyyy').format(item.createdAt!) : 'Recorded');

    final bool isCampus = item.isCampusWide;
    final String orgName = item.organizationName?.isNotEmpty == true ? item.organizationName! : (isCampus ? 'SAO Campus' : 'Club');
    final Color orgBadgeColor = isCampus ? Colors.blue.shade700 : Colors.purple.shade600;

    final String methodStr = item.paymentMethod != null && item.paymentMethod!.isNotEmpty
        ? ' • ${item.paymentMethod!.toUpperCase()}'
        : '';

    final String refStr = item.paymentReference != null && item.paymentReference!.isNotEmpty
        ? ' (Ref: ${item.paymentReference})'
        : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      orgName,
                      style: TextStyle(
                        color: orgBadgeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      '$methodStr$refStr',
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₱${item.paidAmount > 0 ? item.paidAmount.toStringAsFixed(0) : item.assignedAmount.toStringAsFixed(0)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                dateStr,
                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade500, fontSize: 10.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

