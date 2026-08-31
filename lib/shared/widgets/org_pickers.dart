import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_response.dart';
import '../../features/org/data/models/org_models.dart';
import '../../features/org/data/org_repositories.dart';
import '../widgets/app_dropdown.dart';

class CompanyPicker extends ConsumerStatefulWidget {
  const CompanyPicker({
    super.key,
    required this.onChanged,
    this.value,
    this.enabled = true,
    this.allowNone = false,
  });

  final Company? value;
  final ValueChanged<Company?> onChanged;
  final bool enabled;
  final bool allowNone;

  @override
  ConsumerState<CompanyPicker> createState() => _CompanyPickerState();
}

class _CompanyPickerState extends ConsumerState<CompanyPicker> {
  List<Company> _items = const [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(companyRepositoryProvider).list(limit: 100);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _friendlyError(e);
      });
    }
  }

  String _friendlyError(Object e) {
    final raw = e is ApiException ? e.message : e.toString();
    final cleaned = raw
        .replaceFirst(RegExp(r'^Exception:\s*'), '')
        .replaceFirst(RegExp(r'^ApiException:\s*'), '')
        .trim();
    if (cleaned.toLowerCase() == 'not found' || cleaned.isEmpty) {
      return 'Could not load companies. Pull to refresh or try again.';
    }
    return cleaned;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppDropdown<Company>(
          label: 'Company',
          allowNone: widget.allowNone,
          items: [
            if (widget.value != null &&
                !_items.any((c) => c.id == widget.value!.id))
              widget.value!,
            ..._items,
          ],
          value: widget.value,
          itemLabel: (c) => c.displayName,
          enabled: widget.enabled,
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

class BranchFloorLocationCascade extends ConsumerStatefulWidget {
  const BranchFloorLocationCascade({
    super.key,
    required this.companyId,
    this.branch,
    this.floor,
    this.location,
    required this.onBranchChanged,
    required this.onFloorChanged,
    required this.onLocationChanged,
    this.locationRequired = false,
  });

  final String? companyId;
  final Branch? branch;
  final Floor? floor;
  final Location? location;
  final ValueChanged<Branch?> onBranchChanged;
  final ValueChanged<Floor?> onFloorChanged;
  final ValueChanged<Location?> onLocationChanged;
  final bool locationRequired;

  @override
  ConsumerState<BranchFloorLocationCascade> createState() =>
      _BranchFloorLocationCascadeState();
}

class _BranchFloorLocationCascadeState
    extends ConsumerState<BranchFloorLocationCascade> {
  List<Branch> _branches = const [];
  List<Floor> _floors = const [];
  List<Location> _locations = const [];
  bool _loadingBranches = false;
  bool _loadingFloors = false;
  bool _loadingLocations = false;

  @override
  void initState() {
    super.initState();
    if (widget.companyId != null && widget.companyId!.isNotEmpty) {
      _loadBranches(widget.companyId!);
      _loadFloors();
      _loadLocations();
    }
  }

  @override
  void didUpdateWidget(covariant BranchFloorLocationCascade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.companyId != widget.companyId) {
      _branches = const [];
      _floors = const [];
      _locations = const [];
      if (widget.companyId != null && widget.companyId!.isNotEmpty) {
        _loadBranches(widget.companyId!);
        _loadFloors();
        _loadLocations();
      }
    } else if (oldWidget.branch?.id != widget.branch?.id) {
      _floors = const [];
      _loadFloors();
      _loadLocations();
    } else if (oldWidget.floor?.id != widget.floor?.id) {
      _loadLocations();
    }
  }

  Future<void> _loadBranches(String companyId) async {
    setState(() => _loadingBranches = true);
    try {
      final items = await ref
          .read(branchRepositoryProvider)
          .listDependency(companyId: companyId);
      if (!mounted) return;
      setState(() {
        _branches = items;
        _loadingBranches = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _branches = const [];
        _loadingBranches = false;
      });
    }
  }

  Future<void> _loadFloors() async {
    final companyId = widget.companyId;
    if (companyId == null || companyId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _floors = const [];
        _loadingFloors = false;
      });
      return;
    }
    setState(() => _loadingFloors = true);
    try {
      final items = await ref.read(floorRepositoryProvider).listDependency(
            companyId: companyId,
            branchId: widget.branch?.id,
          );
      if (!mounted) return;
      setState(() {
        _floors = items;
        _loadingFloors = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _floors = const [];
        _loadingFloors = false;
      });
    }
  }

  Future<void> _loadLocations() async {
    final companyId = widget.companyId;
    if (companyId == null || companyId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _locations = const [];
        _loadingLocations = false;
      });
      return;
    }
    setState(() => _loadingLocations = true);
    try {
      final items = await ref.read(locationRepositoryProvider).listDependency(
            companyId: companyId,
            branchId: widget.branch?.id,
            floorId: widget.floor?.id,
          );
      if (!mounted) return;
      setState(() {
        _locations = items;
        _loadingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locations = const [];
        _loadingLocations = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasCompany = widget.companyId != null && widget.companyId!.isNotEmpty;

    return Column(
      children: [
        AppDropdown<Branch>(
          label: 'Branch (optional)',
          items: [
            if (widget.branch != null &&
                !_branches.any((b) => b.id == widget.branch!.id))
              widget.branch!,
            ..._branches,
          ],
          value: widget.branch,
          itemLabel: (b) => b.displayName,
          enabled: hasCompany,
          isLoading: _loadingBranches,
          allowNone: true,
          onChanged: (branch) {
            widget.onBranchChanged(branch);
            widget.onFloorChanged(null);
          },
        ),
        const SizedBox(height: 12),
        AppDropdown<Floor>(
          label: 'Floor (optional)',
          items: [
            if (widget.floor != null &&
                !_floors.any((f) => f.id == widget.floor!.id))
              widget.floor!,
            ..._floors,
          ],
          value: widget.floor,
          itemLabel: (f) => f.displayName,
          enabled: hasCompany,
          isLoading: _loadingFloors,
          allowNone: true,
          onChanged: widget.onFloorChanged,
        ),
        const SizedBox(height: 12),
        AppDropdown<Location>(
          label: widget.locationRequired ? 'Location *' : 'Location (optional)',
          items: [
            if (widget.location != null &&
                !_locations.any((l) => l.id == widget.location!.id))
              widget.location!,
            ..._locations,
          ],
          value: widget.location,
          itemLabel: (l) => l.displayName,
          enabled: hasCompany,
          isLoading: _loadingLocations,
          allowNone: !widget.locationRequired,
          onChanged: widget.onLocationChanged,
        ),
      ],
    );
  }
}
