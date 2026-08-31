import '../config/app_config.dart';

/// Resolve API/public image paths for display (matches web `resolveQuestionImageUrl`).
String buildImageUrlFromUploadurl(String? uploadurl) {
  final value = uploadurl?.trim() ?? '';
  if (value.isEmpty) return '';
  if (value.startsWith('/public/')) return value;
  if (value.startsWith('public/')) return '/$value';
  return '/public/${value.replaceFirst(RegExp(r'^/'), '')}';
}

String resolveMediaUrl(Object? image, {String? apiOrigin}) {
  if (image == null) return '';

  if (image is String) {
    final value = image.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:')) {
      return value;
    }
    final path = value.startsWith('/') ? value : '/$value';
    final origin = apiOrigin ?? _defaultApiOrigin();
    return '$origin$path';
  }

  if (image is Map) {
    final map = Map<String, dynamic>.from(image);
    final imageUrl = (map['image_url'] ?? map['question_image_url'])?.toString().trim();
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return resolveMediaUrl(imageUrl, apiOrigin: apiOrigin);
    }
    final uploadPath = buildImageUrlFromUploadurl(
      (map['uploadurl'] ?? map['upload_url'])?.toString(),
    );
    if (uploadPath.isEmpty) return '';
    return resolveMediaUrl(uploadPath, apiOrigin: apiOrigin);
  }

  return '';
}

String _defaultApiOrigin() {
  try {
    final config = AppConfig.instance;
    final fromBase = config.apiBaseUrl.replaceAll(RegExp(r'/+$'), '');
    if (fromBase.isNotEmpty) return fromBase;
    return config.apiV1BaseUrl.replaceAll(RegExp(r'/api/v1/?$'), '');
  } catch (_) {
    return '';
  }
}

const maxProofImageBytes = 5 * 1024 * 1024;

const allowedProofMimeTypes = {
  'image/png',
  'image/jpeg',
  'image/jpg',
  'image/gif',
  'image/webp',
};

String? validateProofImage({required String? mimeType, required int sizeBytes}) {
  final type = (mimeType ?? '').toLowerCase().trim();
  if (type.isNotEmpty && !allowedProofMimeTypes.contains(type)) {
    return 'Please select a PNG, JPEG, GIF, or WebP image.';
  }
  if (sizeBytes > maxProofImageBytes) {
    return 'Image must be smaller than 5 MB.';
  }
  return null;
}
