import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../org/data/models/org_models.dart';
import '../data/action_plan_settings_repository.dart';
import '../data/action_plan_utils.dart';

class ActionPlanSettingsState extends Equatable {
  const ActionPlanSettingsState({
    this.company,
    this.auditType,
    this.high = defaultHighPriorityDueDays,
    this.medium = defaultMediumPriorityDueDays,
    this.low = defaultLowPriorityDueDays,
    this.loading = false,
    this.saving = false,
    this.errorMessage,
    this.successMessage,
  });

  final Company? company;
  final FiveSAuditType? auditType;
  final int high;
  final int medium;
  final int low;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final String? successMessage;

  ActionPlanSettingsState copyWith({
    Company? company,
    FiveSAuditType? auditType,
    int? high,
    int? medium,
    int? low,
    bool? loading,
    bool? saving,
    String? errorMessage,
    String? successMessage,
    bool clearCompany = false,
    bool clearAuditType = false,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return ActionPlanSettingsState(
      company: clearCompany ? null : (company ?? this.company),
      auditType: clearAuditType ? null : (auditType ?? this.auditType),
      high: high ?? this.high,
      medium: medium ?? this.medium,
      low: low ?? this.low,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }

  @override
  List<Object?> get props =>
      [company, auditType, high, medium, low, loading, saving, errorMessage, successMessage];
}

class ActionPlanSettingsController extends StateNotifier<ActionPlanSettingsState> {
  ActionPlanSettingsController(this._ref) : super(const ActionPlanSettingsState());

  final Ref _ref;

  ActionPlanSettingsRepository get _repo =>
      _ref.read(actionPlanSettingsRepositoryProvider);

  void selectCompany(Company? company) {
    state = state.copyWith(
      company: company,
      clearCompany: company == null,
      clearAuditType: true,
      clearError: true,
      clearSuccess: true,
    );
  }

  void selectAuditType(FiveSAuditType? type) {
    state = state.copyWith(
      auditType: type,
      clearAuditType: type == null,
      clearError: true,
      clearSuccess: true,
    );
    if (type != null && state.company != null) {
      load();
    }
  }

  void setHigh(int value) => state = state.copyWith(high: value.clamp(0, 365));
  void setMedium(int value) => state = state.copyWith(medium: value.clamp(0, 365));
  void setLow(int value) => state = state.copyWith(low: value.clamp(0, 365));

  Future<void> load() async {
    final company = state.company;
    final type = state.auditType;
    if (company == null || type == null) return;

    state = state.copyWith(loading: true, clearError: true, clearSuccess: true);
    try {
      final settings = await _repo.get(
        companyId: company.id,
        auditTypeId: type.id,
      );
      state = state.copyWith(
        high: settings.highPriorityDueDays,
        medium: settings.mediumPriorityDueDays,
        low: settings.lowPriorityDueDays,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, errorMessage: 'Failed to load settings');
    }
  }

  Future<bool> save() async {
    final company = state.company;
    final type = state.auditType;
    if (company == null || type == null) {
      state = state.copyWith(errorMessage: 'Select company and audit type');
      return false;
    }
    state = state.copyWith(saving: true, clearError: true, clearSuccess: true);
    try {
      final settings = await _repo.update(
        companyId: company.id,
        auditTypeId: type.id,
        highPriorityDueDays: state.high,
        mediumPriorityDueDays: state.medium,
        lowPriorityDueDays: state.low,
      );
      state = state.copyWith(
        high: settings.highPriorityDueDays,
        medium: settings.mediumPriorityDueDays,
        low: settings.lowPriorityDueDays,
        saving: false,
        successMessage: 'Settings saved',
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(saving: false, errorMessage: 'Failed to save settings');
      return false;
    }
  }
}

final actionPlanSettingsControllerProvider =
    StateNotifierProvider.autoDispose<ActionPlanSettingsController, ActionPlanSettingsState>(
  (ref) => ActionPlanSettingsController(ref),
);
