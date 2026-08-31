import 'package:flutter_test/flutter_test.dart';

import 'package:five_s_audit/core/constants/audit_status.dart';
import 'package:five_s_audit/core/network/api_response.dart';

void main() {
  group('AuditStatusMapper', () {
    test('maps submitted ↔ published', () {
      expect(AuditStatusMapper.toApi('submitted'), 'published');
      expect(AuditStatusMapper.toUi('published'), 'submitted');
      expect(AuditStatusMapper.toApi('draft'), 'draft');
    });
  });

  group('ApiResponse', () {
    test('parses envelope', () {
      final res = ApiResponse<Map<String, dynamic>>.fromJson(
        {
          'success': true,
          'message': 'ok',
          'data': {'id': 1},
        },
        (json) => json as Map<String, dynamic>,
      );
      expect(res.success, isTrue);
      expect(res.message, 'ok');
      expect(res.data?['id'], 1);
    });
  });
}
