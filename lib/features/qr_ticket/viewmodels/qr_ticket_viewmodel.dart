import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/qr_ticket_model.dart';
import 'package:sti_sync/features/auth/models/student_model.dart';
import '../repositories/qr_ticket_repository.dart';

/// Sealed union for QR Ticket states.
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

    try {
      if (_repository.isOnline) {
        // We already have the fully populated student data!
        final eventTitle = await _repository.getEventTitle(eventId);
        
        final studentName = '${student.firstName} ${student.lastName}'.trim();
        final studentIdNumber = student.studentId;
        final profilePhotoUrl = student.profilePhotoUrl;
        
        String courseCode = student.courseCode.isNotEmpty ? student.courseCode : student.courseId;
        String yearLevel = student.yearLevel;
        String section = student.section;
        String courseInfo = [courseCode, yearLevel, section].where((e) => e.isNotEmpty).join(' - ');

        // Cache the status and data for offline use
        await _repository.cacheTicketStatus(
          studentAuthUid, 
          eventId,
          studentName: studentName,
          studentIdNumber: studentIdNumber,
          profilePhotoUrl: profilePhotoUrl,
          eventTitle: eventTitle,
          courseInfo: courseInfo,
        );

        // Listen to real-time updates
        _subscription?.cancel();
        _subscription = _repository
            .watchTicketStatus(studentAuthUid, eventId)
            .listen((status) {
          if (status.isUnlocked) {
            if (status.paymentStatus == 'free') {
              // Free event
              final ticket = QrTicketModel.forFreeEvent(
                eventId: eventId,
                eventTitle: eventTitle,
                student: student,
              );
              state = QrTicketNoTicket(ticket);
            } else {
              // Paid and unlocked
              final ticket = QrTicketModel(
                eventId: eventId,
                studentId: studentIdNumber,
                studentAuthUid: studentAuthUid,
                studentName: studentName,
                eventTitle: eventTitle,
                profilePhotoUrl: profilePhotoUrl,
                courseInfo: courseInfo,
                generatedAt: DateTime.now(),
              );
              state = QrTicketUnlocked(ticket);
            }
          } else {
            state = QrTicketLocked(
              amountDue: status.amountDue,
              paymentStatus: status.paymentStatus,
              eventTitle: eventTitle,
              studentName: studentName,
              studentId: studentIdNumber,
              profilePhotoUrl: profilePhotoUrl,
              courseInfo: courseInfo,
            );
          }
        }, onError: (e) {
          state = QrTicketError('Failed to load ticket: $e');
        });
      } else {
        // Offline mode — read from Drift cache
        final cached = await _repository.getLocalTicketStatus(studentAuthUid, eventId);
        
        // Since we have the student object from AuthViewModel (even offline),
        // we should just use it directly! This fixes missing offline fields!
        final studentName = '${student.firstName} ${student.lastName}'.trim();
        final studentIdNumber = student.studentId;
        final profilePhotoUrl = student.profilePhotoUrl;
        
        String courseCode = student.courseCode.isNotEmpty ? student.courseCode : student.courseId;
        String yearLevel = student.yearLevel;
        String section = student.section;
        String courseInfo = [courseCode, yearLevel, section].where((e) => e.isNotEmpty).join(' - ');

        if (cached == null) {
          state = const QrTicketError('No cached ticket data available offline.');
          return;
        }

        // Use the memory-cached student fields and Drift-cached ticket status
        if (cached.isUnlocked) {
          final ticket = QrTicketModel(
            eventId: eventId,
            studentId: studentIdNumber,
            studentAuthUid: studentAuthUid,
            studentName: studentName,
            eventTitle: cached.eventTitle ?? 'Event',
            profilePhotoUrl: profilePhotoUrl,
            courseInfo: courseInfo,
            generatedAt: DateTime.now(),
          );
          state = QrTicketUnlocked(ticket);
        } else {
          state = QrTicketLocked(
            amountDue: cached.amountDue,
            paymentStatus: cached.paymentStatus,
            eventTitle: cached.eventTitle ?? 'Event',
            studentName: studentName,
            studentId: studentIdNumber,
            profilePhotoUrl: profilePhotoUrl,
            courseInfo: courseInfo,
          );
        }
      }
    } catch (e) {
      state = QrTicketError('Error loading ticket: $e');
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
