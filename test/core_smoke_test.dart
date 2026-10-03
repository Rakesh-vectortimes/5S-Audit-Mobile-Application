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

    test('treats published as submitted', () {
      expect(AuditStatusMapper.isSubmitted('submitted'), isTrue);
      expect(AuditStatusMapper.isSubmitted('published'), isTrue);
      expect(AuditStatusMapper.isSubmitted('draft'), isFalse);
      expect(AuditStatusMapper.isSubmitted(AuditStatus.published), isTrue);
    });

    test('parses backend enum values', () {
      expect(AuditStatus.fromApi('published'), AuditStatus.published);
      expect(AuditStatus.fromApi('submitted'), AuditStatus.published);
      expect(AuditStatus.fromApi('draft'), AuditStatus.draft);
      expect(AuditStatus.published.canEdit, isFalse);
      expect(AuditStatus.draft.canEdit, isTrue);
      expect(AuditStatus.published.apiValue, 'published');
      expect(AuditStatus.published.label, 'Submitted');
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
