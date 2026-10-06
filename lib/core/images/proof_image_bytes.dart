import 'dart:typed_data';

/// MIME type when [bytes] is a PNG, JPEG, GIF, or WebP. Otherwise null.
String? sniffAllowedImageMime(Uint8List bytes) {
  if (bytes.length >= 3 &&
      bytes[0] == 0xFF &&
      bytes[1] == 0xD8 &&
      bytes[2] == 0xFF) {
    return 'image/jpeg';
  }
  if (bytes.length >= 8 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47 &&
      bytes[4] == 0x0D &&
      bytes[5] == 0x0A &&
      bytes[6] == 0x1A &&
      bytes[7] == 0x0A) {
    return 'image/png';
  }
  if (bytes.length >= 6 &&
      bytes[0] == 0x47 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x38) {
    return 'image/gif';
  }
  if (bytes.length >= 12 &&
      bytes[0] == 0x52 &&
      bytes[1] == 0x49 &&
      bytes[2] == 0x46 &&
      bytes[3] == 0x46 &&
      bytes[8] == 0x57 &&
      bytes[9] == 0x45 &&
      bytes[10] == 0x42 &&
      bytes[11] == 0x50) {
    return 'image/webp';
  }
  return null;
}

/// Camera rolls often store HEIC/HEIF. Those are not in the allowed upload types.
bool looksLikeHeic(Uint8List bytes) {
  if (bytes.length < 12) return false;
  if (bytes[4] != 0x66 ||
      bytes[5] != 0x74 ||
      bytes[6] != 0x79 ||
      bytes[7] != 0x70) {
    return false;
  }
  final brand = String.fromCharCodes(bytes.sublist(8, 12)).toLowerCase();
  return brand.startsWith('hei') ||
      brand == 'mif1' ||
      brand == 'msf1' ||
      brand == 'avif';
}

/// Safe JPEG filename. Camera names such as `IMG_123.heic` become `IMG_123.jpg`.
String proofJpegFileName(String? originalName) {
  final raw = (originalName ?? '').trim();
  final slash = raw.lastIndexOf(RegExp(r'[/\\]'));
  final base = slash >= 0 ? raw.substring(slash + 1) : raw;
  final dot = base.lastIndexOf('.');
  var stem = dot > 0 ? base.substring(0, dot) : base;
  stem = stem.replaceAll(RegExp(r'[^\w\-]+'), '_');
  stem = stem.replaceAll(RegExp(r'_+'), '_');
  stem = stem.replaceAll(RegExp(r'^_|_$'), '');
  if (stem.isEmpty || stem.length > 40) stem = 'proof';
  return '$stem.jpg';
}
