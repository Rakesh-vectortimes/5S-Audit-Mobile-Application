import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'action_plan_utils.dart';

class ActionPlanSettingsRepository {
  ActionPlanSettingsRepository(this.dio);

  final Dio dio;

  Future<ActionPlanDueDaySettings> get({
    required String companyId,
    required String auditTypeId,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '/5s-audit-action-plan-settings',
        queryParameters: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
        },
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to load settings',
          statusCode: response.statusCode,
        );
      }
      final data = envelope.data;
      return ActionPlanDueDaySettings.normalize(
        data is Map ? Map<String, dynamic>.from(data) : null,
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to load settings',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ActionPlanDueDaySettings> update({
    required String companyId,
    required String auditTypeId,
    required int highPriorityDueDays,
    required int mediumPriorityDueDays,
    required int lowPriorityDueDays,
  }) async {
    try {
      final response = await dio.put<dynamic>(
        '/5s-audit-action-plan-settings',
        data: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
          'high_priority_due_days': highPriorityDueDays,
          'medium_priority_due_days': mediumPriorityDueDays,
          'low_priority_due_days': lowPriorityDueDays,
        },
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to save settings',
          statusCode: response.statusCode,
        );
      }
      final data = envelope.data;
      return ActionPlanDueDaySettings.normalize(
        data is Map ? Map<String, dynamic>.from(data) : null,
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to save settings',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final actionPlanSettingsRepositoryProvider =
    Provider<ActionPlanSettingsRepository>((ref) {
  return ActionPlanSettingsRepository(ref.watch(dioProvider));
});
