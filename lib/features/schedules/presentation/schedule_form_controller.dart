import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/permissions/record_permissions.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../org/data/models/org_models.dart';
import '../data/models/schedule_models.dart';
import '../data/schedule_repository.dart';
import '../data/schedule_utils.dart';

class ScheduleFormState extends Equatable {
  const ScheduleFormState({
    this.recordId,
    this.title = '',
    this.company,
    this.branch,
    this.floor,
    this.location,
    this.auditType,
    this.assignees = const [],
    this.frequency = 1,
    this.duration = ScheduleDuration.week,
    this.startDate,
    this.endDate,
    this.status = ScheduleStatus.active,
    this.loading = false,
    this.saving = false,
    this.errorMessage,
    this.initialized = false,
    this.permissionDenied = false,
    this.suppressCascade = false,
    this.canRunNow = false,
  });

  final String? recordId;
  final String title;
  final Company? company;
  final Branch? branch;
  final Floor? floor;
  final Location? location;
  final FiveSAuditType? auditType;
  final List<AssigneeUser> assignees;
  final int frequency;
  final ScheduleDuration duration;
  final String? startDate;
  final String? endDate;
  final ScheduleStatus status;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final bool initialized;
  final bool permissionDenied;
  final bool suppressCascade;
  final bool canRunNow;

  bool get isEdit => recordId != null && recordId!.isNotEmpty;

  String? get nextPreview => computeNextPreviewDate(
        frequency: frequency,
        duration: duration,
        startDate: parseYmd(startDate),
        endDate: parseYmd(endDate),
      );

  ScheduleFormState copyWith({
    String? recordId,
    String? title,
    Company? company,
    Branch? branch,
    Floor? floor,
    Location? location,
    FiveSAuditType? auditType,
    List<AssigneeUser>? assignees,
    int? frequency,
    ScheduleDuration? duration,
    String? startDate,
    String? endDate,
    ScheduleStatus? status,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool? initialized,
    bool? permissionDenied,
    bool? suppressCascade,
    bool? canRunNow,
    bool clearCompany = false,
    bool clearBranch = false,
    bool clearFloor = false,
    bool clearLocation = false,
    bool clearAuditType = false,
    bool clearAssignees = false,
    bool clearStart = false,
    bool clearEnd = false,
    bool clearError = false,
  }) {
    return ScheduleFormState(
      recordId: recordId ?? this.recordId,
      title: title ?? this.title,
      company: clearCompany ? null : (company ?? this.company),
      branch: clearBranch ? null : (branch ?? this.branch),
      floor: clearFloor ? null : (floor ?? this.floor),
      location: clearLocation ? null : (location ?? this.location),
      auditType: clearAuditType ? null : (auditType ?? this.auditType),
      assignees: clearAssignees ? const [] : (assignees ?? this.assignees),
      frequency: frequency ?? this.frequency,
      duration: duration ?? this.duration,
      startDate: clearStart ? null : (startDate ?? this.startDate),
      endDate: clearEnd ? null : (endDate ?? this.endDate),
      status: status ?? this.status,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialized: initialized ?? this.initialized,
      permissionDenied: permissionDenied ?? this.permissionDenied,
      suppressCascade: suppressCascade ?? this.suppressCascade,
      canRunNow: canRunNow ?? this.canRunNow,
    );
  }

  @override
  List<Object?> get props => [
        recordId,
        title,
        company,
        branch,
        floor,
        location,
        auditType,
        assignees,
        frequency,
        duration,
        startDate,
        endDate,
        status,
        loading,
        saving,
        errorMessage,
        initialized,
        permissionDenied,
        suppressCascade,
        canRunNow,
      ];
}

class ScheduleFormController extends StateNotifier<ScheduleFormState> {
  ScheduleFormController(this._ref) : super(const ScheduleFormState());

  final Ref _ref;

  ScheduleAuditRepository get _repo => _ref.read(scheduleAuditRepositoryProvider);

  void resetForCreate() {
    state = const ScheduleFormState(initialized: true, frequency: 1);
  }

  Future<void> loadForEdit(String id) async {
    state = state.copyWith(loading: true, clearError: true, recordId: id, suppressCascade: true);
    try {
      final record = await _repo.getById(id);
      final user = _ref.read(authControllerProvider).user;
      final canManage = user?.canManageScheduleAudits == true;
      final canEdit = canManage &&
          RecordPermissions.canEditRecord(
            user: user,
            createdByRole: record.createdByRole,
            createdBy: record.createdBy,
          );
      if (!canEdit) {
        state = state.copyWith(
          loading: false,
          permissionDenied: true,
          errorMessage: 'You do not have permission to edit this schedule.',
          suppressCascade: false,
        );
        return;
      }

      state = ScheduleFormState(
        recordId: record.id,
        title: record.title,
        company: record.companyId.isEmpty
            ? null
            : Company(id: record.companyId, companyName: record.companyName ?? ''),
        branch: record.branchId.isEmpty
            ? null
            : Branch(
                id: record.branchId,
                companyId: record.companyId,
                branchName: record.branchName ?? '',
              ),
        floor: record.floorId.isEmpty
            ? null
            : Floor(
                id: record.floorId,
                companyId: record.companyId,
                branchId: record.branchId,
                floorName: record.floorName ?? '',
              ),
        location: record.locationId.isEmpty
            ? null
            : Location(
                id: record.locationId,
                companyId: record.companyId,
                branchId: record.branchId,
                floorId: record.floorId,
                locationName: record.locationName ?? '',
              ),
        auditType: record.auditTypeId.isEmpty
            ? null
            : FiveSAuditType(
                id: record.auditTypeId,
                companyId: record.companyId,
                auditName: record.auditTypeName ?? '',
              ),
        assignees: record.assigneeIds.isNotEmpty
            ? [
                for (var i = 0; i < record.assigneeIds.length; i++)
                  AssigneeUser(
                    id: record.assigneeIds[i],
                    name: i < record.assigneeNames.length
                        ? record.assigneeNames[i]
                        : (record.assigneeName ?? ''),
                    clientCompanyId: record.companyId,
                  ),
              ]
            : record.assigneeId.isEmpty
                ? const []
                : [
                    AssigneeUser(
                      id: record.assigneeId,
                      name: record.assigneeName ?? '',
                      clientCompanyId: record.companyId,
                    ),
                  ],
        frequency: record.frequency,
        duration: record.duration,
        startDate: record.startDate,
        endDate: record.endDate,
        status: record.status,
        loading: false,
        initialized: true,
        suppressCascade: false,
        canRunNow: record.canRunNow,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        errorMessage: e.message,
        suppressCascade: false,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Failed to load schedule',
        suppressCascade: false,
      );
    }
  }

  void setTitle(String title) => state = state.copyWith(title: title);

  void selectCompany(Company? company) {
    if (state.suppressCascade) {
      state = state.copyWith(company: company, clearCompany: company == null);
      return;
    }
    state = state.copyWith(
      company: company,
      clearCompany: company == null,
      clearBranch: true,
      clearFloor: true,
      clearLocation: true,
      clearAuditType: true,
      clearAssignees: true,
    );
  }

  void selectBranch(Branch? branch) {
    if (state.suppressCascade) {
      state = state.copyWith(branch: branch, clearBranch: branch == null);
      return;
    }
    state = state.copyWith(
      branch: branch,
      clearBranch: branch == null,
      clearFloor: true,
    );
  }

  void selectFloor(Floor? floor) {
    state = state.copyWith(
      floor: floor,
      clearFloor: floor == null,
    );
  }

  void selectLocation(Location? location) {
    final branchId = location?.branchId;
    final floorId = location?.floorId;
    state = state.copyWith(
      location: location,
      clearLocation: location == null,
      branch: branchId == null || branchId.isEmpty
          ? state.branch
          : Branch(
              id: branchId,
              companyId: location?.companyId ?? state.company?.id ?? '',
              branchName: state.branch?.id == branchId
                  ? (state.branch?.branchName ?? '')
                  : '',
            ),
      floor: floorId == null || floorId.isEmpty
          ? state.floor
          : Floor(
              id: floorId,
              companyId: location?.companyId ?? state.company?.id ?? '',
              branchId: branchId ?? state.branch?.id ?? '',
              floorName: state.floor?.id == floorId
                  ? (state.floor?.floorName ?? '')
                  : '',
            ),
    );
  }

  void selectAuditType(FiveSAuditType? type) {
    state = state.copyWith(auditType: type, clearAuditType: type == null);
  }

  void selectAssignees(List<AssigneeUser> assignees) {
    state = state.copyWith(assignees: assignees);
  }

  void setFrequency(int frequency) {
    state = state.copyWith(frequency: frequency.clamp(1, 365));
  }

  void setDuration(ScheduleDuration duration) {
    state = state.copyWith(duration: duration);
  }

  void setStartDate(String? date) {
    state = state.copyWith(startDate: date, clearStart: date == null);
  }

  void setEndDate(String? date) {
    state = state.copyWith(endDate: date, clearEnd: date == null);
  }

  void setStatus(ScheduleStatus status) {
    state = state.copyWith(status: status);
  }

  String? validate() {
    if (state.title.trim().length < 2) return 'Title must be at least 2 characters';
    if (state.title.trim().length > 300) return 'Title must be at most 300 characters';
    if (state.company == null) return 'Select a company';
    if (state.location == null) return 'Select a location';
    if (state.auditType == null) return 'Select an audit type';
    if (state.assignees.isEmpty) return 'Select at least one assigned auditor';
    if (state.frequency < 1 || state.frequency > 365) {
      return 'Frequency must be between 1 and 365';
    }
    return null;
  }

  Future<ScheduleAuditConfig?> save() async {
    final error = validate();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return null;
    }

    state = state.copyWith(saving: true, clearError: true);
    try {
      final payload = buildSchedulePayload(
        title: state.title,
        companyId: state.company!.id,
        branchId: state.branch?.id ?? state.location?.branchId,
        floorId: state.floor?.id ?? state.location?.floorId,
        locationId: state.location!.id,
        auditTypeId: state.auditType!.id,
        assigneeIds: state.assignees.map((a) => a.id).toList(),
        frequency: state.frequency,
        duration: state.duration,
        startDate: state.startDate,
        endDate: state.endDate,
        status: state.status,
      );

      final record = state.isEdit
          ? await _repo.update(state.recordId!, payload)
          : await _repo.create(payload);

      state = state.copyWith(saving: false, recordId: record.id);
      return record;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(saving: false, errorMessage: 'Failed to save schedule');
      return null;
    }
  }

  Future<String?> trigger() async {
    if (!state.isEdit) return null;
    if (!state.canRunNow) {
      state = state.copyWith(
        errorMessage: 'Only assigned auditors can run this schedule now.',
      );
      return null;
    }
    try {
      return await _repo.trigger(state.recordId!);
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
      return null;
    }
  }
}

final scheduleFormControllerProvider =
    StateNotifierProvider.autoDispose<ScheduleFormController, ScheduleFormState>((ref) {
  return ScheduleFormController(ref);
});
