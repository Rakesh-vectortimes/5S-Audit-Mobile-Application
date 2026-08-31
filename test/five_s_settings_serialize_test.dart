import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/core/network/image_url.dart';
import 'package:five_s_audit/features/five_s_config/data/models/five_s_config_models.dart';
import 'package:five_s_audit/features/five_s_config/data/settings_serialize.dart';
import 'package:five_s_audit/features/five_s_config/domain/section_hierarchy.dart';
import 'package:five_s_audit/features/settings/presentation/five_s_questions_settings_page.dart';

void main() {
  group('computeGradePercentage', () {
    test('scales against overall max', () {
      expect(
        computeGradePercentage(maxScore: 5, peerMaxScores: const [10, 8]),
        50,
      );
      expect(
        computeGradePercentage(maxScore: 10, peerMaxScores: const [5]),
        100,
      );
    });
  });

  group('serializeActionPlan / question document', () {
    test('strips disabled action_plan', () {
      const item = FiveSAuditQuestionItem(
        questionId: 1,
        question: 'Q1',
        actionPlan: FiveSAuditQuestionActionPlan(enabled: false),
        options: [
          FiveSAuditQuestionOption(score: 0, description: 'No'),
        ],
      );
      final json = serializeQuestionItem(item);
      expect(json.containsKey('action_plan'), isFalse);
      expect(json['question'], 'Q1');
    });

    test('includes enabled action_plan with assignees', () {
      const item = FiveSAuditQuestionItem(
        questionId: 2,
        question: 'Q2',
        actionPlan: FiveSAuditQuestionActionPlan(
          enabled: true,
          mandatory: true,
          defaultAssigneeIds: ['u1'],
          defaultAssigneeNames: ['Alex'],
          triggerOptionIndexes: [0],
          triggerScores: [0],
          defaultValue: 'Fix it',
        ),
        options: [
          FiveSAuditQuestionOption(score: 0, description: 'Bad'),
        ],
      );
      final json = serializeQuestionItem(item);
      expect(json['action_plan'], isA<Map>());
      final ap = json['action_plan'] as Map;
      expect(ap['enabled'], isTrue);
      expect(ap['default_assignee_ids'], ['u1']);
    });

    test('buildQuestionDocumentPayload nests fields', () {
      final payload = buildQuestionDocumentPayload(
        companyId: 'c1',
        auditTypeId: 't1',
        sectionId: 's1',
        questions: const [
          FiveSAuditQuestionItem(questionId: 1, question: 'Hello'),
        ],
      );
      expect(payload['company_id'], 'c1');
      expect(payload['fk_audit_type_id'], 't1');
      expect(payload['fk_section_id'], 's1');
      expect(payload['questions'], hasLength(1));
    });
  });

  group('section hierarchy for settings', () {
    test('question targets prefer children when present', () {
      const parent = FiveSAuditSection(id: 'p1', sectionName: 'Sort', sectionOrder: 1);
      const child = FiveSAuditSection(
        id: 'c1',
        sectionName: 'Tools',
        fkParentSectionId: 'p1',
        sectionOrder: 1,
      );
      const lonely = FiveSAuditSection(id: 'p2', sectionName: 'Shine', sectionOrder: 2);

      final targets = questionTargetSections(const [parent, child, lonely]);
      expect(targets.map((s) => s.id), ['c1', 'p2']);
    });

    test('getChildSections only under top-level parent', () {
      const parent = FiveSAuditSection(id: 'p1', sectionName: 'Sort');
      const child = FiveSAuditSection(
        id: 'c1',
        sectionName: 'Tools',
        fkParentSectionId: 'p1',
      );
      expect(getChildSections(const [parent, child], 'p1'), [child]);
      expect(parent.isTopLevel, isTrue);
      expect(child.isTopLevel, isFalse);
    });
  });

  group('image validation', () {
    test('rejects bad type and oversized files', () {
      expect(
        validateQuestionImage(mimeType: 'application/pdf', sizeBytes: 10),
        isNotNull,
      );
      expect(
        validateQuestionImage(
          mimeType: 'image/png',
          sizeBytes: maxProofImageBytes + 1,
        ),
        isNotNull,
      );
      expect(
        validateQuestionImage(mimeType: 'image/jpeg', sizeBytes: 100),
        isNull,
      );
    });
  });
}
