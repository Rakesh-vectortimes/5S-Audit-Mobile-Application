import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/image_url.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/action_plan_repository.dart';
import '../data/action_plan_utils.dart';
import '../data/models/action_plan_models.dart';

class ActionPlanDetailState extends Equatable {
  const ActionPlanDetailState({
    this.detail,
    this.workStatus = ActionPlanWorkStatus.open,
    this.response = '',
    this.proofImages = const [],
    this.loading = false,
    this.saving = false,
    this.uploading = false,
    this.updatingDueDate = false,
    this.errorMessage,
  });

  final ActionPlanDetail? detail;
  final ActionPlanWorkStatus workStatus;
  final String response;
  final List<ActionPlanProofImage> proofImages;
  final bool loading;
  final bool saving;
  final bool uploading;
  final bool updatingDueDate;
  final String? errorMessage;

  ActionPlanDetailState copyWith({
    ActionPlanDetail? detail,
    ActionPlanWorkStatus? workStatus,
    String? response,
    List<ActionPlanProofImage>? proofImages,
    bool? loading,
    bool? saving,
    bool? uploading,
    bool? updatingDueDate,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActionPlanDetailState(
      detail: detail ?? this.detail,
      workStatus: workStatus ?? this.workStatus,
      response: response ?? this.response,
      proofImages: proofImages ?? this.proofImages,
      loading: loading ?? this.loading,
      saving: saving ?? this.saving,
      uploading: uploading ?? this.uploading,
      updatingDueDate: updatingDueDate ?? this.updatingDueDate,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        detail,
        workStatus,
        response,
        proofImages,
        loading,
        saving,
        uploading,
        updatingDueDate,
        errorMessage,
      ];
}

class ActionPlanDetailController extends StateNotifier<ActionPlanDetailState> {
  ActionPlanDetailController(this._ref, this.planId)
      : super(const ActionPlanDetailState());

  final Ref _ref;
  final String planId;

  ActionPlanRepository get _repo => _ref.read(actionPlanRepositoryProvider);

  bool get canUpdate {
    final user = _ref.read(authControllerProvider).user;
    final d = state.detail;
    if (d == null || user == null) return false;
    return canUpdateActionPlan(
      user: user,
      canUpdate: d.canUpdate,
      assigneeId: d.assigneeId,
      assigneeIds: d.assigneeIds,
    );
  }

  Future<void> load() async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final detail = await _repo.getById(planId);
      state = state.copyWith(
        detail: detail,
        workStatus: toActionPlanWorkStatus(detail.status.apiValue),
        response: detail.response ?? '',
        proofImages: detail.proofImages,
        loading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        errorMessage: 'Failed to load action plan',
      );
    }
  }

  void setWorkStatus(ActionPlanWorkStatus status) {
    state = state.copyWith(workStatus: status);
  }

  void setResponse(String value) {
    state = state.copyWith(response: value);
  }

  void removeProofAt(int index) {
    if (index < 0 || index >= state.proofImages.length) return;
    final next = [...state.proofImages]..removeAt(index);
    state = state.copyWith(proofImages: next);
  }

  Future<String?> uploadProof({
    required String filePath,
    String? fileName,
    String? mimeType,
    required int sizeBytes,
  }) async {
    if (!canUpdate) return 'You cannot update this action plan.';
    final validation = validateProofImage(mimeType: mimeType, sizeBytes: sizeBytes);
    if (validation != null) return validation;

    state = state.copyWith(uploading: true, clearError: true);
    try {
      final image = await _repo.uploadProofImage(
        id: planId,
        filePath: filePath,
        fileName: fileName,
      );
      state = state.copyWith(
        proofImages: [...state.proofImages, image],
        uploading: false,
      );
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(uploading: false, errorMessage: e.message);
      return e.message;
    } catch (_) {
      state = state.copyWith(
        uploading: false,
        errorMessage: 'Failed to upload proof image',
      );
      return 'Failed to upload proof image';
    }
  }

  Future<bool> save() async {
    if (!canUpdate) {
      state = state.copyWith(errorMessage: 'You cannot update this action plan.');
      return false;
    }
    state = state.copyWith(saving: true, clearError: true);
    try {
      final payload = buildActionPlanUpdatePayload(
        status: state.workStatus,
        response: state.response,
        proofImages: state.proofImages,
      );
      final detail = await _repo.update(planId, payload);
      state = state.copyWith(
        detail: detail,
        workStatus: toActionPlanWorkStatus(detail.status.apiValue),
        response: detail.response ?? state.response,
        proofImages: detail.proofImages,
        saving: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(saving: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        saving: false,
        errorMessage: 'Failed to save action plan',
      );
      return false;
    }
  }

  Future<bool> updateDueDate({
    required String dueDate,
    required String reason,
  }) async {
    if (!canUpdate) {
      state = state.copyWith(errorMessage: 'You cannot update this action plan.');
      return false;
    }
    if (reason.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Due date reason is required');
      return false;
    }
    state = state.copyWith(updatingDueDate: true, clearError: true);
    try {
      final detail = await _repo.updateDueDate(
        id: planId,
        dueDate: dueDate,
        dueDateReason: reason.trim(),
      );
      state = state.copyWith(detail: detail, updatingDueDate: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(updatingDueDate: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        updatingDueDate: false,
        errorMessage: 'Failed to update due date',
      );
      return false;
    }
  }
}

final actionPlanDetailControllerProvider = StateNotifierProvider.autoDispose
    .family<ActionPlanDetailController, ActionPlanDetailState, String>(
  (ref, planId) {
    final controller = ActionPlanDetailController(ref, planId);
    controller.load();
    return controller;
  },
);
