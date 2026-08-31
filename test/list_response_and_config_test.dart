import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/core/network/list_response.dart';
import 'package:five_s_audit/features/five_s_config/data/models/five_s_config_models.dart';
import 'package:five_s_audit/features/five_s_config/domain/section_hierarchy.dart';
import 'package:five_s_audit/features/org/data/models/org_models.dart';

void main() {
  group('ListResponse.extractItems', () {
    test('handles bare array', () {
      final items = ListResponse.extractItems(
        [
          {'_id': '1', 'company_name': 'Acme'},
          {'id': '2', 'company_name': 'Beta'},
        ],
        Company.fromJson,
      );
      expect(items.map((e) => e.id), ['1', '2']);
      expect(items.first.companyName, 'Acme');
    });

    test('handles {items: [...]}', () {
      final items = ListResponse.extractItems(
        {
          'items': [
            {'_id': 'b1', 'company_id': 'c1', 'branch_name': 'HQ'},
          ],
          'total': 1,
          'page': 1,
        },
        Branch.fromJson,
      );
      expect(items, hasLength(1));
      expect(items.first.id, 'b1');
      expect(items.first.companyId, 'c1');
    });

    test('handles nested data key', () {
      final items = ListResponse.extractItems(
        {
          'data': [
            {'id': 'f1', 'company_id': 'c1', 'branch_id': 'b1', 'floor_name': 'L1'},
          ],
        },
        Floor.fromJson,
      );
      expect(items.single.floorName, 'L1');
    });
  });

  group('ListResponse.extractId', () {
    test('prefers id then _id', () {
      expect(ListResponse.extractId({'id': 'a', '_id': 'b'}), 'a');
      expect(ListResponse.extractId({'_id': 'b'}), 'b');
      expect(
        ListResponse.extractId({'company_id': 'c1'}, preferredKeys: const ['company_id']),
        'c1',
      );
    });
  });

  group('ListResponse.flattenAssigneeGroups', () {
    test('flattens grouped employees', () {
      final flat = ListResponse.flattenAssigneeGroups([
        {
          'client_company_id': 'cc1',
          'client_company_name': 'Client',
          'employees': [
            {'_id': 'e1', 'name': 'Ann', 'email': 'a@x.com'},
            {'id': 'e2', 'name': 'Bob'},
          ],
        },
      ]);
      expect(flat, hasLength(2));
      final users = flat.map(AssigneeUser.fromJson).toList();
      expect(users.first.clientCompanyId, 'cc1');
      expect(users.map((e) => e.name), ['Ann', 'Bob']);
    });
  });

  group('assessment steps', () {
    test('creates child steps when subsections exist', () {
      const parent = FiveSAuditSection(
        id: 'p1',
        sectionName: 'Sort',
        sectionOrder: 1,
      );
      const child = FiveSAuditSection(
        id: 'c1',
        sectionName: 'Tools',
        fkParentSectionId: 'p1',
        sectionOrder: 1,
        sectionDisplayLabel: 'Sort > Tools',
      );
      final steps = buildAssessmentSteps(
        sections: const [parent, child],
        flatQuestions: const [],
      );
      expect(steps, hasLength(1));
      expect(steps.first.category, 'Sort');
      expect(steps.first.subCategory, 'Tools');
      expect(steps.first.label, 'Sort > Tools');
    });

    test('falls back to question categories when sections are missing', () {
      const questions = [
        FlatAuditQuestion(id: 1, category: 'Sort', text: 'Q1'),
        FlatAuditQuestion(
          id: 2,
          category: 'Sort',
          subCategory: 'Tools',
          text: 'Q2',
        ),
        FlatAuditQuestion(id: 3, category: 'Shine', text: 'Q3'),
      ];
      final steps = buildAssessmentSteps(
        sections: const [],
        flatQuestions: questions,
      );
      expect(steps.map((s) => s.key), ['Sort', 'Sort::Tools', 'Shine']);
    });

    test('parses question documents when questions are nested or unwrapped', () {
      final nested = FiveSAuditQuestionDocument.fromJson({
        '_id': 'doc1',
        'fk_section_id': 's1',
        'questions': [
          {'question_id': 1, 'question': 'Are tools labeled?'},
          {'question_id': '2', 'question_text': 'Is the aisle clear?'},
        ],
      });
      expect(nested.questions.map((q) => q.questionId), [1, 2]);

      final unwrapped = FiveSAuditQuestionDocument.fromJson({
        'id': 'doc2',
        'fk_section_id': 's1',
        'question_id': 9,
        'question': 'Standalone question',
      });
      expect(unwrapped.questions, hasLength(1));
      expect(unwrapped.questions.single.questionId, 9);
    });

    test('maps flat questions from section hierarchy', () {
      const parent = FiveSAuditSection(id: 'p1', sectionName: 'Sort', sectionOrder: 1);
      const child = FiveSAuditSection(
        id: 'c1',
        sectionName: 'Tools',
        fkParentSectionId: 'p1',
        sectionOrder: 1,
      );
      const doc = FiveSAuditQuestionDocument(
        id: 'qdoc1',
        fkSectionId: 'c1',
        questions: [
          FiveSAuditQuestionItem(
            questionId: 10,
            question: 'Are tools labeled?',
            options: [
              FiveSAuditQuestionOption(score: 0, description: 'No'),
              FiveSAuditQuestionOption(score: 5, description: 'Yes'),
            ],
          ),
        ],
      );
      final flat = mapFlatQuestions(sections: const [parent, child], documents: const [doc]);
      expect(flat, hasLength(1));
      expect(flat.first.category, 'Sort');
      expect(flat.first.subCategory, 'Tools');
      expect(flat.first.id, 10);
    });
  });
}
