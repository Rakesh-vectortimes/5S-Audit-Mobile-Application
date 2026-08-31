import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/assessment_export_share.dart';
import '../data/assessment_repository.dart';
import '../data/models/assessment_models.dart';

class AssessmentPreviewPage extends ConsumerStatefulWidget {
  const AssessmentPreviewPage({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  ConsumerState<AssessmentPreviewPage> createState() => _AssessmentPreviewPageState();
}

class _AssessmentPreviewPageState extends ConsumerState<AssessmentPreviewPage> {
  FiveSAuditRecord? _record;
  String? _error;
  bool _loading = true;
  bool _exportingPdf = false;
  bool _exportingWord = false;

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
      final record = await ref
          .read(fiveSAuditAssessmentRepositoryProvider)
          .getById(widget.assessmentId);
      if (!mounted) return;
      setState(() {
        _record = record;
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
        _error = 'Failed to load audit';
        _loading = false;
      });
    }
  }

  Future<void> _export({required bool pdf}) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.canViewReports && !auth.isAuthenticated) {
      _snack('You do not have permission to export reports.');
      return;
    }
    final record = _record;
    if (record == null) return;

    setState(() {
      if (pdf) {
        _exportingPdf = true;
      } else {
        _exportingWord = true;
      }
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
          _exportingPdf = false;
          _exportingWord = false;
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
    final canExport = auth.canViewReports || auth.isAuthenticated;
    final record = _record;
    final exporting = _exportingPdf || _exportingWord;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit preview'),
        actions: [
          if (canExport && record != null) ...[
            IconButton(
              tooltip: 'Export PDF',
              onPressed: exporting ? null : () => _export(pdf: true),
              icon: _exportingPdf
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.picture_as_pdf_outlined),
            ),
            IconButton(
              tooltip: 'Export Word',
              onPressed: exporting ? null : () => _export(pdf: false),
              icon: _exportingWord
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.description_outlined),
            ),
          ],
        ],
      ),
      bottomNavigationBar: canExport && record != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: exporting ? null : () => _export(pdf: true),
                        icon: _exportingPdf
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Export PDF'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: exporting ? null : () => _export(pdf: false),
                        icon: _exportingWord
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.description_outlined),
                        label: const Text('Export Word'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : record == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        Text(record.displayTitle, style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 8),
                        Text('Status: ${record.status}'),
                        Text('Audit type: ${record.auditTypeName ?? '-'}'),
                        Text('Report date: ${record.reportDate ?? '-'}'),
                        Text('Prepared by: ${record.preparedBy ?? record.createdByName ?? '-'}'),
                        const Divider(height: 28),
                        Text('Company background', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text('Company: ${record.companyName ?? record.companyBackground?.companyName ?? '-'}'),
                        Text('Location: ${record.companyBackground?.location ?? '-'}'),
                        Text('Workforce: ${record.companyBackground?.totalWorkforce ?? '-'}'),
                        Text('Shifts: ${record.companyBackground?.shiftOperation ?? '-'}'),
                        Text('Hours: ${record.companyBackground?.workingHours ?? '-'}'),
                        const Divider(height: 28),
                        Text('Responses', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        if (record.responses.isEmpty)
                          const Text('No responses')
                        else
                          ...record.responses.map(
                            (r) => Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(r.question ?? 'Q${r.questionId}'),
                                subtitle: Text(
                                  [
                                    r.category,
                                    if (r.subCategory != null && r.subCategory!.isNotEmpty)
                                      r.subCategory!,
                                    'Score: ${r.score ?? '-'}',
                                    if (r.selectedResponse != null) r.selectedResponse!,
                                    if (r.comments != null && r.comments!.isNotEmpty)
                                      'Comments: ${r.comments}',
                                  ].join(' · '),
                                ),
                              ),
                            ),
                          ),
                        const Divider(height: 28),
                        Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(record.summary.isEmpty ? '-' : record.summary),
                        const SizedBox(height: 16),
                        Text('Signature', style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 6),
                        Text(record.sign ? 'Signed' : 'Not signed'),
                        if ((record.declarationSignature ?? '').startsWith('data:image'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.memory(
                              Uri.parse(record.declarationSignature!).data!.contentAsBytes(),
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          )
                        else if ((record.declarationSignature ?? '').startsWith('http'))
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Image.network(
                              record.declarationSignature!,
                              height: 120,
                              fit: BoxFit.contain,
                            ),
                          ),
                      ],
                    ),
    );
  }
}
