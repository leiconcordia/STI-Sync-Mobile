import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

/// Handles all file uploads to Cloudinary using the unsigned upload preset.
///
/// SECURITY: Only the cloud name and preset name are embedded — no API key
/// or API secret. Unsigned preset `sti_sync_uploads` allows anonymous uploads
/// from trusted client origins without exposing credentials.
///
/// ALL image/document uploads in this app (profile photos, school IDs, any
/// future document submissions) MUST go through this service. Firestore stores
/// only the returned `secure_url` string — never local paths or byte data.
class CloudinaryService {
  static const String _cloudName = 'djwlkcgnx';
  static const String _uploadPreset = 'sti_sync_uploads';
  static const String _baseUrl =
      'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload';

  /// Uploads [file] to Cloudinary under [folder] and returns the `secure_url`.
  ///
  /// [onProgress] receives bytes sent / total bytes (0.0–1.0) as upload progresses.
  /// Throws a [CloudinaryUploadException] on any non-200 response or network error.
  Future<String> uploadFile(
    File file, {
    required String folder,
    void Function(double progress)? onProgress,
  }) async {
    final bytes = await file.readAsBytes();
    final length = bytes.length;



    // Rely on Cloudinary's built-in validation instead of strict magic bytes
    // which can sometimes reject valid camera images on certain devices.

    final uri = Uri.parse(_baseUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..fields['folder'] = folder
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.path.split(Platform.pathSeparator).last,
      ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw CloudinaryUploadException(
          'Upload failed (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw CloudinaryUploadException('Upload succeeded but no URL was returned.');
    }
    return url;
  }


}

class CloudinaryUploadException implements Exception {
  final String message;
  CloudinaryUploadException(this.message);
  @override
  String toString() => 'CloudinaryUploadException: $message';
}
