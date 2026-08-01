import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
import 'package:sti_sync/features/organizations/models/organization_model.dart';
import 'package:sti_sync/shared/providers/providers.dart';

class JoinOrganizationSheet extends ConsumerStatefulWidget {
  const JoinOrganizationSheet({super.key});

  @override
  ConsumerState<JoinOrganizationSheet> createState() =>
      _JoinOrganizationSheetState();
}

class _JoinOrganizationSheetState
    extends ConsumerState<JoinOrganizationSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<OrganizationModel> _organizations = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedOrgId;
  String _searchQuery = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrganizations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrganizations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(organizationRepositoryProvider);
      final rawOrgs = await repo.fetchAllOrganizations();

      if (rawOrgs.isEmpty) {
        setState(() {
          _errorMessage =
              'You are currently offline or no organizations are available. Please check your internet connection and try again.';
          _isLoading = false;
        });
        return;
      }

      final parsed = rawOrgs.map((data) {
        final id = data['id'] as String? ?? '';
        return OrganizationModel.fromFirestore(data, id);
      }).toList();

      setState(() {
        _organizations = parsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'You are currently offline. Please connect to the internet to browse and join organizations.';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitJoinRequest() async {
    if (_selectedOrgId == null) return;

    final student = ref.read(authViewModelProvider).student;
    if (student == null || student.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to join an organization.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(organizationRepositoryProvider);
      await repo.joinOrganization(
        student: student,
        organizationId: _selectedOrgId!,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Join request sent! Pending officer approval.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send join request: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = ref.watch(authViewModelProvider).student;
    final studentDeptId = student?.departmentId;
    final studentDeptName = student?.departmentName;

    final filteredOrgs = _organizations.where((org) {
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.trim().toLowerCase();
      return org.name.toLowerCase().contains(q) ||
          org.acronym.toLowerCase().contains(q);
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Join Organization',
                style: AppTextStyles.h2.copyWith(color: AppColors.primaryDark),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Text(
            'Select an organization to request membership. Your request will be sent to the officers for approval.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          // Search bar
          TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Search organization by name or code...',
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              filled: true,
              fillColor: AppColors.background,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Organizations list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      )
                    : filteredOrgs.isEmpty
                        ? const Center(
                            child: Text(
                              'No organizations found.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: filteredOrgs.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final org = filteredOrgs[index];
                              final id = org.id;
                              final name = org.name;
                              final acronym = org.acronym;
                              final isSelected = _selectedOrgId == id;
                              final isEligible = org.isStudentEligible(studentDeptId, studentDeptName);

                              return InkWell(
                                onTap: isEligible
                                    ? () => setState(() => _selectedOrgId = id)
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Opacity(
                                  opacity: isEligible ? 1.0 : 0.6,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.08)
                                          : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey.shade200,
                                        width: isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 20,
                                              backgroundColor: AppColors.primary,
                                              child: Text(
                                                acronym.isNotEmpty
                                                    ? (acronym.length > 2
                                                        ? acronym.substring(0, 2)
                                                        : acronym)
                                                    : 'ORG',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: AppTextStyles.bodyMedium
                                                        .copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.primaryDark,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  Row(
                                                    children: [
                                                      if (acronym.isNotEmpty) ...[
                                                        Text(
                                                          acronym,
                                                          style: const TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                      ],
                                                      // Scope badge
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: org.isDepartmental
                                                              ? AppColors.primary.withOpacity(0.1)
                                                              : AppColors.success.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(6),
                                                        ),
                                                        child: Text(
                                                          org.isDepartmental ? '🏢 Departmental' : '🌐 Open to All',
                                                          style: TextStyle(
                                                            color: org.isDepartmental ? AppColors.primary : AppColors.success,
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Radio<String>(
                                              value: id,
                                              groupValue: _selectedOrgId,
                                              onChanged: isEligible
                                                  ? (val) => setState(() => _selectedOrgId = val)
                                                  : null,
                                              activeColor: AppColors.primary,
                                            ),
                                          ],
                                        ),
                                        if (!isEligible) ...[
                                          const SizedBox(height: 6),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 52.0),
                                            child: Text(
                                              'Departmental club reserved for matching department students.',
                                              style: AppTextStyles.labelSmall.copyWith(
                                                color: AppColors.error,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),

          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: (_selectedOrgId != null && !_isSubmitting)
                  ? _submitJoinRequest
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Request to Join',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
