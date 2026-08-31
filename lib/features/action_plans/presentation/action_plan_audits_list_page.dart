import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/audit_pickers.dart';
import '../../../shared/widgets/org_pickers.dart';
import '../data/models/action_plan_models.dart';
import 'action_plan_audits_list_controller.dart';

class ActionPlanAuditsListPage extends ConsumerStatefulWidget {
  const ActionPlanAuditsListPage({super.key});

  @override
  ConsumerState<ActionPlanAuditsListPage> createState() =>
      _ActionPlanAuditsListPageState();
}

class _ActionPlanAuditsListPageState
    extends ConsumerState<ActionPlanAuditsListPage> {
  final _searchController = TextEditingController();
  bool _appliedQuery = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyRouteQuery();
      ref.read(actionPlanAuditsListControllerProvider.notifier).refresh();
    });
  }

  void _applyRouteQuery() {
    if (_appliedQuery || !mounted) return;
    _appliedQuery = true;
    final q = GoRouterState.of(context).uri.queryParameters;
    final companyId = q['company_id'];
    final auditTypeId = q['audit_type_id'];
    if ((companyId != null && companyId.isNotEmpty) ||
        (auditTypeId != null && auditTypeId.isNotEmpty)) {
      ref.read(actionPlanAuditsListControllerProvider.notifier).applyQueryFilters(
            companyId: companyId,
            companyName: q['company_name'],
            auditTypeId: auditTypeId,
            auditTypeName: q['audit_type_name'],
          );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(actionPlanAuditsListControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Action Plans')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search audits',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref
                              .read(actionPlanAuditsListControllerProvider.notifier)
                              .setSearch('');
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                ref
                    .read(actionPlanAuditsListControllerProvider.notifier)
                    .setSearch(value);
              },
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.36,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  CompanyPicker(
                    value: list.company,
                    allowNone: true,
                    onChanged: (company) {
                      ref
                          .read(actionPlanAuditsListControllerProvider.notifier)
                          .setCompany(company);
                    },
                  ),
                  const SizedBox(height: 12),
                  BranchFloorLocationCascade(
                    companyId: list.company?.id,
                    branch: list.branch,
                    floor: list.floor,
                    location: list.location,
                    onBranchChanged: (branch) {
                      ref
                          .read(actionPlanAuditsListControllerProvider.notifier)
                          .setBranch(branch);
                    },
                    onFloorChanged: (floor) {
                      ref
                          .read(actionPlanAuditsListControllerProvider.notifier)
                          .setFloor(floor);
                    },
                    onLocationChanged: (location) {
                      ref
                          .read(actionPlanAuditsListControllerProvider.notifier)
                          .setLocation(location);
                    },
                  ),
                  const SizedBox(height: 12),
                  AuditTypePicker(
                    companyId: list.company?.id,
                    value: list.auditType,
                    allowNone: true,
                    onChanged: (type) {
                      ref
                          .read(actionPlanAuditsListControllerProvider.notifier)
                          .setAuditType(type);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final filter in const [
                  'all',
                  'open',
                  'submitted',
                  'in_progress',
                  'overdue',
                  'closed',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_statusLabel(filter)),
                      selected: list.statusFilter == filter,
                      onSelected: (_) {
                        ref
                            .read(actionPlanAuditsListControllerProvider.notifier)
                            .setStatusFilter(filter);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final priority in const [null, 'high', 'medium', 'low'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(priority ?? 'All priority'),
                      selected: list.priorityFilter == priority,
                      onSelected: (_) {
                        ref
                            .read(actionPlanAuditsListControllerProvider.notifier)
                            .setPriorityFilter(priority);
                      },
                    ),
                  ),
                TextButton.icon(
                  onPressed: () => _pickDates(list),
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    list.dateFrom == null && list.dateTo == null
                        ? 'Dates'
                        : '${list.dateFrom ?? '…'} → ${list.dateTo ?? '…'}',
                  ),
                ),
              ],
            ),
          ),
          if (list.summary != null) _SummaryRow(summary: list.summary!),
          if (list.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                list.errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(actionPlanAuditsListControllerProvider.notifier).refresh(),
              child: list.loading && list.items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: CircularProgressIndicator()),
                      ],
                    )
                  : list.items.isEmpty
                      ? ListView(
                          children: [
                            const SizedBox(height: 120),
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  list.company != null && list.auditType != null
                                      ? 'No action plans found for this company and 5S audit.'
                                      : list.company != null
                                          ? 'No action plans found for this company.'
                                          : 'No action plans found.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >=
                                n.metrics.maxScrollExtent - 120) {
                              ref
                                  .read(actionPlanAuditsListControllerProvider.notifier)
                                  .loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount:
                                list.items.length + (list.loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index >= list.items.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final item = list.items[index];
                              return _AuditGroupCard(
                                item: item,
                                onTap: () => context.push(
                                  AppRoutes.actionPlanAuditPath(item.assessmentId),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  String _statusLabel(String filter) {
    switch (filter) {
      case 'open':
        return 'Open';
      case 'submitted':
        return 'Submitted';
      case 'in_progress':
        return 'In progress';
      case 'overdue':
        return 'Overdue';
      case 'closed':
        return 'Closed';
      default:
        return 'All';
    }
  }

  Future<void> _pickDates(ActionPlanAuditsListState list) async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: list.dateFrom != null && list.dateTo != null
          ? DateTimeRange(
              start: DateTime.tryParse(list.dateFrom!) ?? DateTime.now(),
              end: DateTime.tryParse(list.dateTo!) ?? DateTime.now(),
            )
          : null,
    );
    if (range == null) return;
    String ymd(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await ref.read(actionPlanAuditsListControllerProvider.notifier).setDateRange(
          from: ymd(range.start),
          to: ymd(range.end),
        );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});

  final ActionPlanSummary summary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          _chip('Open', summary.open, AppColors.warning),
          _chip('Submitted', summary.submitted, AppColors.primary),
          _chip('Overdue', summary.overdue, AppColors.error),
          _chip('Closed', summary.closed, AppColors.success),
        ],
      ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}

class _AuditGroupCard extends StatelessWidget {
  const _AuditGroupCard({required this.item, required this.onTap});

  final ActionPlanAuditGroup item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date = item.auditDate == null
        ? '—'
        : () {
            try {
              return DateFormat('dd MMM yyyy').format(DateTime.parse(item.auditDate!));
            } catch (_) {
              return item.auditDate!;
            }
          }();

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title?.trim().isNotEmpty == true
                    ? item.title!
                    : item.assessmentCode,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(item.assessmentCode),
              Text(
                [
                  item.companyName ?? item.companyId ?? '',
                  item.locationName ?? item.locationId ?? '',
                  date,
                ].where((e) => e.toString().trim().isNotEmpty).join(' · '),
              ),
              const SizedBox(height: 8),
              Text(
                'Plans ${item.actionPlanCount} · Open ${item.openCount} · '
                'Overdue ${item.overdueCount} · Closed ${item.closedCount}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
