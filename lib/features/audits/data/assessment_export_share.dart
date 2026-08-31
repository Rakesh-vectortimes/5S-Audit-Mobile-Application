import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'export_filename.dart';

Future<void> shareAssessmentExport(AssessmentExportFile file) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}${Platform.pathSeparator}${file.filename}';
  final out = File(path);
  await out.writeAsBytes(file.bytes, flush: true);
  await Share.shareXFiles(
    [XFile(path, mimeType: file.mimeType, name: file.filename)],
    subject: file.filename,
  );
}
