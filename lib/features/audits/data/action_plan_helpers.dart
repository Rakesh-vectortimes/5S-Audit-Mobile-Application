import '../../five_s_config/data/models/five_s_config_models.dart';
import 'models/assessment_models.dart';

bool isAnsweredScore(num? score) => score != null;

bool isActionPlanTriggered({
  required FlatAuditQuestion question,
  required num? score,
  int? optionIndex,
}) {
  final config = question.actionPlan;
  if (config == null || !config.enabled || score == null) return false;

  final triggerIndexes = _resolveTriggerOptionIndexes(config, question.options);
  if (triggerIndexes.isNotEmpty) {
    if (optionIndex != null) {
      return triggerIndexes.contains(optionIndex);
    }
    final matching = <int>[];
    for (var i = 0; i < question.options.length; i++) {
      if (question.options[i].score == score) matching.add(i);
    }
    if (matching.length == 1) {
      return triggerIndexes.contains(matching.first);
    }
    return false;
  }

  return config.triggerScores.map((e) => e.toDouble()).contains(score.toDouble());
}

List<int> _resolveTriggerOptionIndexes(
  FiveSAuditQuestionActionPlan config,
  List<FiveSAuditQuestionOption> options,
) {
  final stored = config.triggerOptionIndexes
      .where((i) => i >= 0 && i < options.length)
      .toSet()
      .toList()
    ..sort();
  if (stored.isNotEmpty || config.triggerOptionIndexes.isNotEmpty) {
    return stored;
  }
  if (config.triggerScores.isEmpty) return const [];
  final scores = config.triggerScores.map((e) => e.toDouble()).toSet();
  final indexes = <int>[];
  for (var i = 0; i < options.length; i++) {
    if (scores.contains(options[i].score.toDouble())) indexes.add(i);
  }
  return indexes;
}

bool isActionPlanComplete({
  required FlatAuditQuestion question,
  required num? score,
  int? optionIndex,
  ActionPlanAnswer? actionPlan,
}) {
  if (!isActionPlanTriggered(
    question: question,
    score: score,
    optionIndex: optionIndex,
  )) {
    return true;
  }
  final notes = actionPlan?.notes.trim() ?? '';
  final assignees = actionPlan?.assigneeIds ?? const [];
  return notes.isNotEmpty && assignees.isNotEmpty;
}

/// Prefills notes/assignees from question settings without overwriting user input.
ActionPlanAnswer buildActionPlanWithDefaults({
  ActionPlanAnswer? existing,
  FiveSAuditQuestionActionPlan? config,
}) {
  final defaultNotes = (config?.defaultValue ?? '').trim();
  final defaultAssigneeIds = config?.defaultAssigneeIds ?? const <String>[];
  final defaultAssigneeNames = config?.defaultAssigneeNames ?? const <String>[];

  if (existing == null) {
    return ActionPlanAnswer(
      notes: defaultNotes,
      assigneeIds: defaultAssigneeIds,
      assigneeNames: defaultAssigneeNames,
    );
  }

  final notes = existing.notes.trim().isEmpty ? defaultNotes : existing.notes;
  final assigneeIds =
      existing.assigneeIds.isEmpty ? defaultAssigneeIds : existing.assigneeIds;
  final assigneeNames = existing.assigneeNames.isEmpty
      ? defaultAssigneeNames
      : existing.assigneeNames;

  return existing.copyWith(
    notes: notes,
    assigneeIds: assigneeIds,
    assigneeNames: assigneeNames,
  );
}

String gradeForScore({
  required num totalScore,
  required num maxScore,
  required List<FiveSAuditGrade> grades,
}) {
  if (maxScore <= 0) return '-';
  final percentage = (totalScore / maxScore) * 100;
  final sorted = [...grades]..sort((a, b) => (a.gradeOrder ?? 0).compareTo(b.gradeOrder ?? 0));
  for (final grade in sorted) {
    if (percentage >= grade.minScore && percentage <= grade.maxScore) {
      return grade.gradingCriteria;
    }
  }
  // Fallback: match absolute score ranges if percentage fields look like absolute.
  for (final grade in sorted) {
    if (totalScore >= grade.minScore && totalScore <= grade.maxScore) {
      return grade.gradingCriteria;
    }
  }
  return '-';
}
