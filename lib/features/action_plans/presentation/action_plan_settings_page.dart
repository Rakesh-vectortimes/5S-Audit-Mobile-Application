import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/audit_pickers.dart';
import '../../../shared/widgets/org_pickers.dart';
import 'action_plan_settings_controller.dart';

class ActionPlanSettingsPage extends ConsumerWidget {
  const ActionPlanSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(actionPlanSettingsControllerProvider);
    final controller = ref.read(actionPlanSettingsControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Action plan settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(state.errorMessage!, style: const TextStyle(color: AppColors.error)),
            ),
          if (state.successMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(state.successMessage!, style: const TextStyle(color: AppColors.success)),
            ),
          CompanyPicker(
            value: state.company,
            onChanged: controller.selectCompany,
          ),
          const SizedBox(height: 12),
          AuditTypePicker(
            companyId: state.company?.id,
            value: state.auditType,
            onChanged: controller.selectAuditType,
          ),
          const SizedBox(height: 16),
          if (state.loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else ...[
            TextFormField(
              key: ValueKey('high-${state.high}-${state.company?.id}-${state.auditType?.id}'),
              initialValue: '${state.high}',
              decoration: const InputDecoration(labelText: 'High priority due days'),
              keyboardType: TextInputType.number,
              onChanged: (v) => controller.setHigh(int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('med-${state.medium}-${state.company?.id}-${state.auditType?.id}'),
              initialValue: '${state.medium}',
              decoration: const InputDecoration(labelText: 'Medium priority due days'),
              keyboardType: TextInputType.number,
              onChanged: (v) => controller.setMedium(int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: ValueKey('low-${state.low}-${state.company?.id}-${state.auditType?.id}'),
              initialValue: '${state.low}',
              decoration: const InputDecoration(labelText: 'Low priority due days'),
              keyboardType: TextInputType.number,
              onChanged: (v) => controller.setLow(int.tryParse(v) ?? 0),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: state.saving ? null : () => controller.save(),
              child: state.saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save settings'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: state.company == null
                  ? () => context.go(AppRoutes.actionPlans)
                  : () {
                      final uri = Uri(
                        path: AppRoutes.actionPlans,
                        queryParameters: {
                          if (state.company != null) 'company_id': state.company!.id,
                          if (state.company?.companyName.isNotEmpty == true)
                            'company_name': state.company!.companyName,
                          if (state.auditType != null) 'audit_type_id': state.auditType!.id,
                          if (state.auditType?.auditName.isNotEmpty == true)
                            'audit_type_name': state.auditType!.auditName,
                        },
                      );
                      context.go(uri.toString());
                    },
              child: const Text('View action plans'),
            ),
          ],
        ],
      ),
    );
  }
}
