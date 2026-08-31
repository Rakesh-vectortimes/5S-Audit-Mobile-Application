import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../data/action_plan_utils.dart';
import '../data/models/action_plan_models.dart';
import 'action_plan_audit_view_controller.dart';

class ActionPlanAuditViewPage extends ConsumerWidget {
  const ActionPlanAuditViewPage({super.key, required this.assessmentId});

  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(actionPlanAuditViewControllerProvider(assessmentId));
    final detail = state.detail;

    return Scaffold(
      appBar: AppBar(title: const Text('Audit action plans')),
      body: state.loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && detail == null
              ? Center(child: Text(state.errorMessage!))
              : detail == null
                  ? const Center(child: Text('Audit not found'))
                  : RefreshIndicator(
                      onRefresh: () => ref
                          .read(actionPlanAuditViewControllerProvider(assessmentId).notifier)
                          .load(assessmentId),
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            detail.title?.trim().isNotEmpty == true
                                ? detail.title!
                                : detail.assessmentCode,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(detail.assessmentCode),
                          Text(
                            [
                              detail.companyName ?? detail.companyId ?? '',
                              detail.locationName ?? '',
                              detail.auditName ?? '',
                              _fmt(detail.auditDate),
                            ].where((e) => e.trim().isNotEmpty).join(' · '),
                          ),
                          const SizedBox(height: 8),
                          Text('${detail.actionPlanCount} action plans'),
                          const SizedBox(height: 12),
                          for (final section in detail.sections)
                            ExpansionTile(
                              initiallyExpanded: true,
                              title: Text(
                                section.sectionOrderLabel == null
                                    ? section.sectionName
                                    : '${section.sectionOrderLabel} ${section.sectionName}',
                              ),
                              children: [
                                for (final sub in section.subSections) ...[
                                  ListTile(
                                    dense: true,
                                    title: Text(
                                      sub.sectionOrderLabel == null
                                          ? sub.subSectionName
                                          : '${sub.sectionOrderLabel} ${sub.subSectionName}',
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                  for (final plan in sub.actionPlans)
                                    _PlanRow(plan: plan),
                                ],
                                for (final plan in section.actionPlans)
                                  _PlanRow(plan: plan),
                              ],
                            ),
                        ],
                      ),
                    ),
    );
  }

  String _fmt(String? ymd) {
    if (ymd == null || ymd.isEmpty) return '';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(ymd));
    } catch (_) {
      return ymd;
    }
  }
}

class _PlanRow extends StatelessWidget {
  const _PlanRow({required this.plan});

  final ActionPlanRecord plan;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(plan.displayCode),
      subtitle: Text(
        [
          plan.questionText ?? '',
          plan.assigneesLabel,
          if (plan.dueDate != null) 'Due ${plan.dueDate}',
        ].where((e) => e.trim().isNotEmpty).join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _StatusChip(status: plan.status),
          if (plan.priority != null)
            Text(plan.priority!.label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
      onTap: () => context.push(AppRoutes.actionPlanDetailPath(plan.id)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final ActionPlanStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      ActionPlanStatus.closed => AppColors.success,
      ActionPlanStatus.overdue => AppColors.error,
      ActionPlanStatus.open => AppColors.warning,
      _ => AppColors.primary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}
