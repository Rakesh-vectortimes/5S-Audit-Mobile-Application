import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../five_s_config/data/five_s_config_repositories.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/data/settings_serialize.dart';
import 'five_s_settings_context.dart';

class FiveSAuditTypesSettingsPage extends ConsumerStatefulWidget {
  const FiveSAuditTypesSettingsPage({super.key});

  @override
  ConsumerState<FiveSAuditTypesSettingsPage> createState() =>
      _FiveSAuditTypesSettingsPageState();
}

class _FiveSAuditTypesSettingsPageState
    extends ConsumerState<FiveSAuditTypesSettingsPage> {
  List<FiveSAuditType> _items = const [];
  bool _loading = false;
  String? _error;
  String? _busyId;
  String? _loadedForCompany;

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(fiveSSettingsContextProvider);
    if (!ctx.hasCompany) {
      return const Center(child: Text('Select a company to manage audit types.'));
    }
    if (_loadedForCompany != ctx.companyId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadedForCompany = ctx.companyId;
        _refresh();
      });
    }

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'settings-audit-types-fab',
        onPressed: _busyId != null ? null : () => _openEditor(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _items.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No audit types yet')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final t = _items[index];
                        final busy = _busyId == t.id;
                        return ListTile(
                          title: Text(t.displayName),
                          trailing: busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined),
                                      onPressed: () => _openEditor(t),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(t),
                                    ),
                                  ],
                                ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh() async {
    final companyId = ref.read(fiveSSettingsContextProvider).companyId;
    if (companyId == null || companyId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items =
          await ref.read(fiveSAuditTypeRepositoryProvider).list(companyId: companyId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load audit types';
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([FiveSAuditType? existing]) async {
    final controller = TextEditingController(text: existing?.auditName ?? '');
    final name = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? 'New audit type' : 'Edit audit type',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Audit name *'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final value = controller.text.trim();
                  if (value.isEmpty) return;
                  Navigator.pop(context, value);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (name == null || !mounted) return;

    final companyId = ref.read(fiveSSettingsContextProvider).companyId!;
    setState(() => _busyId = existing?.id ?? 'new');
    try {
      final repo = ref.read(fiveSAuditTypeRepositoryProvider);
      final payload = buildAuditTypePayload(companyId: companyId, auditName: name);
      if (existing == null) {
        await repo.create(payload);
      } else {
        await repo.update(id: existing.id, companyId: companyId, payload: payload);
      }
      await ref.read(fiveSSettingsContextProvider.notifier).refreshConfigCache();
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _delete(FiveSAuditType type) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete audit type?'),
        content: Text('Delete "${type.displayName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final companyId = ref.read(fiveSSettingsContextProvider).companyId!;
    setState(() => _busyId = type.id);
    try {
      await ref
          .read(fiveSAuditTypeRepositoryProvider)
          .delete(id: type.id, companyId: companyId);
      final ctx = ref.read(fiveSSettingsContextProvider);
      if (ctx.auditTypeId == type.id) {
        ref.read(fiveSSettingsContextProvider.notifier).selectAuditType(null);
      }
      await ref.read(fiveSSettingsContextProvider.notifier).refreshConfigCache();
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}
