import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_get_helper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/list_response.dart';
import '../../org/data/models/org_models.dart';
import 'models/schedule_models.dart';

class ScheduleAuditRepository with ApiGetHelper {
  ScheduleAuditRepository(this.dio);

  @override
  final Dio dio;

  Future<PaginatedSchedules> getPage({
    int page = 1,
    int limit = 10,
    String? search,
    String? companyId,
    String? branchId,
    String? floorId,
    String? locationId,
    String? assigneeId,
    String? status,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '/5s-audit-schedules',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
          if (branchId != null && branchId.isNotEmpty) 'branch_id': branchId,
          if (floorId != null && floorId.isNotEmpty) 'floor_id': floorId,
          if (locationId != null && locationId.isNotEmpty) 'location_id': locationId,
          if (assigneeId != null && assigneeId.isNotEmpty) 'assignee_id': assigneeId,
          if (status != null && status.isNotEmpty && status != 'all') 'status': status,
        },
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to load schedules',
          statusCode: response.statusCode,
        );
      }

      final data = envelope.data;
      final items = ListResponse.extractItems<ScheduleAuditConfig>(
        data,
        ScheduleAuditConfig.fromJson,
        nestedKeys: const ['items', 'results', 'data', 'schedules'],
      );

      int asInt(Object? v, int fallback) {
        if (v is int) return v;
        if (v is num) return v.toInt();
        return int.tryParse('$v') ?? fallback;
      }

      final map = data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
      final total = asInt(map['total'], items.length);
      final pageNum = asInt(map['page'], page);
      final limitNum = asInt(map['limit'], limit);
      final pages = asInt(
        map['pages'],
        limitNum == 0 ? 1 : ((total + limitNum - 1) ~/ limitNum).clamp(1, 1 << 30),
      );

      return PaginatedSchedules(
        items: items,
        total: total,
        page: pageNum,
        limit: limitNum,
        pages: pages,
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to load schedules'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ScheduleAuditConfig> getById(String id) async {
    try {
      final response = await dio.get<dynamic>('/5s-audit-schedules/$id');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to load schedule',
          statusCode: response.statusCode,
        );
      }
      return ScheduleAuditConfig.fromJson(Map<String, dynamic>.from(envelope.data as Map));
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to load schedule'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ScheduleAuditConfig> create(Map<String, dynamic> payload) async {
    try {
      final response = await dio.post<dynamic>('/5s-audit-schedules', data: payload);
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to create schedule',
          statusCode: response.statusCode,
        );
      }
      return ScheduleAuditConfig.fromJson(Map<String, dynamic>.from(envelope.data as Map));
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to create schedule'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ScheduleAuditConfig> update(String id, Map<String, dynamic> payload) async {
    try {
      final response = await dio.put<dynamic>('/5s-audit-schedules/$id', data: payload);
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to update schedule',
          statusCode: response.statusCode,
        );
      }
      return ScheduleAuditConfig.fromJson(Map<String, dynamic>.from(envelope.data as Map));
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to update schedule'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      final response = await dio.delete<dynamic>('/5s-audit-schedules/$id');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          !envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to delete schedule',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to delete schedule'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<String> trigger(String id) async {
    try {
      final response = await dio.post<dynamic>('/5s-audit-schedules/$id/trigger', data: {});
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to trigger schedule',
          statusCode: response.statusCode,
        );
      }
      return envelope.message.isNotEmpty ? envelope.message : 'Schedule triggered successfully';
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to trigger schedule'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<AssigneeUser>> listAssignees({
    required String companyId,
    String? search,
    String status = 'active',
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '/5s-audit-schedules/assignees/dependency',
        queryParameters: {
          'company_id': companyId,
          if (search != null && search.isNotEmpty) 'search': search,
          'status': status,
        },
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to load assigned auditors',
          statusCode: response.statusCode,
        );
      }
      final rows = ListResponse.flattenAssigneeGroups(envelope.data);
      return rows.map(AssigneeUser.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to load assigned auditors',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final scheduleAuditRepositoryProvider = Provider<ScheduleAuditRepository>((ref) {
  return ScheduleAuditRepository(ref.watch(dioProvider));
});
