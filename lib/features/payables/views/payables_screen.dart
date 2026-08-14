import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/payables/widgets/payment_overview_card.dart';
import 'package:sti_sync/features/payables/widgets/finance_tabs.dart';
import 'package:sti_sync/features/payables/widgets/dues_list_view.dart';
import 'package:sti_sync/features/payables/widgets/history_list_view.dart';
import 'package:sti_sync/features/payables/widgets/fines_list_view.dart';
import 'package:sti_sync/features/payables/widgets/payment_instructions_bottom_sheet.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class PayablesScreen extends ConsumerStatefulWidget {
  const PayablesScreen({super.key});

  @override
  ConsumerState<PayablesScreen> createState() => _PayablesScreenState();
}

class _PayablesScreenState extends ConsumerState<PayablesScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final activeSemester = ref.watch(activeSemesterProvider).valueOrNull ?? 'Active Semester';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(studentPayablesStreamProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payables & Finance',
                          style: AppTextStyles.h1.copyWith(
                            fontSize: 26,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activeSemester.isNotEmpty ? activeSemester : 'Real-time Payment Obligations',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: const Icon(
                          Icons.help_outline_rounded,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      tooltip: 'Payment Instructions',
                      onPressed: () => PaymentInstructionsBottomSheet.show(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const PaymentOverviewCard(),
                const SizedBox(height: 20),
                FinanceTabs(
                  selectedIndex: _selectedTabIndex,
                  onTabChanged: (index) {
                    setState(() {
                      _selectedTabIndex = index;
                    });
                  },
                ),
                const SizedBox(height: 20),
                if (_selectedTabIndex == 0) const DuesListView(),
                if (_selectedTabIndex == 1) const HistoryListView(),
                if (_selectedTabIndex == 2) const FinesListView(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

