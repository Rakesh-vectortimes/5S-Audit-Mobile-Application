import '../../../core/constants/audit_status.dart';
import '../../../core/network/list_response.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import 'action_plan_helpers.dart';
import 'models/assessment_models.dart';

abstract final class FiveSAuditMapper {
  static Map<String, dynamic>? sectionDetails(dynamic section) {
    if (section is! Map) return null;
    final map = Map<String, dynamic>.from(section);
    final details = map['details'];
    if (details is Map) return Map<String, dynamic>.from(details);
    return map;
  }

  static List<AssessmentResponse> extractResponses(Map<String, dynamic> raw) {
    final assessment = raw['assessment'];
    if (assessment is! Map) return const [];
    final map = Map<String, dynamic>.from(assessment);
    if (map['responses'] is List) {
      return (map['responses'] as List)
          .whereType<Map>()
          .map((e) => AssessmentResponse.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    final details = map['details'];
    if (details is Map && details['responses'] is List) {
      return (details['responses'] as List)
          .whereType<Map>()
          .map((e) => AssessmentResponse.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    return const [];
  }

  static List<AssessmentResponse> enrichResponses({
    required List<AssessmentResponse> responses,
    required List<FlatAuditQuestion> questions,
  }) {
    final byId = {for (final q in questions) q.id: q};
    final seen = <int>{};
    final enriched = <AssessmentResponse>[];

    for (final response in responses) {
      final questionId = response.questionId;
      if (questionId < 1 || !seen.add(questionId)) continue;

      final question = byId[questionId];
      final category = (question?.category.trim().isNotEmpty == true)
          ? question!.category
          : response.category.trim();
      if (category.isEmpty) continue;

      final optionIndex = response.optionIndex;
      String? selectedResponse = response.selectedResponse;
      if (question != null) {
        if (optionIndex != null &&
            optionIndex >= 0 &&
            optionIndex < question.options.length) {
          selectedResponse = question.options[optionIndex].description;
        } else if (selectedResponse == null || selectedResponse.isEmpty) {
          selectedResponse = _levelDescription(question, response.score);
        }
      }

      final includeActionPlan = question != null &&
          isActionPlanTriggered(
            question: question,
            score: response.score,
            optionIndex: optionIndex,
          ) &&
          response.actionPlan != null &&
          response.actionPlan!.hasContent;

      final subCategory =
          (response.subCategory?.trim().isNotEmpty == true)
              ? response.subCategory
              : question?.subCategory;

      enriched.add(
        AssessmentResponse(
          questionId: questionId,
          category: category,
          subCategory: subCategory,
          score: response.score,
          optionIndex: optionIndex,
          question: response.question ?? question?.text,
          selectedResponse: selectedResponse,
          comments: response.comments,
          actionPlan: includeActionPlan ? response.actionPlan : null,
        ),
      );
    }
    return enriched;
  }

  static String _levelDescription(FlatAuditQuestion question, num? score) {
    if (score == null) return '';
    for (final option in question.options) {
      if (option.score == score) return option.description;
    }
    return '';
  }

  static ({String summary, bool sign, String declarationSignature}) extractReviewAndSign(
    Map<String, dynamic> raw,
  ) {
    final assessmentDetails = sectionDetails(raw['assessment']);
    final reviewDetails = sectionDetails(raw['review_and_sign']);

    final summary = (raw['summary'] ??
            assessmentDetails?['summary'] ??
            reviewDetails?['summary'] ??
            '')
        .toString();

    final signatureRaw = raw['declaration_signature'] ??
        assessmentDetails?['declaration_signature'] ??
        reviewDetails?['declaration_signature'] ??
        raw['auditor_signature'] ??
        assessmentDetails?['auditor_signature'] ??
        reviewDetails?['auditor_signature'];

    final declarationSignature = _resolveSignature(signatureRaw);
    final signRaw =
        raw['sign'] ?? assessmentDetails?['sign'] ?? reviewDetails?['sign'] ?? false;
    final sign = declarationSignature.isNotEmpty ||
        signRaw == true ||
        signRaw == 'true' ||
        signRaw == 1 ||
        signRaw == '1';

    return (
      summary: summary,
      sign: sign,
      declarationSignature: declarationSignature,
    );
  }

  static String _resolveSignature(Object? raw) {
    if (raw == null) return '';
    if (raw is String) return raw.trim();
    if (raw is Map) {
      final map = Map<String, dynamic>.from(raw);
      final url = map['image_url'] ?? map['uploadurl'] ?? map['url'] ?? map['data'];
      return url?.toString().trim() ?? '';
    }
    return raw.toString().trim();
  }

  static String formatApiDate(Object? value) {
    if (value == null || value.toString().trim().isEmpty) {
      final now = DateTime.now();
      return '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')}';
    }
    return value.toString().split('T').first;
  }

  /// Builds POST/PUT payload matching web `buildFiveSAuditApiPayload`.
  static Map<String, dynamic> buildApiPayload({
    required String? companyId,
    required String? auditTypeId,
    required String companyName,
    String? auditTypeName,
    required String reportDate,
    required String statusUi,
    required String summary,
    required bool sign,
    String? declarationSignature,
    required CompanyBackground background,
    required List<AssessmentResponse> responses,
    required List<FlatAuditQuestion> questions,
  }) {
    final name = companyName.trim().isEmpty ? '5S Audit' : companyName.trim();
    final typeName = auditTypeName?.trim() ?? '';
    final enriched = enrichResponses(responses: responses, questions: questions);
    final signature = (declarationSignature ?? '').trim();
    final signed = sign || signature.isNotEmpty;

    final bg = background
        .copyWith(
          companyId: normalizeEntityId(companyId) ?? background.companyId,
          companyName: name,
        )
        .toJson();

    return {
      'company_id': normalizeEntityId(companyId),
      'audit_type_id': normalizeEntityId(auditTypeId),
      'title': typeName.isNotEmpty ? '$name - $typeName' : '$name 5S Audit',
      'company_name': name,
      'report_date': formatApiDate(reportDate),
      'status': AuditStatusMapper.toApi(statusUi),
      'summary': summary,
      'sign': signed,
      'declaration_signature': signature.isEmpty ? null : signature,
      'company_background': {'details': bg},
      'assessment': {
        'details': {
          'responses': enriched
              .map((r) => r.toJson(includeActionPlan: r.actionPlan != null))
              .toList(),
          'summary': summary,
          'sign': signed,
          'declaration_signature': signature.isEmpty ? null : signature,
        },
      },
      'review_and_sign': {
        'details': {
          'summary': summary,
          'sign': signed,
          'declaration_signature': signature.isEmpty ? null : signature,
        },
      },
    };
  }

  static FiveSAuditRecord normalizeRecord(Map<String, dynamic> raw) {
    final backgroundDetails = sectionDetails(raw['company_background']);
    final background = CompanyBackground.fromJson(backgroundDetails);
    final review = extractReviewAndSign(raw);
    final responses = extractResponses(raw);

    final preparedBy = (raw['created_by_name'] as String?) ??
        _displayName(raw['prepared_by']) ??
        _displayName(raw['created_by']);

    final updatedBy = (raw['updated_by_name'] as String?) ??
        _displayName(raw['updated_by']) ??
        _displayName(raw['updatedBy']);

    final createdByRole = raw['created_by_role'] as String? ??
        raw['creator_role'] as String? ??
        (raw['created_by'] is Map
            ? (raw['created_by'] as Map)['role']?.toString()
            : null);

    return FiveSAuditRecord(
      id: ListResponse.extractId(raw, preferredKeys: const ['assessment_id']),
      companyId: normalizeEntityId(raw['company_id']) ?? background.companyId,
      auditTypeId: normalizeEntityId(raw['audit_type_id'] ?? raw['fk_audit_type_id']),
      auditTypeName: raw['audit_type_name'] as String? ?? raw['audit_name'] as String?,
      companyName: (raw['company_name'] as String?) ?? background.companyName,
      title: raw['title'] as String?,
      reportDate: formatApiDate(raw['report_date']),
      preparedBy: preparedBy,
      createdByName: raw['created_by_name'] as String?,
      createdByRole: createdByRole,
      updatedBy: updatedBy,
      status: AuditStatusMapper.toUi(raw['status']?.toString()),
      summary: review.summary,
      sign: review.sign,
      declarationSignature: review.declarationSignature,
      companyBackground: background,
      responses: responses,
      createdAt: raw['created_at']?.toString() ?? raw['created_on']?.toString(),
      updatedAt: raw['updated_at']?.toString() ?? raw['updated_on']?.toString(),
      createdBy: raw['created_by'] ?? raw['createdBy'],
    );
  }

  static String? _displayName(Object? value) {
    if (value == null) return null;
    if (value is String) {
      if (RegExp(r'^[a-f\d]{24}$', caseSensitive: false).hasMatch(value)) {
        return null;
      }
      return value;
    }
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      return (map['name'] ?? map['full_name'] ?? map['email'])?.toString();
    }
    return null;
  }
}
