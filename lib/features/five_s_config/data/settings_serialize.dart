import '../../../core/network/image_url.dart';
import 'models/five_s_config_models.dart';

/// Auto % from this grade's max vs overall max among peers (web-style).
num computeGradePercentage({
  required num maxScore,
  required Iterable<num> peerMaxScores,
}) {
  final peers = peerMaxScores.where((n) => n > 0).toList();
  final overall = [
    if (maxScore > 0) maxScore,
    ...peers,
  ].fold<num>(0, (a, b) => a > b ? a : b);
  if (overall <= 0) return 0;
  return ((maxScore / overall) * 100 * 100).round() / 100;
}

Map<String, dynamic> buildGradePayload({
  required String gradingCriteria,
  String? score,
  required num minScore,
  required num maxScore,
  required num percentage,
  int? gradeOrder,
  Object? status = 1,
}) {
  return {
    'grading_criteria': gradingCriteria.trim(),
    'score': (score ?? '').trim(),
    'min_score': minScore,
    'max_score': maxScore,
    'percentage': percentage,
    if (gradeOrder != null) 'grade_order': gradeOrder,
    'status': status ?? 1,
  };
}

Map<String, dynamic> buildAuditTypePayload({
  required String companyId,
  required String auditName,
  Object? status = 1,
}) {
  return {
    'company_id': companyId,
    'audit_name': auditName.trim(),
    if (status != null) 'status': status,
  };
}

Map<String, dynamic> buildSectionPayload({
  required String companyId,
  required String auditTypeId,
  required String sectionName,
  String? parentSectionId,
  int noOfQuestions = 0,
  num totalMarks = 0,
  int? sectionOrder,
  Object? status = 1,
}) {
  return {
    'company_id': companyId,
    'fk_audit_type_id': auditTypeId,
    'section_name': sectionName.trim(),
    'no_of_questions': noOfQuestions,
    'total_marks': totalMarks,
    if (sectionOrder != null) 'section_order': sectionOrder,
    'fk_parent_section_id':
        (parentSectionId == null || parentSectionId.trim().isEmpty)
            ? null
            : parentSectionId,
    'status': status ?? 1,
  };
}

Map<String, dynamic>? serializeActionPlan(FiveSAuditQuestionActionPlan? plan) {
  if (plan == null || !plan.enabled) return null;
  final ids = plan.defaultAssigneeIds;
  final names = plan.defaultAssigneeNames;
  return {
    'enabled': true,
    'mandatory': plan.mandatory,
    'default_assignee_id': ids.isEmpty ? null : ids.first,
    'default_assignee_name': names.isEmpty ? null : names.join(', '),
    'default_assignee_ids': ids,
    'default_assignee_names': names,
    'trigger_scores': plan.triggerScores,
    'trigger_option_indexes': plan.triggerOptionIndexes,
    'default_value': plan.defaultValue?.trim() ?? '',
  };
}

List<Map<String, dynamic>> serializeQuestionImages(
  List<FiveSAuditQuestionImage> images,
) {
  return images
      .where((i) => (i.uploadUrl ?? '').trim().isNotEmpty)
      .map(
        (i) => {
          if ((i.fileName ?? '').isNotEmpty) 'file_name': i.fileName,
          'uploadurl': i.uploadUrl!.trim(),
          if ((i.fileType ?? '').isNotEmpty) 'file_type': i.fileType,
          if (i.fileSize != null) 'file_size': i.fileSize,
        },
      )
      .toList();
}

Map<String, dynamic> serializeQuestionItem(FiveSAuditQuestionItem item) {
  final images = serializeQuestionImages(item.images);
  final actionPlan = serializeActionPlan(item.actionPlan);
  return {
    'question_id': item.questionId,
    'question': item.question.trim(),
    'is_mandatory': item.isMandatory,
    'comments_enabled': item.commentsEnabled,
    if (images.isNotEmpty) 'images': images,
    if (actionPlan != null) 'action_plan': actionPlan,
    'options': item.options
        .map(
          (o) => {
            'score': o.score,
            'description': o.description.trim(),
          },
        )
        .toList(),
  };
}

Map<String, dynamic> buildQuestionDocumentPayload({
  required String companyId,
  required String auditTypeId,
  required String sectionId,
  required List<FiveSAuditQuestionItem> questions,
  Object? status = 1,
}) {
  return {
    'company_id': companyId,
    'fk_audit_type_id': auditTypeId,
    'fk_section_id': sectionId,
    'questions': questions.map(serializeQuestionItem).toList(),
    'status': status ?? 1,
  };
}

/// Re-export image validation for settings question uploads.
String? validateQuestionImage({required String? mimeType, required int sizeBytes}) {
  return validateProofImage(mimeType: mimeType, sizeBytes: sizeBytes);
}
