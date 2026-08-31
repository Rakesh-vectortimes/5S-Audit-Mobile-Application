// Working-day helpers for schedule audits (Sundays are non-working).

bool isSunday(DateTime date) => date.weekday == DateTime.sunday;

bool isWorkingDay(DateTime date) => !isSunday(date);

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

/// Same date, or next Monday if Sunday.
DateTime ensureWorkingDay(DateTime date) {
  var result = dateOnly(date);
  while (isSunday(result)) {
    result = result.add(const Duration(days: 1));
  }
  return result;
}

/// Advance by calendar days, then skip Sunday if landed on one.
DateTime addScheduleDays(DateTime from, int calendarDays) {
  final result = dateOnly(from).add(Duration(days: calendarDays < 0 ? 0 : calendarDays));
  return ensureWorkingDay(result);
}

/// Advance by N working days (Sundays do not count).
DateTime addWorkingDays(DateTime from, int workingDays) {
  if (workingDays <= 0) return ensureWorkingDay(from);

  var result = dateOnly(from);
  var remaining = workingDays;
  while (remaining > 0) {
    result = result.add(const Duration(days: 1));
    if (!isSunday(result)) {
      remaining -= 1;
    }
  }
  return result;
}

String formatDateYmd(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

DateTime? parseYmd(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
  if (match == null) return null;
  return DateTime(
    int.parse(match.group(1)!),
    int.parse(match.group(2)!),
    int.parse(match.group(3)!),
  );
}

enum ScheduleDuration { day, week, month }

extension ScheduleDurationX on ScheduleDuration {
  String get apiValue {
    switch (this) {
      case ScheduleDuration.day:
        return 'day';
      case ScheduleDuration.week:
        return 'week';
      case ScheduleDuration.month:
        return 'month';
    }
  }

  String get label {
    switch (this) {
      case ScheduleDuration.day:
        return 'Day';
      case ScheduleDuration.week:
        return 'Week';
      case ScheduleDuration.month:
        return 'Month';
    }
  }

  int get unitDays {
    switch (this) {
      case ScheduleDuration.day:
        return 1;
      case ScheduleDuration.week:
        return 7;
      case ScheduleDuration.month:
        return 30;
    }
  }

  bool get workingDays => this == ScheduleDuration.day;

  static ScheduleDuration fromApi(String? value) {
    switch ((value ?? '').toLowerCase().trim()) {
      case 'day':
        return ScheduleDuration.day;
      case 'month':
        return ScheduleDuration.month;
      default:
        return ScheduleDuration.week;
    }
  }
}

({int frequency, ScheduleDuration duration})? parseLegacyScheduleFrequency(Object? value) {
  if (value is! String) return null;
  final key = value.trim().toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
  const map = <String, (int, ScheduleDuration)>{
    '1_day': (1, ScheduleDuration.day),
    'day': (1, ScheduleDuration.day),
    'daily': (1, ScheduleDuration.day),
    '1_week': (1, ScheduleDuration.week),
    'week': (1, ScheduleDuration.week),
    'weekly': (1, ScheduleDuration.week),
    '1_month': (1, ScheduleDuration.month),
    'month': (1, ScheduleDuration.month),
    'monthly': (1, ScheduleDuration.month),
    '3_months': (3, ScheduleDuration.month),
    '3_month': (3, ScheduleDuration.month),
    'quarter': (3, ScheduleDuration.month),
    'quarterly': (3, ScheduleDuration.month),
  };
  final hit = map[key];
  if (hit == null) return null;
  return (frequency: hit.$1, duration: hit.$2);
}

({int frequency, ScheduleDuration duration}) normalizeFrequencyParts(
  Object? frequency,
  Object? duration,
) {
  final legacy = parseLegacyScheduleFrequency(frequency);
  if (legacy != null && (duration == null || duration.toString().trim().isEmpty)) {
    return legacy;
  }

  final unitRaw = (duration ?? 'week').toString().trim().toLowerCase();
  final unit = ScheduleDurationX.fromApi(unitRaw);

  int count = 1;
  if (frequency is num && frequency.isFinite) {
    count = frequency.floor().clamp(1, 365);
  } else if (frequency is String && RegExp(r'^\d+$').hasMatch(frequency.trim())) {
    count = (int.tryParse(frequency.trim()) ?? 1).clamp(1, 365);
  } else if (legacy != null) {
    return legacy;
  }

  return (frequency: count, duration: unit);
}

String formatScheduleFrequencyLabel(int? frequency, Object? duration) {
  final count = (frequency ?? 0) > 0 ? frequency! : 0;
  final unit = duration is ScheduleDuration
      ? duration.apiValue
      : duration?.toString().toLowerCase().trim() ?? '';
  if (count <= 0 || unit.isEmpty) return '—';
  final label = unit[0].toUpperCase() + unit.substring(1);
  return '$count $label${count == 1 ? '' : 's'}';
}

/// Client-only next preview (Sundays skipped per duration rules).
String? computeNextPreviewDate({
  required int frequency,
  required ScheduleDuration duration,
  DateTime? startDate,
  DateTime? endDate,
}) {
  final count = frequency.clamp(1, 365);
  final start = ensureWorkingDay(startDate ?? DateTime.now());
  final next = duration.workingDays
      ? addWorkingDays(start, count)
      : addScheduleDays(start, duration.unitDays * count);

  if (endDate != null) {
    final endDay = dateOnly(endDate);
    if (next.isAfter(endDay)) return null;
  }
  return formatDateYmd(next);
}
