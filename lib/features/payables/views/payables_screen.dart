import 'package:flutter/material.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/payables/widgets/payment_overview_card.dart';
import 'package:sti_sync/features/payables/widgets/finance_tabs.dart';
import 'package:sti_sync/features/payables/widgets/dues_list_view.dart';
import 'package:sti_sync/features/payables/widgets/history_list_view.dart';
import 'package:sti_sync/features/payables/widgets/fines_list_view.dart';

class PayablesScreen extends StatefulWidget {
  const PayablesScreen({super.key});

  @override
  State<PayablesScreen> createState() => _PayablesScreenState();
}

class _PayablesScreenState extends State<PayablesScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Finance', style: AppTextStyles.h1.copyWith(fontSize: 28, color: AppColors.primaryDark)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          '2nd Sem',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const PaymentOverviewCard(),
              const SizedBox(height: 24),
              FinanceTabs(
                selectedIndex: _selectedTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    _selectedTabIndex = index;
                  });
                },
              ),
              const SizedBox(height: 24),
              if (_selectedTabIndex == 0) const DuesListView(),
              if (_selectedTabIndex == 1) const HistoryListView(),
              if (_selectedTabIndex == 2) const FinesListView(),
              const SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}
