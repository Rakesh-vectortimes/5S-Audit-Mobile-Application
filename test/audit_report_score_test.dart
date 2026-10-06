import 'package:five_s_audit/features/audits/data/audit_report_score.dart';
import 'package:five_s_audit/features/audits/data/models/assessment_models.dart';
import 'package:five_s_audit/features/five_s_config/data/models/five_s_config_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buildAuditReportScore matches PDF percentage and section totals', () {
    final questions = [
      _question(1, '1S - SORT', [0, 2, 4]),
      _question(2, '1S - SORT', [0, 5]),
      _question(3, '2S - SET', [0, 3]),
    ];
    final responses = [
      _response(1, '1S - SORT', 4),
      _response(2, '1S - SORT', 5),
      _response(3, '2S - SET', 0),
    ];

    final score = buildAuditReportScore(
      responses: responses,
      questions: questions,
      sectionOrder: const ['1S - SORT', '2S - SET'],
    );

    expect(score.total, 9);
    expect(score.max, 12);
    expect(score.percent, 75);
    expect(score.sections.map((s) => s.name), ['1S - SORT', '2S - SET']);
    expect(score.sections.first.score, 9);
    expect(score.sections.first.maxScore, 9);
    expect(formatReportNumber(202), '202');
    expect(formatReportNumber(1.5), '1.5');
  });
}

FlatAuditQuestion _question(int id, String category, List<num> scores) {
  return FlatAuditQuestion(
    id: id,
    category: category,
    text: 'Q$id',
    options: [
      for (final score in scores)
        FiveSAuditQuestionOption(score: score, description: '$score'),
    ],
  );
}

AssessmentResponse _response(int id, String category, num score) {
  return AssessmentResponse(
    questionId: id,
    category: category,
    score: score,
  );
}
