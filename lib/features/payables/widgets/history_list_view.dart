import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/currency_formatter.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class HistoryListView extends ConsumerWidget {
  const HistoryListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);

    final myOrgs = ref.watch(myOrganizationsProvider).valueOrNull ?? [];

    return payablesAsync.when(
      data: (payables) {
        final history = payables.where((p) => p.isPaid || p.status == 'paid' || p.isRefunded || (p.assignedAmount > 0 && p.paidAmount >= p.assignedAmount)).toList();

        if (history.isEmpty) {
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
                  'Your completed payment transactions, refunds, and receipts will appear here once settled.',
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
                  'Transaction History',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 16),
                ),
                Text(
                  '${history.length} settled',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...history.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildHistoryCard(item, myOrgs),
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

  Widget _buildHistoryCard(PayableModel item, List<dynamic> myOrgs) {
    final isRefunded = item.isRefunded;
    final dateStr = isRefunded
        ? (item.refundedAt != null
            ? formatAppDate(item.refundedAt)
            : (item.paidAt != null ? formatAppDate(item.paidAt) : 'Recorded'))
        : (item.paidAt != null 
            ? formatAppDate(item.paidAt) 
            : (item.createdAt != null ? formatAppDate(item.createdAt) : 'Recorded'));

    final bool isCampus = item.isCampusWide;
    String orgName = 'Organization';
    if (item.organizationName?.isNotEmpty == true) {
      orgName = item.organizationName!;
    } else if (isCampus) {
      orgName = 'SAO Campus';
    } else if (item.organizationId?.isNotEmpty == true) {
      final matching = myOrgs.where((o) => o.organizationId == item.organizationId).firstOrNull;
      if (matching != null && matching.organizationName.toString().isNotEmpty) {
        orgName = matching.organizationName.toString();
      } else {
        orgName = 'Student Organization';
      }
    } else {
      orgName = 'Student Organization';
    }
    final Color orgBadgeColor = isCampus ? Colors.blue.shade700 : Colors.purple.shade600;

    final String methodStr = isRefunded
        ? (item.refundMethod != null && item.refundMethod!.isNotEmpty
            ? ' • Disbursed via ${item.refundMethod!.toUpperCase()}'
            : ' • Refund Disbursed')
        : (item.paymentMethod != null && item.paymentMethod!.isNotEmpty
            ? ' • ${item.paymentMethod!.toUpperCase()}'
            : '');

    final String refStr = isRefunded
        ? (item.refundReceiptNumber != null && item.refundReceiptNumber!.isNotEmpty
            ? ' (Receipt #${item.refundReceiptNumber})'
            : '')
        : (item.paymentReference != null && item.paymentReference!.isNotEmpty
            ? ' (Ref: ${item.paymentReference})'
            : '');

    final double amount = isRefunded
        ? ((item.refundDue ?? 0) > 0 ? item.refundDue! : item.paidAmount)
        : (item.paidAmount > 0 ? item.paidAmount : item.assignedAmount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isRefunded ? Colors.blue.shade100 : Colors.grey.shade200),
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
              color: isRefunded
                  ? Colors.blue.shade50
                  : AppColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isRefunded ? Icons.assignment_return_rounded : Icons.check_circle_rounded,
              color: isRefunded ? Colors.blue.shade700 : AppColors.success,
              size: 22,
            ),
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
                    fontSize: 14.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        orgName,
                        style: TextStyle(
                          color: orgBadgeColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (methodStr.isNotEmpty || refStr.isNotEmpty)
                      Flexible(
                        child: Text(
                          '$methodStr$refStr',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isRefunded ? Colors.blue.shade800 : Colors.grey.shade600,
                            fontSize: 11,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                formatCurrency(amount),
                style: AppTextStyles.bodyLarge.copyWith(
                  color: isRefunded ? Colors.blue.shade700 : AppColors.success,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isRefunded ? '$dateStr (Refunded)' : dateStr,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isRefunded ? Colors.blue.shade600 : Colors.grey.shade500,
                  fontSize: 10.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

