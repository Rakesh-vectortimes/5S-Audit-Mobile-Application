import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../five_s_config/data/five_s_config_repositories.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/data/settings_serialize.dart';
import '../../five_s_config/domain/section_hierarchy.dart';
import 'five_s_settings_context.dart';

class FiveSSectionsSettingsPage extends ConsumerStatefulWidget {
  const FiveSSectionsSettingsPage({super.key});

  @override
  ConsumerState<FiveSSectionsSettingsPage> createState() =>
      _FiveSSectionsSettingsPageState();
}

class _FiveSSectionsSettingsPageState
    extends ConsumerState<FiveSSectionsSettingsPage> {
  List<FiveSAuditSection> _items = const [];
  bool _loading = false;
  String? _error;
  String? _busyId;
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(fiveSSettingsContextProvider);
    if (!ctx.hasCompanyAndType) {
      return const Center(
        child: Text('Select company and audit type to manage sections.'),
      );
    }
    final key = '${ctx.companyId}:${ctx.auditTypeId}';
    if (_loadedKey != key) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _loadedKey = key;
        _refresh();
      });
    }

    if (_loading && _items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final tops = getTopLevelSections(_items);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'settings-sections-fab',
        onPressed: _busyId != null ? null : () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Section'),
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
              child: tops.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        Center(child: Text('No sections yet')),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                      itemCount: tops.length,
                      itemBuilder: (context, index) {
                        final section = tops[index];
                        final children = getChildSections(_items, section.id);
                        return ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(section.displayLabel),
                          subtitle: Text(
                            'Order ${section.sectionOrder ?? '—'} · Q ${section.noOfQuestions} · Marks ${section.totalMarks}',
                          ),
                          trailing: _rowActions(section, allowSub: true),
                          children: [
                            for (final child in children)
                              ListTile(
                                contentPadding: const EdgeInsets.only(left: 32, right: 8),
                                title: Text(child.displayLabel),
                                subtitle: Text(
                                  'Sub-section · Order ${child.sectionOrder ?? '—'}',
                                ),
                                trailing: _rowActions(child, allowSub: false),
                              ),
                            ListTile(
                              contentPadding: const EdgeInsets.only(left: 32, right: 16),
                              leading: const Icon(Icons.add),
                              title: const Text('Add sub-section'),
                              onTap: _busyId != null
                                  ? null
                                  : () => _openEditor(parent: section),
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _rowActions(FiveSAuditSection section, {required bool allowSub}) {
    final busy = _busyId == section.id;
    if (busy) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          onPressed: () => _openEditor(existing: section),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: () => _delete(section),
        ),
      ],
    );
  }

  Future<void> _refresh() async {
    final ctx = ref.read(fiveSSettingsContextProvider);
    if (!ctx.hasCompanyAndType) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(fiveSAuditSectionRepositoryProvider).list(
            companyId: ctx.companyId!,
            auditTypeId: ctx.auditTypeId!,
          );
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
        _error = 'Failed to load sections';
        _loading = false;
      });
    }
  }

  Future<void> _openEditor({
    FiveSAuditSection? existing,
    FiveSAuditSection? parent,
  }) async {
    if (parent != null && !parent.isTopLevel) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sub-sections must be under a top-level section.')),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: existing?.sectionName ?? '');
    final orderCtrl =
        TextEditingController(text: existing?.sectionOrder?.toString() ?? '');
    final questionsCtrl =
        TextEditingController(text: '${existing?.noOfQuestions ?? 0}');
    final marksCtrl =
        TextEditingController(text: '${existing?.totalMarks ?? 0}');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final bottom = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  existing == null
                      ? (parent == null ? 'New section' : 'New sub-section')
                      : 'Edit section',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (parent != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('Under ${parent.displayLabel}'),
                  ),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Section name *'),
                ),
                TextField(
                  controller: orderCtrl,
                  decoration: const InputDecoration(labelText: 'Order'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: questionsCtrl,
                  decoration: const InputDecoration(labelText: 'No. of questions'),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: marksCtrl,
                  decoration: const InputDecoration(labelText: 'Total marks'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (nameCtrl.text.trim().isEmpty) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        );
      },
    );

    final name = nameCtrl.text.trim();
    final order = int.tryParse(orderCtrl.text.trim());
    final questions = int.tryParse(questionsCtrl.text.trim()) ?? 0;
    final marks = num.tryParse(marksCtrl.text.trim()) ?? 0;
    nameCtrl.dispose();
    orderCtrl.dispose();
    questionsCtrl.dispose();
    marksCtrl.dispose();

    if (saved != true || name.isEmpty || !mounted) return;

    final ctx = ref.read(fiveSSettingsContextProvider);
    setState(() => _busyId = existing?.id ?? 'new');
    try {
      final repo = ref.read(fiveSAuditSectionRepositoryProvider);
      final parentId = existing?.fkParentSectionId ?? parent?.id;
      final payload = buildSectionPayload(
        companyId: ctx.companyId!,
        auditTypeId: ctx.auditTypeId!,
        sectionName: name,
        parentSectionId: parentId,
        noOfQuestions: questions,
        totalMarks: marks,
        sectionOrder: order,
      );
      if (existing == null) {
        await repo.create(payload);
      } else {
        await repo.update(
          id: existing.id,
          companyId: ctx.companyId!,
          auditTypeId: ctx.auditTypeId!,
          payload: payload,
        );
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

  Future<void> _delete(FiveSAuditSection section) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete section?'),
        content: Text('Delete "${section.displayLabel}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ctx = ref.read(fiveSSettingsContextProvider);
    setState(() => _busyId = section.id);
    try {
      await ref.read(fiveSAuditSectionRepositoryProvider).delete(
            id: section.id,
            companyId: ctx.companyId!,
            auditTypeId: ctx.auditTypeId!,
          );
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
