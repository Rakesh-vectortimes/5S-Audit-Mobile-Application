import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../data/action_plan_repository.dart';
import '../data/models/action_plan_models.dart';

class ActionPlanAuditViewState extends Equatable {
  const ActionPlanAuditViewState({
    this.detail,
    this.loading = false,
    this.errorMessage,
  });

  final ActionPlanAuditDetail? detail;
  final bool loading;
  final String? errorMessage;

  ActionPlanAuditViewState copyWith({
    ActionPlanAuditDetail? detail,
    bool? loading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ActionPlanAuditViewState(
      detail: detail ?? this.detail,
      loading: loading ?? this.loading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [detail, loading, errorMessage];
}

class ActionPlanAuditViewController
    extends StateNotifier<ActionPlanAuditViewState> {
  ActionPlanAuditViewController(this._ref) : super(const ActionPlanAuditViewState());

  final Ref _ref;

  Future<void> load(String assessmentId) async {
    state = state.copyWith(loading: true, clearError: true);
    try {
      final detail =
          await _ref.read(actionPlanRepositoryProvider).getAuditById(assessmentId);
      state = state.copyWith(detail: detail, loading: false);
    } on ApiException catch (e) {
      state = state.copyWith(loading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(loading: false, errorMessage: 'Failed to load audit');
    }
  }
}

final actionPlanAuditViewControllerProvider = StateNotifierProvider.autoDispose
    .family<ActionPlanAuditViewController, ActionPlanAuditViewState, String>(
  (ref, assessmentId) {
    final controller = ActionPlanAuditViewController(ref);
    controller.load(assessmentId);
    return controller;
  },
);
