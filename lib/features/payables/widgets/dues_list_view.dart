import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class DuesListView extends ConsumerWidget {
  const DuesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);

    return payablesAsync.when(
      data: (payables) {
        final dues = payables.where((p) => p.type != 'org_fine' && p.type != 'admin_fine').toList();

        if (dues.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 48, color: AppColors.success.withOpacity(0.8)),
                const SizedBox(height: 12),
                Text(
                  'No Active Dues',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'You have no pending membership dues or event fees.',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: dues.map((due) => Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: _buildDuesCard(due),
          )).toList(),
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
          'Failed to load dues: $err',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildDuesCard(PayableModel due) {
    final String orgName = due.organizationName?.isNotEmpty == true ? due.organizationName! : 'SAO Campus';
    final String avatarText = orgName.length >= 2 ? orgName.substring(0, 2).toUpperCase() : 'ST';
    
    final double total = due.assignedAmount > 0 ? due.assignedAmount : (due.amountDue + due.paidAmount);
    final double paid = due.paidAmount;
    final double remaining = due.remainingBalance;
    final double progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 1.0;

    final String statusText;
    final Color statusColor;
    if (due.isPaid) {
      statusText = 'Paid';
      statusColor = AppColors.success;
    } else if (paid > 0) {
      statusText = 'Partial';
      statusColor = Colors.orange;
    } else {
      statusText = due.status.toUpperCase();
      statusColor = AppColors.secondary;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary,
                      child: Text(avatarText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(due.label, style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                          Text(orgName, style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  statusText,
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: due.isPaid ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(
                children: [
                  TextSpan(text: 'Total ', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                  TextSpan(text: '₱${total.toStringAsFixed(0)}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                ]
              )),
              Text.rich(TextSpan(
                children: [
                  TextSpan(text: 'Paid ', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                  TextSpan(text: '₱${paid.toStringAsFixed(0)}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                ]
              )),
              Text.rich(TextSpan(
                children: [
                  TextSpan(text: 'Balance ', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                  TextSpan(text: '₱${remaining.toStringAsFixed(0)}', style: AppTextStyles.labelSmall.copyWith(color: remaining > 0 ? AppColors.error : AppColors.success, fontWeight: FontWeight.bold)),
                ]
              )),
            ],
          ),
          if (due.dueDate != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'Due by ${DateFormat('MMM dd, yyyy').format(due.dueDate!)}',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
