import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_get_helper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/list_response.dart';
import 'export_filename.dart';
import 'five_s_audit_mapper.dart';
import 'models/assessment_models.dart';

class FiveSAuditAssessmentRepository with ApiGetHelper {
  FiveSAuditAssessmentRepository(this.dio);

  @override
  final Dio dio;

  Future<PaginatedAssessments> getPage({
    int page = 1,
    int limit = 10,
    String? search,
    String? companyId,
    String? orgCompanyId,
    String? createdBy,
    String? preparedBy,
    String? reportDateFrom,
    String? reportDateTo,
    String? statusApi,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        '/5s-audit-assessments',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (companyId != null && companyId.isNotEmpty) 'company_id': companyId,
          if (orgCompanyId != null && orgCompanyId.isNotEmpty)
            'org_company_id': orgCompanyId,
          if (createdBy != null && createdBy.isNotEmpty) 'created_by': createdBy,
          if (preparedBy != null && preparedBy.isNotEmpty) 'prepared_by': preparedBy,
          if (reportDateFrom != null && reportDateFrom.isNotEmpty)
            'report_date_from': reportDateFrom,
          if (reportDateTo != null && reportDateTo.isNotEmpty)
            'report_date_to': reportDateTo,
          if (statusApi != null && statusApi.isNotEmpty) 'status': statusApi,
        },
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to load audits',
          statusCode: response.statusCode,
        );
      }

      final data = envelope.data;
      final items = ListResponse.extractItems<FiveSAuditRecord>(
        data,
        (json) => FiveSAuditMapper.normalizeRecord(json),
        nestedKeys: const [
          'items',
          'results',
          'data',
          'assessments',
          'lean_maturity_assessments',
        ],
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

      return PaginatedAssessments(
        items: items,
        total: total,
        page: pageNum,
        limit: limitNum,
        pages: pages,
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to load audits'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<FiveSAuditRecord> getById(String id) async {
    try {
      final response = await dio.get<dynamic>('/5s-audit-assessments/$id');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to load audit',
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditMapper.normalizeRecord(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to load audit'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<FiveSAuditRecord> create(Map<String, dynamic> payload) async {
    try {
      final response = await dio.post<dynamic>('/5s-audit-assessments', data: payload);
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to create audit',
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditMapper.normalizeRecord(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to create audit'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<FiveSAuditRecord> update(String id, Map<String, dynamic> payload) async {
    try {
      final response = await dio.put<dynamic>('/5s-audit-assessments/$id', data: payload);
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to update audit',
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditMapper.normalizeRecord(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to update audit'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> delete(String id) async {
    try {
      final response = await dio.delete<dynamic>('/5s-audit-assessments/$id');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          !envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to delete audit',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to delete audit'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AssessmentExportFile> exportPdf(
    String id, {
    String? companyName,
    String? reportDate,
    String fontFamily = defaultExportFontFamily,
    String fontSize = defaultExportFontSize,
  }) {
    return _export(
      id: id,
      path: '/5s-audit-assessments/$id/export/pdf',
      extension: 'pdf',
      mimeType: 'application/pdf',
      companyName: companyName,
      reportDate: reportDate,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fallbackError: 'Failed to export PDF',
    );
  }

  Future<AssessmentExportFile> exportWord(
    String id, {
    String? companyName,
    String? reportDate,
    String fontFamily = defaultExportFontFamily,
    String fontSize = defaultExportFontSize,
  }) {
    return _export(
      id: id,
      path: '/5s-audit-assessments/$id/export/word',
      extension: 'docx',
      mimeType:
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      companyName: companyName,
      reportDate: reportDate,
      fontFamily: fontFamily,
      fontSize: fontSize,
      fallbackError: 'Failed to export Word',
    );
  }

  Future<AssessmentExportFile> _export({
    required String id,
    required String path,
    required String extension,
    required String mimeType,
    required String fallbackError,
    String? companyName,
    String? reportDate,
    required String fontFamily,
    required String fontSize,
  }) async {
    try {
      final response = await dio.get<List<int>>(
        path,
        queryParameters: {
          'font_family': fontFamily,
          'font_size': fontSize,
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {'Accept': '*/*'},
        ),
      );

      final status = response.statusCode ?? 0;
      final raw = response.data ?? const <int>[];
      final bytes = Uint8List.fromList(raw);

      if (status >= 400) {
        throw ApiException(
          tryDecodeApiErrorMessage(bytes) ?? fallbackError,
          statusCode: status,
        );
      }

      if (bytes.isEmpty) {
        throw ApiException(fallbackError, statusCode: status);
      }

      // JSON error disguised as 200
      final maybeError = tryDecodeApiErrorMessage(bytes);
      if (maybeError != null && bytes.length < 512) {
        throw ApiException(maybeError, statusCode: status);
      }

      final filename = resolveExportFilename(
        contentDisposition: response.headers.value('content-disposition'),
        extension: extension,
        companyName: companyName,
        reportDate: reportDate,
        idFallback: id,
      );

      return AssessmentExportFile(
        bytes: bytes,
        filename: filename,
        mimeType: mimeType,
      );
    } on ApiException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      if (data is List<int>) {
        final message = tryDecodeApiErrorMessage(Uint8List.fromList(data));
        if (message != null) {
          throw ApiException(message, statusCode: e.response?.statusCode);
        }
      }
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallbackError),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final fiveSAuditAssessmentRepositoryProvider =
    Provider<FiveSAuditAssessmentRepository>((ref) {
  return FiveSAuditAssessmentRepository(ref.watch(dioProvider));
});
