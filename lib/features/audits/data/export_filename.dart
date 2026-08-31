import 'dart:convert';
import 'dart:typed_data';

/// Default typography for 5S assessment exports (match web).
const defaultExportFontFamily = 'Calibri';
const defaultExportFontSize = '15px';

class AssessmentExportFile {
  const AssessmentExportFile({
    required this.bytes,
    required this.filename,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String filename;
  final String mimeType;
}

/// Prefer Content-Disposition `filename*=UTF-8''…` or `filename="…"`.
String? filenameFromContentDisposition(String? header) {
  if (header == null || header.trim().isEmpty) return null;

  final utf8Match = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false)
      .firstMatch(header);
  if (utf8Match != null) {
    final raw = utf8Match.group(1)!.replaceAll(RegExp(r'''["']'''), '');
    try {
      return Uri.decodeComponent(raw);
    } catch (_) {
      return raw;
    }
  }

  final quoted = RegExp(r'filename="([^"]+)"', caseSensitive: false).firstMatch(header);
  if (quoted != null) return quoted.group(1);

  final plain = RegExp(r'filename=([^;]+)', caseSensitive: false).firstMatch(header);
  return plain?.group(1)?.trim().replaceAll(RegExp(r'''["']'''), '');
}

/// Fallback when header is missing: "{company} 5s audit report (yyyy-MM-dd).ext"
String buildFallbackExportFilename({
  required String extension,
  String? companyName,
  String? reportDate,
  DateTime? now,
}) {
  final cleaned = (companyName ?? '5S Audit')
      .replaceAll(RegExp(r' 5S Audit$', caseSensitive: false), '')
      .trim();
  final name = cleaned.isEmpty ? '5S Audit' : cleaned;
  final date = _ymd(reportDate) ?? _ymdFromDate(now ?? DateTime.now());
  final ext = extension.startsWith('.') ? extension.substring(1) : extension;
  return '$name 5s audit report ($date).$ext';
}

String resolveExportFilename({
  required String? contentDisposition,
  required String extension,
  String? companyName,
  String? reportDate,
  String? idFallback,
}) {
  final fromHeader = filenameFromContentDisposition(contentDisposition);
  if (fromHeader != null && fromHeader.trim().isNotEmpty) {
    return fromHeader.trim();
  }
  final built = buildFallbackExportFilename(
    extension: extension,
    companyName: companyName,
    reportDate: reportDate,
  );
  if (built.trim().isNotEmpty) return built;
  return '5s-audit-${idFallback ?? 'export'}.$extension';
}

String? tryDecodeApiErrorMessage(Uint8List bytes) {
  try {
    final text = utf8.decode(bytes);
    final decoded = jsonDecode(text);
    if (decoded is Map && decoded['message'] is String) {
      final message = (decoded['message'] as String).trim();
      if (message.isNotEmpty) return message;
    }
  } catch (_) {}
  return null;
}

String? _ymd(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final match = RegExp(r'^(\d{4}-\d{2}-\d{2})').firstMatch(value.trim());
  return match?.group(1);
}

String _ymdFromDate(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y-$m-$day';
}
