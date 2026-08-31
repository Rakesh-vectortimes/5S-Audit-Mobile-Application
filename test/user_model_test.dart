import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/features/auth/data/models/user.dart';

void main() {
  test('User.fromJson maps _id and permission flags', () {
    final user = User.fromJson(const {
      '_id': 'abc123',
      'name': 'Test User',
      'email': 'test@example.com',
      'role': 'admin',
      'company_type': 'child',
      'can_write_reports': true,
      'can_view_reports': true,
      'show_5s_audit_settings': true,
      'show_action_plan_settings': false,
      'custom_role_id': null,
      'permission_overrides': {'can_view_reports': true},
      'is_client_company_employee': false,
    });

    expect(user.id, 'abc123');
    expect(user.canWriteReports, isTrue);
    expect(user.show5sAuditSettings, isTrue);
    expect(user.showActionPlanSettings, isFalse);
    expect(user.showAnySettings, isTrue);
  });

  test('AuthTokens.fromJson includes nested user', () {
    final tokens = AuthTokens.fromJson(const {
      'access_token': 'a',
      'refresh_token': 'r',
      'token_type': 'bearer',
      'user': {
        'id': 'u1',
        'name': 'N',
        'email': 'n@e.com',
        'can_view_reports': true,
      },
    });

    expect(tokens.accessToken, 'a');
    expect(tokens.refreshToken, 'r');
    expect(tokens.user?.id, 'u1');
    expect(tokens.user?.canViewReports, isTrue);
  });
}
