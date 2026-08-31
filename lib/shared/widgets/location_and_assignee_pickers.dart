import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/org/data/models/org_models.dart';
import '../../features/org/data/org_repositories.dart';
import '../../features/schedules/data/schedule_repository.dart';
import '../widgets/app_dropdown.dart';

class LocationPicker extends ConsumerStatefulWidget {
  const LocationPicker({
    super.key,
    required this.companyId,
    required this.onChanged,
    this.value,
  });

  final String? companyId;
  final Location? value;
  final ValueChanged<Location?> onChanged;

  @override
  ConsumerState<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends ConsumerState<LocationPicker> {
  List<Location> _items = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companyId != null) _load(widget.companyId!);
  }

  @override
  void didUpdateWidget(covariant LocationPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _items = const [];
      if (widget.companyId != null && widget.companyId!.isNotEmpty) {
        _load(widget.companyId!);
      }
    }
  }

  Future<void> _load(String companyId) async {
    setState(() => _loading = true);
    try {
      final items = await ref
          .read(locationRepositoryProvider)
          .listDependency(companyId: companyId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppDropdown<Location>(
      label: 'Location',
      items: [
        if (widget.value != null &&
            !_items.any((l) => l.id == widget.value!.id))
          widget.value!,
        ..._items,
      ],
      value: widget.value,
      itemLabel: (l) => l.displayName,
      enabled: widget.companyId != null && widget.companyId!.isNotEmpty,
      isLoading: _loading,
      onChanged: widget.onChanged,
    );
  }
}

class MultiAssigneePicker extends ConsumerStatefulWidget {
  const MultiAssigneePicker({
    super.key,
    this.clientCompanyId,
    required this.selectedIds,
    required this.onChanged,
    this.useScheduleAssignees = false,
    this.label = 'Assignees',
  });

  final String? clientCompanyId;
  final List<String> selectedIds;
  final ValueChanged<List<AssigneeUser>> onChanged;
  final bool useScheduleAssignees;
  final String label;

  @override
  ConsumerState<MultiAssigneePicker> createState() => _MultiAssigneePickerState();
}

class _MultiAssigneePickerState extends ConsumerState<MultiAssigneePicker> {
  List<AssigneeUser> _items = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant MultiAssigneePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientCompanyId != widget.clientCompanyId ||
        oldWidget.useScheduleAssignees != widget.useScheduleAssignees) {
      _load();
    }
  }

  Future<void> _load() async {
    final companyId = widget.clientCompanyId;
    if (companyId == null || companyId.isEmpty) {
      setState(() {
        _items = const [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final items = widget.useScheduleAssignees
          ? await ref.read(scheduleAuditRepositoryProvider).listAssignees(
                companyId: companyId,
              )
          : await ref.read(clientEmployeeRepositoryProvider).listDependency(
                clientCompanyId: companyId,
              );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.clientCompanyId == null || widget.clientCompanyId!.isEmpty) {
      return const Text('Select a company first', style: TextStyle(fontSize: 13));
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_items.isEmpty) {
      return const Text('No assignees available', style: TextStyle(fontSize: 13));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: _items.map((user) {
            final selected = widget.selectedIds.contains(user.id);
            return FilterChip(
              label: Text(user.displayName),
              selected: selected,
              onSelected: (value) {
                final ids = Set<String>.from(widget.selectedIds);
                if (value) {
                  ids.add(user.id);
                } else {
                  ids.remove(user.id);
                }
                widget.onChanged(_items.where((u) => ids.contains(u.id)).toList());
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
