import 'package:sti_sync/firebase_options.dart';

/// Centralized Application Configuration & API Keys.
///
/// Keys defined here prioritize `--dart-define=GEMINI_API_KEY=your_key`
/// or dynamic keys stored in Firestore `/system_configs/ai`,
/// and fallback to project default Firebase options.
class AppConfig {
  AppConfig._();

  /// Google Gemini AI Vision API Key for Student ID verification
  static String get geminiApiKey {
    const envKey = String.fromEnvironment('GEMINI_API_KEY');
    if (envKey.trim().isNotEmpty) return envKey.trim();
    return DefaultFirebaseOptions.currentPlatform.apiKey;
  }

  /// Fallback Google API Key
  static String get googleFallbackApiKey {
    const envKey = String.fromEnvironment('GOOGLE_FALLBACK_API_KEY');
    if (envKey.trim().isNotEmpty) return envKey.trim();
    return DefaultFirebaseOptions.currentPlatform.apiKey;
  }
}
