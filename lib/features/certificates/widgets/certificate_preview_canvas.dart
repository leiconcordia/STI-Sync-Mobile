import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sti_sync/core/theme/app_colors.dart';
import 'package:sti_sync/features/certificates/models/certificate_template_model.dart';
import 'package:sti_sync/features/certificates/models/issued_certificate_model.dart';

class CertificatePreviewCanvas extends StatelessWidget {
  final IssuedCertificateModel certificate;
  final CertificateTemplateModel? template;
  final bool isInteractive;

  const CertificatePreviewCanvas({
    super.key,
    required this.certificate,
    this.template,
    this.isInteractive = false,
  });

  Color _parseColor(String? hexString) {
    if (hexString == null || hexString.isEmpty) return const Color(0xFF001A4D);
    try {
      final buffer = StringBuffer();
      if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
      buffer.write(hexString.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (_) {
      return const Color(0xFF001A4D);
    }
  }

  TextAlign _parseTextAlign(String? align) {
    if (align == 'left') return TextAlign.left;
    if (align == 'right') return TextAlign.right;
    return TextAlign.center;
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = (template?.orientation.toLowerCase() ?? 'landscape') != 'portrait';
    final aspectRatio = isLandscape ? 1.414 : (1 / 1.414);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFBFBFA),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background Image from Template
            if (template != null && template!.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: template!.imageUrl,
                fit: BoxFit.fill,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFFBFBFA),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallbackBorder(),
              )
            else
              _buildFallbackBorder(),

            // 2. Text Elements directly from Admin Template
            LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                final h = constraints.maxHeight;

                // If template has defined elements from admin canvas
                if (template != null && template!.elements.isNotEmpty) {
                  return Stack(
                    children: template!.elements.map((elem) {
                      String displayText = elem.text;
                      if (elem.type == 'recipient_name' ||
                          displayText.contains('{recipientName}') ||
                          displayText.contains('{name}') ||
                          displayText.trim().isEmpty) {
                        displayText = displayText.isEmpty
                            ? certificate.recipientName
                            : displayText.replaceAll(
                                RegExp(r'\{recipientName\}|\{name\}'),
                                certificate.recipientName,
                              );
                      }

                      displayText = displayText
                          .replaceAll('{eventName}', certificate.eventTitle)
                          .replaceAll('{course}', certificate.course);

                      final left = (elem.xPercent / 100.0) * w;
                      final top = (elem.yPercent / 100.0) * h;
                      final width = (elem.widthPercent / 100.0) * w;
                      final fontSize = (elem.fontSizePt * (w / 800.0)).clamp(6.0, 36.0);
                      final color = _parseColor(elem.textColor);
                      final textAlign = _parseTextAlign(elem.textAlign);
                      final isBold = elem.fontWeight.toLowerCase().contains('bold');
                      final isItalic = elem.fontWeight.toLowerCase().contains('italic');

                      return Positioned(
                        left: (left - (width / 2)).clamp(0.0, w - width),
                        top: top.clamp(0.0, h - 20),
                        width: width,
                        child: Text(
                          displayText,
                          textAlign: textAlign,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.montserrat(
                            fontSize: fontSize,
                            color: color,
                            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                            fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                          ),
                        ),
                      );
                    }).toList(),
                  );
                } else {
                  // Fallback: only place recipient name at template namePosition
                  final pos = template?.namePosition ?? const CertificatePosition();
                  final left = (pos.xPercent / 100.0) * w;
                  final top = (pos.yPercent / 100.0) * h;
                  final width = (pos.widthPercent / 100.0) * w;
                  final fontSize = (pos.fontSizePt * (w / 800.0)).clamp(8.0, 36.0);
                  final color = _parseColor(pos.textColor);
                  final textAlign = _parseTextAlign(pos.textAlign);
                  final isBold = pos.fontWeight.toLowerCase().contains('bold');

                  return Stack(
                    children: [
                      Positioned(
                        left: (left - (width / 2)).clamp(0.0, w - width),
                        top: top.clamp(0.0, h - 30),
                        width: width,
                        child: Text(
                          certificate.recipientName,
                          textAlign: textAlign,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cinzel(
                            fontSize: fontSize,
                            color: color,
                            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBorder() {
    return Container(
      color: const Color(0xFFFBFBFA),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.primaryDark, width: 2.5),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFFFD41C), width: 1.2),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
