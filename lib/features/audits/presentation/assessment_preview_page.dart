import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../five_s_config/data/five_s_config_repositories.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/domain/section_hierarchy.dart';
import '../data/assessment_export_share.dart';
import '../data/assessment_repository.dart';
import '../data/models/assessment_models.dart';
import 'assessment_report_view.dart';

class AssessmentPreviewPage extends ConsumerStatefulWidget {
  const AssessmentPreviewPage({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  ConsumerState<AssessmentPreviewPage> createState() => _AssessmentPreviewPageState();
}

class _AssessmentPreviewPageState extends ConsumerState<AssessmentPreviewPage> {
  FiveSAuditRecord? _record;
  String? _auditTypeName;
  List<FlatAuditQuestion> _questions = const [];
  List<String> _sectionOrder = const [];
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
      final config = await _loadReportConfig(record);
      if (!mounted) return;
      setState(() {
        _record = record;
        _auditTypeName = config.typeName;
        _questions = config.questions;
        _sectionOrder = config.sectionOrder;
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

  Future<({String? typeName, List<FlatAuditQuestion> questions, List<String> sectionOrder})>
      _loadReportConfig(FiveSAuditRecord record) async {
    final companyId = record.companyId ?? record.companyBackground?.companyId;
    final auditTypeId = record.auditTypeId;
    if (companyId == null ||
        companyId.isEmpty ||
        auditTypeId == null ||
        auditTypeId.isEmpty) {
      return (
        typeName: record.auditTypeName,
        questions: const <FlatAuditQuestion>[],
        sectionOrder: const <String>[],
      );
    }

    String? typeName = record.auditTypeName;
    try {
      final types = await ref.read(fiveSAuditTypeRepositoryProvider).list(companyId: companyId);
      for (final type in types) {
        if (type.id == auditTypeId && type.auditName.trim().isNotEmpty) {
          typeName = type.auditName.trim();
          break;
        }
      }
    } catch (_) {
      // The cover title falls back to the name already on the audit.
    }

    try {
      final sections = await ref.read(fiveSAuditSectionRepositoryProvider).list(
            companyId: companyId,
            auditTypeId: auditTypeId,
          );
      final questionRepo = ref.read(fiveSAuditQuestionRepositoryProvider);
      var documents = await questionRepo.list(
        companyId: companyId,
        auditTypeId: auditTypeId,
      );
      if (documents.isEmpty && sections.isNotEmpty) {
        final byId = <String, FiveSAuditQuestionDocument>{};
        for (final section in sections) {
          try {
            final docs = await questionRepo.list(
              companyId: companyId,
              auditTypeId: auditTypeId,
              sectionId: section.id,
            );
            for (final doc in docs) {
              byId[doc.id.isEmpty ? section.id : doc.id] = doc;
            }
          } catch (_) {
            continue;
          }
        }
        documents = byId.values.toList();
      }
      final ordered = List<FiveSAuditSection>.from(sections)..sort(compareSectionsByOrder);
      return (
        typeName: typeName,
        questions: mapFlatQuestions(sections: ordered, documents: documents),
        sectionOrder: getTopLevelSections(ordered).map((section) => section.sectionName).toList(),
      );
    } catch (_) {
      return (
        typeName: typeName,
        questions: const <FlatAuditQuestion>[],
        sectionOrder: const <String>[],
      );
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
                  : AssessmentReportView(
                      record: record,
                      auditTypeName: _auditTypeName,
                      questions: _questions,
                      sectionOrder: _sectionOrder,
                    ),
    );
  }
}
