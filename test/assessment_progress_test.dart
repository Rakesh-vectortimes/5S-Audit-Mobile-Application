import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/features/audits/data/assessment_progress.dart';
import 'package:five_s_audit/features/audits/data/models/assessment_models.dart';

AssessmentResponse _response(int id, {num? score}) {
  return AssessmentResponse(questionId: id, category: 'Sort', score: score);
}

void main() {
  group('countAnsweredQuestions', () {
    test('counts only questions that have a score', () {
      final answered = countAnsweredQuestions(
        questionIds: const [1, 2, 3, 4, 5],
        responses: {
          1: _response(1, score: 2),
          2: _response(2),
          4: _response(4, score: 0),
        },
      );
      expect(answered, 2);
    });

    test('ignores extra responses that are not in the question list', () {
      final answered = countAnsweredQuestions(
        questionIds: const [1, 2],
        responses: {
          1: _response(1, score: 1),
          99: _response(99, score: 5),
        },
      );
      expect(answered, 1);
    });
  });

  group('questionProgressPercent', () {
    test('is 0 when there are no questions', () {
      expect(
        questionProgressPercent(totalQuestions: 0, answeredQuestions: 0),
        0,
      );
    });

    test('uses answered / total, not page index', () {
      expect(
        questionProgressPercent(totalQuestions: 10, answeredQuestions: 2),
        20,
      );
      expect(
        questionProgressPercent(totalQuestions: 10, answeredQuestions: 3),
        30,
      );
      expect(
        questionProgressPercent(totalQuestions: 10, answeredQuestions: 10),
        100,
      );
    });
  });
}
