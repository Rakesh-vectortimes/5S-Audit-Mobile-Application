import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/features/schedules/data/models/schedule_models.dart';
import 'package:five_s_audit/features/schedules/data/schedule_utils.dart';

void main() {
  group('parseLegacyScheduleFrequency', () {
    test('maps common legacy strings', () {
      expect(parseLegacyScheduleFrequency('daily'), (frequency: 1, duration: ScheduleDuration.day));
      expect(parseLegacyScheduleFrequency('1_day'), (frequency: 1, duration: ScheduleDuration.day));
      expect(parseLegacyScheduleFrequency('weekly'), (frequency: 1, duration: ScheduleDuration.week));
      expect(parseLegacyScheduleFrequency('1_week'), (frequency: 1, duration: ScheduleDuration.week));
      expect(parseLegacyScheduleFrequency('monthly'), (frequency: 1, duration: ScheduleDuration.month));
      expect(parseLegacyScheduleFrequency('1_month'), (frequency: 1, duration: ScheduleDuration.month));
      expect(parseLegacyScheduleFrequency('quarterly'), (frequency: 3, duration: ScheduleDuration.month));
      expect(parseLegacyScheduleFrequency('3_months'), (frequency: 3, duration: ScheduleDuration.month));
    });

    test('returns null for unknown / non-string', () {
      expect(parseLegacyScheduleFrequency('biweekly'), isNull);
      expect(parseLegacyScheduleFrequency(2), isNull);
    });
  });

  group('formatScheduleFrequencyLabel', () {
    test('formats singular and plural', () {
      expect(formatScheduleFrequencyLabel(1, ScheduleDuration.week), '1 Week');
      expect(formatScheduleFrequencyLabel(2, ScheduleDuration.day), '2 Days');
      expect(formatScheduleFrequencyLabel(3, ScheduleDuration.month), '3 Months');
      expect(formatScheduleFrequencyLabel(0, ScheduleDuration.week), '—');
    });
  });

  group('working day helpers', () {
    test('ensureWorkingDay moves Sunday to Monday', () {
      // 2026-08-02 is a Sunday
      final sunday = DateTime(2026, 8, 2);
      expect(sunday.weekday, DateTime.sunday);
      final next = ensureWorkingDay(sunday);
      expect(next, DateTime(2026, 8, 3));
      expect(next.weekday, DateTime.monday);
    });

    test('ensureWorkingDay leaves weekday unchanged', () {
      final monday = DateTime(2026, 8, 3);
      expect(ensureWorkingDay(monday), monday);
    });

    test('addWorkingDays skips Sundays', () {
      // Saturday + 1 working day => Monday (Sunday skipped)
      final saturday = DateTime(2026, 8, 1);
      expect(saturday.weekday, DateTime.saturday);
      expect(addWorkingDays(saturday, 1), DateTime(2026, 8, 3));
    });

    test('addScheduleDays then ensureWorkingDay on Sunday land', () {
      // Saturday + 1 calendar day = Sunday → Monday
      final saturday = DateTime(2026, 8, 1);
      expect(addScheduleDays(saturday, 1), DateTime(2026, 8, 3));
    });
  });

  group('computeNextPreviewDate', () {
    test('day duration uses working days', () {
      final preview = computeNextPreviewDate(
        frequency: 1,
        duration: ScheduleDuration.day,
        startDate: DateTime(2026, 8, 1), // Saturday
      );
      expect(preview, '2026-08-03');
    });

    test('week duration uses calendar days', () {
      final preview = computeNextPreviewDate(
        frequency: 1,
        duration: ScheduleDuration.week,
        startDate: DateTime(2026, 8, 3), // Monday
      );
      expect(preview, '2026-08-10');
    });

    test('returns null when next is beyond end_date', () {
      final preview = computeNextPreviewDate(
        frequency: 1,
        duration: ScheduleDuration.week,
        startDate: DateTime(2026, 8, 3),
        endDate: DateTime(2026, 8, 5),
      );
      expect(preview, isNull);
    });
  });

  group('buildSchedulePayload', () {
    test('emits flat fields, clamps frequency, ensures working start', () {
      final payload = buildSchedulePayload(
        title: '  Plant A weekly  ',
        companyId: 'c1',
        branchId: 'b1',
        floorId: 'f1',
        locationId: 'l1',
        auditTypeId: 't1',
        assigneeIds: const ['u1'],
        frequency: 0,
        duration: ScheduleDuration.week,
        startDate: '2026-08-02', // Sunday
        endDate: '2026-12-31',
        status: ScheduleStatus.active,
      );

      expect(payload['title'], 'Plant A weekly');
      expect(payload['company_id'], 'c1');
      expect(payload['branch_id'], 'b1');
      expect(payload['floor_id'], 'f1');
      expect(payload['location_id'], 'l1');
      expect(payload['audit_type_id'], 't1');
      expect(payload['assignee_id'], 'u1');
      expect(payload['assignee_ids'], ['u1']);
      expect(payload.containsKey('branch_id'), isTrue);
      expect(payload['duration'], 'week');
      expect(payload['start_date'], '2026-08-03');
      expect(payload['end_date'], '2026-12-31');
      expect(payload['status'], 'active');
      expect(payload.containsKey('assessment'), isFalse);
    });

    test('sends null branch_id and floor_id when omitted', () {
      final payload = buildSchedulePayload(
        title: 'Location only',
        companyId: 'c1',
        locationId: 'l1',
        auditTypeId: 't1',
        assigneeIds: const ['u1', 'u2'],
        frequency: 1,
        duration: ScheduleDuration.week,
      );

      expect(payload['assignee_ids'], ['u1', 'u2']);
      expect(payload['assignee_id'], 'u1');
      expect(payload['branch_id'], isNull);
      expect(payload['floor_id'], isNull);
    });
  });

  group('ScheduleAuditConfig.fromJson', () {
    test('accepts location_ids[0] and assigned_user_* aliases', () {
      final record = ScheduleAuditConfig.fromJson(const {
        'id': 's1',
        'title': 'Schedule',
        'company_id': 'c1',
        'branch_id': 'b1',
        'floor_id': 'f1',
        'location_ids': ['loc-9'],
        'audit_type_id': 't1',
        'assigned_user_id': 'u9',
        'assigned_user_name': 'Alex',
        'frequency': 'weekly',
        'status': 'inactive',
      });

      expect(record.locationId, 'loc-9');
      expect(record.assigneeId, 'u9');
      expect(record.assigneeIds, ['u9']);
      expect(record.assigneeName, 'Alex');
      expect(record.frequency, 1);
      expect(record.duration, ScheduleDuration.week);
      expect(record.status, ScheduleStatus.inactive);
      expect(record.canRunNow, isFalse);
    });

    test('parses assignee_ids and can_run_now', () {
      final record = ScheduleAuditConfig.fromJson(const {
        'id': 's2',
        'title': 'Multi',
        'company_id': 'c1',
        'location_id': 'l1',
        'audit_type_id': 't1',
        'assignee_ids': ['u1', 'u2'],
        'assignee_names': ['Ann', 'Bob'],
        'frequency': 1,
        'duration': 'week',
        'can_run_now': true,
      });
      expect(record.assigneeIds, ['u1', 'u2']);
      expect(record.displayAssignees, 'Ann, Bob');
      expect(record.canRunNow, isTrue);
    });
  });
}
