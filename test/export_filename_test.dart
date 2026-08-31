import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/features/audits/data/export_filename.dart';

void main() {
  group('filenameFromContentDisposition', () {
    test('parses UTF-8 starred filename', () {
      expect(
        filenameFromContentDisposition(
          "attachment; filename*=UTF-8''Acme%20Report.pdf",
        ),
        'Acme Report.pdf',
      );
    });

    test('parses quoted filename', () {
      expect(
        filenameFromContentDisposition('attachment; filename="plant.docx"'),
        'plant.docx',
      );
    });

    test('returns null when missing', () {
      expect(filenameFromContentDisposition(null), isNull);
      expect(filenameFromContentDisposition('inline'), isNull);
    });
  });

  group('buildFallbackExportFilename', () {
    test('strips trailing 5S Audit and uses yyyy-MM-dd', () {
      expect(
        buildFallbackExportFilename(
          extension: 'pdf',
          companyName: 'Acme Corp 5S Audit',
          reportDate: '2026-08-04T10:00:00Z',
        ),
        'Acme Corp 5s audit report (2026-08-04).pdf',
      );
    });

    test('uses today when report date missing', () {
      final name = buildFallbackExportFilename(
        extension: 'docx',
        companyName: 'Plant A',
        now: DateTime(2026, 8, 4),
      );
      expect(name, 'Plant A 5s audit report (2026-08-04).docx');
    });
  });

  group('resolveExportFilename', () {
    test('prefers Content-Disposition over fallback', () {
      expect(
        resolveExportFilename(
          contentDisposition: 'attachment; filename="from-header.pdf"',
          extension: 'pdf',
          companyName: 'Ignored',
          reportDate: '2026-01-01',
        ),
        'from-header.pdf',
      );
    });
  });
}
