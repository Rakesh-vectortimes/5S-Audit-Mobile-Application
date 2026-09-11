import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/features/audits/data/action_plan_helpers.dart';
import 'package:five_s_audit/features/audits/data/models/assessment_models.dart';
import 'package:five_s_audit/features/five_s_config/data/models/five_s_config_models.dart';

void main() {
  group('FiveSAuditQuestionActionPlan.fromJson', () {
    test('reads default_value and infers enabled when flag is omitted', () {
      final plan = FiveSAuditQuestionActionPlan.fromJson({
        'default_value':
            'Penetration of 5S concept at Micro zone Leader / Member Level.',
        'trigger_option_indexes': [0, 1],
        'default_assignee_ids': ['u1'],
      });

      expect(plan.enabled, isTrue);
      expect(
        plan.defaultValue,
        'Penetration of 5S concept at Micro zone Leader / Member Level.',
      );
      expect(plan.triggerOptionIndexes, [0, 1]);
    });

    test('falls back to alternate default text keys', () {
      final plan = FiveSAuditQuestionActionPlan.fromJson({
        'enabled': true,
        'action_required': 'Carryout necessary Training Session',
      });
      expect(plan.defaultValue, 'Carryout necessary Training Session');
    });
  });

  group('buildActionPlanWithDefaults', () {
    const config = FiveSAuditQuestionActionPlan(
      enabled: true,
      defaultValue: 'Train members on Red Tag Procedure',
      defaultAssigneeIds: ['a1'],
      defaultAssigneeNames: ['Priya'],
    );

    test('creates new plan from defaults', () {
      final plan = buildActionPlanWithDefaults(config: config);
      expect(plan.notes, 'Train members on Red Tag Procedure');
      expect(plan.assigneeIds, ['a1']);
      expect(plan.assigneeNames, ['Priya']);
    });

    test('fills empty notes/assignees but keeps user edits', () {
      final filled = buildActionPlanWithDefaults(
        existing: const ActionPlanAnswer(notes: '', assigneeIds: []),
        config: config,
      );
      expect(filled.notes, 'Train members on Red Tag Procedure');
      expect(filled.assigneeIds, ['a1']);

      final kept = buildActionPlanWithDefaults(
        existing: const ActionPlanAnswer(
          notes: 'Custom notes',
          assigneeIds: ['x1'],
          assigneeNames: ['Ali'],
        ),
        config: config,
      );
      expect(kept.notes, 'Custom notes');
      expect(kept.assigneeIds, ['x1']);
      expect(kept.assigneeNames, ['Ali']);
    });
  });

  group('isActionPlanTriggered', () {
    final question = FlatAuditQuestion(
      id: 1,
      category: '5S',
      text: 'Training?',
      options: const [
        FiveSAuditQuestionOption(score: 0, description: 'No training done'),
        FiveSAuditQuestionOption(score: 10, description: 'Yes 100%'),
      ],
      actionPlan: const FiveSAuditQuestionActionPlan(
        enabled: true,
        triggerOptionIndexes: [0],
        defaultValue: 'Schedule training',
      ),
    );

    test('triggers on configured option index', () {
      expect(
        isActionPlanTriggered(question: question, score: 0, optionIndex: 0),
        isTrue,
      );
      expect(
        isActionPlanTriggered(question: question, score: 10, optionIndex: 1),
        isFalse,
      );
    });
  });
}
