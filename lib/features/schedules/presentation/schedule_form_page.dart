import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/audit_pickers.dart';
import '../../../shared/widgets/location_and_assignee_pickers.dart';
import '../../../shared/widgets/org_pickers.dart';
import '../data/models/schedule_models.dart';
import '../data/schedule_utils.dart';
import 'schedule_form_controller.dart';

class ScheduleFormPage extends ConsumerStatefulWidget {
  const ScheduleFormPage({super.key, this.scheduleId});

  final String? scheduleId;

  @override
  ConsumerState<ScheduleFormPage> createState() => _ScheduleFormPageState();
}

class _ScheduleFormPageState extends ConsumerState<ScheduleFormPage> {
  final _titleController = TextEditingController();
  final _frequencyController = TextEditingController(text: '1');
  bool _seeded = false;

  bool get _isEdit => widget.scheduleId != null && widget.scheduleId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(scheduleFormControllerProvider.notifier);
      if (_isEdit) {
        controller.loadForEdit(widget.scheduleId!);
      } else {
        controller.resetForCreate();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _frequencyController.dispose();
    super.dispose();
  }

  void _syncControllers(ScheduleFormState form) {
    if (_seeded || !form.initialized || form.loading) return;
    _titleController.text = form.title;
    _frequencyController.text = '${form.frequency}';
    _seeded = true;
  }

  Future<void> _pickDate({required bool start}) async {
    final form = ref.read(scheduleFormControllerProvider);
    final current = parseYmd(start ? form.startDate : form.endDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked == null) return;
    final ymd = formatDateYmd(picked);
    final controller = ref.read(scheduleFormControllerProvider.notifier);
    if (start) {
      controller.setStartDate(ymd);
    } else {
      controller.setEndDate(ymd);
    }
  }

  Future<void> _save() async {
    final record = await ref.read(scheduleFormControllerProvider.notifier).save();
    if (!mounted) return;
    if (record != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Schedule saved')),
      );
      context.pop(true);
    }
  }

  Future<void> _trigger() async {
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
    if (ok != true || !mounted) return;
    final message = await ref.read(scheduleFormControllerProvider.notifier).trigger();
    if (!mounted) return;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(scheduleFormControllerProvider);
    _syncControllers(form);

    if (form.permissionDenied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(form.errorMessage ?? 'Permission denied')),
        );
        context.go(AppRoutes.schedules);
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit schedule' : 'New schedule'),
        actions: [
          if (_isEdit && form.canRunNow)
            IconButton(
              tooltip: 'Run now',
              onPressed: form.saving ? null : _trigger,
              icon: const Icon(Icons.play_arrow),
            ),
        ],
      ),
      body: form.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (form.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(form.errorMessage!, style: const TextStyle(color: AppColors.error)),
                  ),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  onChanged: ref.read(scheduleFormControllerProvider.notifier).setTitle,
                ),
                const SizedBox(height: 12),
                CompanyPicker(
                  value: form.company,
                  onChanged: ref.read(scheduleFormControllerProvider.notifier).selectCompany,
                ),
                const SizedBox(height: 12),
                BranchFloorLocationCascade(
                  companyId: form.company?.id,
                  branch: form.branch,
                  floor: form.floor,
                  location: form.location,
                  locationRequired: true,
                  onBranchChanged:
                      ref.read(scheduleFormControllerProvider.notifier).selectBranch,
                  onFloorChanged:
                      ref.read(scheduleFormControllerProvider.notifier).selectFloor,
                  onLocationChanged:
                      ref.read(scheduleFormControllerProvider.notifier).selectLocation,
                ),
                const SizedBox(height: 12),
                AuditTypePicker(
                  companyId: form.company?.id,
                  value: form.auditType,
                  onChanged:
                      ref.read(scheduleFormControllerProvider.notifier).selectAuditType,
                ),
                const SizedBox(height: 12),
                MultiAssigneePicker(
                  clientCompanyId: form.company?.id,
                  selectedIds: form.assignees.map((a) => a.id).toList(),
                  useScheduleAssignees: true,
                  label: 'Assigned Auditor(s)',
                  onChanged:
                      ref.read(scheduleFormControllerProvider.notifier).selectAssignees,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _frequencyController,
                        decoration: const InputDecoration(labelText: 'Frequency *'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final n = int.tryParse(v) ?? 1;
                          ref.read(scheduleFormControllerProvider.notifier).setFrequency(n);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<ScheduleDuration>(
                        value: form.duration,
                        decoration: const InputDecoration(labelText: 'Duration *'),
                        items: ScheduleDuration.values
                            .map(
                              (d) => DropdownMenuItem(value: d, child: Text(d.label)),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            ref
                                .read(scheduleFormControllerProvider.notifier)
                                .setDuration(value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  form.nextPreview == null
                      ? 'Next preview: beyond end date / —'
                      : 'Next preview: ${form.nextPreview}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Start date'),
                  subtitle: Text(_formatDate(form.startDate) ?? 'Optional'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (form.startDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref
                              .read(scheduleFormControllerProvider.notifier)
                              .setStartDate(null),
                        ),
                      const Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                  onTap: () => _pickDate(start: true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('End date'),
                  subtitle: Text(_formatDate(form.endDate) ?? 'Optional'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (form.endDate != null)
                        IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () => ref
                              .read(scheduleFormControllerProvider.notifier)
                              .setEndDate(null),
                        ),
                      const Icon(Icons.calendar_today_outlined),
                    ],
                  ),
                  onTap: () => _pickDate(start: false),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ScheduleStatus>(
                  value: form.status,
                  decoration: const InputDecoration(labelText: 'Status *'),
                  items: ScheduleStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(scheduleFormControllerProvider.notifier).setStatus(value);
                    }
                  },
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: form.saving ? null : _save,
                    child: form.saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(_isEdit ? 'Update schedule' : 'Create schedule'),
                  ),
                ),
              ],
            ),
    );
  }

  String? _formatDate(String? ymd) {
    if (ymd == null || ymd.isEmpty) return null;
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }
}
