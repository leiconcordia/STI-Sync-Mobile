import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/payables/models/payable_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class FinesListView extends ConsumerWidget {
  const FinesListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payablesAsync = ref.watch(payablesStreamProvider);

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
              borderRadius: BorderRadius.circular(16),
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
                  'Great job! You have zero org or administrative fines.',
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.secondary),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.secondary),
                      const SizedBox(width: 12),
                      Text(
                        'Outstanding Fines',
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₱${totalOutstandingFines.toStringAsFixed(0)}',
                    style: AppTextStyles.h2.copyWith(color: AppColors.error),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            ...fines.map((fine) => Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: _buildFineCard(fine),
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

  Widget _buildFineCard(PayableModel fine) {
    final dueStr = fine.dueDate != null ? DateFormat('MMM dd').format(fine.dueDate!) : 'TBA';
    final isUnpaid = fine.isPending;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fine.label,
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      fine.organizationName ?? 'SAO Office',
                      style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${fine.remainingBalance.toStringAsFixed(0)}',
                style: AppTextStyles.h1.copyWith(color: isUnpaid ? AppColors.error : AppColors.success),
              ),
            ],
          ),
          if (fine.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              fine.description,
              style: AppTextStyles.labelSmall.copyWith(color: Colors.grey.shade700),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    'Due: $dueStr',
                    style: AppTextStyles.labelSmall.copyWith(color: Colors.grey),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnpaid ? AppColors.error.withOpacity(0.1) : AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  isUnpaid ? 'Unpaid' : 'Settled',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isUnpaid ? AppColors.error : AppColors.success,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
