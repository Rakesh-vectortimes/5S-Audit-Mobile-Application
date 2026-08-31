import '../data/models/five_s_config_models.dart';

int compareSectionsByOrder(FiveSAuditSection left, FiveSAuditSection right) {
  final leftLabel = left.sectionOrderLabel?.trim();
  final rightLabel = right.sectionOrderLabel?.trim();
  if (leftLabel != null &&
      leftLabel.isNotEmpty &&
      rightLabel != null &&
      rightLabel.isNotEmpty) {
    return _compareOrderLabels(leftLabel, rightLabel);
  }
  return (left.sectionOrder ?? 0).compareTo(right.sectionOrder ?? 0);
}

int _compareOrderLabels(String left, String right) {
  final leftParts = left.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final rightParts = right.split('.').map((p) => int.tryParse(p) ?? 0).toList();
  final length = leftParts.length > rightParts.length ? leftParts.length : rightParts.length;
  for (var i = 0; i < length; i++) {
    final diff = (i < leftParts.length ? leftParts[i] : 0) -
        (i < rightParts.length ? rightParts[i] : 0);
    if (diff != 0) return diff;
  }
  return 0;
}

List<FiveSAuditSection> getTopLevelSections(List<FiveSAuditSection> sections) {
  return sections.where((s) => s.isTopLevel).toList()..sort(compareSectionsByOrder);
}

List<FiveSAuditSection> getChildSections(
  List<FiveSAuditSection> sections,
  String parentId,
) {
  final normalized = parentId.trim();
  if (normalized.isEmpty) return const [];
  return sections
      .where((s) => (s.fkParentSectionId ?? '').trim() == normalized)
      .toList()
    ..sort(compareSectionsByOrder);
}

({String category, String? subCategory}) resolveQuestionCategory(
  FiveSAuditSection section,
  List<FiveSAuditSection> sections,
) {
  final parentId = section.fkParentSectionId?.trim();
  if (parentId == null || parentId.isEmpty) {
    return (category: section.sectionName, subCategory: null);
  }
  FiveSAuditSection? parent;
  for (final candidate in sections) {
    if (candidate.id == parentId) {
      parent = candidate;
      break;
    }
  }
  return (
    category: parent?.sectionName ?? section.sectionName,
    subCategory: section.sectionName,
  );
}

List<AssessmentStep> buildAssessmentSteps({
  required List<FiveSAuditSection> sections,
  required List<FlatAuditQuestion> flatQuestions,
}) {
  final steps = <AssessmentStep>[];

  for (final parent in getTopLevelSections(sections)) {
    final children = getChildSections(sections, parent.id);
    if (children.isNotEmpty) {
      for (final child in children) {
        steps.add(
          AssessmentStep(
            key: '${parent.sectionName}::${child.sectionName}',
            category: parent.sectionName,
            subCategory: child.sectionName,
            label: child.displayLabel,
          ),
        );
      }
      if (_questionsForGroup(flatQuestions, parent.sectionName).isNotEmpty) {
        steps.add(
          AssessmentStep(
            key: '${parent.sectionName}::',
            category: parent.sectionName,
            label: parent.displayLabel,
          ),
        );
      }
      continue;
    }

    final subCategories = _subCategoriesForCategory(flatQuestions, parent.sectionName);
    if (subCategories.isNotEmpty) {
      for (final sub in subCategories) {
        steps.add(
          AssessmentStep(
            key: '${parent.sectionName}::$sub',
            category: parent.sectionName,
            subCategory: sub,
            label: sub,
          ),
        );
      }
      if (_questionsForGroup(flatQuestions, parent.sectionName).isNotEmpty) {
        steps.add(
          AssessmentStep(
            key: '${parent.sectionName}::',
            category: parent.sectionName,
            label: parent.displayLabel,
          ),
        );
      }
      continue;
    }

    steps.add(
      AssessmentStep(
        key: parent.sectionName,
        category: parent.sectionName,
        label: parent.displayLabel,
      ),
    );
  }

  if (steps.isEmpty && flatQuestions.isNotEmpty) {
    final seen = <String>{};
    for (final question in flatQuestions) {
      final category = question.category.trim().isEmpty ? 'Questions' : question.category;
      final sub = question.subCategory?.trim();
      final key = sub == null || sub.isEmpty ? category : '$category::$sub';
      if (!seen.add(key)) continue;
      steps.add(
        AssessmentStep(
          key: key,
          category: category,
          subCategory: sub == null || sub.isEmpty ? null : sub,
          label: sub == null || sub.isEmpty ? category : sub,
        ),
      );
    }
  }

  return steps;
}

List<String> _subCategoriesForCategory(
  List<FlatAuditQuestion> questions,
  String category,
) {
  final seen = <String>{};
  final result = <String>[];
  for (final q in questions.where((q) => q.category == category)) {
    final sub = q.subCategory?.trim();
    if (sub != null && sub.isNotEmpty && seen.add(sub)) {
      result.add(sub);
    }
  }
  return result;
}

List<FlatAuditQuestion> _questionsForGroup(
  List<FlatAuditQuestion> questions,
  String category, [
  String? subCategory,
]) {
  if (subCategory == null) {
    return questions
        .where((q) => q.category == category && (q.subCategory == null || q.subCategory!.isEmpty))
        .toList();
  }
  return questions
      .where((q) => q.category == category && q.subCategory == subCategory)
      .toList();
}

List<FlatAuditQuestion> questionsForStep(
  List<FlatAuditQuestion> questions,
  AssessmentStep step,
) {
  return _questionsForGroup(questions, step.category, step.subCategory);
}

List<FlatAuditQuestion> mapFlatQuestions({
  required List<FiveSAuditSection> sections,
  required List<FiveSAuditQuestionDocument> documents,
}) {
  final sectionById = {
    for (final section in sections) section.id: section,
  };
  final byId = <int, FlatAuditQuestion>{};

  for (final doc in documents) {
    final section = sectionById[doc.fkSectionId];
    final resolved = section != null
        ? resolveQuestionCategory(section, sections)
        : (category: 'General', subCategory: null as String?);

    for (final item in doc.questions) {
      if (item.questionId < 1) continue;
      byId[item.questionId] = FlatAuditQuestion(
        id: item.questionId,
        category: resolved.category,
        subCategory: resolved.subCategory,
        text: item.question,
        isMandatory: item.isMandatory,
        commentsEnabled: item.commentsEnabled,
        options: [...item.options]..sort((a, b) => a.score.compareTo(b.score)),
        actionPlan: item.actionPlan?.enabled == true ? item.actionPlan : null,
        images: item.images,
      );
    }
  }

  final list = byId.values.toList()..sort((a, b) => a.id.compareTo(b.id));
  return list;
}
