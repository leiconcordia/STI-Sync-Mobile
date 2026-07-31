import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';

import '../models/qr_ticket_model.dart';
import '../repositories/qr_ticket_repository.dart';

abstract class QrTicketState {
  const QrTicketState();
}

class QrTicketLoading extends QrTicketState {
  const QrTicketLoading();
}

class QrTicketUnlocked extends QrTicketState {
  final QrTicketModel ticket;
  const QrTicketUnlocked(this.ticket);
}

class QrTicketLocked extends QrTicketState {
  final double amountDue;
  final String paymentStatus;
  final String eventTitle;
  final String studentName;
  final String studentId;
  final String profilePhotoUrl;
  final String courseInfo;

  const QrTicketLocked({
    required this.amountDue,
    required this.paymentStatus,
    required this.eventTitle,
    required this.studentName,
    required this.studentId,
    required this.profilePhotoUrl,
    required this.courseInfo,
  });
}

class QrTicketNoTicket extends QrTicketState {
  final QrTicketModel ticket;
  const QrTicketNoTicket(this.ticket);
}

class QrTicketError extends QrTicketState {
  final String message;
  const QrTicketError(this.message);
}

class QrTicketViewModel extends StateNotifier<QrTicketState> {
  final QrTicketRepository _repository;
  StreamSubscription? _subscription;

  QrTicketViewModel(this._repository) : super(const QrTicketLoading());

  Future<void> loadTicket(StudentModel student, String eventId) async {
    state = const QrTicketLoading();
    final studentAuthUid = student.id;
    final studentName = '${student.firstName} ${student.lastName}'.trim();
    final studentIdNumber = student.studentId;
    final profilePhotoUrl = student.profilePhotoUrl;
    final courseCode =
        student.courseCode.isNotEmpty ? student.courseCode : student.courseId;
    final courseInfo = [courseCode, student.yearLevel, student.section]
        .where((value) => value.isNotEmpty)
        .join(' - ');

    try {
      final isOnline = await _repository.checkOnline();
      final config = isOnline
          ? await _repository.getEventTicketConfig(eventId)
          : await _repository.getLocalEventTicketConfig(eventId);

      if (config == null) {
        state = const QrTicketError(
          'Connect once to prepare this event ticket for offline use.',
        );
        return;
      }
      if (!config.isTicketAvailable) {
        state = const QrTicketError(
          'QR tickets are not enabled for this event.',
        );
        return;
      }

      if (!isOnline) {
        final cached =
            await _repository.getLocalTicketStatus(studentAuthUid, eventId);
        if (cached == null) {
          state = const QrTicketError(
            'Connect once to prepare this event ticket for offline use.',
          );
          return;
        }
        _setStateFromStatus(
          isUnlocked: cached.isUnlocked,
          amountDue: cached.amountDue,
          paymentStatus: cached.paymentStatus,
          eventId: eventId,
          eventTitle: cached.eventTitle ?? config.title,
          student: student,
          studentName: studentName,
          studentIdNumber: studentIdNumber,
          profilePhotoUrl: profilePhotoUrl,
          courseInfo: courseInfo,
        );
        return;
      }

      await _repository.cacheTicketStatus(
        studentAuthUid,
        eventId,
        studentName: studentName,
        studentIdNumber: studentIdNumber,
        profilePhotoUrl: profilePhotoUrl,
        eventTitle: config.title,
        courseInfo: courseInfo,
        config: config,
      );

      _subscription?.cancel();
      _subscription = _repository
          .watchTicketStatus(studentAuthUid, eventId, config)
          .listen((status) async {
        await _repository.cacheTicketStatus(
          studentAuthUid,
          eventId,
          studentName: studentName,
          studentIdNumber: studentIdNumber,
          profilePhotoUrl: profilePhotoUrl,
          eventTitle: config.title,
          courseInfo: courseInfo,
          config: config,
        );
        _setStateFromStatus(
          isUnlocked: status.isUnlocked,
          amountDue: status.amountDue,
          paymentStatus: status.paymentStatus,
          eventId: eventId,
          eventTitle: config.title,
          student: student,
          studentName: studentName,
          studentIdNumber: studentIdNumber,
          profilePhotoUrl: profilePhotoUrl,
          courseInfo: courseInfo,
        );
      }, onError: (Object error) {
        state = QrTicketError('Failed to load ticket: $error');
      });
    } catch (error) {
      state = QrTicketError('Error loading ticket: $error');
    }
  }

  void _setStateFromStatus({
    required bool isUnlocked,
    required double amountDue,
    required String paymentStatus,
    required String eventId,
    required String eventTitle,
    required StudentModel student,
    required String studentName,
    required String studentIdNumber,
    required String profilePhotoUrl,
    required String courseInfo,
  }) {
    if (isUnlocked) {
      final ticket = paymentStatus == 'free'
          ? QrTicketModel.forFreeEvent(
              eventId: eventId,
              eventTitle: eventTitle,
              student: student,
            )
          : QrTicketModel(
              eventId: eventId,
              studentId: studentIdNumber,
              studentAuthUid: student.id,
              studentName: studentName,
              eventTitle: eventTitle,
              profilePhotoUrl: profilePhotoUrl,
              courseInfo: courseInfo,
              generatedAt: DateTime.now(),
            );
      state = paymentStatus == 'free'
          ? QrTicketNoTicket(ticket)
          : QrTicketUnlocked(ticket);
      return;
    }

    state = QrTicketLocked(
      amountDue: amountDue,
      paymentStatus: paymentStatus,
      eventTitle: eventTitle,
      studentName: studentName,
      studentId: studentIdNumber,
      profilePhotoUrl: profilePhotoUrl,
      courseInfo: courseInfo,
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
