import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/core/utils/currency_formatter.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'payment_instructions_bottom_sheet.dart';

class FinesListView extends ConsumerWidget {
  const FinesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);
    final myOrgs = ref.watch(myOrganizationsProvider).valueOrNull ?? [];

    return payablesAsync.when(
      data: (payables) {
        final fines = payables.where((p) => p.type == 'org_fine' || p.type == 'admin_fine').toList();
        final unpaidFines = fines.where((p) => p.isPending).toList();

        double totalOutstandingFines = 0;
        for (final f in unpaidFines) {
          totalOutstandingFines += f.remainingBalance;
        }

        if (fines.isEmpty) {
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
                const Icon(Icons.shield_outlined, size: 48, color: AppColors.success),
                const SizedBox(height: 12),
                Text(
                  'No Fines Record',
                  style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
                ),
                const SizedBox(height: 4),
                Text(
                  'Great job! You have zero organization or SAO administrative fines.',
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.error_outline, color: AppColors.secondary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Outstanding Fines',
                                style: AppTextStyles.bodyLarge.copyWith(
                                  color: AppColors.primaryDark,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${unpaidFines.length} unpaid violation fine(s)',
                                style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatCurrency(totalOutstandingFines),
                    style: AppTextStyles.h2.copyWith(
                      color: totalOutstandingFines > 0 ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...fines.map((fine) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildFineCard(context, fine, myOrgs),
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
          'Failed to load fines: $err',
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildFineCard(BuildContext context, PayableModel fine, List<dynamic> myOrgs) {
    final bool isCampus = fine.isCampusWide;
    String orgName = 'Organization';
    if (fine.organizationName?.isNotEmpty == true) {
      orgName = fine.organizationName!;
    } else if (isCampus) {
      orgName = 'SAO Violation';
    } else if (fine.organizationId?.isNotEmpty == true) {
      final matching = myOrgs.where((o) => o.organizationId == fine.organizationId).firstOrNull;
      if (matching != null && matching.organizationName.toString().isNotEmpty) {
        orgName = matching.organizationName.toString();
      } else {
        orgName = 'Student Organization';
      }
    } else {
      orgName = 'Student Organization';
    }
    final Color badgeColor = isCampus ? Colors.blue.shade700 : Colors.purple.shade600;
    final dueStr = fine.dueDate != null ? formatAppDate(fine.dueDate) : 'TBA';
    final isUnpaid = fine.isPending;

    return InkWell(
      onTap: () => PaymentInstructionsBottomSheet.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isUnpaid ? AppColors.error.withValues(alpha: 0.25) : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      orgName,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isUnpaid ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isUnpaid ? 'Unpaid Fine' : 'Settled',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isUnpaid ? AppColors.error : AppColors.success,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fine.label,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.primaryDark,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      if (fine.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          fine.description,
                          style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  formatCurrency(fine.remainingBalance),
                  style: AppTextStyles.h2.copyWith(
                    color: isUnpaid ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.grey.shade200, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_today, size: 12, color: isUnpaid ? AppColors.error : Colors.grey),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          'Due: $dueStr',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isUnpaid ? AppColors.error : Colors.grey.shade600,
                            fontSize: 11,
                            fontWeight: isUnpaid ? FontWeight.bold : FontWeight.normal,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isUnpaid)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 8),
                      Text(
                        'Pay Fine',
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

