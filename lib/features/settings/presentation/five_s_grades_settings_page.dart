import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../five_s_config/data/five_s_config_repositories.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/data/settings_serialize.dart';
import 'five_s_settings_context.dart';

class FiveSGradesSettingsPage extends ConsumerStatefulWidget {
  const FiveSGradesSettingsPage({super.key});

  @override
  ConsumerState<FiveSGradesSettingsPage> createState() =>
      _FiveSGradesSettingsPageState();
}

class _FiveSGradesSettingsPageState
    extends ConsumerState<FiveSGradesSettingsPage> {
  List<FiveSAuditGrade> _items = const [];
  bool _loading = true;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(fiveSAuditGradeRepositoryProvider).list();
      items.sort((a, b) => (a.gradeOrder ?? 0).compareTo(b.gradeOrder ?? 0));
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
        _error = 'Failed to load grades';
        _loading = false;
      });
    }
  }

  Future<void> _openEditor([FiveSAuditGrade? existing]) async {
    final result = await showModalBottomSheet<_GradeFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _GradeEditorSheet(
        existing: existing,
        peerMaxScores: _items
            .where((g) => g.id != existing?.id)
            .map((g) => g.maxScore),
      ),
    );
    if (result == null || !mounted) return;

    setState(() => _busyId = existing?.id ?? 'new');
    try {
      final repo = ref.read(fiveSAuditGradeRepositoryProvider);
      final percentage = computeGradePercentage(
        maxScore: result.maxScore,
        peerMaxScores: _items
            .where((g) => g.id != existing?.id)
            .map((g) => g.maxScore)
            .followedBy([result.maxScore]),
      );
      final payload = buildGradePayload(
        gradingCriteria: result.criteria,
        score: result.score,
        minScore: result.minScore,
        maxScore: result.maxScore,
        percentage: result.percentage ?? percentage,
        gradeOrder: result.gradeOrder,
      );
      if (existing == null) {
        await repo.create(payload);
      } else {
        await repo.update(id: existing.id, payload: payload);
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

  Future<void> _delete(FiveSAuditGrade grade) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete grade?'),
        content: Text('Delete "${grade.gradingCriteria}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busyId = grade.id);
    try {
      await ref.read(fiveSAuditGradeRepositoryProvider).delete(grade.id);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'settings-grades-fab',
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
                        Center(child: Text('No grades yet')),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final g = _items[index];
                        final busy = _busyId == g.id;
                        return ListTile(
                          title: Text(g.gradingCriteria),
                          subtitle: Text(
                            'Score ${g.score ?? '—'} · ${g.minScore}–${g.maxScore} · ${g.percentage}%',
                          ),
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
                                      onPressed: () => _openEditor(g),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      onPressed: () => _delete(g),
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
}

class _GradeFormResult {
  const _GradeFormResult({
    required this.criteria,
    required this.score,
    required this.minScore,
    required this.maxScore,
    required this.gradeOrder,
    this.percentage,
  });

  final String criteria;
  final String score;
  final num minScore;
  final num maxScore;
  final int? gradeOrder;
  final num? percentage;
}

class _GradeEditorSheet extends StatefulWidget {
  const _GradeEditorSheet({this.existing, required this.peerMaxScores});

  final FiveSAuditGrade? existing;
  final Iterable<num> peerMaxScores;

  @override
  State<_GradeEditorSheet> createState() => _GradeEditorSheetState();
}

class _GradeEditorSheetState extends State<_GradeEditorSheet> {
  late final TextEditingController _criteria;
  late final TextEditingController _score;
  late final TextEditingController _min;
  late final TextEditingController _max;
  late final TextEditingController _order;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _criteria = TextEditingController(text: e?.gradingCriteria ?? '');
    _score = TextEditingController(text: e?.score ?? '');
    _min = TextEditingController(text: '${e?.minScore ?? 0}');
    _max = TextEditingController(text: '${e?.maxScore ?? 0}');
    _order = TextEditingController(text: e?.gradeOrder?.toString() ?? '');
  }

  @override
  void dispose() {
    _criteria.dispose();
    _score.dispose();
    _min.dispose();
    _max.dispose();
    _order.dispose();
    super.dispose();
  }

  void _submit() {
    final criteria = _criteria.text.trim();
    final min = num.tryParse(_min.text.trim());
    final max = num.tryParse(_max.text.trim());
    if (criteria.isEmpty) {
      setState(() => _error = 'Grading criteria is required');
      return;
    }
    if (min == null || max == null) {
      setState(() => _error = 'Min and max scores must be numbers');
      return;
    }
    if (min > max) {
      setState(() => _error = 'Min score must be ≤ max score');
      return;
    }
    final percentage = computeGradePercentage(
      maxScore: max,
      peerMaxScores: widget.peerMaxScores.followedBy([max]),
    );
    if (percentage < 0 || percentage > 100) {
      setState(() => _error = 'Percentage must be between 0 and 100');
      return;
    }
    Navigator.pop(
      context,
      _GradeFormResult(
        criteria: criteria,
        score: _score.text.trim(),
        minScore: min,
        maxScore: max,
        gradeOrder: int.tryParse(_order.text.trim()),
        percentage: percentage,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null ? 'New grade' : 'Edit grade',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(_error!, style: const TextStyle(color: AppColors.error)),
              ),
            TextField(controller: _criteria, decoration: const InputDecoration(labelText: 'Criteria *')),
            TextField(controller: _score, decoration: const InputDecoration(labelText: 'Score label')),
            TextField(controller: _min, decoration: const InputDecoration(labelText: 'Min score *'), keyboardType: TextInputType.number),
            TextField(controller: _max, decoration: const InputDecoration(labelText: 'Max score *'), keyboardType: TextInputType.number),
            TextField(controller: _order, decoration: const InputDecoration(labelText: 'Order'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
