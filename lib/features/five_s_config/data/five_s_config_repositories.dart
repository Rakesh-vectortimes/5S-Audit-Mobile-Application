import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_get_helper.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import 'models/five_s_config_models.dart';

class FiveSAuditTypeRepository with ApiGetHelper {
  FiveSAuditTypeRepository(this.dio);

  @override
  final Dio dio;

  Future<List<FiveSAuditType>> list({
    required String companyId,
    String? search,
  }) {
    return getList(
      '/5s-audit-types',
      queryParameters: {
        'company_id': companyId,
        'search': search,
      },
      fromJson: FiveSAuditType.fromJson,
      fallbackMessage: 'Failed to load audit types',
    );
  }

  Future<FiveSAuditType> create(Map<String, dynamic> payload) async {
    return _mutateObject(
      () => dio.post<dynamic>('/5s-audit-types', data: payload),
      fallback: 'Failed to create audit type',
    );
  }

  Future<FiveSAuditType> update({
    required String id,
    required String companyId,
    required Map<String, dynamic> payload,
  }) async {
    return _mutateObject(
      () => dio.put<dynamic>(
        '/5s-audit-types/$id',
        queryParameters: {'company_id': companyId},
        data: payload,
      ),
      fallback: 'Failed to update audit type',
    );
  }

  Future<void> delete({required String id, required String companyId}) async {
    await _mutateVoid(
      () => dio.delete<dynamic>(
        '/5s-audit-types/$id',
        queryParameters: {'company_id': companyId},
      ),
      fallback: 'Failed to delete audit type',
    );
  }

  Future<FiveSAuditType> _mutateObject(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditType.fromJson(Map<String, dynamic>.from(envelope.data as Map));
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> _mutateVoid(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          !envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class FiveSAuditSectionRepository with ApiGetHelper {
  FiveSAuditSectionRepository(this.dio);

  @override
  final Dio dio;

  Future<List<FiveSAuditSection>> list({
    required String companyId,
    required String auditTypeId,
    String? search,
    bool? leafOnly,
  }) {
    return getList(
      '/5s-audit-sections',
      queryParameters: {
        'company_id': companyId,
        'audit_type_id': auditTypeId,
        'search': search,
        if (leafOnly != null) 'leaf_only': leafOnly,
      },
      fromJson: FiveSAuditSection.fromJson,
      fallbackMessage: 'Failed to load sections',
    );
  }

  Future<FiveSAuditSection> create(Map<String, dynamic> payload) async {
    return _mutateObject(
      () => dio.post<dynamic>('/5s-audit-sections', data: payload),
      fallback: 'Failed to create section',
    );
  }

  Future<FiveSAuditSection> update({
    required String id,
    required String companyId,
    required String auditTypeId,
    required Map<String, dynamic> payload,
  }) async {
    return _mutateObject(
      () => dio.put<dynamic>(
        '/5s-audit-sections/$id',
        queryParameters: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
        },
        data: payload,
      ),
      fallback: 'Failed to update section',
    );
  }

  Future<void> delete({
    required String id,
    required String companyId,
    required String auditTypeId,
  }) async {
    await _mutateVoid(
      () => dio.delete<dynamic>(
        '/5s-audit-sections/$id',
        queryParameters: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
        },
      ),
      fallback: 'Failed to delete section',
    );
  }

  Future<FiveSAuditSection> _mutateObject(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditSection.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> _mutateVoid(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          !envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class FiveSAuditQuestionRepository with ApiGetHelper {
  FiveSAuditQuestionRepository(this.dio);

  @override
  final Dio dio;

  Future<List<FiveSAuditQuestionDocument>> list({
    required String companyId,
    required String auditTypeId,
    String? sectionId,
  }) {
    return getList(
      '/5s-audit-questions',
      queryParameters: {
        'company_id': companyId,
        'audit_type_id': auditTypeId,
        if (sectionId != null && sectionId.isNotEmpty) 'fk_section_id': sectionId,
      },
      fromJson: FiveSAuditQuestionDocument.fromJson,
      fallbackMessage: 'Failed to load questions',
    );
  }

  Future<FiveSAuditQuestionDocument> create(Map<String, dynamic> payload) async {
    return _mutateObject(
      () => dio.post<dynamic>('/5s-audit-questions', data: payload),
      fallback: 'Failed to create questions',
    );
  }

  Future<FiveSAuditQuestionDocument> update({
    required String id,
    required String companyId,
    required String auditTypeId,
    required Map<String, dynamic> payload,
  }) async {
    return _mutateObject(
      () => dio.put<dynamic>(
        '/5s-audit-questions/$id',
        queryParameters: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
        },
        data: payload,
      ),
      fallback: 'Failed to update questions',
    );
  }

  Future<void> delete({
    required String id,
    required String companyId,
    required String auditTypeId,
  }) async {
    await _mutateVoid(
      () => dio.delete<dynamic>(
        '/5s-audit-questions/$id',
        queryParameters: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
        },
      ),
      fallback: 'Failed to delete questions',
    );
  }

  Future<FiveSAuditQuestionImage> uploadQuestionImage({
    required String companyId,
    required String auditTypeId,
    required String filePath,
    String? fileName,
  }) async {
    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath, filename: fileName),
      });
      final response = await dio.post<dynamic>(
        '/5s-audit-questions/question-image',
        queryParameters: {
          'company_id': companyId,
          'audit_type_id': auditTypeId,
        },
        data: formData,
      );
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty
              ? envelope.message
              : 'Failed to upload question image',
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditQuestionImage.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(
          e.response?.data,
          fallback: 'Failed to upload question image',
        ),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<FiveSAuditQuestionDocument> _mutateObject(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditQuestionDocument.fromJson(
        Map<String, dynamic>.from(envelope.data as Map),
      );
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> _mutateVoid(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          !envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class FiveSAuditGradeRepository with ApiGetHelper {
  FiveSAuditGradeRepository(this.dio);

  @override
  final Dio dio;

  Future<List<FiveSAuditGrade>> list({String? search}) {
    return getList(
      '/5s-audit-grades',
      queryParameters: {'search': search},
      fromJson: FiveSAuditGrade.fromJson,
      fallbackMessage: 'Failed to load grades',
    );
  }

  Future<FiveSAuditGrade> create(Map<String, dynamic> payload) async {
    return _mutateObject(
      () => dio.post<dynamic>('/5s-audit-grades', data: payload),
      fallback: 'Failed to create grade',
    );
  }

  Future<FiveSAuditGrade> update({
    required String id,
    required Map<String, dynamic> payload,
  }) async {
    return _mutateObject(
      () => dio.put<dynamic>('/5s-audit-grades/$id', data: payload),
      fallback: 'Failed to update grade',
    );
  }

  Future<void> delete(String id) async {
    try {
      final response = await dio.delete<dynamic>('/5s-audit-grades/$id');
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (response.statusCode != null &&
          response.statusCode! >= 400 &&
          !envelope.success) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : 'Failed to delete grade',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: 'Failed to delete grade'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<FiveSAuditGrade> _mutateObject(
    Future<Response<dynamic>> Function() call, {
    required String fallback,
  }) async {
    try {
      final response = await call();
      final envelope = ApiResponse.fromDioData<dynamic>(response.data, null);
      if (!envelope.success || envelope.data is! Map) {
        throw ApiException(
          envelope.message.isNotEmpty ? envelope.message : fallback,
          statusCode: response.statusCode,
        );
      }
      return FiveSAuditGrade.fromJson(Map<String, dynamic>.from(envelope.data as Map));
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFromBody(e.response?.data, fallback: fallback),
        statusCode: e.response?.statusCode,
      );
    }
  }
}

final fiveSAuditTypeRepositoryProvider = Provider<FiveSAuditTypeRepository>((ref) {
  return FiveSAuditTypeRepository(ref.watch(dioProvider));
});

final fiveSAuditSectionRepositoryProvider =
    Provider<FiveSAuditSectionRepository>((ref) {
  return FiveSAuditSectionRepository(ref.watch(dioProvider));
});

final fiveSAuditQuestionRepositoryProvider =
    Provider<FiveSAuditQuestionRepository>((ref) {
  return FiveSAuditQuestionRepository(ref.watch(dioProvider));
});

final fiveSAuditGradeRepositoryProvider = Provider<FiveSAuditGradeRepository>((ref) {
  return FiveSAuditGradeRepository(ref.watch(dioProvider));
});
