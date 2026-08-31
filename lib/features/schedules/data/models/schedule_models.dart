import 'package:equatable/equatable.dart';

import '../../../../core/network/list_response.dart';
import '../schedule_utils.dart';

enum ScheduleStatus { active, inactive }

extension ScheduleStatusX on ScheduleStatus {
  String get apiValue => this == ScheduleStatus.inactive ? 'inactive' : 'active';

  String get label => this == ScheduleStatus.inactive ? 'Inactive' : 'Active';

  static ScheduleStatus fromApi(Object? value) {
    return value?.toString().toLowerCase().trim() == 'inactive'
        ? ScheduleStatus.inactive
        : ScheduleStatus.active;
  }
}

class ScheduleAuditConfig extends Equatable {
  const ScheduleAuditConfig({
    required this.id,
    required this.title,
    required this.companyId,
    this.companyName,
    required this.branchId,
    this.branchName,
    required this.floorId,
    this.floorName,
    required this.locationId,
    this.locationName,
    required this.auditTypeId,
    this.auditTypeName,
    this.frequency = 1,
    this.duration = ScheduleDuration.week,
    this.frequencyLabel,
    required this.assigneeId,
    this.assigneeName,
    this.assigneeIds = const [],
    this.assigneeNames = const [],
    this.startDate,
    this.endDate,
    this.nextAuditDate,
    this.status = ScheduleStatus.active,
    this.canRunNow = false,
    this.createdByRole,
    this.createdByName,
    this.createdBy,
    this.updatedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String companyId;
  final String? companyName;
  final String branchId;
  final String? branchName;
  final String floorId;
  final String? floorName;
  final String locationId;
  final String? locationName;
  final String auditTypeId;
  final String? auditTypeName;
  final int frequency;
  final ScheduleDuration duration;
  final String? frequencyLabel;
  final String assigneeId;
  final String? assigneeName;
  final List<String> assigneeIds;
  final List<String> assigneeNames;
  final String? startDate;
  final String? endDate;
  final String? nextAuditDate;
  final ScheduleStatus status;
  final bool canRunNow;
  final String? createdByRole;
  final String? createdByName;
  final dynamic createdBy;
  final String? updatedBy;
  final String? createdAt;
  final String? updatedAt;

  String get displayAssignees {
    if (assigneeNames.isNotEmpty) return assigneeNames.join(', ');
    return assigneeName?.trim() ?? '';
  }

  String get displayFrequency =>
      frequencyLabel?.trim().isNotEmpty == true
          ? frequencyLabel!.trim()
          : formatScheduleFrequencyLabel(frequency, duration);

  factory ScheduleAuditConfig.fromJson(Map<String, dynamic> json) {
    final locationId = normalizeEntityId(json['location_id']) ??
        (json['location_ids'] is List && (json['location_ids'] as List).isNotEmpty
            ? normalizeEntityId((json['location_ids'] as List).first)
            : null) ??
        '';

    final assigneeIds = _normalizeIds(
      json['assignee_ids'] ?? json['assigned_user_ids'],
    );
    final assigneeId = normalizeEntityId(json['assignee_id']) ??
        normalizeEntityId(json['assigned_user_id']) ??
        (assigneeIds.isNotEmpty ? assigneeIds.first : '') ??
        '';
    if (assigneeId.isNotEmpty && !assigneeIds.contains(assigneeId)) {
      assigneeIds.insert(0, assigneeId);
    }

    final assigneeNames = _normalizeNames(
      json['assignee_names'] ?? json['assigned_user_names'],
    );
    final assigneeName = (json['assignee_name'] as String?)?.trim() ??
        (json['assigned_user_name'] as String?)?.trim() ??
        (assigneeNames.isNotEmpty ? assigneeNames.join(', ') : null);

    final parts = normalizeFrequencyParts(
      json['frequency'],
      json['duration'] ?? json['frequency_unit'],
    );

    return ScheduleAuditConfig(
      id: ListResponse.extractId(json),
      title: (json['title'] as String?)?.trim() ?? '',
      companyId: normalizeEntityId(json['company_id']) ?? '',
      companyName: json['company_name'] as String?,
      branchId: normalizeEntityId(json['branch_id']) ?? '',
      branchName: json['branch_name'] as String?,
      floorId: normalizeEntityId(json['floor_id']) ?? '',
      floorName: json['floor_name'] as String?,
      locationId: locationId,
      locationName: json['location_name'] as String?,
      auditTypeId: normalizeEntityId(json['audit_type_id']) ?? '',
      auditTypeName: json['audit_type_name'] as String?,
      frequency: parts.frequency,
      duration: parts.duration,
      frequencyLabel: json['frequency_label'] as String?,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assigneeIds: assigneeIds,
      assigneeNames: assigneeNames.isNotEmpty
          ? assigneeNames
          : (assigneeName == null || assigneeName.isEmpty
              ? const []
              : assigneeName.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()),
      startDate: _dateOrNull(json['start_date']),
      endDate: _dateOrNull(json['end_date']),
      nextAuditDate: _dateOrNull(json['next_audit_date']),
      status: ScheduleStatusX.fromApi(json['status']),
      canRunNow: json['can_run_now'] == true,
      createdByRole: json['created_by_role'] as String? ??
          json['creator_role'] as String? ??
          (json['created_by'] is Map
              ? (json['created_by'] as Map)['role']?.toString()
              : null),
      createdByName: json['created_by_name'] as String?,
      createdBy: json['created_by'] ?? json['createdBy'],
      updatedBy: json['updated_by']?.toString() ?? json['updated_by_name'] as String?,
      createdAt: json['created_at']?.toString() ?? json['created_on']?.toString(),
      updatedAt: json['updated_at']?.toString() ?? json['updated_on']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, title, status, companyId, frequency, duration];
}

class PaginatedSchedules {
  const PaginatedSchedules({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  final List<ScheduleAuditConfig> items;
  final int total;
  final int page;
  final int limit;
  final int pages;
}

Map<String, dynamic> buildSchedulePayload({
  required String title,
  required String companyId,
  String? branchId,
  String? floorId,
  required String locationId,
  required String auditTypeId,
  required List<String> assigneeIds,
  required int frequency,
  required ScheduleDuration duration,
  String? startDate,
  String? endDate,
  ScheduleStatus status = ScheduleStatus.active,
}) {
  final ids = {
    for (final id in assigneeIds)
      if (id.trim().isNotEmpty) id.trim(),
  }.toList();
  final start = parseYmd(startDate);
  final branch = (branchId ?? '').trim();
  final floor = (floorId ?? '').trim();
  return {
    'title': title.trim(),
    'company_id': companyId,
    'branch_id': branch.isEmpty ? null : branch,
    'floor_id': floor.isEmpty ? null : floor,
    'location_id': locationId,
    'audit_type_id': auditTypeId,
    'assignee_ids': ids,
    if (ids.isNotEmpty) 'assignee_id': ids.first,
    'frequency': frequency.clamp(1, 365),
    'duration': duration.apiValue,
    'start_date': start != null ? formatDateYmd(ensureWorkingDay(start)) : null,
    'end_date': parseYmd(endDate) != null ? formatDateYmd(parseYmd(endDate)!) : null,
    'status': status.apiValue,
  };
}

List<String> _normalizeIds(Object? value) {
  if (value is! List) return [];
  final ids = <String>[];
  for (final item in value) {
    final id = normalizeEntityId(item);
    if (id != null && id.isNotEmpty && !ids.contains(id)) ids.add(id);
  }
  return ids;
}

List<String> _normalizeNames(Object? value) {
  if (value is! List) return const [];
  return value
      .map((e) => e?.toString().trim() ?? '')
      .where((e) => e.isNotEmpty)
      .toList();
}

String? _dateOrNull(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return s.split('T').first;
}
