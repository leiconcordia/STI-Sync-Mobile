import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/currency_formatter.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'payment_instructions_bottom_sheet.dart';

class DuesListView extends ConsumerWidget {
  const DuesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);

    final myOrgs = ref.watch(myOrganizationsProvider).valueOrNull ?? [];

    return payablesAsync.when(
      data: (payables) {
        final dues = payables.where((p) => p.type != 'org_fine' && p.type != 'admin_fine').toList();

        if (dues.isEmpty) {
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
                Icon(Icons.check_circle_outline_rounded, size: 48, color: AppColors.success.withValues(alpha: 0.8)),
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
            child: _buildDuesCard(context, due, myOrgs),
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

  Widget _buildDuesCard(BuildContext context, PayableModel due, List<dynamic> myOrgs) {
    final bool isCampus = due.isCampusWide;
    String orgName = 'Organization';
    if (due.organizationName?.isNotEmpty == true) {
      orgName = due.organizationName!;
    } else if (isCampus) {
      orgName = 'SAO Campus';
    } else if (due.organizationId?.isNotEmpty == true) {
      final matching = myOrgs.where((o) => o.organizationId == due.organizationId).firstOrNull;
      if (matching != null && matching.organizationName.toString().isNotEmpty) {
        orgName = matching.organizationName.toString();
      } else {
        orgName = 'Student Organization';
      }
    } else {
      orgName = 'Student Organization';
    }
    final Color badgeColor = isCampus ? Colors.blue.shade700 : Colors.purple.shade600;
    
    final double total = due.assignedAmount > 0 ? due.assignedAmount : (due.amountDue + due.paidAmount);
    final double paid = due.paidAmount;
    final double remaining = due.remainingBalance;
    final double progress = total > 0 ? (paid / total).clamp(0.0, 1.0) : 1.0;

    final String statusText;
    final Color statusColor;
    if (due.isPaid) {
      statusText = 'Fully Paid';
      statusColor = AppColors.success;
    } else if (due.isOverdue) {
      statusText = 'Overdue';
      statusColor = AppColors.error;
    } else if (paid > 0) {
      statusText = 'Partially Paid';
      statusColor = Colors.orange.shade800;
    } else {
      statusText = 'Pending';
      statusColor = Colors.orange.shade700;
    }

    return InkWell(
      onTap: () => PaymentInstructionsBottomSheet.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: due.isOverdue ? AppColors.error.withValues(alpha: 0.3) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCampus ? Icons.school_outlined : Icons.groups_outlined,
                          size: 13,
                          color: badgeColor,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isCampus ? 'SAO Campus' : orgName,
                            style: TextStyle(
                              color: badgeColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              due.label,
              style: AppTextStyles.h2.copyWith(
                color: AppColors.primaryDark,
                fontSize: 16,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (due.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                due.description,
                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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
                      color: due.isPaid ? AppColors.success : (due.isOverdue ? AppColors.error : AppColors.primary),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Total', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600, fontSize: 10)),
                        const SizedBox(height: 2),
                        Text(
                          formatCurrency(total),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Paid', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            formatCurrency(paid),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(width: 1, height: 24, color: Colors.grey.shade300),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Balance', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600, fontSize: 10)),
                          const SizedBox(height: 2),
                          Text(
                            formatCurrency(remaining),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: remaining > 0 ? (due.isOverdue ? AppColors.error : Colors.orange.shade800) : AppColors.success,
                              fontWeight: FontWeight.bold,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: due.isOverdue ? AppColors.error : Colors.grey),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          due.dueDate != null ? 'Due by ${formatAppDate(due.dueDate)}' : 'No due date set',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: due.isOverdue ? AppColors.error : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: due.isOverdue ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!due.isPaid)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'How to Pay',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

