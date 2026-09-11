import 'package:equatable/equatable.dart';

import '../../../../core/network/list_response.dart';

class FiveSAuditType extends Equatable {
  const FiveSAuditType({
    required this.id,
    required this.companyId,
    required this.auditName,
    this.auditOrder,
    this.status,
  });

  final String id;
  final String companyId;
  final String auditName;
  final int? auditOrder;
  final dynamic status;

  String get displayName => auditName.isEmpty ? id : auditName;

  factory FiveSAuditType.fromJson(Map<String, dynamic> json) {
    return FiveSAuditType(
      id: ListResponse.extractId(json, preferredKeys: const ['audit_type_id']),
      companyId: normalizeEntityId(json['company_id']) ?? '',
      auditName: json['audit_name']?.toString().trim() ??
          json['name']?.toString().trim() ??
          '',
      auditOrder: _asInt(json['audit_order']),
      status: json['status'],
    );
  }

  @override
  List<Object?> get props => [id, companyId, auditName];
}

class FiveSAuditSection extends Equatable {
  const FiveSAuditSection({
    required this.id,
    required this.sectionName,
    this.companyId,
    this.fkAuditTypeId,
    this.fkParentSectionId,
    this.noOfQuestions = 0,
    this.totalMarks = 0,
    this.sectionOrder,
    this.sectionOrderLabel,
    this.isSubSection,
    this.isLeaf,
    this.parentSectionName,
    this.sectionDisplayLabel,
    this.status,
  });

  final String id;
  final String? companyId;
  final String? fkAuditTypeId;
  final String? fkParentSectionId;
  final String sectionName;
  final int noOfQuestions;
  final int totalMarks;
  final int? sectionOrder;
  final String? sectionOrderLabel;
  final bool? isSubSection;
  final bool? isLeaf;
  final String? parentSectionName;
  final String? sectionDisplayLabel;
  final dynamic status;

  bool get isTopLevel {
    if (isSubSection == true) return false;
    return fkParentSectionId == null || fkParentSectionId!.trim().isEmpty;
  }

  String get displayLabel {
    final label = sectionDisplayLabel?.trim();
    if (label != null && label.isNotEmpty) return label;
    return sectionName;
  }

  factory FiveSAuditSection.fromJson(Map<String, dynamic> json) {
    return FiveSAuditSection(
      id: ListResponse.extractId(json),
      companyId: normalizeEntityId(json['company_id']),
      fkAuditTypeId: normalizeEntityId(
        json['fk_audit_type_id'] ?? json['audit_type_id'],
      ),
      fkParentSectionId: normalizeEntityId(
        json['fk_parent_section_id'] ?? json['parent_section_id'],
      ),
      sectionName: json['section_name']?.toString().trim() ?? '',
      noOfQuestions: _asInt(json['no_of_questions']) ?? 0,
      totalMarks: _asInt(json['total_marks']) ?? 0,
      sectionOrder: _asInt(json['section_order']),
      sectionOrderLabel: json['section_order_label']?.toString(),
      isSubSection: _asBool(json['is_sub_section']),
      isLeaf: _asBool(json['is_leaf']),
      parentSectionName: json['parent_section_name']?.toString(),
      sectionDisplayLabel: json['section_display_label']?.toString(),
      status: json['status'],
    );
  }

  @override
  List<Object?> get props => [id, sectionName, fkParentSectionId];
}

class FiveSAuditGrade extends Equatable {
  const FiveSAuditGrade({
    required this.id,
    required this.gradingCriteria,
    this.score,
    this.minScore = 0,
    this.maxScore = 0,
    this.percentage = 0,
    this.gradeOrder,
  });

  final String id;
  final String gradingCriteria;
  final String? score;
  final num minScore;
  final num maxScore;
  final num percentage;
  final int? gradeOrder;

  factory FiveSAuditGrade.fromJson(Map<String, dynamic> json) {
    return FiveSAuditGrade(
      id: ListResponse.extractId(json),
      gradingCriteria: json['grading_criteria']?.toString().trim() ?? '',
      score: json['score']?.toString(),
      minScore: _asNum(json['min_score']) ?? 0,
      maxScore: _asNum(json['max_score']) ?? 0,
      percentage: _asNum(json['percentage']) ?? 0,
      gradeOrder: _asInt(json['grade_order']),
    );
  }

  @override
  List<Object?> get props => [id, gradingCriteria];
}

class FiveSAuditQuestionOption extends Equatable {
  const FiveSAuditQuestionOption({
    required this.score,
    required this.description,
  });

  final num score;
  final String description;

  factory FiveSAuditQuestionOption.fromJson(Map<String, dynamic> json) {
    return FiveSAuditQuestionOption(
      score: _asNum(json['score']) ?? 0,
      description: json['description']?.toString().trim() ?? '',
    );
  }

  @override
  List<Object?> get props => [score, description];
}

class FiveSAuditQuestionActionPlan extends Equatable {
  const FiveSAuditQuestionActionPlan({
    this.enabled = false,
    this.mandatory = false,
    this.defaultAssigneeIds = const [],
    this.defaultAssigneeNames = const [],
    this.triggerScores = const [],
    this.triggerOptionIndexes = const [],
    this.defaultValue,
  });

  final bool enabled;
  final bool mandatory;
  final List<String> defaultAssigneeIds;
  final List<String> defaultAssigneeNames;
  final List<int> triggerScores;
  final List<int> triggerOptionIndexes;
  final String? defaultValue;

  factory FiveSAuditQuestionActionPlan.fromJson(Map<String, dynamic> json) {
    final defaultValue = _firstNonEmptyString([
      json['default_value'],
      json['default_notes'],
      json['action_required'],
    ]);
    final triggerOptionIndexes = _asIntList(json['trigger_option_indexes']);
    final triggerScores = _asIntList(json['trigger_scores']);
    final enabledExplicit =
        _asBool(json['enabled'] ?? json['action_plan_required']);
    // Some API payloads omit `enabled` even when action-plan config is present.
    final enabled = enabledExplicit ??
        (triggerOptionIndexes.isNotEmpty ||
            triggerScores.isNotEmpty ||
            (defaultValue != null && defaultValue.isNotEmpty) ||
            _asStringList(json['default_assignee_ids']).isNotEmpty);

    return FiveSAuditQuestionActionPlan(
      enabled: enabled,
      mandatory: _asBool(json['mandatory']) ?? false,
      defaultAssigneeIds: _asStringList(json['default_assignee_ids']),
      defaultAssigneeNames: _asStringList(json['default_assignee_names']),
      triggerScores: triggerScores,
      triggerOptionIndexes: triggerOptionIndexes,
      defaultValue: defaultValue,
    );
  }

  @override
  List<Object?> get props =>
      [enabled, mandatory, triggerOptionIndexes, defaultValue];
}

class FiveSAuditQuestionImage extends Equatable {
  const FiveSAuditQuestionImage({
    this.imageUrl,
    this.fileName,
    this.uploadUrl,
    this.fileType,
    this.fileSize,
  });

  final String? imageUrl;
  final String? fileName;
  final String? uploadUrl;
  final String? fileType;
  final num? fileSize;

  factory FiveSAuditQuestionImage.fromJson(Map<String, dynamic> json) {
    return FiveSAuditQuestionImage(
      imageUrl: json['image_url']?.toString(),
      fileName: json['file_name']?.toString(),
      uploadUrl: json['uploadurl']?.toString(),
      fileType: json['file_type']?.toString(),
      fileSize: _asNum(json['file_size']),
    );
  }

  @override
  List<Object?> get props => [imageUrl, fileName];
}

class FiveSAuditQuestionItem extends Equatable {
  const FiveSAuditQuestionItem({
    required this.questionId,
    required this.question,
    this.isMandatory = true,
    this.commentsEnabled = false,
    this.images = const [],
    this.actionPlan,
    this.options = const [],
  });

  final int questionId;
  final String question;
  final bool isMandatory;
  final bool commentsEnabled;
  final List<FiveSAuditQuestionImage> images;
  final FiveSAuditQuestionActionPlan? actionPlan;
  final List<FiveSAuditQuestionOption> options;

  factory FiveSAuditQuestionItem.fromJson(Map<String, dynamic> json) {
    final optionsRaw = json['options'];
    final imagesRaw = json['images'];
    final actionPlanRaw = json['action_plan'];

    return FiveSAuditQuestionItem(
      questionId: _asInt(json['question_id']) ?? _asInt(json['id']) ?? 0,
      question: json['question']?.toString().trim() ??
          json['question_text']?.toString().trim() ??
          '',
      isMandatory: json['is_mandatory'] != false,
      commentsEnabled: json['comments_enabled'] == true,
      images: imagesRaw is List
          ? imagesRaw
              .whereType<Map>()
              .map((e) => FiveSAuditQuestionImage.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      actionPlan: actionPlanRaw is Map
          ? FiveSAuditQuestionActionPlan.fromJson(
              Map<String, dynamic>.from(actionPlanRaw),
            )
          : null,
      options: optionsRaw is List
          ? optionsRaw
              .whereType<Map>()
              .map((e) => FiveSAuditQuestionOption.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
    );
  }

  @override
  List<Object?> get props => [questionId, question];
}

class FiveSAuditQuestionDocument extends Equatable {
  const FiveSAuditQuestionDocument({
    required this.id,
    required this.fkSectionId,
    this.companyId,
    this.fkAuditTypeId,
    this.questions = const [],
  });

  final String id;
  final String? companyId;
  final String? fkAuditTypeId;
  final String fkSectionId;
  final List<FiveSAuditQuestionItem> questions;

  factory FiveSAuditQuestionDocument.fromJson(Map<String, dynamic> json) {
    final details = json['details'];
    final source = details is Map
        ? {...json, ...Map<String, dynamic>.from(details)}
        : json;
    final questionsRaw = source['questions'] ?? json['questions'];
    var questions = _parseQuestionItems(questionsRaw);
    if (questions.isEmpty) {
      final maybeItem = FiveSAuditQuestionItem.fromJson(source);
      if (maybeItem.questionId > 0 && maybeItem.question.isNotEmpty) {
        questions = [maybeItem];
      }
    }
    return FiveSAuditQuestionDocument(
      id: ListResponse.extractId(source),
      companyId: normalizeEntityId(source['company_id']),
      fkAuditTypeId: normalizeEntityId(
        source['fk_audit_type_id'] ?? source['audit_type_id'],
      ),
      fkSectionId: normalizeEntityId(
            source['fk_section_id'] ?? source['section_id'],
          ) ??
          '',
      questions: questions,
    );
  }

  @override
  List<Object?> get props => [id, fkSectionId];
}

/// Flattened question used by assessment steps (mirrors web LeanMaturityQuestion).
class FlatAuditQuestion extends Equatable {
  const FlatAuditQuestion({
    required this.id,
    required this.category,
    required this.text,
    this.subCategory,
    this.isMandatory = true,
    this.commentsEnabled = false,
    this.options = const [],
    this.actionPlan,
    this.images = const [],
  });

  final int id;
  final String category;
  final String? subCategory;
  final String text;
  final bool isMandatory;
  final bool commentsEnabled;
  final List<FiveSAuditQuestionOption> options;
  final FiveSAuditQuestionActionPlan? actionPlan;
  final List<FiveSAuditQuestionImage> images;

  @override
  List<Object?> get props => [id, category, subCategory, text];
}

class AssessmentStep extends Equatable {
  const AssessmentStep({
    required this.key,
    required this.category,
    required this.label,
    this.subCategory,
  });

  final String key;
  final String category;
  final String? subCategory;
  final String label;

  @override
  List<Object?> get props => [key, category, subCategory, label];
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim());
  return null;
}

bool? _asBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return null;
}

num? _asNum(Object? value) {
  if (value is num) return value;
  if (value is String) return num.tryParse(value);
  return null;
}

List<String> _asStringList(Object? value) {
  if (value is! List) return const [];
  return value.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
}

List<int> _asIntList(Object? value) {
  if (value is! List) return const [];
  return value.map(_asInt).whereType<int>().toList();
}

String? _firstNonEmptyString(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return null;
}

List<FiveSAuditQuestionItem> _parseQuestionItems(Object? raw) {
  Iterable<Object?> items;
  if (raw is List) {
    items = raw;
  } else if (raw is Map) {
    items = raw.values;
  } else {
    return const [];
  }

  final parsed = <FiveSAuditQuestionItem>[];
  for (final item in items) {
    if (item is! Map) continue;
    try {
      final question = FiveSAuditQuestionItem.fromJson(
        Map<String, dynamic>.from(item),
      );
      if (question.questionId > 0) parsed.add(question);
    } catch (_) {
      continue;
    }
  }
  return parsed;
}
