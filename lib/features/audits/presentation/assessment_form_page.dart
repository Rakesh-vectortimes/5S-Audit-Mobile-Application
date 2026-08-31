import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/audit_pickers.dart';
import '../../../shared/widgets/location_and_assignee_pickers.dart';
import '../../../shared/widgets/org_pickers.dart';
import '../../../shared/widgets/signature_pad.dart';
import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/domain/section_hierarchy.dart';
import '../../five_s_config/presentation/five_s_audit_config_controller.dart';
import '../data/action_plan_helpers.dart';
import '../data/models/assessment_models.dart';
import 'assessment_form_controller.dart';

class AssessmentFormPage extends ConsumerStatefulWidget {
  const AssessmentFormPage({super.key, this.assessmentId});

  final String? assessmentId;

  @override
  ConsumerState<AssessmentFormPage> createState() => _AssessmentFormPageState();
}

class _AssessmentFormPageState extends ConsumerState<AssessmentFormPage> {
  final _pageController = PageController();
  int _stepIndex = 0;
  final _signatureKey = GlobalKey<SignaturePadState>();

  bool get _isEdit => widget.assessmentId != null && widget.assessmentId!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(assessmentFormControllerProvider.notifier);
      if (_isEdit) {
        controller.loadForEdit(widget.assessmentId!);
      } else {
        controller.resetForCreate();
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<_FormStep> _steps(List<AssessmentStep> assessmentSteps) {
    return [
      const _FormStep(kind: _StepKind.details, title: 'Details'),
      ...assessmentSteps.map(
        (s) => _FormStep(kind: _StepKind.questions, title: s.label, assessmentStep: s),
      ),
      const _FormStep(kind: _StepKind.review, title: 'Review & sign'),
    ];
  }

  Future<void> _pickDate() async {
    final form = ref.read(assessmentFormControllerProvider);
    final initial = DateTime.tryParse(form.reportDate ?? '') ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      final formatted =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      ref.read(assessmentFormControllerProvider.notifier).setReportDate(formatted);
    }
  }

  Future<void> _goTo(int index, int total) async {
    if (index < 0 || index >= total) return;
    setState(() => _stepIndex = index);
    if (!_pageController.hasClients) return;
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _goNext() async {
    final form = ref.read(assessmentFormControllerProvider);
    if (_stepIndex == 0 && form.company != null && form.auditType != null) {
      var config = ref.read(fiveSAuditConfigControllerProvider);
      if (config.status != FiveSConfigStatus.loaded ||
          config.flatQuestions.isEmpty) {
        await ref.read(fiveSAuditConfigControllerProvider.notifier).load(
              companyId: form.company!.id,
              auditTypeId: form.auditType!.id,
              force: true,
            );
        if (!mounted) return;
        config = ref.read(fiveSAuditConfigControllerProvider);
      }
      if (config.flatQuestions.isEmpty) {
        return;
      }
    }

    final steps = _steps(
      ref.read(fiveSAuditConfigControllerProvider).assessmentSteps,
    );
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await _goTo(_stepIndex + 1, steps.length);
  }

  Future<void> _saveDraft() async {
    final record = await ref.read(assessmentFormControllerProvider.notifier).saveDraft();
    if (!mounted) return;
    if (record != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft saved')),
      );
      context.pop(true);
    }
  }

  Future<void> _submit() async {
    final record = await ref.read(assessmentFormControllerProvider.notifier).submit();
    if (!mounted) return;
    if (record != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Audit submitted')),
      );
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(assessmentFormControllerProvider);
    final config = ref.watch(fiveSAuditConfigControllerProvider);
    final steps = _steps(config.assessmentSteps);
    final current = steps[_stepIndex.clamp(0, steps.length - 1)];
    final configError = config.errorMessage;
    final configLoading = config.status == FiveSConfigStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit audit' : 'New audit'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Step ${_stepIndex + 1}/${steps.length}: ${current.title}',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                Text(
                  '${((_stepIndex + 1) / steps.length * 100).round()}%',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
      body: form.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (form.errorMessage != null)
                  _FormBanner(message: form.errorMessage!, isError: true),
                if (configLoading)
                  const _FormBanner(message: 'Loading audit questions…'),
                if (!configLoading && configError != null)
                  _FormBanner(message: configError, isError: true),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: steps.length,
                    onPageChanged: (i) => setState(() => _stepIndex = i),
                    itemBuilder: (context, index) {
                      final step = steps[index];
                      switch (step.kind) {
                        case _StepKind.details:
                          return _DetailsStep(
                            form: form,
                            onPickDate: _pickDate,
                          );
                        case _StepKind.questions:
                          return _QuestionsStep(
                            assessmentStep: step.assessmentStep!,
                            form: form,
                            config: config,
                          );
                        case _StepKind.review:
                          return _ReviewStep(
                            form: form,
                            config: config,
                            signatureKey: _signatureKey,
                          );
                      }
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Row(
                      children: [
                        if (_stepIndex > 0)
                          OutlinedButton(
                            onPressed: form.saving
                                ? null
                                : () => _goTo(_stepIndex - 1, steps.length),
                            child: const Text('Back'),
                          ),
                        const Spacer(),
                        if (_stepIndex < steps.length - 1)
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(88, 48),
                            ),
                            onPressed: form.saving || configLoading
                                ? null
                                : _goNext,
                            child: const Text('Next'),
                          )
                        else ...[
                          OutlinedButton(
                            onPressed: form.saving ? null : _saveDraft,
                            child: const Text('Save draft'),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(88, 48),
                            ),
                            onPressed: form.saving ? null : _submit,
                            child: form.saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Submit'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _FormBanner extends StatelessWidget {
  const _FormBanner({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.error : AppColors.primary;
    return Material(
      color: color.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.hourglass_top,
              color: color,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: color, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StepKind { details, questions, review }

class _FormStep {
  const _FormStep({
    required this.kind,
    required this.title,
    this.assessmentStep,
  });

  final _StepKind kind;
  final String title;
  final AssessmentStep? assessmentStep;
}

class _DetailsStep extends ConsumerWidget {
  const _DetailsStep({required this.form, required this.onPickDate});

  final AssessmentFormState form;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(assessmentFormControllerProvider.notifier);
    final dateLabel = () {
      try {
        return DateFormat('dd MMM yyyy').format(DateTime.parse(form.reportDate!));
      } catch (_) {
        return form.reportDate ?? 'Select date';
      }
    }();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CompanyPicker(
          value: form.company,
          onChanged: controller.selectCompany,
        ),
        const SizedBox(height: 12),
        AuditTypePicker(
          companyId: form.company?.id,
          value: form.auditType,
          onChanged: controller.selectAuditType,
        ),
        const SizedBox(height: 12),
        BranchFloorLocationCascade(
          companyId: form.company?.id,
          branch: form.branch,
          floor: form.floor,
          location: form.location,
          onBranchChanged: controller.selectBranch,
          onFloorChanged: controller.selectFloor,
          onLocationChanged: controller.selectLocation,
        ),
        const SizedBox(height: 12),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Report date'),
          subtitle: Text(dateLabel),
          trailing: const Icon(Icons.calendar_today_outlined),
          onTap: onPickDate,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: form.title,
          decoration: const InputDecoration(labelText: 'Title'),
          onChanged: controller.setTitle,
        ),
        const SizedBox(height: 12),
        Text(
          'Company background (prefilled; editable)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: '${form.background.totalWorkforce ?? ''}',
          decoration: const InputDecoration(labelText: 'Workforce'),
          keyboardType: TextInputType.number,
          onChanged: (v) => controller.updateBackground(
            form.background.copyWith(totalWorkforce: int.tryParse(v) ?? v),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: '${form.background.shiftOperation ?? ''}',
          decoration: const InputDecoration(labelText: 'Shifts'),
          onChanged: (v) => controller.updateBackground(
            form.background.copyWith(shiftOperation: v),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: form.background.workingHours ?? '',
          decoration: const InputDecoration(labelText: 'Working hours'),
          onChanged: (v) => controller.updateBackground(
            form.background.copyWith(workingHours: v),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: '${form.background.workingDays ?? ''}',
          decoration: const InputDecoration(labelText: 'Working days'),
          onChanged: (v) => controller.updateBackground(
            form.background.copyWith(workingDays: v),
          ),
        ),
      ],
    );
  }
}

class _QuestionsStep extends ConsumerWidget {
  const _QuestionsStep({
    required this.assessmentStep,
    required this.form,
    required this.config,
  });

  final AssessmentStep assessmentStep;
  final AssessmentFormState form;
  final FiveSAuditConfigState config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questions = questionsForStep(config.flatQuestions, assessmentStep);
    final controller = ref.read(assessmentFormControllerProvider.notifier);

    num total = 0;
    num max = 0;
    var answered = 0;
    for (final q in questions) {
      final response = form.responses[q.id];
      final qMax = q.options.isEmpty
          ? 0
          : q.options.map((o) => o.score).reduce((a, b) => a > b ? a : b);
      max += qMax;
      if (response?.score != null) {
        answered++;
        total += response!.score!;
      }
    }
    final grade = gradeForScore(
      totalScore: total,
      maxScore: max,
      grades: config.grades,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Progress $answered/${questions.length} · Score $total / $max · Grade $grade',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (questions.isEmpty)
          const Text('No questions in this step.')
        else
          ...questions.map((q) {
            final response = form.responses[q.id];
            final triggered = isActionPlanTriggered(
              question: q,
              score: response?.score,
              optionIndex: response?.optionIndex,
            );
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      q.text,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (q.isMandatory)
                      const Text('Mandatory', style: TextStyle(fontSize: 12, color: AppColors.warning)),
                    const SizedBox(height: 8),
                    ...List.generate(q.options.length, (index) {
                      final option = q.options[index];
                      return RadioListTile<int>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text('${option.score} — ${option.description}'),
                        value: index,
                        groupValue: response?.optionIndex,
                        onChanged: (value) {
                          if (value != null) {
                            controller.answerQuestion(question: q, optionIndex: value);
                          }
                        },
                      );
                    }),
                    if (q.commentsEnabled) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: response?.comments ?? '',
                        decoration: const InputDecoration(labelText: 'Comments'),
                        maxLines: 2,
                        onChanged: (v) => controller.setComments(q.id, v),
                      ),
                    ],
                    if (triggered) ...[
                      const SizedBox(height: 10),
                      const Text('Action plan', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextFormField(
                        initialValue: response?.actionPlan?.notes ?? '',
                        decoration: const InputDecoration(labelText: 'Notes *'),
                        maxLines: 2,
                        onChanged: (v) {
                          final current = response?.actionPlan ?? const ActionPlanAnswer();
                          controller.setActionPlan(q.id, current.copyWith(notes: v));
                        },
                      ),
                      const SizedBox(height: 8),
                      MultiAssigneePicker(
                        clientCompanyId: form.company?.id,
                        selectedIds: response?.actionPlan?.assigneeIds ?? const [],
                        onChanged: (users) {
                          final current = response?.actionPlan ?? const ActionPlanAnswer();
                          controller.setActionPlan(
                            q.id,
                            current.copyWith(
                              assigneeIds: users.map((u) => u.id).toList(),
                              assigneeNames: users.map((u) => u.displayName).toList(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: response?.actionPlan?.priority ?? 'medium',
                        decoration: const InputDecoration(labelText: 'Priority'),
                        items: const [
                          DropdownMenuItem(value: 'high', child: Text('High')),
                          DropdownMenuItem(value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'low', child: Text('Low')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          final current = response?.actionPlan ?? const ActionPlanAnswer();
                          controller.setActionPlan(q.id, current.copyWith(priority: value));
                        },
                      ),
                      const SizedBox(height: 8),
                      InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Due date',
                          helperText: 'Set automatically from priority due days',
                        ),
                        child: Text(
                          _formatDueDate(
                            response?.actionPlan?.dueDate ??
                                controller.dueDateForPriority(
                                  response?.actionPlan?.priority,
                                ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _ReviewStep extends ConsumerWidget {
  const _ReviewStep({
    required this.form,
    required this.config,
    required this.signatureKey,
  });

  final AssessmentFormState form;
  final FiveSAuditConfigState config;
  final GlobalKey<SignaturePadState> signatureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(assessmentFormControllerProvider.notifier);
    num total = 0;
    num max = 0;
    for (final q in config.flatQuestions) {
      final response = form.responses[q.id];
      final qMax = q.options.isEmpty
          ? 0
          : q.options.map((o) => o.score).reduce((a, b) => a > b ? a : b);
      max += qMax;
      if (response?.score != null) total += response!.score!;
    }
    final grade = gradeForScore(
      totalScore: total,
      maxScore: max,
      grades: config.grades,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Score summary', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text('Total $total / $max · Grade $grade'),
        Text('Answered ${form.responses.values.where((r) => r.isAnswered).length}/${config.flatQuestions.length}'),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: form.summary,
          decoration: const InputDecoration(labelText: 'Summary'),
          maxLines: 4,
          onChanged: controller.setSummary,
        ),
        const SizedBox(height: 16),
        Text('Signature', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (form.declarationSignature.isNotEmpty)
          const Text('Signature captured', style: TextStyle(color: AppColors.success)),
        SignaturePad(
          key: signatureKey,
          onChanged: controller.setSignature,
        ),
      ],
    );
  }
}

String _formatDueDate(String iso) {
  final parsed = DateTime.tryParse(iso.trim());
  if (parsed == null) return iso.trim().isEmpty ? '—' : iso.trim();
  return DateFormat('dd-MM-yyyy').format(parsed);
}
