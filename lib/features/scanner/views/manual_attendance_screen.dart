import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' as drift;
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/local/app_database.dart';
import '../../../shared/providers/providers.dart';
import '../viewmodels/scanner_viewmodel.dart';

/// Screen for manually recording attendance when QR scanning is not possible.
///
/// Route: `/scanner/:eventId/manual`
/// Only accessible when `scanner.allowManualAttendance == true`.
///
/// Supports two flows:
/// 1. **Known attendee:** search cached participants → select → record
/// 2. **Unknown attendee:** enter name/details manually → record
class ManualAttendanceScreen extends ConsumerStatefulWidget {
  final String eventId;

  const ManualAttendanceScreen({super.key, required this.eventId});

  @override
  ConsumerState<ManualAttendanceScreen> createState() =>
      _ManualAttendanceScreenState();
}

class _ManualAttendanceScreenState
    extends ConsumerState<ManualAttendanceScreen> {
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _courseController = TextEditingController();
  final _noteController = TextEditingController();

  List<CachedParticipant> _searchResults = [];
  CachedParticipant? _selectedParticipant;
  bool _isUnknownAttendee = false;
  bool _isSearching = false;
  bool _isSubmitting = false;

  String _gateType = 'Time-In';
  String? _flagReason;

  static const _flagReasons = [
    ('no_phone', 'No Phone'),
    ('payment_pending', 'Payment Pending'),
    ('not_registered', 'Not Registered'),
    ('device_error', 'Device Error'),
    ('other', 'Other'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _studentNumberController.dispose();
    _courseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // ─── Search ──────────────────────────────────────────────────────────────

  Future<void> _performSearch(String query) async {
    if (query.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    final repo = ref.read(offlineAttendanceRepositoryProvider);
    final results = await repo.searchParticipants(widget.eventId, query);

    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });
    }
  }

  void _selectParticipant(CachedParticipant participant) {
    setState(() {
      _selectedParticipant = participant;
      _isUnknownAttendee = false;
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _selectUnknownAttendee() {
    setState(() {
      _selectedParticipant = null;
      _isUnknownAttendee = true;
      _searchResults = [];
      _searchController.clear();
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedParticipant = null;
      _isUnknownAttendee = false;
      _gateType = 'Time-In';
      _flagReason = null;
      _noteController.clear();
      _nameController.clear();
      _studentNumberController.clear();
      _courseController.clear();
    });
  }

  // ─── Submit ──────────────────────────────────────────────────────────────

  Future<void> _submitRecord() async {
    if (_flagReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a flag reason'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_isUnknownAttendee && _nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the attendee\'s name'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final currentUserId =
          ref.read(authViewModelProvider).student?.id ?? 'unknown';
      final now = DateTime.now().millisecondsSinceEpoch;

      // Determine student info
      final String studentId;
      final String studentName;

      if (_selectedParticipant != null) {
        studentId = _selectedParticipant!.id;
        studentName = _selectedParticipant!.studentName;
      } else {
        studentId = ''; // Unknown attendee — no Firebase UID
        studentName = _nameController.text.trim();
      }

      // Get the active session ID from scanner state
      final scannerState = ref.read(scannerViewModelProvider);
      final sessionId = scannerState.selectedSessionId ?? '';

      // Local duplicate check before saving
      if (studentId.isNotEmpty) {
        final existing = await ref.read(appDatabaseProvider).attendanceDao.checkDuplicate(
          studentId: studentId,
          studentNumber: _selectedParticipant?.studentNumber,
          eventId: widget.eventId,
          sessionId: sessionId,
          gateType: _gateType,
        );
        if (existing != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Duplicate: $studentName already has a $_gateType record for this event.'),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          setState(() => _isSubmitting = false);
          return;
        }
      }

      final localId = 'manual_${studentId.isNotEmpty ? studentId : studentName.hashCode}_${sessionId}_${_gateType}_$now';

      final record = OfflineAttendanceCompanion(
        localId: drift.Value(localId),
        eventId: drift.Value(widget.eventId),
        sessionId: drift.Value(sessionId),
        studentId: drift.Value(studentId),
        studentName: drift.Value(studentName),
        gateType: drift.Value(_gateType),
        scanMethod: const drift.Value('Manual'),
        scannedBy: drift.Value(currentUserId),
        scannedAt: drift.Value(now),
        synced: const drift.Value(0),
        conflictResolved: const drift.Value(0),
        status: const drift.Value('Present'),
        isFlagged: const drift.Value(1),
        flagReason: drift.Value(_flagReason),
        flagNote: drift.Value(
            _noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
        isManual: const drift.Value(1),
      );

      final repo = ref.read(offlineAttendanceRepositoryProvider);
      await repo.saveFlaggedRecord(record);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text('Attendance recorded for $studentName'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        _clearSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record attendance: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ─── Permissions ────────────────────────────────────────────────────────

  Map<String, dynamic> get _permissions {
    final scannerState = ref.read(scannerViewModelProvider);
    final assignment = scannerState.assignments.firstWhere(
      (a) => a.eventId == widget.eventId,
      orElse: () => scannerState.assignments.first,
    );
    return assignment.permissions;
  }

  bool get _canCheckIn =>
      _permissions['fullAccess'] == true ||
      _permissions['canCheckIn'] == true;

  bool get _canCheckOut {
    final scannerState = ref.read(scannerViewModelProvider);
    final assignment = scannerState.assignments.firstWhere(
      (a) => a.eventId == widget.eventId,
      orElse: () => scannerState.assignments.first,
    );
    final activeSessionId = scannerState.selectedSessionId;
    final activeSession = assignment.sessions.firstWhere(
      (s) => s['id'] == activeSessionId,
      orElse: () => assignment.sessions.isNotEmpty ? assignment.sessions.first : {},
    );
    final bool sessionHasTimeOut = activeSession['hasTimeOut'] == true;
    final permissionCheckOut = _permissions['fullAccess'] == true ||
        _permissions['canCheckOut'] == true;
    return permissionCheckOut && sessionHasTimeOut;
  }

  // ─── Build ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Manual Attendance'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _selectedParticipant != null || _isUnknownAttendee
          ? _buildRecordForm()
          : _buildSearchView(),
    );
  }

  // ─── Search View ────────────────────────────────────────────────────────

  Widget _buildSearchView() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.primary,
          child: Column(
            children: [
              TextField(
                controller: _searchController,
                onChanged: _performSearch,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by name or student number...',
                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  prefixIcon:
                      Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              // Add Unknown Attendee button — always visible below search bar
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _selectUnknownAttendee,
                  icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
                  label: const Text('Add Unknown Attendee'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Results
        Expanded(
          child: _isSearching
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.primary))
              : _searchResults.isEmpty && _searchController.text.length >= 2
                  ? _buildNoResults()
                  : _searchResults.isEmpty
                      ? _buildSearchPrompt()
                      : _buildResultsList(),
        ),
      ],
    );
  }

  Widget _buildSearchPrompt() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_search,
              size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            'Search for a student',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type at least 2 characters to search\ncached participants',
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off,
            size: 48, color: AppColors.textSecondary.withValues(alpha: 0.4)),
        const SizedBox(height: 12),
        Text(
          'No student found',
          style: AppTextStyles.bodyLarge
              .copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        _buildAddUnknownButton(),
      ],
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length + 1, // +1 for "Add Unknown" option
      itemBuilder: (context, index) {
        if (index == _searchResults.length) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: _buildAddUnknownButton(),
          );
        }

        final participant = _searchResults[index];
        return _buildParticipantTile(participant);
      },
    );
  }

  Widget _buildParticipantTile(CachedParticipant participant) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: participant.profilePhotoUrl != null &&
                  participant.profilePhotoUrl!.isNotEmpty
              ? NetworkImage(participant.profilePhotoUrl!)
              : null,
          child: participant.profilePhotoUrl == null ||
                  participant.profilePhotoUrl!.isEmpty
              ? Text(
                  participant.studentName.isNotEmpty
                      ? participant.studentName[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
        title: Text(
          participant.studentName,
          style: AppTextStyles.bodyMedium
              .copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${participant.studentNumber ?? 'No ID'} • ${participant.course ?? 'N/A'}',
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () => _selectParticipant(participant),
      ),
    );
  }

  Widget _buildAddUnknownButton() {
    return OutlinedButton.icon(
      onPressed: _selectUnknownAttendee,
      icon: const Icon(Icons.person_add_alt_1, color: AppColors.primary),
      label: const Text('Add Unknown Attendee'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─── Record Form ────────────────────────────────────────────────────────

  Widget _buildRecordForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Student card or unknown attendee fields
          if (_selectedParticipant != null) _buildStudentCard(),
          if (_isUnknownAttendee) _buildUnknownAttendeeFields(),

          const SizedBox(height: 24),

          // Gate type selector
          Text('Gate Type',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildGateTypeSelector(),

          const SizedBox(height: 24),

          // Flag reason dropdown
          Text('Flag Reason *',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          _buildFlagReasonDropdown(),

          const SizedBox(height: 24),

          // Notes
          Text('Notes (optional)',
              style: AppTextStyles.bodyMedium
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Additional notes...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const SizedBox(height: 32),

          // Submit button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _submitRecord,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle),
              label: Text(_isSubmitting
                  ? 'Recording...'
                  : 'Record Manual Attendance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Cancel / back
          TextButton(
            onPressed: _clearSelection,
            child: const Text('← Back to Search'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentCard() {
    final p = _selectedParticipant!;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              backgroundImage:
                  p.profilePhotoUrl != null && p.profilePhotoUrl!.isNotEmpty
                      ? NetworkImage(p.profilePhotoUrl!)
                      : null,
              child:
                  p.profilePhotoUrl == null || p.profilePhotoUrl!.isEmpty
                      ? Text(
                          p.studentName.isNotEmpty
                              ? p.studentName[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.headlineMedium
                              .copyWith(color: AppColors.primary),
                        )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.studentName,
                      style: AppTextStyles.bodyLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    '${p.studentNumber ?? 'No ID'} • ${p.course ?? 'N/A'}',
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownAttendeeFields() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_add_alt_1,
                    color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text('Unknown Attendee',
                    style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade700)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _studentNumberController,
              decoration: InputDecoration(
                labelText: 'Student Number (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _courseController,
              decoration: InputDecoration(
                labelText: 'Course (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGateTypeSelector() {
    return Row(
      children: [
        if (_canCheckIn)
          Expanded(
            child: _buildGateChip('Time-In', Icons.login, AppColors.success),
          ),
        if (_canCheckIn && _canCheckOut) const SizedBox(width: 12),
        if (_canCheckOut)
          Expanded(
            child: _buildGateChip('Time-Out', Icons.logout, AppColors.error),
          ),
      ],
    );
  }

  Widget _buildGateChip(String type, IconData icon, Color color) {
    final isSelected = _gateType == type;
    return GestureDetector(
      onTap: () => setState(() => _gateType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : AppColors.textSecondary, size: 20),
            const SizedBox(width: 8),
            Text(
              type,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlagReasonDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _flagReason,
          isExpanded: true,
          hint: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('Select reason...'),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          items: _flagReasons.map((r) {
            return DropdownMenuItem(
              value: r.$1,
              child: Text(r.$2),
            );
          }).toList(),
          onChanged: (value) => setState(() => _flagReason = value),
        ),
      ),
    );
  }
}
