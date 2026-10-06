import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:sti_sync/features/certificates/models/issued_certificate_model.dart';
import 'package:sti_sync/features/certificates/models/certificate_template_model.dart';
import 'package:sti_sync/features/certificates/repositories/certificate_repository.dart';

class CertificateDownloadState {
  final bool isGenerating;
  final String? error;
  final String? currentCertId;
  final String? savedFilePath;

  const CertificateDownloadState({
    this.isGenerating = false,
    this.error,
    this.currentCertId,
    this.savedFilePath,
  });

  CertificateDownloadState copyWith({
    bool? isGenerating,
    String? error,
    String? currentCertId,
    String? savedFilePath,
  }) {
    return CertificateDownloadState(
      isGenerating: isGenerating ?? this.isGenerating,
      error: error,
      currentCertId: currentCertId ?? this.currentCertId,
      savedFilePath: savedFilePath ?? this.savedFilePath,
    );
  }
}

class CertificateViewModel extends StateNotifier<CertificateDownloadState> {
  final CertificateRepository _repository;

  CertificateViewModel(this._repository) : super(const CertificateDownloadState());

  /// Generates a high-definition single-recipient PDF for the logged-in student,
  /// saves it locally to the device downloads/documents folder, and launches
  /// the system print & PDF save dialog.
  Future<bool> downloadSingleCertificate({
    required BuildContext context,
    required IssuedCertificateModel cert,
    CertificateTemplateModel? template,
  }) async {
    state = state.copyWith(
      isGenerating: true,
      error: null,
      currentCertId: cert.id,
      savedFilePath: null,
    );

    try {
      // 1. Resolve template if not provided
      final resolvedTemplate = template ?? await _repository.getTemplateById(cert.templateId);
      final pdfDoc = pw.Document();

      // 2. Determine Page Format & Dimensions
      final isLandscape = (resolvedTemplate?.orientation.toLowerCase() ?? 'landscape') != 'portrait';
      PdfPageFormat format = PdfPageFormat.a4;
      if (resolvedTemplate?.paperSize == 'letter' || resolvedTemplate?.paperSize == 'short') {
        format = PdfPageFormat.letter;
      }
      final pageFormat = isLandscape ? format.landscape : format.portrait;

      // 3. Load background image if available
      Uint8List? bgImageBytes;
      if (resolvedTemplate != null && resolvedTemplate.imageUrl.isNotEmpty) {
        try {
          final response = await http.get(Uri.parse(resolvedTemplate.imageUrl)).timeout(
            const Duration(seconds: 10),
          );
          if (response.statusCode == 200) {
            bgImageBytes = response.bodyBytes;
          }
        } catch (e) {
          debugPrint('Template background image fetch error (falling back to frame): $e');
        }
      }

      pw.MemoryImage? memImage;
      if (bgImageBytes != null && bgImageBytes.isNotEmpty) {
        try {
          memImage = pw.MemoryImage(bgImageBytes);
        } catch (e) {
          debugPrint('Template background image decode error: $e');
          memImage = null;
        }
      }

      // 4. Safe Unicode Font Resolution
      pw.Font boldFont = pw.Font.helveticaBold();
      pw.Font regularFont = pw.Font.helvetica();
      try {
        boldFont = await PdfGoogleFonts.montserratBold();
        regularFont = await PdfGoogleFonts.montserratRegular();
      } catch (_) {
        // Fallback to standard Helvetica if offline
      }

      // Helper color parsing for PDF
      PdfColor parsePdfColor(String? hexString) {
        if (hexString == null || hexString.isEmpty) return PdfColor.fromHex('#001A4D');
        try {
          String cleanHex = hexString.replaceFirst('#', '');
          if (cleanHex.length == 6 || cleanHex.length == 8) {
            return PdfColor.fromHex('#$cleanHex');
          }
          return PdfColor.fromHex('#001A4D');
        } catch (_) {
          return PdfColor.fromHex('#001A4D');
        }
      }

      pw.TextAlign parsePdfTextAlign(String? align) {
        if (align == 'left') return pw.TextAlign.left;
        if (align == 'right') return pw.TextAlign.right;
        return pw.TextAlign.center;
      }

      // 5. Construct Single-Recipient PDF Document
      // Only renders admin-positioned text elements or recipient name (no added dates or hardcoded phrases)
      pdfDoc.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (pw.Context pwContext) {
            final double pwWidth = pageFormat.width;
            final double pwHeight = pageFormat.height;

            return pw.Stack(
              fit: pw.StackFit.expand,
              children: [
                // Template Background Image (or minimal fallback background)
                if (memImage != null)
                  pw.Positioned.fill(
                    child: pw.Image(
                      memImage,
                      fit: pw.BoxFit.fill,
                    ),
                  )
                else
                  pw.Positioned.fill(
                    child: pw.Container(
                      color: PdfColor.fromHex('#FCFCFD'),
                    ),
                  ),

                // Admin-defined text elements only
                if (resolvedTemplate != null && resolvedTemplate.elements.isNotEmpty)
                  ...resolvedTemplate.elements.map((elem) {
                    String displayText = elem.text;
                    if (elem.type == 'recipient_name' ||
                        displayText.contains('{recipientName}') ||
                        displayText.contains('{name}') ||
                        displayText.trim().isEmpty) {
                      displayText = displayText.isEmpty
                          ? cert.recipientName
                          : displayText.replaceAll(
                              RegExp(r'\{recipientName\}|\{name\}'),
                              cert.recipientName,
                            );
                    }

                    displayText = displayText
                        .replaceAll('{eventName}', cert.eventTitle)
                        .replaceAll('{course}', cert.course);

                    final left = (elem.xPercent / 100.0) * pwWidth;
                    final top = (elem.yPercent / 100.0) * pwHeight;
                    final width = (elem.widthPercent / 100.0) * pwWidth;
                    final isBold = elem.fontWeight.toLowerCase().contains('bold');
                    final isItalic = elem.fontWeight.toLowerCase().contains('italic');
                    final font = isBold ? boldFont : regularFont;
                    final color = parsePdfColor(elem.textColor);
                    final textAlign = parsePdfTextAlign(elem.textAlign);
                    final fontSize = elem.fontSizePt > 0 ? elem.fontSizePt : 14.0;

                    return pw.Positioned(
                      left: (left - (width / 2)).clamp(0.0, pwWidth - width),
                      top: top.clamp(0.0, pwHeight - 20),
                      child: pw.SizedBox(
                        width: width,
                        child: pw.Text(
                          displayText,
                          textAlign: textAlign,
                          style: pw.TextStyle(
                            font: font,
                            fontStyle: isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
                            fontSize: fontSize,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  })
                else ...[
                  // Fallback: render only recipient name at namePosition
                  () {
                    final pos = resolvedTemplate?.namePosition ?? const CertificatePosition();
                    final left = (pos.xPercent / 100.0) * pwWidth;
                    final top = (pos.yPercent / 100.0) * pwHeight;
                    final width = (pos.widthPercent / 100.0) * pwWidth;
                    final fontSize = pos.fontSizePt > 0 ? pos.fontSizePt : 24.0;
                    final color = parsePdfColor(pos.textColor);
                    final textAlign = parsePdfTextAlign(pos.textAlign);
                    final isBold = pos.fontWeight.toLowerCase().contains('bold');

                    return pw.Positioned(
                      left: (left - (width / 2)).clamp(0.0, pwWidth - width),
                      top: top.clamp(0.0, pwHeight - 30),
                      child: pw.SizedBox(
                        width: width,
                        child: pw.Text(
                          cert.recipientName,
                          textAlign: textAlign,
                          style: pw.TextStyle(
                            font: isBold ? boldFont : regularFont,
                            fontSize: fontSize,
                            color: color,
                          ),
                        ),
                      ),
                    );
                  }(),
                ],
              ],
            );
          },
        ),
      );

      final safeName = cert.eventTitle.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '${safeName}_Certificate_${cert.studentId}.pdf';
      final pdfBytes = await pdfDoc.save();

      // 6. Direct Local Storage Save (Downloads directory)
      String? localSavedPath;
      if (!kIsWeb) {
        try {
          Directory? targetDir;
          if (Platform.isWindows) {
            // First check user profile Downloads
            final userProfile = Platform.environment['USERPROFILE'];
            if (userProfile != null && userProfile.isNotEmpty) {
              final dl = Directory('$userProfile\\Downloads');
              if (dl.existsSync()) {
                targetDir = dl;
              }
            }
            targetDir ??= await getDownloadsDirectory();
          } else if (Platform.isMacOS || Platform.isLinux) {
            targetDir = await getDownloadsDirectory();
          } else if (Platform.isAndroid) {
            // Use public Downloads directory on Android so user can easily find it in Files
            final publicDownload = Directory('/storage/emulated/0/Download');
            if (publicDownload.existsSync()) {
              targetDir = publicDownload;
            } else {
              targetDir = await getDownloadsDirectory() ??
                  await getExternalStorageDirectory() ??
                  await getApplicationDocumentsDirectory();
            }
          } else {
            targetDir = await getApplicationDocumentsDirectory();
          }

          if (targetDir != null) {
            final file = File('${targetDir.path}${Platform.pathSeparator}$fileName');
            await file.writeAsBytes(pdfBytes, flush: true);
            localSavedPath = file.path;
            debugPrint('Certificate PDF saved directly to: $localSavedPath');

            // On Windows desktop, reveal the downloaded file in File Explorer
            if (Platform.isWindows) {
              try {
                await Process.run('explorer.exe', ['/select,', localSavedPath]);
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint('Local file save note: $e');
        }
      }

      // 7. System Print / Save As PDF / Share Sheet Launch
      try {
        if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
          try {
            await Printing.sharePdf(
              bytes: pdfBytes,
              filename: fileName,
            );
          } catch (_) {
            await Printing.layoutPdf(
              onLayout: (PdfPageFormat format) async => pdfBytes,
              name: fileName,
            );
          }
        } else {
          // Desktop (Windows/macOS/Linux) or Web: opens system print/save-as-PDF dialog
          await Printing.layoutPdf(
            onLayout: (PdfPageFormat format) async => pdfBytes,
            name: fileName,
          );
        }
      } catch (printErr) {
        debugPrint('Printing channel note (restart required if newly installed): $printErr');
      }

      state = state.copyWith(
        isGenerating: false,
        error: null,
        currentCertId: null,
        savedFilePath: localSavedPath,
      );
      return true;
    } catch (e, stack) {
      debugPrint('Certificate PDF generation error: $e\n$stack');
      state = state.copyWith(
        isGenerating: false,
        error: 'Please restart the app (full restart required for new plugins). Detail: $e',
        currentCertId: null,
      );
      return false;
    }
  }
}
