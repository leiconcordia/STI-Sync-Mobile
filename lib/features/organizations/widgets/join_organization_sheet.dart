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

enum OrgFilter {
  allEligible,
  myDepartment,
  crossDepartmental,
  all,
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
  OrgFilter _selectedFilter = OrgFilter.allEligible;

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

    final selectedOrg = _organizations.firstWhere(
      (o) => o.id == _selectedOrgId,
      orElse: () => _organizations.first,
    );

    if (!selectedOrg.isStudentEligible(student.departmentId, student.departmentName)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'This organization is restricted to ${selectedOrg.departmentName.isNotEmpty ? selectedOrg.departmentName : "departmental"} students.',
          ),
          backgroundColor: AppColors.error,
        ),
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
        final errorMsg = e.toString().replaceAll('Exception:', '').trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg.isNotEmpty ? errorMsg : 'Failed to send join request: $e'),
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
      if (_searchQuery.trim().isNotEmpty) {
        final q = _searchQuery.trim().toLowerCase();
        final matchesSearch = org.name.toLowerCase().contains(q) ||
            org.acronym.toLowerCase().contains(q) ||
            org.departmentName.toLowerCase().contains(q);
        if (!matchesSearch) return false;
      }

      final isEligible = org.isStudentEligible(studentDeptId, studentDeptName);

      switch (_selectedFilter) {
        case OrgFilter.allEligible:
          return isEligible;
        case OrgFilter.myDepartment:
          return !org.isCrossDepartmental && isEligible;
        case OrgFilter.crossDepartmental:
          return org.isCrossDepartmental;
        case OrgFilter.all:
          return true;
      }
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
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
            'Select an organization to request membership. Cross-departmental clubs are open to all students, while departmental clubs are exclusive to students of that department.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 14),

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
          const SizedBox(height: 12),

          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'All Eligible',
                  filter: OrgFilter.allEligible,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'My Department',
                  filter: OrgFilter.myDepartment,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Cross-Departmental',
                  filter: OrgFilter.crossDepartmental,
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: 'All Organizations',
                  filter: OrgFilter.all,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

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
                            child: Padding(
                              padding: EdgeInsets.all(24.0),
                              child: Text(
                                'No organizations found matching your criteria.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
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
                                    ? () {
                                        setState(() {
                                          _selectedOrgId = isSelected ? null : id;
                                        });
                                      }
                                    : null,
                                borderRadius: BorderRadius.circular(12),
                                child: Opacity(
                                  opacity: isEligible ? 1.0 : 0.55,
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColors.primary.withOpacity(0.08)
                                          : (isEligible ? Colors.white : Colors.grey.shade50),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : (isEligible ? Colors.grey.shade200 : Colors.grey.shade300),
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
                                              backgroundColor: isEligible ? AppColors.primary : Colors.grey.shade400,
                                              child: Text(
                                                acronym.isNotEmpty
                                                    ? (acronym.length > 2
                                                        ? acronym.substring(0, 2)
                                                        : acronym)
                                                    : 'OR',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    name,
                                                    style: AppTextStyles.bodyMedium.copyWith(
                                                      fontWeight: FontWeight.bold,
                                                      color: isEligible ? AppColors.primaryDark : Colors.grey.shade700,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 3),
                                                  Row(
                                                    children: [
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: org.isCrossDepartmental
                                                              ? AppColors.success.withOpacity(0.12)
                                                              : (isEligible
                                                                  ? AppColors.primary.withOpacity(0.12)
                                                                  : Colors.red.shade50),
                                                          borderRadius: BorderRadius.circular(6),
                                                          border: Border.all(
                                                            color: org.isCrossDepartmental
                                                                ? AppColors.success.withOpacity(0.3)
                                                                : (isEligible
                                                                    ? AppColors.primary.withOpacity(0.3)
                                                                    : Colors.red.shade200),
                                                            width: 0.8,
                                                          ),
                                                        ),
                                                        child: Text(
                                                          org.isCrossDepartmental
                                                              ? '🌐 Open to All Departments'
                                                              : (isEligible
                                                                  ? '🏛️ Your Department (${org.departmentName})'
                                                                  : '🔒 Restricted Department'),
                                                          style: TextStyle(
                                                            color: org.isCrossDepartmental
                                                                ? AppColors.success
                                                                : (isEligible
                                                                    ? AppColors.primary
                                                                    : Colors.red.shade700),
                                                            fontSize: 10,
                                                            fontWeight: FontWeight.w600,
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
                                          const SizedBox(height: 8),
                                          Container(
                                            margin: const EdgeInsets.only(left: 52.0),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Exclusive to ${org.departmentName.isNotEmpty ? org.departmentName : "matching department"} students. (Your department: ${studentDeptName ?? studentDeptId ?? "N/A"})',
                                              style: TextStyle(
                                                color: Colors.red.shade800,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
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

  Widget _buildFilterChip({
    required String label,
    required OrgFilter filter,
  }) {
    final isSelected = _selectedFilter == filter;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : AppColors.primaryDark,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = filter;
          });
        }
      },
      selectedColor: AppColors.primary,
      backgroundColor: Colors.grey.shade100,
      side: BorderSide(
        color: isSelected ? AppColors.primary : Colors.grey.shade300,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}
