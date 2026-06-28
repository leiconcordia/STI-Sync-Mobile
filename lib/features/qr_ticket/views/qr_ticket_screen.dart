
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/qr_ticket_viewmodel.dart';
import '../widgets/qr_code_display.dart';
import '../widgets/locked_qr_card.dart';

class QrTicketScreen extends ConsumerStatefulWidget {
  final String eventId;

  const QrTicketScreen({super.key, required this.eventId});

  @override
  ConsumerState<QrTicketScreen> createState() => _QrTicketScreenState();
}

class _QrTicketScreenState extends ConsumerState<QrTicketScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = ref.read(authViewModelProvider);
      final student = authState.student;
      if (student != null) {
        ref
            .read(qrTicketViewModelProvider(widget.eventId).notifier)
            .loadTicket(student, widget.eventId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final ticketState = ref.watch(qrTicketViewModelProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppColors.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            context.goNamed('events');
          },
        ),
        title: Text(
          'STI Sync · Digital Student ID',
          style: AppTextStyles.bodyMedium.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildBody(ticketState)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Tap card to maximize brightness',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(QrTicketState state) {
    if (state is QrTicketLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is QrTicketUnlocked) {
      return QrCodeDisplay(ticket: state.ticket);
    }

    if (state is QrTicketNoTicket) {
      // Free event — show QR
      return QrCodeDisplay(ticket: state.ticket);
    }

    if (state is QrTicketLocked) {
      return LockedQrCard(
        amountDue: state.amountDue,
        paymentStatus: state.paymentStatus,
        eventTitle: state.eventTitle,
        studentName: state.studentName,
        studentId: state.studentId,
        profilePhotoUrl: state.profilePhotoUrl,
      );
    }

    if (state is QrTicketError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                state.message,
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  final authState = ref.read(authViewModelProvider);
                  final student = authState.student;
                  if (student != null) {
                    ref
                        .read(qrTicketViewModelProvider(widget.eventId).notifier)
                        .loadTicket(student, widget.eventId);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
