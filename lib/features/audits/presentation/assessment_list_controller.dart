import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/audit_status.dart';
import '../../../core/network/api_response.dart';
import '../data/assessment_repository.dart';
import '../data/models/assessment_models.dart';

class AssessmentListState extends Equatable {
  const AssessmentListState({
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.pages = 1,
    this.search = '',
    this.statusFilter = 'all',
    this.loading = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  final List<FiveSAuditRecord> items;
  final int page;
  final int limit;
  final int total;
  final int pages;
  final String search;
  final String statusFilter;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;

  bool get hasMore => page < pages;

  AssessmentListState copyWith({
    List<FiveSAuditRecord>? items,
    int? page,
    int? limit,
    int? total,
    int? pages,
    String? search,
    String? statusFilter,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AssessmentListState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props =>
      [items, page, total, search, statusFilter, loading, loadingMore, errorMessage];
}

class AssessmentListController extends StateNotifier<AssessmentListState> {
  AssessmentListController(this._ref) : super(const AssessmentListState());

  final Ref _ref;

  FiveSAuditAssessmentRepository get _repo =>
      _ref.read(fiveSAuditAssessmentRepositoryProvider);

  Future<void> refresh() => _load(page: 1, replace: true);

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value);
    await _load(page: 1, replace: true);
  }

  Future<void> setStatusFilter(String value) async {
    state = state.copyWith(statusFilter: value);
    await _load(page: 1, replace: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    await _load(page: state.page + 1, replace: false);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<void> _load({required int page, required bool replace}) async {
    state = state.copyWith(
      loading: replace,
      loadingMore: !replace,
      clearError: true,
    );
    try {
      final result = await _repo.getPage(
        page: page,
        limit: state.limit,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        statusApi: AuditStatusMapper.toApiFilter(state.statusFilter),
      );
      state = state.copyWith(
        items: replace ? result.items : [...state.items, ...result.items],
        page: result.page,
        total: result.total,
        pages: result.pages,
        limit: result.limit,
        loading: false,
        loadingMore: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        errorMessage: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        errorMessage: 'Failed to load audits',
      );
    }
  }
}

final assessmentListControllerProvider =
    StateNotifierProvider<AssessmentListController, AssessmentListState>((ref) {
  return AssessmentListController(ref);
});
