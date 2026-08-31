import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/location_and_assignee_pickers.dart';
import '../../five_s_config/data/five_s_config_repositories.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/data/settings_serialize.dart';
import '../../five_s_config/domain/section_hierarchy.dart';
import 'five_s_settings_context.dart';

List<FiveSAuditSection> questionTargetSections(List<FiveSAuditSection> sections) {
  final tops = getTopLevelSections(sections);
  final result = <FiveSAuditSection>[];
  for (final top in tops) {
    final kids = getChildSections(sections, top.id);
    if (kids.isEmpty) {
      result.add(top);
    } else {
      result.addAll(kids);
    }
  }
  return result;
}

class FiveSQuestionsSettingsPage extends ConsumerStatefulWidget {
  const FiveSQuestionsSettingsPage({super.key});

  @override
  ConsumerState<FiveSQuestionsSettingsPage> createState() =>
      _FiveSQuestionsSettingsPageState();
}

class _FiveSQuestionsSettingsPageState
    extends ConsumerState<FiveSQuestionsSettingsPage> {
  List<FiveSAuditSection> _sections = const [];
  List<FiveSAuditQuestionDocument> _docs = const [];
  bool _loading = false;
  String? _error;
  String? _loadedKey;

  @override
  Widget build(BuildContext context) {
    final ctx = ref.watch(fiveSSettingsContextProvider);
    if (!ctx.hasCompanyAndType) {
      return const Center(
        child: Text('Select company and audit type to manage questions.'),
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

    if (_loading && _sections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final targets = questionTargetSections(_sections);

    return Column(
      children: [
        if (_error != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_error!, style: const TextStyle(color: AppColors.error)),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            child: targets.isEmpty
                ? ListView(
                    children: const [
                      SizedBox(height: 80),
                      Center(child: Text('Create sections first')),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: targets.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final section = targets[index];
                      FiveSAuditQuestionDocument? doc;
                      for (final d in _docs) {
                        if (d.fkSectionId == section.id) {
                          doc = d;
                          break;
                        }
                      }
                      return Card(
                        child: ListTile(
                          title: Text(section.displayLabel),
                          subtitle: Text(
                            doc == null
                                ? 'No question document'
                                : '${doc.questions.length} questions',
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => _QuestionDocumentEditorPage(
                                  section: section,
                                  document: doc,
                                ),
                              ),
                            );
                            await _refresh();
                          },
                        ),
                      );
                    },
                  ),
          ),
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
      final sections = await ref.read(fiveSAuditSectionRepositoryProvider).list(
            companyId: ctx.companyId!,
            auditTypeId: ctx.auditTypeId!,
          );
      final docs = await ref.read(fiveSAuditQuestionRepositoryProvider).list(
            companyId: ctx.companyId!,
            auditTypeId: ctx.auditTypeId!,
          );
      if (!mounted) return;
      setState(() {
        _sections = sections;
        _docs = docs;
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
        _error = 'Failed to load questions';
        _loading = false;
      });
    }
  }
}

class _QuestionDocumentEditorPage extends ConsumerStatefulWidget {
  const _QuestionDocumentEditorPage({
    required this.section,
    required this.document,
  });

  final FiveSAuditSection section;
  final FiveSAuditQuestionDocument? document;

  @override
  ConsumerState<_QuestionDocumentEditorPage> createState() =>
      _QuestionDocumentEditorPageState();
}

class _QuestionDocumentEditorPageState
    extends ConsumerState<_QuestionDocumentEditorPage> {
  late List<FiveSAuditQuestionItem> _questions;
  String? _docId;
  bool _saving = false;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _docId = widget.document?.id;
    _questions = List.of(widget.document?.questions ?? const []);
  }

  int _nextQuestionId() {
    var maxId = 0;
    for (final q in _questions) {
      if (q.questionId > maxId) maxId = q.questionId;
    }
    return maxId + 1;
  }

  Future<void> _save() async {
    final ctx = ref.read(fiveSSettingsContextProvider);
    setState(() => _saving = true);
    try {
      final repo = ref.read(fiveSAuditQuestionRepositoryProvider);
      final payload = buildQuestionDocumentPayload(
        companyId: ctx.companyId!,
        auditTypeId: ctx.auditTypeId!,
        sectionId: widget.section.id,
        questions: _questions,
      );
      final saved = _docId == null || _docId!.isEmpty
          ? await repo.create(payload)
          : await repo.update(
              id: _docId!,
              companyId: ctx.companyId!,
              auditTypeId: ctx.auditTypeId!,
              payload: payload,
            );
      _docId = saved.id;
      _questions = List.of(saved.questions);
      await ref.read(fiveSSettingsContextProvider.notifier).refreshConfigCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Questions saved')),
      );
      setState(() {});
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deleteDoc() async {
    if (_docId == null || _docId!.isEmpty) {
      Navigator.pop(context);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete question document?'),
        content: const Text('This removes all questions for this section.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final ctx = ref.read(fiveSSettingsContextProvider);
    try {
      await ref.read(fiveSAuditQuestionRepositoryProvider).delete(
            id: _docId!,
            companyId: ctx.companyId!,
            auditTypeId: ctx.auditTypeId!,
          );
      await ref.read(fiveSSettingsContextProvider.notifier).refreshConfigCache();
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _editQuestion([FiveSAuditQuestionItem? existing, int? index]) async {
    final edited = await showModalBottomSheet<FiveSAuditQuestionItem>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _QuestionEditorSheet(
        existing: existing,
        companyId: ref.read(fiveSSettingsContextProvider).companyId,
        nextId: _nextQuestionId(),
        onUploadImage: _uploadImage,
        uploading: _uploading,
      ),
    );
    if (edited == null) return;
    setState(() {
      if (index == null) {
        _questions = [..._questions, edited];
      } else {
        final next = [..._questions];
        next[index] = edited;
        _questions = next;
      }
    });
  }

  Future<FiveSAuditQuestionImage?> _uploadImage(XFile file) async {
    final ctx = ref.read(fiveSSettingsContextProvider);
    final bytes = await file.length();
    final mime = file.mimeType ?? _guessMime(file.path);
    final error = validateQuestionImage(mimeType: mime, sizeBytes: bytes);
    if (error != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
      return null;
    }
    setState(() => _uploading = true);
    try {
      return await ref.read(fiveSAuditQuestionRepositoryProvider).uploadQuestionImage(
            companyId: ctx.companyId!,
            auditTypeId: ctx.auditTypeId!,
            filePath: file.path,
            fileName: file.name,
          );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  String? _guessMime(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.section.displayLabel),
        actions: [
          IconButton(
            tooltip: 'Delete document',
            onPressed: _saving ? null : _deleteDoc,
            icon: const Icon(Icons.delete_outline),
          ),
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'settings-questions-fab',
        onPressed: () => _editQuestion(),
        child: const Icon(Icons.add),
      ),
      body: _questions.isEmpty
          ? const Center(child: Text('No questions — tap + to add'))
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: _questions.length,
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final item = _questions.removeAt(oldIndex);
                  _questions.insert(newIndex, item);
                });
              },
              itemBuilder: (context, index) {
                final q = _questions[index];
                return Card(
                  key: ValueKey('q-${q.questionId}-$index'),
                  child: ListTile(
                    title: Text(q.question.isEmpty ? 'Question ${q.questionId}' : q.question),
                    subtitle: Text(
                      '${q.options.length} options'
                      '${q.actionPlan?.enabled == true ? ' · action plan' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => _questions = [..._questions]..removeAt(index));
                      },
                    ),
                    onTap: () => _editQuestion(q, index),
                  ),
                );
              },
            ),
    );
  }
}

class _QuestionEditorSheet extends StatefulWidget {
  const _QuestionEditorSheet({
    this.existing,
    required this.companyId,
    required this.nextId,
    required this.onUploadImage,
    required this.uploading,
  });

  final FiveSAuditQuestionItem? existing;
  final String? companyId;
  final int nextId;
  final Future<FiveSAuditQuestionImage?> Function(XFile file) onUploadImage;
  final bool uploading;

  @override
  State<_QuestionEditorSheet> createState() => _QuestionEditorSheetState();
}

class _QuestionEditorSheetState extends State<_QuestionEditorSheet> {
  late final TextEditingController _text;
  late final TextEditingController _defaultValue;
  late bool _mandatory;
  late bool _comments;
  late bool _apEnabled;
  late bool _apMandatory;
  late List<FiveSAuditQuestionOption> _options;
  late List<FiveSAuditQuestionImage> _images;
  late List<String> _assigneeIds;
  late List<String> _assigneeNames;
  late Set<int> _triggerIndexes;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _text = TextEditingController(text: e?.question ?? '');
    _defaultValue = TextEditingController(text: e?.actionPlan?.defaultValue ?? '');
    _mandatory = e?.isMandatory ?? true;
    _comments = e?.commentsEnabled ?? false;
    _apEnabled = e?.actionPlan?.enabled ?? false;
    _apMandatory = e?.actionPlan?.mandatory ?? false;
    _options = List.of(e?.options ?? const []);
    _images = List.of(e?.images ?? const []);
    _assigneeIds = List.of(e?.actionPlan?.defaultAssigneeIds ?? const []);
    _assigneeNames = List.of(e?.actionPlan?.defaultAssigneeNames ?? const []);
    _triggerIndexes = {...(e?.actionPlan?.triggerOptionIndexes ?? const [])};
  }

  @override
  void dispose() {
    _text.dispose();
    _defaultValue.dispose();
    super.dispose();
  }

  void _save() {
    if (_text.text.trim().isEmpty) return;
    final triggers = _triggerIndexes.toList()..sort();
    final triggerScores = triggers
        .where((i) => i >= 0 && i < _options.length)
        .map((i) => _options[i].score.toInt())
        .toList();
    Navigator.pop(
      context,
      FiveSAuditQuestionItem(
        questionId: widget.existing?.questionId ?? widget.nextId,
        question: _text.text.trim(),
        isMandatory: _mandatory,
        commentsEnabled: _comments,
        images: _images,
        options: _options,
        actionPlan: FiveSAuditQuestionActionPlan(
          enabled: _apEnabled,
          mandatory: _apMandatory,
          defaultAssigneeIds: _assigneeIds,
          defaultAssigneeNames: _assigneeNames,
          triggerOptionIndexes: triggers,
          triggerScores: triggerScores,
          defaultValue: _defaultValue.text.trim(),
        ),
      ),
    );
  }

  Future<void> _addOption() async {
    final scoreCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add option'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: scoreCtrl, decoration: const InputDecoration(labelText: 'Score'), keyboardType: TextInputType.number),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Add')),
        ],
      ),
    );
    final score = num.tryParse(scoreCtrl.text.trim()) ?? 0;
    final desc = descCtrl.text.trim();
    scoreCtrl.dispose();
    descCtrl.dispose();
    if (ok == true && desc.isNotEmpty) {
      setState(() => _options = [..._options, FiveSAuditQuestionOption(score: score, description: desc)]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'New question' : 'Edit question',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            TextField(
              controller: _text,
              decoration: const InputDecoration(labelText: 'Question *'),
              minLines: 2,
              maxLines: 4,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Mandatory'),
              value: _mandatory,
              onChanged: (v) => setState(() => _mandatory = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Comments enabled'),
              value: _comments,
              onChanged: (v) => setState(() => _comments = v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Options', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                TextButton(onPressed: _addOption, child: const Text('Add')),
              ],
            ),
            for (var i = 0; i < _options.length; i++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('${_options[i].score} — ${_options[i].description}'),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _options = [..._options]..removeAt(i);
                      _triggerIndexes.remove(i);
                    });
                  },
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Images', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (widget.uploading)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () async {
                      final file = await _picker.pickImage(source: ImageSource.gallery);
                      if (file == null) return;
                      final image = await widget.onUploadImage(file);
                      if (image != null) {
                        setState(() => _images = [..._images, image]);
                      }
                    },
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                  ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                for (final img in _images)
                  Chip(
                    label: Text(img.fileName ?? 'image'),
                    onDeleted: () {
                      setState(() => _images = _images.where((e) => e != img).toList());
                    },
                  ),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Action plan'),
              value: _apEnabled,
              onChanged: (v) => setState(() => _apEnabled = v),
            ),
            if (_apEnabled) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Action plan mandatory'),
                value: _apMandatory,
                onChanged: (v) => setState(() => _apMandatory = v),
              ),
              Text('Trigger options', style: Theme.of(context).textTheme.bodyMedium),
              for (var i = 0; i < _options.length; i++)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(_options[i].description),
                  value: _triggerIndexes.contains(i),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _triggerIndexes.add(i);
                      } else {
                        _triggerIndexes.remove(i);
                      }
                    });
                  },
                ),
              MultiAssigneePicker(
                clientCompanyId: widget.companyId,
                selectedIds: _assigneeIds,
                onChanged: (users) {
                  setState(() {
                    _assigneeIds = users.map((u) => u.id).toList();
                    _assigneeNames = users.map((u) => u.displayName).toList();
                  });
                },
              ),
              TextField(
                controller: _defaultValue,
                decoration: const InputDecoration(labelText: 'Default action value'),
              ),
            ],
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Apply')),
          ],
        ),
      ),
    );
  }
}
