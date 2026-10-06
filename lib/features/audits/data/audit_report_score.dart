import '../../five_s_config/data/models/five_s_config_models.dart';
import 'models/assessment_models.dart';

class AuditSectionScore {
  const AuditSectionScore({
    required this.name,
    required this.score,
    required this.maxScore,
  });

  final String name;
  final num score;
  final num maxScore;
}

class AuditReportScore {
  const AuditReportScore({
    required this.total,
    required this.max,
    required this.sections,
    required this.hasQuestionMax,
  });

  final num total;
  final num max;
  final List<AuditSectionScore> sections;
  final bool hasQuestionMax;

  int get percent {
    if (!hasQuestionMax || max <= 0) return 0;
    return ((total / max) * 100).round();
  }
}

/// Overall and per-section scores, matching the PDF cover (`91% (202/222)`).
AuditReportScore buildAuditReportScore({
  required List<AssessmentResponse> responses,
  List<FlatAuditQuestion> questions = const [],
  List<String> sectionOrder = const [],
}) {
  final maxByQuestion = <int, num>{};
  final categoryByQuestion = <int, String>{};
  final categoryOrder = <String>[];

  void addCategory(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || categoryOrder.contains(trimmed)) return;
    categoryOrder.add(trimmed);
  }

  for (final name in sectionOrder) {
    addCategory(name);
  }

  for (final question in questions) {
    addCategory(question.category);
    categoryByQuestion[question.id] = question.category.trim();
    if (question.options.isEmpty) continue;
    var maxScore = question.options.first.score;
    for (final option in question.options.skip(1)) {
      if (option.score > maxScore) maxScore = option.score;
    }
    maxByQuestion[question.id] = maxScore;
  }

  for (final response in responses) {
    final category = categoryByQuestion[response.questionId] ?? response.category;
    addCategory(category);
  }

  final totals = {for (final name in categoryOrder) name: 0 as num};
  final maxes = {for (final name in categoryOrder) name: 0 as num};
  final hasQuestionMax = questions.isNotEmpty;

  if (hasQuestionMax) {
    for (final question in questions) {
      final category = question.category.trim().isEmpty ? 'General' : question.category.trim();
      maxes[category] = (maxes[category] ?? 0) + (maxByQuestion[question.id] ?? 0);
    }
    for (final response in responses) {
      if (response.score == null) continue;
      final category = (categoryByQuestion[response.questionId] ?? response.category).trim();
      if (category.isEmpty) continue;
      totals[category] = (totals[category] ?? 0) + response.score!;
    }
  } else {
    for (final response in responses) {
      final category = response.category.trim().isEmpty ? 'General' : response.category.trim();
      totals[category] = (totals[category] ?? 0) + (response.score ?? 0);
    }
  }

  final sections = [
    for (final name in categoryOrder)
      if ((maxes[name] ?? 0) > 0 || (totals[name] ?? 0) > 0)
        AuditSectionScore(
          name: name,
          score: totals[name] ?? 0,
          maxScore: maxes[name] ?? 0,
        ),
  ];

  return AuditReportScore(
    total: sections.fold<num>(0, (sum, section) => sum + section.score),
    max: sections.fold<num>(0, (sum, section) => sum + section.maxScore),
    sections: sections,
    hasQuestionMax: hasQuestionMax,
  );
}

String formatReportNumber(num value) {
  if (value == value.roundToDouble()) return value.round().toString();
  return value.toString();
}
