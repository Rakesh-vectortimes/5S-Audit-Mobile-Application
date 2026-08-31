import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../org/data/models/org_models.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../data/action_plan_repository.dart';
import '../data/models/action_plan_models.dart';

class ActionPlanAuditsListState extends Equatable {
  const ActionPlanAuditsListState({
    this.items = const [],
    this.page = 1,
    this.limit = 25,
    this.total = 0,
    this.pages = 1,
    this.search = '',
    this.statusFilter = 'all',
    this.priorityFilter,
    this.company,
    this.branch,
    this.floor,
    this.location,
    this.auditType,
    this.dateFrom,
    this.dateTo,
    this.summary,
    this.loading = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  final List<ActionPlanAuditGroup> items;
  final int page;
  final int limit;
  final int total;
  final int pages;
  final String search;
  final String statusFilter;
  final String? priorityFilter;
  final Company? company;
  final Branch? branch;
  final Floor? floor;
  final Location? location;
  final FiveSAuditType? auditType;
  final String? dateFrom;
  final String? dateTo;
  final ActionPlanSummary? summary;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;

  bool get hasMore => page < pages;

  ActionPlanAuditsListState copyWith({
    List<ActionPlanAuditGroup>? items,
    int? page,
    int? limit,
    int? total,
    int? pages,
    String? search,
    String? statusFilter,
    String? priorityFilter,
    Company? company,
    Branch? branch,
    Floor? floor,
    Location? location,
    FiveSAuditType? auditType,
    String? dateFrom,
    String? dateTo,
    ActionPlanSummary? summary,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
    bool clearCompany = false,
    bool clearBranch = false,
    bool clearFloor = false,
    bool clearLocation = false,
    bool clearAuditType = false,
    bool clearPriority = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return ActionPlanAuditsListState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      priorityFilter: clearPriority ? null : (priorityFilter ?? this.priorityFilter),
      company: clearCompany ? null : (company ?? this.company),
      branch: clearBranch ? null : (branch ?? this.branch),
      floor: clearFloor ? null : (floor ?? this.floor),
      location: clearLocation ? null : (location ?? this.location),
      auditType: clearAuditType ? null : (auditType ?? this.auditType),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      summary: summary ?? this.summary,
      loading: loading ?? this.loading,
      loadingMore: loadingMore ?? this.loadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        items,
        page,
        total,
        search,
        statusFilter,
        priorityFilter,
        company,
        branch,
        floor,
        location,
        auditType,
        dateFrom,
        dateTo,
        summary,
        loading,
        loadingMore,
        errorMessage,
      ];
}

class ActionPlanAuditsListController
    extends StateNotifier<ActionPlanAuditsListState> {
  ActionPlanAuditsListController(this._ref) : super(const ActionPlanAuditsListState());

  final Ref _ref;

  ActionPlanRepository get _repo => _ref.read(actionPlanRepositoryProvider);

  Future<void> refresh() => _load(page: 1, replace: true);

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value);
    await _load(page: 1, replace: true);
  }

  Future<void> setStatusFilter(String value) async {
    state = state.copyWith(statusFilter: value);
    await _load(page: 1, replace: true);
  }

  Future<void> setPriorityFilter(String? value) async {
    state = state.copyWith(priorityFilter: value, clearPriority: value == null);
    await _load(page: 1, replace: true);
  }

  Future<void> setCompany(Company? company) async {
    state = state.copyWith(
      company: company,
      clearCompany: company == null,
      clearBranch: true,
      clearFloor: true,
      clearLocation: true,
      clearAuditType: true,
    );
    await _load(page: 1, replace: true);
  }

  Future<void> setBranch(Branch? branch) async {
    state = state.copyWith(
      branch: branch,
      clearBranch: branch == null,
      clearFloor: true,
      clearLocation: true,
    );
    await _load(page: 1, replace: true);
  }

  Future<void> setFloor(Floor? floor) async {
    state = state.copyWith(
      floor: floor,
      clearFloor: floor == null,
      clearLocation: true,
    );
    await _load(page: 1, replace: true);
  }

  Future<void> setLocation(Location? location) async {
    state = state.copyWith(
      location: location,
      clearLocation: location == null,
    );
    await _load(page: 1, replace: true);
  }

  Future<void> setAuditType(FiveSAuditType? type) async {
    state = state.copyWith(auditType: type, clearAuditType: type == null);
    await _load(page: 1, replace: true);
  }

  Future<void> setDateRange({String? from, String? to}) async {
    state = state.copyWith(
      dateFrom: from,
      dateTo: to,
      clearDateFrom: from == null,
      clearDateTo: to == null,
    );
    await _load(page: 1, replace: true);
  }

  Future<void> applyQueryFilters({
    String? companyId,
    String? companyName,
    String? auditTypeId,
    String? auditTypeName,
  }) async {
    state = state.copyWith(
      company: companyId == null || companyId.isEmpty
          ? null
          : Company(id: companyId, companyName: companyName ?? ''),
      clearCompany: companyId == null || companyId.isEmpty,
      auditType: auditTypeId == null || auditTypeId.isEmpty
          ? null
          : FiveSAuditType(
              id: auditTypeId,
              companyId: companyId ?? '',
              auditName: auditTypeName ?? '',
            ),
      clearAuditType: auditTypeId == null || auditTypeId.isEmpty,
    );
    await _load(page: 1, replace: true);
  }

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    await _load(page: state.page + 1, replace: false);
  }

  Future<void> _load({required int page, required bool replace}) async {
    final companyId = state.company?.id;
    final auditTypeId = state.auditType?.id;
    final locationId = state.location?.id;

    state = state.copyWith(loading: replace, loadingMore: !replace, clearError: true);
    try {
      final result = await _repo.listAudits(
        page: page,
        limit: state.limit,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        companyId: companyId,
        // Audit types are company-scoped, matching the website list.
        auditTypeId:
            companyId == null || companyId.isEmpty ? null : auditTypeId,
        locationId: locationId,
        status: state.statusFilter,
        priority: state.priorityFilter,
        dateFrom: state.dateFrom,
        dateTo: state.dateTo,
      );
      state = state.copyWith(
        items: replace ? result.items : [...state.items, ...result.items],
        page: result.page,
        total: result.total,
        pages: result.pages,
        limit: result.limit,
        summary: result.summary,
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
        errorMessage: 'Failed to load action plan audits',
      );
    }
  }
}

final actionPlanAuditsListControllerProvider =
    StateNotifierProvider<ActionPlanAuditsListController, ActionPlanAuditsListState>((ref) {
  return ActionPlanAuditsListController(ref);
});
