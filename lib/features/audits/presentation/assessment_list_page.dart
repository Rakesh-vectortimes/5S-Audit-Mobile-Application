import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/network/api_response.dart';
import '../../../core/permissions/record_permissions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/assessment_export_share.dart';
import '../data/assessment_repository.dart';
import '../data/models/assessment_models.dart';
import 'assessment_list_controller.dart';

class AssessmentListPage extends ConsumerStatefulWidget {
  const AssessmentListPage({super.key});

  @override
  ConsumerState<AssessmentListPage> createState() => _AssessmentListPageState();
}

class _AssessmentListPageState extends ConsumerState<AssessmentListPage> {
  final _searchController = TextEditingController();
  String? _busyId;
  String? _busyAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(assessmentListControllerProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isBusy(String id, [String? action]) {
    if (_busyId != id) return false;
    if (action == null) return true;
    return _busyAction == action;
  }

  Future<void> _export(FiveSAuditRecord record, {required bool pdf}) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.canViewReports && !auth.isAuthenticated) {
      _snack('You do not have permission to export reports.');
      return;
    }
    setState(() {
      _busyId = record.id;
      _busyAction = pdf ? 'pdf' : 'word';
    });
    try {
      final repo = ref.read(fiveSAuditAssessmentRepositoryProvider);
      final file = pdf
          ? await repo.exportPdf(
              record.id,
              companyName: record.companyName,
              reportDate: record.reportDate,
            )
          : await repo.exportWord(
              record.id,
              companyName: record.companyName,
              reportDate: record.reportDate,
            );
      await shareAssessmentExport(file);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message);
    } catch (e) {
      if (mounted) _snack('$e');
    } finally {
      if (mounted) {
        setState(() {
          _busyId = null;
          _busyAction = null;
        });
      }
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final list = ref.watch(assessmentListControllerProvider);
    final canView = auth.canViewReports || auth.isAuthenticated;
    final canWrite = auth.canWriteReports;
    final canExport = auth.canViewReports || auth.isAuthenticated;

    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Audits')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to view 5S audit reports.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Audits')),
      floatingActionButton: canWrite
          ? FloatingActionButton.extended(
              heroTag: 'audits-new-fab',
              onPressed: () async {
                await context.push(AppRoutes.auditCreate);
                if (mounted) {
                  ref.read(assessmentListControllerProvider.notifier).refresh();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New audit'),
            )
          : null,
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
                          ref.read(assessmentListControllerProvider.notifier).setSearch('');
                          setState(() {});
                        },
                      ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: (_) => setState(() {}),
              onSubmitted: (value) {
                ref.read(assessmentListControllerProvider.notifier).setSearch(value);
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (final filter in const ['all', 'draft', 'submitted'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_label(filter)),
                      selected: list.statusFilter == filter,
                      onSelected: (_) {
                        ref
                            .read(assessmentListControllerProvider.notifier)
                            .setStatusFilter(filter);
                      },
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
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
                  ref.read(assessmentListControllerProvider.notifier).refresh(),
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
                            const Center(child: Text('No audits yet')),
                            if (canWrite) ...[
                              const SizedBox(height: 16),
                              Center(
                                child: FilledButton.icon(
                                  onPressed: () => context.push(AppRoutes.auditCreate),
                                  icon: const Icon(Icons.add),
                                  label: const Text('Create audit'),
                                ),
                              ),
                            ],
                          ],
                        )
                      : NotificationListener<ScrollNotification>(
                          onNotification: (n) {
                            if (n.metrics.pixels >= n.metrics.maxScrollExtent - 120) {
                              ref.read(assessmentListControllerProvider.notifier).loadMore();
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
                              final canEdit = RecordPermissions.canEditRecord(
                                user: auth.user,
                                createdByRole: record.createdByRole,
                                createdBy: record.createdBy,
                              );
                              final busy = _isBusy(record.id);
                              return _AuditCard(
                                record: record,
                                canEdit: canEdit,
                                canExport: canExport,
                                busy: busy,
                                exportingPdf: _isBusy(record.id, 'pdf'),
                                exportingWord: _isBusy(record.id, 'word'),
                                onOpen: () => context.push(
                                  AppRoutes.auditPreviewPath(record.id),
                                ),
                                onEdit: busy
                                    ? null
                                    : () async {
                                        await context.push(AppRoutes.auditEditPath(record.id));
                                        if (mounted) {
                                          ref
                                              .read(assessmentListControllerProvider.notifier)
                                              .refresh();
                                        }
                                      },
                                onDelete: busy ? null : () => _confirmDelete(record),
                                onExportPdf: () => _export(record, pdf: true),
                                onExportWord: () => _export(record, pdf: false),
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

  String _label(String filter) {
    switch (filter) {
      case 'draft':
        return 'Draft';
      case 'submitted':
        return 'Submitted';
      default:
        return 'All';
    }
  }

  Future<void> _confirmDelete(FiveSAuditRecord record) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete audit?'),
        content: Text('Delete "${record.displayTitle}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) {
      setState(() {
        _busyId = record.id;
        _busyAction = 'delete';
      });
      try {
        await ref.read(assessmentListControllerProvider.notifier).delete(record.id);
      } catch (e) {
        if (mounted) _snack('$e');
      } finally {
        if (mounted) {
          setState(() {
            _busyId = null;
            _busyAction = null;
          });
        }
      }
    }
  }
}

class _AuditCard extends StatelessWidget {
  const _AuditCard({
    required this.record,
    required this.canEdit,
    required this.canExport,
    required this.busy,
    required this.exportingPdf,
    required this.exportingWord,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
    required this.onExportPdf,
    required this.onExportWord,
  });

  final FiveSAuditRecord record;
  final bool canEdit;
  final bool canExport;
  final bool busy;
  final bool exportingPdf;
  final bool exportingWord;
  final VoidCallback onOpen;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback onExportPdf;
  final VoidCallback onExportWord;

  @override
  Widget build(BuildContext context) {
    final date = record.reportDate == null
        ? '-'
        : () {
            try {
              return DateFormat('dd MMM yyyy').format(DateTime.parse(record.reportDate!));
            } catch (_) {
              return record.reportDate!;
            }
          }();

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.displayTitle,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  _StatusChip(status: record.status),
                ],
              ),
              const SizedBox(height: 6),
              Text(record.auditTypeName ?? 'Audit type'),
              const SizedBox(height: 4),
              Text(
                [
                  date,
                  if ((record.preparedBy ?? record.createdByName)?.isNotEmpty == true)
                    record.preparedBy ?? record.createdByName!,
                ].join(' · '),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (canExport || canEdit) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Spacer(),
                    if (canExport) ...[
                      _ActionIconButton(
                        tooltip: 'Export PDF',
                        icon: Icons.picture_as_pdf_outlined,
                        onPressed: busy ? null : onExportPdf,
                        loading: exportingPdf,
                      ),
                      _ActionIconButton(
                        tooltip: 'Export Word',
                        icon: Icons.description_outlined,
                        onPressed: busy ? null : onExportWord,
                        loading: exportingWord,
                      ),
                    ],
                    if (canEdit) ...[
                      _ActionIconButton(
                        tooltip: 'Edit',
                        icon: Icons.edit_outlined,
                        onPressed: onEdit,
                      ),
                      _ActionIconButton(
                        tooltip: 'Delete',
                        icon: Icons.delete_outline,
                        color: AppColors.error,
                        onPressed: onDelete,
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionIconButton extends StatelessWidget {
  const _ActionIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color,
    this.loading = false,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color? color;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: loading ? null : onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: EdgeInsets.zero,
      color: color ?? AppColors.primary,
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 22),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final submitted = status == 'submitted';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (submitted ? AppColors.success : AppColors.warning).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        submitted ? 'Submitted' : 'Draft',
        style: TextStyle(
          color: submitted ? AppColors.success : AppColors.warning,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
