import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../features/five_s_config/data/five_s_config_repositories.dart';
import '../../features/five_s_config/data/models/five_s_config_models.dart';
import '../../features/org/data/models/org_models.dart';
import '../../features/org/data/org_repositories.dart';
import '../widgets/app_dropdown.dart';

class AuditTypePicker extends ConsumerStatefulWidget {
  const AuditTypePicker({
    super.key,
    required this.companyId,
    required this.onChanged,
    this.value,
    this.allowNone = false,
  });

  final String? companyId;
  final FiveSAuditType? value;
  final ValueChanged<FiveSAuditType?> onChanged;
  final bool allowNone;

  @override
  ConsumerState<AuditTypePicker> createState() => _AuditTypePickerState();
}

class _AuditTypePickerState extends ConsumerState<AuditTypePicker> {
  List<FiveSAuditType> _items = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.companyId != null) _load(widget.companyId!);
  }

  @override
  void didUpdateWidget(covariant AuditTypePicker oldWidget) {
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
          .read(fiveSAuditTypeRepositoryProvider)
          .list(companyId: companyId);
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
    return AppDropdown<FiveSAuditType>(
      label: widget.allowNone ? 'Audit type (optional)' : 'Audit type',
      items: [
        if (widget.value != null &&
            !_items.any((t) => t.id == widget.value!.id))
          widget.value!,
        ..._items,
      ],
      value: widget.value,
      itemLabel: (t) => t.displayName,
      enabled: widget.companyId != null && widget.companyId!.isNotEmpty,
      isLoading: _loading,
      allowNone: widget.allowNone,
      onChanged: widget.onChanged,
    );
  }
}

class AssigneePicker extends ConsumerStatefulWidget {
  const AssigneePicker({
    super.key,
    this.clientCompanyId,
    required this.onChanged,
    this.value,
  });

  final String? clientCompanyId;
  final AssigneeUser? value;
  final ValueChanged<AssigneeUser?> onChanged;

  @override
  ConsumerState<AssigneePicker> createState() => _AssigneePickerState();
}

class _AssigneePickerState extends ConsumerState<AssigneePicker> {
  List<AssigneeUser> _items = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AssigneePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clientCompanyId != widget.clientCompanyId) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(clientEmployeeRepositoryProvider).listDependency(
            clientCompanyId: widget.clientCompanyId,
          );
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _loading = false;
        _error = e is ApiException
            ? e.message
            : 'Could not load assignees. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = <AssigneeUser>[
      if (widget.value != null &&
          !_items.any((a) => a.id == widget.value!.id))
        widget.value!,
      ..._items,
    ];
    AssigneeUser? resolved;
    if (widget.value != null) {
      for (final item in items) {
        if (item.id == widget.value!.id) {
          resolved = item;
          break;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdown<AssigneeUser>(
          label: 'Assignee',
          items: items,
          value: resolved,
          itemLabel: (a) => a.displayName,
          isLoading: _loading,
          onChanged: widget.onChanged,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              _error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}
