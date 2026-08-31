import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/core/network/image_url.dart';
import 'package:five_s_audit/features/action_plans/data/action_plan_utils.dart';
import 'package:five_s_audit/features/action_plans/data/models/action_plan_models.dart';
import 'package:five_s_audit/features/auth/data/models/user.dart';

void main() {
  group('toActionPlanWorkStatus', () {
    test('maps display statuses to work statuses', () {
      expect(toActionPlanWorkStatus('closed'), ActionPlanWorkStatus.closed);
      expect(toActionPlanWorkStatus('in_progress'), ActionPlanWorkStatus.inProgress);
      expect(toActionPlanWorkStatus('submitted'), ActionPlanWorkStatus.inProgress);
      expect(toActionPlanWorkStatus('open'), ActionPlanWorkStatus.open);
      expect(toActionPlanWorkStatus('overdue'), ActionPlanWorkStatus.open);
      expect(toActionPlanWorkStatus(null), ActionPlanWorkStatus.open);
    });
  });

  group('canUpdateActionPlan', () {
    const user = User(id: 'u1', name: 'Alex', email: 'a@b.c');

    test('prefers can_update true/false', () {
      expect(
        canUpdateActionPlan(user: user, canUpdate: true, assigneeIds: const []),
        isTrue,
      );
      expect(
        canUpdateActionPlan(
          user: user,
          canUpdate: false,
          assigneeIds: const ['u1'],
        ),
        isFalse,
      );
    });

    test('matches assignee ids when can_update absent', () {
      expect(
        canUpdateActionPlan(user: user, assigneeIds: const ['u1', 'u2']),
        isTrue,
      );
      expect(
        canUpdateActionPlan(user: user, assigneeId: 'u1'),
        isTrue,
      );
      expect(
        canUpdateActionPlan(user: user, assigneeIds: const ['u9']),
        isFalse,
      );
    });

    test('empty assignees → false', () {
      expect(canUpdateActionPlan(user: user, assigneeIds: const []), isFalse);
      expect(canUpdateActionPlan(user: null, assigneeIds: const ['u1']), isFalse);
    });
  });

  group('defaultDueDateForPriority', () {
    test('uses 1 / 3 / 5 day defaults', () {
      final from = DateTime(2026, 8, 4);
      expect(
        defaultDueDateForPriority(ActionPlanPriority.high, fromDate: from),
        '2026-08-05',
      );
      expect(
        defaultDueDateForPriority(ActionPlanPriority.medium, fromDate: from),
        '2026-08-07',
      );
      expect(
        defaultDueDateForPriority(ActionPlanPriority.low, fromDate: from),
        '2026-08-09',
      );
    });
  });

  group('settings normalize defaults', () {
    test('empty map → defaults', () {
      final settings = ActionPlanDueDaySettings.normalize(null);
      expect(settings.highPriorityDueDays, 1);
      expect(settings.mediumPriorityDueDays, 3);
      expect(settings.lowPriorityDueDays, 5);
    });

    test('reads provided days', () {
      final settings = ActionPlanDueDaySettings.normalize(const {
        'high_priority_due_days': 2,
        'medium_priority_due_days': 4,
        'low_priority_due_days': 7,
      });
      expect(settings.highPriorityDueDays, 2);
      expect(settings.mediumPriorityDueDays, 4);
      expect(settings.lowPriorityDueDays, 7);
    });

    test('reads nested priority_due_days from API', () {
      final settings = ActionPlanDueDaySettings.normalize(const {
        'priority_due_days': {'high': 1, 'medium': 3, 'low': 5},
      });
      expect(settings.highPriorityDueDays, 1);
      expect(settings.mediumPriorityDueDays, 3);
      expect(settings.lowPriorityDueDays, 5);
    });
  });

  group('ActionPlanSummary.extract', () {
    test('reads summary from list payload', () {
      final summary = ActionPlanSummary.extract({
        'items': <Map<String, dynamic>>[],
        'summary': {
          'open': 2,
          'submitted': 1,
          'overdue': 3,
          'closed': 4,
        },
      });
      expect(summary, isNotNull);
      expect(summary!.open, 2);
      expect(summary.submitted, 1);
      expect(summary.overdue, 3);
      expect(summary.closed, 4);
    });

    test('returns null when summary missing', () {
      expect(ActionPlanSummary.extract({'items': []}), isNull);
      expect(ActionPlanSummary.extract([]), isNull);
    });
  });

  group('image url helpers', () {
    test('buildImageUrlFromUploadurl normalizes public paths', () {
      expect(buildImageUrlFromUploadurl('public/a.png'), '/public/a.png');
      expect(buildImageUrlFromUploadurl('/public/a.png'), '/public/a.png');
      expect(buildImageUrlFromUploadurl('uploads/a.png'), '/public/uploads/a.png');
    });

    test('resolveMediaUrl prefers image_url and prefixes origin', () {
      final url = resolveMediaUrl(
        {'image_url': '/public/x.png'},
        apiOrigin: 'http://localhost:8000',
      );
      expect(url, 'http://localhost:8000/public/x.png');
    });

    test('validateProofImage rejects type and size', () {
      expect(
        validateProofImage(mimeType: 'application/pdf', sizeBytes: 10),
        isNotNull,
      );
      expect(
        validateProofImage(mimeType: 'image/png', sizeBytes: maxProofImageBytes + 1),
        isNotNull,
      );
      expect(
        validateProofImage(mimeType: 'image/jpeg', sizeBytes: 100),
        isNull,
      );
    });
  });
}
