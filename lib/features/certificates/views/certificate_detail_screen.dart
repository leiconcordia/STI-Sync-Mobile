import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/features/certificates/models/issued_certificate_model.dart';
import 'package:sti_sync/features/certificates/widgets/certificate_preview_canvas.dart';
import 'package:sti_sync/shared/providers/providers.dart';
import 'package:sti_sync/core/utils/date_formatter.dart';

class CertificateDetailScreen extends ConsumerWidget {
  final String certificateId;
  final IssuedCertificateModel? certificate;

  const CertificateDetailScreen({
    super.key,
    required this.certificateId,
    this.certificate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If certificate wasn't passed via extra, find it in the certificates stream
    final cert = certificate ??
        ref
            .watch(myCertificatesStreamProvider)
            .asData
            ?.value
            .where((c) => c.id == certificateId)
            .firstOrNull;

    if (cert == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Certificate Details',
            style: GoogleFonts.inter(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final templateAsync = ref.watch(certificateTemplateProvider(cert.templateId));
    final template = templateAsync.asData?.value;
    final downloadState = ref.watch(certificateViewModelProvider);
    final isDownloading = downloadState.isGenerating && downloadState.currentCertId == cert.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Certificate Preview',
          style: GoogleFonts.inter(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview Canvas
            CertificatePreviewCanvas(
              certificate: cert,
              template: template,
              isInteractive: true,
            ),
            const SizedBox(height: 24),

            // Metadata Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.verified, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cert.templateName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: AppColors.primaryDark,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Official Institutional Credential',
                              style: GoogleFonts.inter(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                  ),

                  _buildDetailRow(
                    icon: Icons.event,
                    label: 'Event Title',
                    value: cert.eventTitle,
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.person_outline,
                    label: 'Recipient',
                    value: cert.recipientName,
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.badge_outlined,
                    label: 'Student ID',
                    value: cert.studentId,
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.school_outlined,
                    label: 'Course & Section',
                    value: cert.course.isNotEmpty ? cert.course : 'STI Student',
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date Issued',
                    value: formatAppDate(cert.issuedAt),
                  ),
                  const SizedBox(height: 14),
                  _buildDetailRow(
                    icon: Icons.tag,
                    label: 'Certificate Reference',
                    value: cert.id.toUpperCase(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download & Export Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: isDownloading
                    ? null
                    : () async {
                        final success = await ref
                            .read(certificateViewModelProvider.notifier)
                            .downloadSingleCertificate(
                              context: context,
                              cert: cert,
                              template: template,
                            );
                        if (!context.mounted) return;
                        if (success) {
                          final savedPath = ref.read(certificateViewModelProvider).savedFilePath;
                          if (savedPath != null) {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: const Row(
                                  children: [
                                    Icon(Icons.check_circle, color: AppColors.success),
                                    SizedBox(width: 8),
                                    Text('Certificate Downloaded', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Your certificate has been saved to:'),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade300),
                                      ),
                                      child: SelectableText(
                                        savedPath,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Certificate downloaded and opened!'),
                                backgroundColor: AppColors.success,
                              ),
                            );
                          }
                        } else {
                          final err = ref.read(certificateViewModelProvider).error;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(err ?? 'Could not export certificate.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                icon: isDownloading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.download, size: 22),
                label: Text(
                  isDownloading ? 'Generating Certificate PDF...' : 'Download Certificate PDF',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: AppColors.primaryDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
