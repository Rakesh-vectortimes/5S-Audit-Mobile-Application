import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../org/data/models/org_models.dart';
import '../data/models/schedule_models.dart';
import '../data/schedule_repository.dart';

class ScheduleListState extends Equatable {
  const ScheduleListState({
    this.items = const [],
    this.page = 1,
    this.limit = 10,
    this.total = 0,
    this.pages = 1,
    this.search = '',
    this.statusFilter = 'all',
    this.company,
    this.branch,
    this.floor,
    this.location,
    this.loading = false,
    this.loadingMore = false,
    this.errorMessage,
  });

  final List<ScheduleAuditConfig> items;
  final int page;
  final int limit;
  final int total;
  final int pages;
  final String search;
  final String statusFilter;
  final Company? company;
  final Branch? branch;
  final Floor? floor;
  final Location? location;
  final bool loading;
  final bool loadingMore;
  final String? errorMessage;

  bool get hasMore => page < pages;

  ScheduleListState copyWith({
    List<ScheduleAuditConfig>? items,
    int? page,
    int? limit,
    int? total,
    int? pages,
    String? search,
    String? statusFilter,
    Company? company,
    Branch? branch,
    Floor? floor,
    Location? location,
    bool? loading,
    bool? loadingMore,
    String? errorMessage,
    bool clearError = false,
    bool clearCompany = false,
    bool clearBranch = false,
    bool clearFloor = false,
    bool clearLocation = false,
  }) {
    return ScheduleListState(
      items: items ?? this.items,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      pages: pages ?? this.pages,
      search: search ?? this.search,
      statusFilter: statusFilter ?? this.statusFilter,
      company: clearCompany ? null : (company ?? this.company),
      branch: clearBranch ? null : (branch ?? this.branch),
      floor: clearFloor ? null : (floor ?? this.floor),
      location: clearLocation ? null : (location ?? this.location),
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
        company,
        branch,
        floor,
        location,
        loading,
        loadingMore,
        errorMessage,
      ];
}

class ScheduleListController extends StateNotifier<ScheduleListState> {
  ScheduleListController(this._ref) : super(const ScheduleListState());

  final Ref _ref;

  ScheduleAuditRepository get _repo => _ref.read(scheduleAuditRepositoryProvider);

  Future<void> refresh() => _load(page: 1, replace: true);

  Future<void> setSearch(String value) async {
    state = state.copyWith(search: value);
    await _load(page: 1, replace: true);
  }

  Future<void> setStatusFilter(String value) async {
    state = state.copyWith(statusFilter: value);
    await _load(page: 1, replace: true);
  }

  Future<void> setCompany(Company? company) async {
    state = state.copyWith(
      company: company,
      clearCompany: company == null,
      clearBranch: true,
      clearFloor: true,
      clearLocation: true,
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

  Future<void> loadMore() async {
    if (!state.hasMore || state.loadingMore || state.loading) return;
    await _load(page: state.page + 1, replace: false);
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    await refresh();
  }

  Future<String> trigger(String id) async {
    final message = await _repo.trigger(id);
    await refresh();
    return message;
  }

  Future<void> _load({required int page, required bool replace}) async {
    state = state.copyWith(loading: replace, loadingMore: !replace, clearError: true);
    try {
      final result = await _repo.getPage(
        page: page,
        limit: state.limit,
        search: state.search.trim().isEmpty ? null : state.search.trim(),
        companyId: state.company?.id,
        branchId: state.branch?.id,
        floorId: state.floor?.id,
        locationId: state.location?.id,
        status: state.statusFilter,
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
      state = state.copyWith(loading: false, loadingMore: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(
        loading: false,
        loadingMore: false,
        errorMessage: 'Failed to load schedules',
      );
    }
  }
}

final scheduleListControllerProvider =
    StateNotifierProvider<ScheduleListController, ScheduleListState>((ref) {
  return ScheduleListController(ref);
});
