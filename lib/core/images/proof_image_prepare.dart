import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import '../network/image_url.dart';
import 'proof_image_bytes.dart';

class ProofImagePrepareException implements Exception {
  const ProofImagePrepareException(this.message);

  final String message;

  @override
  String toString() => message;
}

class PreparedProofImage {
  const PreparedProofImage({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  int get sizeBytes => bytes.length;
}

/// Turn a camera or gallery photo into a normal JPEG the upload API accepts.
///
/// Phone cameras often produce HEIC, Ultra HDR, or multi-megabyte JPEGs.
/// Gallery apps such as WhatsApp already store a small JPEG, which is why
/// those uploads succeed while camera photos fail.
Future<PreparedProofImage> prepareProofImage(XFile file) async {
  final compressed = await _compressToLimit(file);
  if (compressed == null || compressed.isEmpty) {
    final raw = await _readWhenReady(file);
    if (looksLikeHeic(raw)) {
      throw const ProofImagePrepareException(
        'This photo format could not be converted. Take the picture again, or choose a JPEG from your gallery.',
      );
    }
    throw const ProofImagePrepareException(
      'Could not read this photo. Please take it again.',
    );
  }
  if (sniffAllowedImageMime(compressed) != 'image/jpeg') {
    throw const ProofImagePrepareException(
      'Could not read this photo. Please take it again.',
    );
  }
  return PreparedProofImage(
    bytes: compressed,
    fileName: proofJpegFileName(file.name),
    mimeType: 'image/jpeg',
  );
}

Future<Uint8List?> _compressToLimit(XFile file) async {
  const preferredMaxBytes = 900 * 1024;
  const steps = <(int edge, int quality)>[
    (1600, 75),
    (1280, 60),
    (1024, 50),
  ];

  Uint8List? current;
  for (final step in steps) {
    final next = current == null
        ? await _compressFile(file, edge: step.$1, quality: step.$2)
        : await _compressBytes(current, edge: step.$1, quality: step.$2);
    if (next == null || next.isEmpty) continue;
    current = next;
    if (current.length <= preferredMaxBytes) return current;
  }
  if (current != null && current.length > maxProofImageBytes) {
    throw const ProofImagePrepareException('Image must be smaller than 5 MB.');
  }
  return current;
}

Future<Uint8List?> _compressFile(
  XFile file, {
  required int edge,
  required int quality,
}) async {
  await _waitUntilReadable(file);
  try {
    final bytes = await FlutterImageCompress.compressWithFile(
      file.path,
      minWidth: edge,
      minHeight: edge,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );
    if (bytes != null && bytes.isNotEmpty) return bytes;
  } catch (_) {
    // Fall through to an in-memory compress. Some camera URIs cannot be
    // opened by path until the camera app finishes writing the file.
  }

  final raw = await _readWhenReady(file);
  if (raw.isEmpty) return null;
  return _compressBytes(raw, edge: edge, quality: quality);
}

Future<Uint8List?> _compressBytes(
  Uint8List raw, {
  required int edge,
  required int quality,
}) async {
  try {
    final bytes = await FlutterImageCompress.compressWithList(
      raw,
      minWidth: edge,
      minHeight: edge,
      quality: quality,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );
    if (bytes.isEmpty) return null;
    return bytes;
  } catch (_) {
    return null;
  }
}

Future<void> _waitUntilReadable(XFile file) async {
  var previous = await file.length();
  if (previous > 0) {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final again = await file.length();
    if (again == previous) return;
    previous = again;
  }
  for (var attempt = 0; attempt < 8; attempt++) {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    final length = await file.length();
    if (length > 0 && length == previous) return;
    previous = length;
  }
}

Future<Uint8List> _readWhenReady(XFile file) async {
  await _waitUntilReadable(file);
  try {
    return await file.readAsBytes();
  } catch (_) {
    return Uint8List(0);
  }
}
