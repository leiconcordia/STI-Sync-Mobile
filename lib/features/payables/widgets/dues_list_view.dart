import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';

class DuesListView extends StatelessWidget {
  const DuesListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildDuesCard(
          avatar: 'IC',
          name: 'ICTSO',
          statusText: 'Partial',
          statusColor: Colors.orange,
          progress: 0.7,
          totalAmount: '₱500',
          paidAmount: '₱350',
          leftAmount: '₱150',
        ),
        const SizedBox(height: 16),
        _buildDuesCard(
          avatar: 'SG',
          name: 'Student Gov\'t',
          statusText: 'Paid',
          statusColor: AppColors.success,
          progress: 1.0,
          totalAmount: '₱300',
          paidAmount: '₱300',
          leftAmount: '₱0',
        ),
      ],
    );
  }

  Widget _buildDuesCard({
    required String avatar,
    required String name,
    required String statusText,
    required Color statusColor,
    required double progress,
    required String totalAmount,
    required String paidAmount,
    required String leftAmount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.primary,
                    child: Text(avatar, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Text(name, style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark)),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      statusText,
                      style: AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.expand_more, color: Colors.grey),
                ],
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
                    color: AppColors.primary,
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
                  TextSpan(text: totalAmount, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                ]
              )),
              Text.rich(TextSpan(
                children: [
                  TextSpan(text: 'Paid ', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                  TextSpan(text: paidAmount, style: AppTextStyles.labelSmall.copyWith(color: AppColors.success, fontWeight: FontWeight.bold)),
                ]
              )),
              Text.rich(TextSpan(
                children: [
                  TextSpan(text: 'Left ', style: AppTextStyles.labelSmall.copyWith(color: Colors.grey)),
                  TextSpan(text: leftAmount, style: AppTextStyles.labelSmall.copyWith(color: AppColors.error, fontWeight: FontWeight.bold)),
                ]
              )),
            ],
          ),
        ],
      ),
    );
  }
}
