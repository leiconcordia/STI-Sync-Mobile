import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

enum AiDecision { autoApprove, autoReject, manualAdminReview }

class AiVerificationResult {
  final bool isActualStiId;
  final bool isBlurry;
  final bool isSelfieValidFace;
  final bool nameMatches;
  final String extractedName;
  final String idPhotoFaceDescription;
  final String selfiePhotoFaceDescription;
  final String comparisonAnalysis;
  final bool isSamePerson;
  final String facialDiscrepancies;
  final double faceMatchConfidence;
  final AiDecision decision;
  final String reason;

  const AiVerificationResult({
    required this.isActualStiId,
    required this.isBlurry,
    required this.isSelfieValidFace,
    required this.nameMatches,
    required this.extractedName,
    required this.idPhotoFaceDescription,
    required this.selfiePhotoFaceDescription,
    required this.comparisonAnalysis,
    required this.isSamePerson,
    required this.facialDiscrepancies,
    required this.faceMatchConfidence,
    required this.decision,
    required this.reason,
  });

  factory AiVerificationResult.fromJson(Map<String, dynamic> json) {
    AiDecision parseDecision(String? d) {
      switch (d) {
        case 'AUTO_APPROVE':
          return AiDecision.autoApprove;
        case 'AUTO_REJECT':
          return AiDecision.autoReject;
        case 'MANUAL_ADMIN_REVIEW':
        default:
          return AiDecision.manualAdminReview;
      }
    }

    return AiVerificationResult(
      isActualStiId: json['isActualStiId'] as bool? ?? false,
      isBlurry: json['isBlurry'] as bool? ?? false,
      isSelfieValidFace: json['isSelfieValidFace'] as bool? ?? false,
      nameMatches: json['nameMatches'] as bool? ?? false,
      extractedName: json['extractedName'] as String? ?? '',
      idPhotoFaceDescription: json['idPhotoFaceDescription'] as String? ?? '',
      selfiePhotoFaceDescription: json['selfiePhotoFaceDescription'] as String? ?? '',
      comparisonAnalysis: json['comparisonAnalysis'] as String? ?? '',
      isSamePerson: json['isSamePerson'] as bool? ?? false,
      facialDiscrepancies: json['facialDiscrepancies'] as String? ?? '',
      faceMatchConfidence: (json['faceMatchConfidence'] as num?)?.toDouble() ?? 0.0,
      decision: parseDecision(json['decision'] as String?),
      reason: json['reason'] as String? ?? 'No reason provided by AI.',
    );
  }
}

class GeminiAiVerificationService {
  final String _apiKey;

  GeminiAiVerificationService({String? apiKey})
      : _apiKey = apiKey ?? const String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const List<String> _candidateModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-2.0-flash-lite',
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-flash-latest',
    'gemini-pro-latest',
  ];

  /// Verifies student registration using Gemini Multimodal Vision API.
  Future<AiVerificationResult> verifyStudentIdentity({
    required File schoolIdFile,
    required File profilePhotoFile,
    required String registeredName,
  }) async {
    try {
      final idBytes = await schoolIdFile.readAsBytes();
      final selfieBytes = await profilePhotoFile.readAsBytes();

      final idMime = _getMimeType(schoolIdFile);
      final selfieMime = _getMimeType(profilePhotoFile);

      final idBase64 = base64Encode(idBytes);
      final selfieBase64 = base64Encode(selfieBytes);

      final promptText = '''
You are an Intelligent Biometric & Document Verification AI examining an STI student enrollment registration.

Verify the uploaded documents across these criteria:

1. DOCUMENT VALIDITY (isActualStiId):
   - Check IMAGE 1 to confirm it is an official STI College document:
     a) STI Student ID Card (Front) containing STI branding, logo, or colors.
     b) STI Certificate of Registration (COR) / Enrollment Assessment Form containing STI header and student details.
   - If IMAGE 1 is an entirely unrelated document (e.g. random selfie, government ID with no STI affiliation, blank/black image), set `isActualStiId = false`.

2. IMAGE QUALITY & BLUR CHECK (isBlurry):
   - Check if IMAGE 1 or IMAGE 2 is completely illegible, black, or severely out of focus such that text or face cannot be recognized. (Minor mobile camera grain is acceptable; set `isBlurry = false` if text and face are recognizable).

3. SELFIE FACE VALIDATION (isSelfieValidFace):
   - Check if IMAGE 2 contains a recognizable human face.

4. NAME MATCHING (nameMatches):
   - Extract the printed student name from IMAGE 1 (Document) and compare it against the Registered Full Name ("$registeredName").
   - Allow common name order variations (e.g. "Last, First Middle" vs "First Middle Last") and minor spacing or middle initial differences.

5. FACIAL COMPARISON & CONFIDENCE:
   - If IMAGE 1 has a portrait photo, compare facial features with IMAGE 2 selfie.
   - If IMAGE 1 is a COR/document without a photo, evaluate based on document authenticity and name match.
   - `faceMatchConfidence`: Score between 0.0 and 1.0 (e.g. 0.85 - 0.99 for matching individuals).

DECISION RULES:
- "AUTO_APPROVE": Output if isActualStiId is true AND isSelfieValidFace is true AND isBlurry is false AND nameMatches is true.
- "AUTO_REJECT": Output if isActualStiId is false OR isSelfieValidFace is false OR isBlurry is true OR nameMatches is false.
- "MANUAL_ADMIN_REVIEW": Output ONLY if there is significant doubt that requires human staff inspection.

Respond STRICTLY in JSON format matching this exact schema:
{
  "isActualStiId": boolean,
  "isBlurry": boolean,
  "isSelfieValidFace": boolean,
  "nameMatches": boolean,
  "extractedName": string,
  "idPhotoFaceDescription": string,
  "selfiePhotoFaceDescription": string,
  "comparisonAnalysis": string,
  "isSamePerson": boolean,
  "facialDiscrepancies": string,
  "faceMatchConfidence": number,
  "decision": "AUTO_APPROVE" | "AUTO_REJECT" | "MANUAL_ADMIN_REVIEW",
  "reason": string
}
''';

      debugPrint('=== GEMINI MULTI-AGENT AI VERIFICATION START ===');
      debugPrint('Registered Name: "$registeredName"');
      debugPrint('School Document File: ${schoolIdFile.path} (${idBytes.length} bytes, $idMime)');
      debugPrint('Profile Selfie File: ${profilePhotoFile.path} (${selfieBytes.length} bytes, $selfieMime)');

      final requestBody = jsonEncode({
        'contents': [
          {
            'parts': [
              {'text': promptText},
              {'text': '=== IMAGE 1: STI SCHOOL ID CARD OR CERTIFICATE OF REGISTRATION (COR) ==='},
              {
                'inlineData': {
                  'mimeType': idMime,
                  'data': idBase64,
                }
              },
              {'text': '=== IMAGE 2: STUDENT SELFIE FACE PHOTO ==='},
              {
                'inlineData': {
                  'mimeType': selfieMime,
                  'data': selfieBase64,
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
        }
      });

      for (final model in _candidateModels) {
        try {
          final uri = Uri.parse(
              'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$_apiKey');

          final response = await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          ).timeout(const Duration(seconds: 15));

          debugPrint('Gemini Agent ($model) HTTP Status: ${response.statusCode}');
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            final candidates = data['candidates'] as List<dynamic>?;
            if (candidates != null && candidates.isNotEmpty) {
              final rawText = candidates.first['content']?['parts']?.first?['text']?.toString() ?? '{}';
              final Map<String, dynamic> parsedJson = jsonDecode(rawText) as Map<String, dynamic>;
              return _enforceRules(AiVerificationResult.fromJson(parsedJson), registeredName);
            }
          } else {
            debugPrint('Gemini Agent ($model) response error: ${response.body}');
          }
        } catch (e) {
          debugPrint('Gemini Agent ($model) error or timeout: $e — falling back to next candidate');
        }
      }

      return _fallbackResult('AI service models unavailable. Application routed to admin review.');
    } catch (e) {
      debugPrint('Gemini AI Verification Exception: $e');
      return _fallbackResult('AI verification error ($e). Defaulting to manual admin review.');
    }
  }

  /// Programmatic safety post-processor enforcing exact user business rules:
  /// - AUTO_REJECT if Not STI document, No selfie face, Name mismatch, or Illegible/Blurry.
  /// - AUTO_APPROVE if Document is valid, Selfie face is valid, Not blurry, and Name matches.
  /// - MANUAL_ADMIN_REVIEW otherwise.
  AiVerificationResult _enforceRules(AiVerificationResult result, String registeredName) {
    debugPrint('=== GEMINI PARSED RESULT BEFORE ENFORCEMENT ===');
    debugPrint('isActualStiId: ${result.isActualStiId}');
    debugPrint('isSelfieValidFace: ${result.isSelfieValidFace}');
    debugPrint('nameMatches: ${result.nameMatches}');
    debugPrint('extractedName: "${result.extractedName}"');
    debugPrint('isBlurry: ${result.isBlurry}');
    debugPrint('faceMatchConfidence: ${result.faceMatchConfidence}');
    debugPrint('raw decision: ${result.decision}');
    debugPrint('raw reason: ${result.reason}');

    if (!result.isActualStiId || !result.isSelfieValidFace || !result.nameMatches || result.isBlurry) {
      String reason = result.reason;
      if (!result.isActualStiId) {
        reason = 'Uploaded document is not a valid STI Student ID card or Certificate of Registration (COR).';
      } else if (!result.isSelfieValidFace) {
        reason = 'Selfie photo does not contain a clear human face.';
      } else if (!result.nameMatches) {
        final extName = result.extractedName.isNotEmpty ? result.extractedName : 'unclear';
        reason = 'Name on school document ("$extName") does not match your registered name ("$registeredName").';
      } else if (result.isBlurry) {
        reason = 'Uploaded document or photo is blurry, out of focus, or illegible.';
      }
      final finalResult = AiVerificationResult(
        isActualStiId: result.isActualStiId,
        isBlurry: result.isBlurry,
        isSelfieValidFace: result.isSelfieValidFace,
        nameMatches: result.nameMatches,
        extractedName: result.extractedName,
        idPhotoFaceDescription: result.idPhotoFaceDescription,
        selfiePhotoFaceDescription: result.selfiePhotoFaceDescription,
        comparisonAnalysis: result.comparisonAnalysis,
        isSamePerson: result.isSamePerson,
        facialDiscrepancies: result.facialDiscrepancies,
        faceMatchConfidence: result.faceMatchConfidence,
        decision: AiDecision.autoReject,
        reason: reason,
      );
      debugPrint('=== FINAL ENFORCED DECISION: AUTO_REJECT (RETURNED) ===');
      debugPrint('Reason: ${finalResult.reason}');
      return finalResult;
    }

    // All document & text checks passed (STI ID valid, Selfie valid face, Name matched, Not blurry).
    // Auto-approve registration as requested:
    final finalResult = AiVerificationResult(
      isActualStiId: result.isActualStiId,
      isBlurry: result.isBlurry,
      isSelfieValidFace: result.isSelfieValidFace,
      nameMatches: result.nameMatches,
      extractedName: result.extractedName,
      idPhotoFaceDescription: result.idPhotoFaceDescription,
      selfiePhotoFaceDescription: result.selfiePhotoFaceDescription,
      comparisonAnalysis: result.comparisonAnalysis,
      isSamePerson: result.isSamePerson,
      facialDiscrepancies: result.facialDiscrepancies,
      faceMatchConfidence: result.faceMatchConfidence,
      decision: AiDecision.autoApprove,
      reason: 'Official STI ID Card and student name verified by AI. Identity automatically approved.',
    );
    debugPrint('=== FINAL ENFORCED DECISION: AUTO_APPROVE (ACTIVE) ===');
    debugPrint('Reason: ${finalResult.reason}');
    return finalResult;
  }

  AiVerificationResult _fallbackResult(String reason) {
    return AiVerificationResult(
      isActualStiId: true,
      isBlurry: true,
      isSelfieValidFace: true,
      nameMatches: false,
      extractedName: '',
      idPhotoFaceDescription: '',
      selfiePhotoFaceDescription: '',
      comparisonAnalysis: '',
      isSamePerson: false,
      facialDiscrepancies: 'AI fallback triggered.',
      faceMatchConfidence: 0.0,
      decision: AiDecision.manualAdminReview,
      reason: reason,
    );
  }

  String _getMimeType(File file) {
    final path = file.path.toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.heic') || path.endsWith('.heif')) return 'image/heic';
    return 'image/jpeg';
  }
}
