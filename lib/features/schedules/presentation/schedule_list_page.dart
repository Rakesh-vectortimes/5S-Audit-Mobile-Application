import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/permissions/record_permissions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/org_pickers.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/models/schedule_models.dart';
import 'schedule_list_controller.dart';

class ScheduleListPage extends ConsumerStatefulWidget {
  const ScheduleListPage({super.key});

  @override
  ConsumerState<ScheduleListPage> createState() => _ScheduleListPageState();
}

class _ScheduleListPageState extends ConsumerState<ScheduleListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scheduleListControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final list = ref.watch(scheduleListControllerProvider);
    final listCtrl = ref.read(scheduleListControllerProvider.notifier);
    final canView = auth.showScheduleAudits;
    final canManage = auth.canManageScheduleAudits;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Schedules')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to view schedules.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Schedules')),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              heroTag: 'schedules-new-fab',
              onPressed: () async {
                await context.push(AppRoutes.scheduleCreate);
                if (mounted) {
                  ref.read(scheduleListControllerProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New schedule'),
            )
          : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search schedules',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(scheduleListControllerProvider.notifier).setSearch('');
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                ref.read(scheduleListControllerProvider.notifier).setSearch(value);
              },
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.34,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  CompanyPicker(
                    value: list.company,
                    onChanged: listCtrl.setCompany,
                  ),
                  const SizedBox(height: 12),
                  BranchFloorLocationCascade(
                    companyId: list.company?.id,
                    branch: list.branch,
                    floor: list.floor,
                    location: list.location,
                    onBranchChanged: listCtrl.setBranch,
                    onFloorChanged: listCtrl.setFloor,
                    onLocationChanged: listCtrl.setLocation,
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
                for (final filter in const ['all', 'active', 'inactive'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_statusLabel(filter)),
                      selected: list.statusFilter == filter,
                      onSelected: (_) => listCtrl.setStatusFilter(filter),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (list.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(list.errorMessage!, style: const TextStyle(color: AppColors.error)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(scheduleListControllerProvider.notifier).refresh(),
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
                            const Center(child: Text('No schedules yet')),
                            if (canManage) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: FilledButton.icon(
                                  onPressed: () => context.push(AppRoutes.scheduleCreate),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create schedule'),
                                ),
                              ),
                            ],
                          ],
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
                              ref.read(scheduleListControllerProvider.notifier).loadMore();
                            }
                            return false;
                          },
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: list.items.length + (list.loadingMore ? 1 : 0),
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              if (index >= list.items.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final record = list.items[index];
                              final canEdit = canManage &&
                                  RecordPermissions.canEditRecord(
                                    user: auth.user,
                                    createdByRole: record.createdByRole,
                                    createdBy: record.createdBy,
                                  );
                              return _ScheduleCard(
                                record: record,
                                canEdit: canEdit,
                                canRunNow: record.canRunNow,
                                onEdit: () async {
                                  await context.push(AppRoutes.scheduleEditPath(record.id));
                                  if (mounted) {
                                    ref.read(scheduleListControllerProvider.notifier).refresh();
                                  }
                                },
                                onDelete: () => _confirmDelete(record),
                                onTrigger: () => _confirmTrigger(record),
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
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      default:
        return 'All';
    }
  }

  Future<void> _confirmDelete(ScheduleAuditConfig record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete schedule?'),
        content: Text('Delete "${record.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        await ref.read(scheduleListControllerProvider.notifier).delete(record.id);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  Future<void> _confirmTrigger(ScheduleAuditConfig record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Run now?'),
        content: const Text('Create the next draft audit for this schedule now?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Run now')),
        ],
      ),
    );
    if (ok == true && mounted) {
      try {
        final message =
            await ref.read(scheduleListControllerProvider.notifier).trigger(record.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.record,
    required this.canEdit,
    required this.canRunNow,
    required this.onEdit,
    required this.onDelete,
    required this.onTrigger,
  });

  final ScheduleAuditConfig record;
  final bool canEdit;
  final bool canRunNow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTrigger;

  @override
  Widget build(BuildContext context) {
    final next = record.nextAuditDate == null
        ? '—'
        : () {
            try {
              return DateFormat('dd MMM yyyy').format(DateTime.parse(record.nextAuditDate!));
            } catch (_) {
              return record.nextAuditDate!;
            }
          }();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(record.title, style: Theme.of(context).textTheme.titleLarge),
                ),
                _StatusChip(status: record.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(record.companyName ?? record.companyId),
            Text(
              [
                record.locationName ?? record.locationId,
                record.auditTypeName ?? 'Audit type',
              ].where((e) => e.toString().trim().isNotEmpty).join(' · '),
            ),
            Text(
              [
                record.displayFrequency,
                if (record.displayAssignees.isNotEmpty) record.displayAssignees,
                'Next: $next',
              ].join(' · '),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (canEdit || canRunNow) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Spacer(),
                  if (canRunNow)
                    IconButton(
                      tooltip: 'Run now',
                      onPressed: onTrigger,
                      color: AppColors.primary,
                      icon: const Icon(Icons.play_arrow),
                    ),
                  if (canEdit) ...[
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: onEdit,
                      color: AppColors.primary,
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      onPressed: onDelete,
                      color: AppColors.error,
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ScheduleStatus status;

  @override
  Widget build(BuildContext context) {
    final active = status == ScheduleStatus.active;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (active ? AppColors.success : AppColors.textSecondary).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: active ? AppColors.success : AppColors.textSecondary,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
