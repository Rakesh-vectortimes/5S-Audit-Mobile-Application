import 'models/assessment_models.dart';

int countAnsweredQuestions({
  required Iterable<int> questionIds,
  required Map<int, AssessmentResponse> responses,
}) {
  var answered = 0;
  for (final id in questionIds) {
    if (responses[id]?.isAnswered == true) answered++;
  }
  return answered;
}

/// 0–100 from answered / total questions. Page changes do not affect this.
int questionProgressPercent({
  required int totalQuestions,
  required int answeredQuestions,
}) {
  if (totalQuestions <= 0) return 0;
  final bounded = answeredQuestions.clamp(0, totalQuestions);
  return ((bounded / totalQuestions) * 100).round();
}
