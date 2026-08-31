import '../../../core/network/list_response.dart';
import '../../auth/data/models/user.dart';

enum ActionPlanStatus { open, submitted, closed, overdue, inProgress }

enum ActionPlanWorkStatus { open, inProgress, closed }

enum ActionPlanPriority { low, medium, high }

extension ActionPlanStatusX on ActionPlanStatus {
  String get apiValue {
    switch (this) {
      case ActionPlanStatus.open:
        return 'open';
      case ActionPlanStatus.submitted:
        return 'submitted';
      case ActionPlanStatus.closed:
        return 'closed';
      case ActionPlanStatus.overdue:
        return 'overdue';
      case ActionPlanStatus.inProgress:
        return 'in_progress';
    }
  }

  String get label {
    switch (this) {
      case ActionPlanStatus.open:
        return 'Open';
      case ActionPlanStatus.submitted:
        return 'Submitted';
      case ActionPlanStatus.closed:
        return 'Closed';
      case ActionPlanStatus.overdue:
        return 'Overdue';
      case ActionPlanStatus.inProgress:
        return 'In Progress';
    }
  }

  static ActionPlanStatus fromApi(Object? value) {
    switch ((value ?? 'open').toString().trim().toLowerCase().replaceAll(' ', '_')) {
      case 'submitted':
        return ActionPlanStatus.submitted;
      case 'closed':
        return ActionPlanStatus.closed;
      case 'overdue':
        return ActionPlanStatus.overdue;
      case 'in_progress':
        return ActionPlanStatus.inProgress;
      default:
        return ActionPlanStatus.open;
    }
  }
}

extension ActionPlanWorkStatusX on ActionPlanWorkStatus {
  String get apiValue {
    switch (this) {
      case ActionPlanWorkStatus.open:
        return 'open';
      case ActionPlanWorkStatus.inProgress:
        return 'in_progress';
      case ActionPlanWorkStatus.closed:
        return 'closed';
    }
  }

  String get label {
    switch (this) {
      case ActionPlanWorkStatus.open:
        return 'Open';
      case ActionPlanWorkStatus.inProgress:
        return 'In Progress';
      case ActionPlanWorkStatus.closed:
        return 'Closed';
    }
  }
}

extension ActionPlanPriorityX on ActionPlanPriority {
  String get apiValue {
    switch (this) {
      case ActionPlanPriority.low:
        return 'low';
      case ActionPlanPriority.medium:
        return 'medium';
      case ActionPlanPriority.high:
        return 'high';
    }
  }

  String get label {
    switch (this) {
      case ActionPlanPriority.low:
        return 'Low';
      case ActionPlanPriority.medium:
        return 'Medium';
      case ActionPlanPriority.high:
        return 'High';
    }
  }

  static ActionPlanPriority? fromApi(Object? value) {
    switch ((value ?? '').toString().trim().toLowerCase()) {
      case 'low':
        return ActionPlanPriority.low;
      case 'medium':
        return ActionPlanPriority.medium;
      case 'high':
        return ActionPlanPriority.high;
      default:
        return null;
    }
  }
}

const defaultHighPriorityDueDays = 1;
const defaultMediumPriorityDueDays = 3;
const defaultLowPriorityDueDays = 5;

class ActionPlanDueDaySettings {
  const ActionPlanDueDaySettings({
    this.highPriorityDueDays = defaultHighPriorityDueDays,
    this.mediumPriorityDueDays = defaultMediumPriorityDueDays,
    this.lowPriorityDueDays = defaultLowPriorityDueDays,
  });

  final int highPriorityDueDays;
  final int mediumPriorityDueDays;
  final int lowPriorityDueDays;

  factory ActionPlanDueDaySettings.normalize(Map<String, dynamic>? raw) {
    if (raw == null || raw.isEmpty) {
      return const ActionPlanDueDaySettings();
    }
    final nested = raw['priority_due_days'];
    final days = nested is Map ? Map<String, dynamic>.from(nested) : raw;
    return ActionPlanDueDaySettings(
      highPriorityDueDays: _asPositiveInt(
        days['high'] ?? raw['high_priority_due_days'],
        defaultHighPriorityDueDays,
      ),
      mediumPriorityDueDays: _asPositiveInt(
        days['medium'] ?? raw['medium_priority_due_days'],
        defaultMediumPriorityDueDays,
      ),
      lowPriorityDueDays: _asPositiveInt(
        days['low'] ?? raw['low_priority_due_days'],
        defaultLowPriorityDueDays,
      ),
    );
  }
}

ActionPlanWorkStatus toActionPlanWorkStatus(Object? status) {
  final normalized = (status ?? 'open')
      .toString()
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '_');
  if (normalized == 'closed') return ActionPlanWorkStatus.closed;
  if (normalized == 'in_progress' || normalized == 'submitted') {
    return ActionPlanWorkStatus.inProgress;
  }
  return ActionPlanWorkStatus.open;
}

List<String> normalizeAssigneeIds(Object? ids, [Object? fallbackId]) {
  final fromArray = <String>[];
  if (ids is List) {
    for (final id in ids) {
      final value = normalizeEntityId(id);
      if (value != null && value.isNotEmpty) fromArray.add(value);
    }
  }
  if (fromArray.isNotEmpty) return {...fromArray}.toList();
  final single = normalizeEntityId(fallbackId);
  return single == null || single.isEmpty ? const [] : [single];
}

List<String> normalizeAssigneeNames(Object? names, [Object? fallbackName]) {
  if (names is List) {
    return names
        .map((n) => n?.toString().trim() ?? '')
        .where((n) => n.isNotEmpty)
        .toList();
  }
  final single = (fallbackName ?? '').toString().trim();
  if (single.isEmpty) return const [];
  return single.split(',').map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
}

/// Prefer API `can_update`; else match current user against assignee ids.
bool canUpdateActionPlan({
  required User? user,
  bool? canUpdate,
  Object? assigneeId,
  Object? assigneeIds,
}) {
  if (user == null) return false;
  if (canUpdate == true) return true;
  if (canUpdate == false) return false;

  final ids = normalizeAssigneeIds(assigneeIds, assigneeId);
  if (ids.isEmpty) return false;

  final candidates = <String>{
    if (user.id.isNotEmpty) user.id,
  };
  return candidates.any(ids.contains);
}

String defaultDueDateForPriority(
  ActionPlanPriority priority, {
  ActionPlanDueDaySettings settings = const ActionPlanDueDaySettings(),
  DateTime? fromDate,
}) {
  final days = switch (priority) {
    ActionPlanPriority.high => settings.highPriorityDueDays,
    ActionPlanPriority.low => settings.lowPriorityDueDays,
    ActionPlanPriority.medium => settings.mediumPriorityDueDays,
  };
  final due = (fromDate ?? DateTime.now()).add(Duration(days: days < 0 ? 0 : days));
  final y = due.year.toString().padLeft(4, '0');
  final m = due.month.toString().padLeft(2, '0');
  final d = due.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

int _asPositiveInt(Object? value, int fallback) {
  if (value is int) return value < 0 ? fallback : value;
  if (value is num) {
    final n = value.toInt();
    return n < 0 ? fallback : n;
  }
  return int.tryParse('$value') ?? fallback;
}
