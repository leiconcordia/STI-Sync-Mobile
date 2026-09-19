import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sti_sync/core/config/app_config.dart';

enum AiDecision { autoApprove, autoReject, manualAdminReview }

class AiVerificationResult {
  final bool isActualStiId;
  final bool isBlurry;
  final bool isSelfieValidFace;
  final bool nameMatches;
  final String extractedName;
  final String extractedStudentId;
  final String idPhotoFaceDescription;
  final String selfiePhotoFaceDescription;
  final String comparisonAnalysis;
  final bool isSamePerson;
  final String facialDiscrepancies;
  final double faceMatchConfidence;
  final AiDecision decision;
  final String reason;
  final String errorCode;
  final String userFriendlyMessage;

  const AiVerificationResult({
    required this.isActualStiId,
    required this.isBlurry,
    required this.isSelfieValidFace,
    required this.nameMatches,
    required this.extractedName,
    this.extractedStudentId = '',
    required this.idPhotoFaceDescription,
    required this.selfiePhotoFaceDescription,
    required this.comparisonAnalysis,
    required this.isSamePerson,
    required this.facialDiscrepancies,
    required this.faceMatchConfidence,
    required this.decision,
    required this.reason,
    this.errorCode = 'NONE',
    this.userFriendlyMessage = '',
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
      extractedStudentId: json['extractedStudentId'] as String? ?? '',
      idPhotoFaceDescription: json['idPhotoFaceDescription'] as String? ?? '',
      selfiePhotoFaceDescription: json['selfiePhotoFaceDescription'] as String? ?? '',
      comparisonAnalysis: json['comparisonAnalysis'] as String? ?? '',
      isSamePerson: json['isSamePerson'] as bool? ?? false,
      facialDiscrepancies: json['facialDiscrepancies'] as String? ?? '',
      faceMatchConfidence: (json['faceMatchConfidence'] as num?)?.toDouble() ?? 0.0,
      decision: parseDecision(json['decision'] as String?),
      reason: json['reason'] as String? ?? 'No reason provided by AI.',
      errorCode: json['errorCode'] as String? ?? 'NONE',
      userFriendlyMessage: json['userFriendlyMessage'] as String? ?? '',
    );
  }
}

class GeminiAiVerificationService {
  final String _apiKey;

  GeminiAiVerificationService({String? apiKey})
      : _apiKey = (apiKey != null && apiKey.isNotEmpty)
            ? apiKey
            : AppConfig.geminiApiKey;

  static const List<String> _candidateModels = [
    'gemini-flash-latest',
    'gemini-3.6-flash',
    'gemini-3.5-flash',
    'gemini-flash-lite-latest',
    'gemini-2.0-flash',
  ];

  /// Fetches an optional dynamic API key from Firestore `/system_configs/ai`
  Future<String?> _fetchDynamicApiKey() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('system_configs')
          .doc('ai')
          .get()
          .timeout(const Duration(seconds: 4));
      if (doc.exists) {
        final data = doc.data();
        final key = data?['geminiApiKey'] as String? ?? data?['apiKey'] as String?;
        if (key != null && key.trim().isNotEmpty) {
          return key.trim();
        }
      }
    } catch (_) {
      // Ignore network / permission errors and proceed with built-in keys
    }
    return null;
  }

  /// Verifies student registration using Gemini Multimodal Vision API.
  Future<AiVerificationResult> verifyStudentIdentity({
    required File schoolIdFile,
    required File profilePhotoFile,
    required String registeredName,
    String registeredStudentId = '',
  }) async {
    try {
      final idBytes = await schoolIdFile.readAsBytes();
      final selfieBytes = await profilePhotoFile.readAsBytes();

      final idMime = _getMimeType(schoolIdFile);
      final selfieMime = _getMimeType(profilePhotoFile);

      final idBase64 = base64Encode(idBytes);
      final selfieBase64 = base64Encode(selfieBytes);

      final promptText = '''
You are an expert Biometric & Document Verification AI verifying an STI College student enrollment registration.

Examine the two images against STI College ID front physical verification criteria:

=== PHYSICAL STI ID CARD FRONT LAYOUT ===
On the front of an official STI College student ID (e.g. STI College Ormoc), only the following are visible:
1. STI LOGO and "STI COLLEGE ORMOC" (or "STI COLLEGE") banner / header with STI blue/yellow branding.
2. PORTRAIT PICTURE of the student.
3. PRINTED FULL NAME of the student.
4. VALIDATION BADGE / STICKER for the academic term (e.g., "SY 2026-27 1st Term").
Note: Student ID number is NOT printed on the front of this ID card. Do NOT reject the document for lacking an ID number.

=== VERIFICATION CRITERIA ===
1. STI BRANDING & DOCUMENT VALIDITY (isActualStiId):
   - Confirm IMAGE 1 is an official STI College document:
     a) Official STI Student ID Card (Front) containing the STI logo, "STI COLLEGE" / "STI COLLEGE ORMOC", or signature blue/yellow STI branding.
     b) Or official STI Certificate of Registration (COR) / Assessment Form containing STI header and student details.
   - If IMAGE 1 is an unrelated non-STI ID (e.g. government ID, another school, driver's license, random object, blank), set `isActualStiId = false`.

2. FULL NAME MATCHING (nameMatches):
   - Extract the printed student name from IMAGE 1: `extractedName`.
   - Compare `extractedName` against the Registered Full Name: "$registeredName".
   - Accept common name orderings (e.g. "LAST, FIRST MIDDLE" vs "FIRST MIDDLE LAST") and middle initial variations (e.g. "J." vs "Junior" or omitted middle name).
   - If the names match or clearly correspond to the same student, set `nameMatches = true`. If completely different, set `nameMatches = false`.

3. LIVE SELFIE VALIDATION (isSelfieValidFace):
   - Check IMAGE 2 to confirm it contains a clear, unobstructed human face looking towards the camera (no sunglasses, face masks, or obscuring hats).

4. BIOMETRIC FACIAL COMPARISON (isSamePerson & faceMatchConfidence):
   - Compare the student picture on IMAGE 1 (STI ID portrait) with the live selfie in IMAGE 2.
   - Evaluate facial structure, eyes, nose, and jawline.
   - `faceMatchConfidence`: Decimal score from 0.0 to 1.0 (0.80 - 0.99 for matching faces).
   - If IMAGE 1 is a COR document without a portrait photo, evaluate authenticity and name match.

5. DOCUMENT CLARITY (isBlurry):
   - If IMAGE 1 or IMAGE 2 is severely blurry, illegible, pitch black, or covered in flash glare masking the name or face, set `isBlurry = true`.
   - Normal mobile camera grain/compression is fine if text and face are recognizable.

DECISION RULES:
- "AUTO_APPROVE": Output if isActualStiId is true AND isSelfieValidFace is true AND isBlurry is false AND nameMatches is true.
- "AUTO_REJECT": Output if isActualStiId is false OR isSelfieValidFace is false OR isBlurry is true OR nameMatches is false.
- "MANUAL_ADMIN_REVIEW": Output ONLY if there is reasonable doubt that requires human SAO staff inspection.

Respond STRICTLY in JSON format matching this exact schema:
{
  "isActualStiId": boolean,
  "isBlurry": boolean,
  "isSelfieValidFace": boolean,
  "nameMatches": boolean,
  "extractedName": string,
  "extractedStudentId": string,
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
      if (registeredStudentId.isNotEmpty) {
        debugPrint('Registered Student ID: "$registeredStudentId"');
      }
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

      // Gather candidate keys: dynamic Firestore key -> configured key -> fallback key
      final dynamicKey = await _fetchDynamicApiKey();
      final candidateKeys = <String>[
        if (dynamicKey != null) dynamicKey,
        _apiKey,
        AppConfig.googleFallbackApiKey,
      ].where((k) => k.isNotEmpty).toSet().toList();

      for (final key in candidateKeys) {
        final keyPrefix = key.length > 8 ? key.substring(0, 8) : key;
        for (final model in _candidateModels) {
          try {
            debugPrint('Trying Gemini Agent ($model) with key prefix ($keyPrefix)...');
            final uri = Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$key');

            final response = await http.post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: requestBody,
            ).timeout(const Duration(seconds: 22));

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
            debugPrint('Gemini Agent ($model) error or timeout: $e — trying next candidate');
          }
        }
      }

      return _fallbackResult('Your registration has been submitted for manual review by SAO staff.');
    } catch (e) {
      debugPrint('Gemini AI Verification Exception: $e');
      return _fallbackResult('Your registration has been submitted for manual review by SAO staff.');
    }
  }

  /// Programmatic safety post-processor enforcing exact business rules:
  /// - AUTO_REJECT if Not STI document, No selfie face, Name mismatch, or Illegible/Blurry.
  /// - AUTO_APPROVE if Document is valid, Selfie face is valid, Not blurry, and Name matches.
  /// - MANUAL_ADMIN_REVIEW otherwise.
  AiVerificationResult _enforceRules(AiVerificationResult result, String registeredName) {
    debugPrint('=== GEMINI PARSED RESULT BEFORE ENFORCEMENT ===');
    debugPrint('isActualStiId: ${result.isActualStiId}');
    debugPrint('isSelfieValidFace: ${result.isSelfieValidFace}');
    debugPrint('nameMatches: ${result.nameMatches}');
    debugPrint('extractedName: "${result.extractedName}"');
    debugPrint('extractedStudentId: "${result.extractedStudentId}"');
    debugPrint('isBlurry: ${result.isBlurry}');
    debugPrint('faceMatchConfidence: ${result.faceMatchConfidence}');
    debugPrint('raw decision: ${result.decision}');
    debugPrint('raw reason: ${result.reason}');

    if (!result.isActualStiId || !result.isSelfieValidFace || !result.nameMatches || result.isBlurry) {
      String reason = result.reason;
      String errorCode = 'REJECTED';
      String userFriendlyMessage = 'Please check your submitted documents.';

      if (!result.isActualStiId) {
        errorCode = 'NOT_STI_DOC';
        reason = 'Uploaded document is not a recognized STI Student ID card or Certificate of Registration (COR).';
        userFriendlyMessage = 'Document not recognized as an official STI ID or Certificate of Registration. Please ensure the STI logo and all 4 corners are clearly visible.';
      } else if (result.isBlurry) {
        errorCode = 'BLURRY_OR_GLARE';
        reason = 'Uploaded document or photo is blurry, out of focus, or obscured by glare.';
        userFriendlyMessage = 'Photo is blurry or glare was detected. Please place your ID flat under good lighting and retake the photo.';
      } else if (!result.isSelfieValidFace) {
        errorCode = 'NO_FACE';
        reason = 'Selfie photo does not contain a clear, unobstructed human face.';
        userFriendlyMessage = 'Selfie photo does not contain a clear human face. Please take a well-lit photo looking directly at the camera without hats or masks.';
      } else if (!result.nameMatches) {
        errorCode = 'NAME_MISMATCH';
        final extName = result.extractedName.isNotEmpty ? result.extractedName : 'unclear';
        reason = 'Name on school document ("$extName") does not match your registered name ("$registeredName").';
        userFriendlyMessage = 'Name on school document does not match your registered name. Please verify your name spelling or upload your own ID.';
      }

      final finalResult = AiVerificationResult(
        isActualStiId: result.isActualStiId,
        isBlurry: result.isBlurry,
        isSelfieValidFace: result.isSelfieValidFace,
        nameMatches: result.nameMatches,
        extractedName: result.extractedName,
        extractedStudentId: result.extractedStudentId,
        idPhotoFaceDescription: result.idPhotoFaceDescription,
        selfiePhotoFaceDescription: result.selfiePhotoFaceDescription,
        comparisonAnalysis: result.comparisonAnalysis,
        isSamePerson: result.isSamePerson,
        facialDiscrepancies: result.facialDiscrepancies,
        faceMatchConfidence: result.faceMatchConfidence,
        decision: AiDecision.autoReject,
        reason: reason,
        errorCode: errorCode,
        userFriendlyMessage: userFriendlyMessage,
      );
      debugPrint('=== FINAL ENFORCED DECISION: AUTO_REJECT (RETURNED) ===');
      debugPrint('Reason: ${finalResult.reason}');
      debugPrint('User Message: ${finalResult.userFriendlyMessage}');
      return finalResult;
    }

    // Check if portrait photo on ID was compared and failed
    if (result.idPhotoFaceDescription.isNotEmpty && !result.isSamePerson && result.faceMatchConfidence < 0.45) {
      final finalResult = AiVerificationResult(
        isActualStiId: result.isActualStiId,
        isBlurry: result.isBlurry,
        isSelfieValidFace: result.isSelfieValidFace,
        nameMatches: result.nameMatches,
        extractedName: result.extractedName,
        extractedStudentId: result.extractedStudentId,
        idPhotoFaceDescription: result.idPhotoFaceDescription,
        selfiePhotoFaceDescription: result.selfiePhotoFaceDescription,
        comparisonAnalysis: result.comparisonAnalysis,
        isSamePerson: false,
        facialDiscrepancies: result.facialDiscrepancies,
        faceMatchConfidence: result.faceMatchConfidence,
        decision: AiDecision.autoReject,
        reason: 'Face in selfie does not match the portrait on the school ID.',
        errorCode: 'FACE_MISMATCH',
        userFriendlyMessage: 'The portrait on your ID does not match your live selfie. Please ensure you upload your own STI ID and a recent selfie.',
      );
      debugPrint('=== FINAL ENFORCED DECISION: AUTO_REJECT (FACE_MISMATCH) ===');
      return finalResult;
    }

    // All document & text checks passed (STI ID valid, Selfie valid face, Name matched, Not blurry).
    // Auto-approve registration:
    final finalResult = AiVerificationResult(
      isActualStiId: result.isActualStiId,
      isBlurry: result.isBlurry,
      isSelfieValidFace: result.isSelfieValidFace,
      nameMatches: result.nameMatches,
      extractedName: result.extractedName,
      extractedStudentId: result.extractedStudentId,
      idPhotoFaceDescription: result.idPhotoFaceDescription,
      selfiePhotoFaceDescription: result.selfiePhotoFaceDescription,
      comparisonAnalysis: result.comparisonAnalysis,
      isSamePerson: result.isSamePerson,
      facialDiscrepancies: result.facialDiscrepancies,
      faceMatchConfidence: result.faceMatchConfidence,
      decision: AiDecision.autoApprove,
      reason: 'Official STI ID Card and student identity successfully verified by AI.',
      errorCode: 'NONE',
      userFriendlyMessage: 'Official STI ID Card and student identity successfully verified.',
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
      extractedStudentId: '',
      idPhotoFaceDescription: '',
      selfiePhotoFaceDescription: '',
      comparisonAnalysis: '',
      isSamePerson: false,
      facialDiscrepancies: 'AI fallback triggered.',
      faceMatchConfidence: 0.0,
      decision: AiDecision.manualAdminReview,
      reason: reason,
      errorCode: 'ADMIN_REVIEW',
      userFriendlyMessage: 'Your registration has been submitted for manual review by SAO staff.',
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
