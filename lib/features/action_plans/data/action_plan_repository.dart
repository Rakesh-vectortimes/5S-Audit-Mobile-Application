import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/list_response.dart';
import 'models/action_plan_models.dart';

class ActionPlanRepository {
  ActionPlanRepository(this.dio);

  final Dio dio;

  Future<PaginatedActionPlanAudits> listAudits({
    int page = 1,
    int limit = 25,
    String? search,
    String? companyId,
    String? auditTypeId,
    String? locationId,
    String? status,
    String? priority,
    String? dateFrom,
    String? dateTo,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '/5s-audit-action-plans/audits',
        queryParameters: _clean({
          'page': page,
          'limit': limit,
          'search': search,
          'company_id': companyId,
          'audit_type_id': auditTypeId,
          'location_id': locationId,
          'status': status == null || status == 'all' ? null : status,
          'priority': priority,
          'date_from': dateFrom,
          'date_to': dateTo,
        }),
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to load audits',
          statusCode: response.statusCode,
        );
      }
      return _toPaginatedAudits(envelope.data, page: page, limit: limit);
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to load audits'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ActionPlanAuditDetail> getAuditById(String assessmentId) async {
    try {
      final response =
          await dio.get<dynamic>('/5s-audit-action-plans/audits/$assessmentId');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to load audit',
          statusCode: response.statusCode,
        );
      }
      return ActionPlanAuditDetail.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to load audit'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ActionPlanDetail> getById(String id) async {
    try {
      final response = await dio.get<dynamic>('/5s-audit-action-plans/$id');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to load action plan',
          statusCode: response.statusCode,
        );
      }
      return ActionPlanDetail.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to load action plan',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ActionPlanDetail> update(String id, Map<String, dynamic> payload) async {
    try {
      final response =
          await dio.put<dynamic>('/5s-audit-action-plans/$id', data: payload);
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to update action plan',
          statusCode: response.statusCode,
        );
      }
      return ActionPlanDetail.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to update action plan',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<ActionPlanDetail> updateDueDate({
    required String id,
    required String dueDate,
    required String dueDateReason,
  }) async {
    try {
      final response = await dio.put<dynamic>(
        '/5s-audit-action-plans/$id/due-date',
        data: {
          'due_date': dueDate,
          'due_date_reason': dueDateReason,
        },
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to update due date',
          statusCode: response.statusCode,
        );
      }
      return ActionPlanDetail.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to update due date',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Upload proof image(s) for an existing action plan (appends on server).
  Future<ActionPlanProofImage> uploadProofImage({
    required String id,
    required String filePath,
    String? fileName,
  }) async {
    final images = await uploadProofImages(
      planId: id,
      files: [
        ProofImageUploadFile(path: filePath, fileName: fileName),
      ],
    );
    if (images.isEmpty) {
      throw ApiException('Failed to upload proof image');
    }
    return images.first;
  }

  /// Upload one or more proof images.
  ///
  /// - During audit edit (no plan id): pass [companyId]
  /// - Existing plan: pass [planId] (optionally [companyId])
  Future<List<ActionPlanProofImage>> uploadProofImages({
    String? planId,
    String? companyId,
    required List<ProofImageUploadFile> files,
  }) async {
    if (files.isEmpty) return const [];
    final hasPlan = planId != null && planId.isNotEmpty;
    final hasCompany = companyId != null && companyId.isNotEmpty;
    if (!hasPlan && !hasCompany) {
      throw ApiException('company_id is required to upload proof images');
    }

    try {
      final formData = FormData();
      for (final file in files) {
        formData.files.add(
          MapEntry(
            'images',
            await MultipartFile.fromFile(
              file.path,
              filename: file.fileName,
            ),
          ),
        );
      }

      final path = hasPlan
          ? '/5s-audit-action-plans/$planId/proof-image'
          : '/5s-audit-action-plans/proof-image';
      final response = await dio.post<dynamic>(
        path,
        data: formData,
        queryParameters: hasCompany ? {'company_id': companyId} : null,
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to upload proof image',
          statusCode: response.statusCode,
        );
      }
      return parseProofImageUploadResponse(envelope.data);
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to upload proof image',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }

  PaginatedActionPlanAudits _toPaginatedAudits(
    dynamic data, {
    required int page,
    required int limit,
  }) {
    final items = ListResponse.extractItems<ActionPlanAuditGroup>(
      data,
      ActionPlanAuditGroup.fromJson,
      nestedKeys: const ['items', 'results', 'data', 'audits'],
    );
    final summary = ActionPlanSummary.extract(data) ??
        ActionPlanSummary(
          open: items.fold(0, (s, i) => s + i.openCount),
          submitted: items.fold(0, (s, i) => s + i.submittedCount),
          overdue: items.fold(0, (s, i) => s + i.overdueCount),
          closed: items.fold(0, (s, i) => s + i.closedCount),
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

    return PaginatedActionPlanAudits(
      items: items,
      total: total,
      page: pageNum,
      limit: limitNum,
      pages: pages,
      summary: summary,
    );
  }

  Map<String, dynamic> _clean(Map<String, dynamic> query) {
    final cleaned = <String, dynamic>{};
    query.forEach((key, value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      cleaned[key] = value;
    });
    return cleaned;
  }
}

final actionPlanRepositoryProvider = Provider<ActionPlanRepository>((ref) {
  return ActionPlanRepository(ref.watch(dioProvider));
});

class ProofImageUploadFile {
  const ProofImageUploadFile({
    required this.path,
    this.fileName,
    this.mimeType,
    this.sizeBytes,
  });

  final String path;
  final String? fileName;
  final String? mimeType;
  final int? sizeBytes;
}

List<ActionPlanProofImage> parseProofImageUploadResponse(dynamic data) {
  if (data == null) return const [];

  List<ActionPlanProofImage> fromList(List<dynamic> list) {
    return list
        .whereType<Object>()
        .map((e) => ActionPlanProofImage.fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  if (data is List) return fromList(data);
  if (data is! Map) return const [];

  final map = Map<String, dynamic>.from(data);
  final images = map['images'] ?? map['proof_images'];
  if (images is List) return fromList(images);

  if (map.containsKey('uploadurl') ||
      map.containsKey('upload_url') ||
      map.containsKey('image_url') ||
      map.containsKey('file_name')) {
    return [ActionPlanProofImage.fromJson(map)];
  }
  return const [];
}
