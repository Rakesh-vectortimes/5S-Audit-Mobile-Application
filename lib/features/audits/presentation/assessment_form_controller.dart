import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/audit_status.dart';
import '../../../core/network/api_response.dart';
import '../../action_plans/data/action_plan_settings_repository.dart';
import '../../action_plans/data/action_plan_utils.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/presentation/five_s_audit_config_controller.dart';
import '../../org/data/models/org_models.dart';
import '../data/action_plan_helpers.dart';
import '../data/assessment_repository.dart';
import '../data/five_s_audit_mapper.dart';
import '../data/models/assessment_models.dart';

class AssessmentFormState extends Equatable {
  const AssessmentFormState({
    this.recordId,
    this.company,
    this.auditType,
    this.branch,
    this.floor,
    this.location,
    this.background = const CompanyBackground(),
    this.reportDate,
    this.title = '',
    this.responses = const {},
    this.summary = '',
    this.declarationSignature = '',
    this.sign = false,
    this.loading = false,
    this.saving = false,
    this.errorMessage,
    this.initialized = false,
    this.dueDaySettings = const ActionPlanDueDaySettings(),
  });

  final String? recordId;
  final Company? company;
  final FiveSAuditType? auditType;
  final Branch? branch;
  final Floor? floor;
  final Location? location;
  final CompanyBackground background;
  final String? reportDate;
  final String title;
  final Map<int, AssessmentResponse> responses;
  final String summary;
  final String declarationSignature;
  final bool sign;
  final bool loading;
  final bool saving;
  final String? errorMessage;
  final bool initialized;
  final ActionPlanDueDaySettings dueDaySettings;

  bool get isEdit => recordId != null && recordId!.isNotEmpty;

  AssessmentFormState copyWith({
    String? recordId,
    Company? company,
    FiveSAuditType? auditType,
    Branch? branch,
    Floor? floor,
    Location? location,
    CompanyBackground? background,
    String? reportDate,
    String? title,
    Map<int, AssessmentResponse>? responses,
    String? summary,
    String? declarationSignature,
    bool? sign,
    bool? loading,
    bool? saving,
    String? errorMessage,
    bool? initialized,
    ActionPlanDueDaySettings? dueDaySettings,
    bool clearCompany = false,
    bool clearAuditType = false,
    bool clearBranch = false,
    bool clearFloor = false,
    bool clearLocation = false,
    bool clearError = false,
  }) {
    return AssessmentFormState(
      recordId: recordId ?? this.recordId,
      company: clearCompany ? null : (company ?? this.company),
      auditType: clearAuditType ? null : (auditType ?? this.auditType),
      branch: clearBranch ? null : (branch ?? this.branch),
      floor: clearFloor ? null : (floor ?? this.floor),
      location: clearLocation ? null : (location ?? this.location),
      background: background ?? this.background,
      reportDate: reportDate ?? this.reportDate,
      title: title ?? this.title,
      responses: responses ?? this.responses,
      summary: summary ?? this.summary,
      declarationSignature: declarationSignature ?? this.declarationSignature,
      sign: sign ?? this.sign,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialized: initialized ?? this.initialized,
      dueDaySettings: dueDaySettings ?? this.dueDaySettings,
    );
  }

  @override
  List<Object?> get props => [
        recordId,
        company,
        auditType,
        branch,
        floor,
        location,
        background,
        reportDate,
        title,
        responses,
        summary,
        declarationSignature,
        sign,
        loading,
        saving,
        errorMessage,
        initialized,
        dueDaySettings.highPriorityDueDays,
        dueDaySettings.mediumPriorityDueDays,
        dueDaySettings.lowPriorityDueDays,
      ];
}

class AssessmentFormController extends StateNotifier<AssessmentFormState> {
  AssessmentFormController(this._ref) : super(AssessmentFormState(
        reportDate: FiveSAuditMapper.formatApiDate(null),
      ));

  final Ref _ref;

  FiveSAuditAssessmentRepository get _repo =>
      _ref.read(fiveSAuditAssessmentRepositoryProvider);

  void resetForCreate() {
    state = AssessmentFormState(
      reportDate: FiveSAuditMapper.formatApiDate(null),
      initialized: true,
    );
    _ref.read(fiveSAuditConfigControllerProvider.notifier).invalidate();
  }

  Future<void> loadForEdit(String id) async {
    state = state.copyWith(loading: true, clearError: true, recordId: id);
    try {
      final record = await _repo.getById(id);
      await _ref.read(fiveSAuditConfigControllerProvider.notifier).load(
            companyId: record.companyId ?? '',
            auditTypeId: record.auditTypeId ?? '',
            force: true,
          );

      final company = record.companyId == null
          ? null
          : Company(
              id: record.companyId!,
              companyName: record.companyName ?? '',
            );
      final auditType = record.auditTypeId == null
          ? null
          : FiveSAuditType(
              id: record.auditTypeId!,
              companyId: record.companyId ?? '',
              auditName: record.auditTypeName ?? '',
            );
      final location = record.companyBackground?.locationId == null
          ? null
          : Location(
              id: record.companyBackground!.locationId!,
              companyId: record.companyId ?? '',
              locationName: record.companyBackground?.location ?? '',
              branchId: null,
              floorId: null,
            );

      final responseMap = {
        for (final r in record.responses) r.questionId: r,
      };

      state = AssessmentFormState(
        recordId: record.id,
        company: company,
        auditType: auditType,
        location: location,
        background: record.companyBackground ?? const CompanyBackground(),
        reportDate: record.reportDate ?? FiveSAuditMapper.formatApiDate(null),
        title: record.title ?? '',
        responses: responseMap,
        summary: record.summary,
        declarationSignature: record.declarationSignature ?? '',
        sign: record.sign,
        loading: false,
        initialized: true,
      );
      await _loadDueDaySettings(
        companyId: record.companyId,
        auditTypeId: record.auditTypeId,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, errorMessage: 'Failed to load audit');
    }
  }

  Future<void> selectCompany(Company? company) async {
    state = state.copyWith(
      company: company,
      clearCompany: company == null,
      clearAuditType: true,
      clearBranch: true,
      clearFloor: true,
      clearLocation: true,
      background: CompanyBackground(
        companyId: company?.id,
        companyName: company?.companyName,
        companyIntroduction: '',
        totalWorkforce: company?.totalWorkforce,
        shiftOperation: company?.shiftOperation,
        workingHours: company?.workingHours,
        workingDays: company?.workingDays,
        currency: company?.currency,
        currencySymbol: company?.currencySymbol,
      ),
      responses: const {},
      title: _deriveTitle(company?.companyName, null),
      dueDaySettings: const ActionPlanDueDaySettings(),
    );
    _ref.read(fiveSAuditConfigControllerProvider.notifier).invalidate();
  }

  Future<void> selectAuditType(FiveSAuditType? type) async {
    state = state.copyWith(
      auditType: type,
      clearAuditType: type == null,
      responses: const {},
      title: _deriveTitle(state.company?.companyName, type?.auditName),
    );
    if (type != null && state.company != null) {
      await _ref.read(fiveSAuditConfigControllerProvider.notifier).load(
            companyId: state.company!.id,
            auditTypeId: type.id,
            force: true,
          );
      await _loadDueDaySettings(
        companyId: state.company!.id,
        auditTypeId: type.id,
      );
    } else {
      _ref.read(fiveSAuditConfigControllerProvider.notifier).invalidate();
      state = state.copyWith(dueDaySettings: const ActionPlanDueDaySettings());
    }
  }

  void selectBranch(Branch? branch) {
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
    state = state.copyWith(
      location: location,
      clearLocation: location == null,
      background: state.background.copyWith(
        location: location?.locationName,
        locationId: location?.id,
      ),
    );
  }

  void updateBackground(CompanyBackground background) {
    state = state.copyWith(background: background);
  }

  void setReportDate(String date) {
    state = state.copyWith(reportDate: date);
    _recalculateActionPlanDueDates();
  }

  void setTitle(String title) {
    state = state.copyWith(title: title);
  }

  void setSummary(String summary) {
    state = state.copyWith(summary: summary);
  }

  void setSignature(String dataUrl) {
    state = state.copyWith(
      declarationSignature: dataUrl,
      sign: dataUrl.trim().isNotEmpty,
    );
  }

  void clearSignature() {
    state = state.copyWith(declarationSignature: '', sign: false);
  }

  void answerQuestion({
    required FlatAuditQuestion question,
    required int optionIndex,
  }) {
    if (optionIndex < 0 || optionIndex >= question.options.length) return;
    final option = question.options[optionIndex];
    final existing = state.responses[question.id];
    final triggered = isActionPlanTriggered(
      question: question,
      score: option.score,
      optionIndex: optionIndex,
    );

    var actionPlan = existing?.actionPlan;
    if (triggered) {
      actionPlan ??= ActionPlanAnswer(
        notes: question.actionPlan?.defaultValue ?? '',
        assigneeIds: question.actionPlan?.defaultAssigneeIds ?? const [],
        assigneeNames: question.actionPlan?.defaultAssigneeNames ?? const [],
      );
      actionPlan = _withDueDate(actionPlan);
    } else {
      actionPlan = null;
    }

    final updated = Map<int, AssessmentResponse>.from(state.responses);
    updated[question.id] = AssessmentResponse(
      questionId: question.id,
      category: question.category,
      subCategory: question.subCategory,
      score: option.score,
      optionIndex: optionIndex,
      question: question.text,
      selectedResponse: option.description,
      comments: existing?.comments,
      actionPlan: actionPlan,
    );
    state = state.copyWith(responses: updated);
  }

  void setComments(int questionId, String comments) {
    final existing = state.responses[questionId];
    if (existing == null) return;
    final updated = Map<int, AssessmentResponse>.from(state.responses);
    updated[questionId] = existing.copyWith(comments: comments);
    state = state.copyWith(responses: updated);
  }

  void setActionPlan(int questionId, ActionPlanAnswer actionPlan) {
    final existing = state.responses[questionId];
    if (existing == null) return;
    final updated = Map<int, AssessmentResponse>.from(state.responses);
    updated[questionId] = existing.copyWith(actionPlan: _withDueDate(actionPlan));
    state = state.copyWith(responses: updated);
  }

  Future<void> _loadDueDaySettings({
    required String? companyId,
    required String? auditTypeId,
  }) async {
    if (companyId == null ||
        companyId.isEmpty ||
        auditTypeId == null ||
        auditTypeId.isEmpty) {
      return;
    }
    try {
      final settings = await _ref.read(actionPlanSettingsRepositoryProvider).get(
            companyId: companyId,
            auditTypeId: auditTypeId,
          );
      state = state.copyWith(dueDaySettings: settings);
      _recalculateActionPlanDueDates();
    } catch (_) {
      // Keep default 1 / 3 / 5 day offsets, matching the website.
    }
  }

  void _recalculateActionPlanDueDates() {
    if (state.responses.isEmpty) return;
    final updated = <int, AssessmentResponse>{};
    var changed = false;
    state.responses.forEach((id, response) {
      final plan = response.actionPlan;
      if (plan == null) {
        updated[id] = response;
        return;
      }
      final next = _withDueDate(plan);
      if (next.dueDate == plan.dueDate) {
        updated[id] = response;
        return;
      }
      changed = true;
      updated[id] = response.copyWith(actionPlan: next);
    });
    if (changed) {
      state = state.copyWith(responses: updated);
    }
  }

  ActionPlanAnswer _withDueDate(ActionPlanAnswer plan) {
    return plan.copyWith(
      dueDate: dueDateForPriority(plan.priority),
      completed: plan.isFilled,
    );
  }

  String dueDateForPriority(String? priority) {
    final parsed =
        ActionPlanPriorityX.fromApi(priority) ?? ActionPlanPriority.medium;
    final raw = state.reportDate;
    DateTime from;
    try {
      from = DateTime.parse(raw ?? '');
    } catch (_) {
      from = DateTime.now();
    }
    return defaultDueDateForPriority(
      parsed,
      settings: state.dueDaySettings,
      fromDate: DateTime(from.year, from.month, from.day),
    );
  }

  String? validateDraft() {
    if (state.company == null) return 'Select a company';
    if (state.auditType == null) return 'Select an audit type';
    if ((state.reportDate ?? '').isEmpty) return 'Select a report date';
    return null;
  }

  String? validateSubmit(List<FlatAuditQuestion> questions) {
    final draftError = validateDraft();
    if (draftError != null) return draftError;

    for (final q in questions.where((q) => q.isMandatory)) {
      final response = state.responses[q.id];
      if (response == null || !isAnsweredScore(response.score)) {
        return 'Answer all mandatory questions before submitting';
      }
      if (!isActionPlanComplete(
        question: q,
        score: response.score,
        optionIndex: response.optionIndex,
        actionPlan: response.actionPlan,
      )) {
        return 'Complete triggered action plans (notes + assignees)';
      }
    }

    if (state.declarationSignature.trim().isEmpty) {
      return 'Signature is required to submit';
    }
    return null;
  }

  Future<FiveSAuditRecord?> saveDraft() => _save(statusUi: AuditStatusMapper.draft);

  Future<FiveSAuditRecord?> submit() => _save(statusUi: AuditStatusMapper.submitted);

  Future<FiveSAuditRecord?> _save({required String statusUi}) async {
    final config = _ref.read(fiveSAuditConfigControllerProvider);
    final questions = config.flatQuestions;

    final error = statusUi == AuditStatusMapper.submitted
        ? validateSubmit(questions)
        : validateDraft();
    if (error != null) {
      state = state.copyWith(errorMessage: error);
      return null;
    }

    state = state.copyWith(saving: true, clearError: true);
    try {
      _recalculateActionPlanDueDates();
      final payload = FiveSAuditMapper.buildApiPayload(
        companyId: state.company?.id,
        auditTypeId: state.auditType?.id,
        companyName: state.company?.companyName ?? state.background.companyName ?? '',
        auditTypeName: state.auditType?.auditName,
        reportDate: state.reportDate ?? FiveSAuditMapper.formatApiDate(null),
        statusUi: statusUi,
        summary: state.summary,
        sign: state.sign,
        declarationSignature: state.declarationSignature,
        background: state.background,
        responses: state.responses.values.toList(),
        questions: questions,
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
      state = state.copyWith(saving: false, errorMessage: 'Failed to save audit');
      return null;
    }
  }

  String _deriveTitle(String? companyName, String? auditTypeName) {
    final name = (companyName ?? '').trim().isEmpty ? '5S Audit' : companyName!.trim();
    final type = (auditTypeName ?? '').trim();
    return type.isNotEmpty ? '$name - $type' : '$name 5S Audit';
  }
}

final assessmentFormControllerProvider =
    StateNotifierProvider.autoDispose<AssessmentFormController, AssessmentFormState>((ref) {
  return AssessmentFormController(ref);
});
