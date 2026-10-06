import 'dart:typed_data';

import 'package:five_s_audit/core/images/proof_image_bytes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('sniffAllowedImageMime', () {
    test('recognizes jpeg, png, gif, and webp', () {
      expect(
        sniffAllowedImageMime(Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(
        sniffAllowedImageMime(
          Uint8List.fromList([0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]),
        ),
        'image/png',
      );
      expect(
        sniffAllowedImageMime(Uint8List.fromList([0x47, 0x49, 0x46, 0x38, 0x39, 0x61])),
        'image/gif',
      );
      final webp = Uint8List(12);
      webp.setRange(0, 4, [0x52, 0x49, 0x46, 0x46]);
      webp.setRange(8, 12, [0x57, 0x45, 0x42, 0x50]);
      expect(sniffAllowedImageMime(webp), 'image/webp');
    });

    test('rejects heic and unknown bytes', () {
      expect(sniffAllowedImageMime(Uint8List.fromList([0, 1, 2, 3])), isNull);
      final heic = Uint8List(12);
      heic.setRange(4, 12, 'ftypheic'.codeUnits);
      expect(sniffAllowedImageMime(heic), isNull);
      expect(looksLikeHeic(heic), isTrue);
    });
  });

  group('proofJpegFileName', () {
    test('rewrites camera heic names to jpg', () {
      expect(proofJpegFileName('IMG_20261005.heic'), 'IMG_20261005.jpg');
      expect(proofJpegFileName('WhatsApp Image 2026.jpeg'), 'WhatsApp_Image_2026.jpg');
      expect(proofJpegFileName(''), 'proof.jpg');
    });
  });
}
