import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/core/theme/app_text_styles.dart';
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
  List<Map<String, dynamic>> _organizations = [];
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
      final orgs = await repo.fetchAllOrganizations();

      if (orgs.isEmpty) {
        setState(() {
          _errorMessage =
              'You are currently offline or no organizations are available. Please check your internet connection and try again.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _organizations = orgs;
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
        final cleanError = e.toString().replaceAll('Exception: ', '');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(cleanError),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrgs = _organizations.where((org) {
      final name = (org['name'] as String).toLowerCase();
      final acronym = (org['acronym'] as String).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || acronym.contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
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
                              final id = org['id'] as String;
                              final name = org['name'] as String;
                              final acronym = org['acronym'] as String;
                              final isSelected = _selectedOrgId == id;

                              return InkWell(
                                onTap: () => setState(() => _selectedOrgId = id),
                                borderRadius: BorderRadius.circular(12),
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
                                  child: Row(
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
                                            if (acronym.isNotEmpty)
                                              Text(
                                                acronym,
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Radio<String>(
                                        value: id,
                                        groupValue: _selectedOrgId,
                                        onChanged: (val) {
                                          setState(() => _selectedOrgId = val);
                                        },
                                        activeColor: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _selectedOrgId == null || _isSubmitting
                  ? null
                  : _submitJoinRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
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
                      'Send Join Request',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
