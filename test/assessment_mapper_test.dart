import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/core/constants/audit_status.dart';
import 'package:five_s_audit/features/action_plans/data/models/action_plan_models.dart';
import 'package:five_s_audit/features/audits/data/five_s_audit_mapper.dart';
import 'package:five_s_audit/features/audits/data/models/assessment_models.dart';
import 'package:five_s_audit/features/five_s_config/data/models/five_s_config_models.dart';

void main() {
  group('AuditStatusMapper', () {
    test('mapStatusToApi / mapStatusToUi', () {
      expect(AuditStatusMapper.toApi('submitted'), 'published');
      expect(AuditStatusMapper.toApi('published'), 'published');
      expect(AuditStatusMapper.toApi('draft'), 'draft');
      expect(AuditStatusMapper.toUi('published'), 'submitted');
      expect(AuditStatusMapper.toApiFilter('submitted'), 'published');
      expect(AuditStatusMapper.toApiFilter('all'), isNull);
    });
  });

  group('FiveSAuditMapper', () {
    test('extracts responses from assessment.details.responses', () {
      final responses = FiveSAuditMapper.extractResponses({
        'assessment': {
          'details': {
            'responses': [
              {'question_id': 1, 'category': 'Sort', 'score': 5, 'option_index': 1},
            ],
          },
        },
      });
      expect(responses, hasLength(1));
      expect(responses.first.optionIndex, 1);
    });

    test('extracts responses from assessment.responses', () {
      final responses = FiveSAuditMapper.extractResponses({
        'assessment': {
          'responses': [
            {'question_id': 2, 'category': 'Set', 'score': 0, 'option_index': 0},
          ],
        },
      });
      expect(responses.single.questionId, 2);
    });

    test('build payload nests details and prefers option_index', () {
      const questions = [
        FlatAuditQuestion(
          id: 1,
          category: 'Sort',
          text: 'Q1',
          options: [
            FiveSAuditQuestionOption(score: 0, description: 'Poor'),
            FiveSAuditQuestionOption(score: 5, description: 'Good'),
            FiveSAuditQuestionOption(score: 5, description: 'Also 5'),
          ],
        ),
      ];
      final payload = FiveSAuditMapper.buildApiPayload(
        companyId: 'c1',
        auditTypeId: 't1',
        companyName: 'Acme',
        auditTypeName: 'Warehouse',
        reportDate: '2026-08-04',
        statusUi: 'submitted',
        summary: 'Looks good',
        sign: true,
        declarationSignature: 'data:image/png;base64,xx',
        background: const CompanyBackground(
          companyId: 'c1',
          companyName: 'Acme',
          location: 'Line 1',
          locationId: 'loc1',
        ),
        responses: const [
          AssessmentResponse(
            questionId: 1,
            category: 'Sort',
            score: 5,
            optionIndex: 2,
          ),
        ],
        questions: questions,
      );

      expect(payload['status'], 'published');
      expect(payload['title'], 'Acme - Warehouse');
      expect(payload['company_background']['details']['location_id'], 'loc1');
      final enriched = payload['assessment']['details']['responses'] as List;
      expect(enriched, hasLength(1));
      expect(enriched.first['option_index'], 2);
      expect(enriched.first['selected_response'], 'Also 5');
      expect(payload['review_and_sign']['details']['summary'], 'Looks good');
    });

    test('omits empty action plan due_date and keeps YYYY-MM-DD', () {
      expect(const ActionPlanAnswer(notes: 'Fix').toJson().containsKey('due_date'), isFalse);
      expect(
        const ActionPlanAnswer(notes: 'Fix', dueDate: '2026-08-14').toJson()['due_date'],
        '2026-08-14',
      );
    });

    test('marks filled action plans completed for API publish check', () {
      expect(
        const ActionPlanAnswer(notes: 'nhz', assigneeIds: ['u1']).toJson()['completed'],
        isTrue,
      );
      expect(const ActionPlanAnswer(notes: 'nhz').toJson()['completed'], isFalse);
    });

    test('includes proof_images metadata on action plan save payload', () {
      final plan = ActionPlanAnswer(
        notes: 'train',
        assigneeIds: const ['u1'],
        proofImages: [
          ActionPlanProofImage(
            fileName: 'photo.jpg',
            uploadUrl: 'public/c1/uploads/photo.jpg',
            fileType: 'image/jpeg',
            fileSize: 12345,
            imageUrl: '/public/c1/uploads/photo.jpg',
            capturedAt: '2026-09-11T10:00:00.000Z',
          ),
        ],
      );
      final json = plan.toJson();
      final images = json['proof_images'] as List;
      expect(images, hasLength(1));
      expect(images.first['file_name'], 'photo.jpg');
      expect(images.first['uploadurl'], 'public/c1/uploads/photo.jpg');
      expect(images.first['image_url'], '/public/c1/uploads/photo.jpg');
    });
  });
}
