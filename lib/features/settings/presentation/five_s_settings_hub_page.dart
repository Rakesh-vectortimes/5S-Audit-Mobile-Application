import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/audit_pickers.dart';
import '../../../shared/widgets/org_pickers.dart';
import '../../auth/presentation/auth_controller.dart';
import 'five_s_audit_types_settings_page.dart';
import 'five_s_grades_settings_page.dart';
import 'five_s_questions_settings_page.dart';
import 'five_s_sections_settings_page.dart';
import 'five_s_settings_context.dart';

class FiveSSettingsHubPage extends ConsumerStatefulWidget {
  const FiveSSettingsHubPage({super.key, this.initialTab = 'grades'});

  final String initialTab;

  @override
  ConsumerState<FiveSSettingsHubPage> createState() => _FiveSSettingsHubPageState();
}

class _FiveSSettingsHubPageState extends ConsumerState<FiveSSettingsHubPage>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['grades', 'audit-types', 'sections', 'questions'];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    final index = _tabs.indexOf(widget.initialTab);
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: index < 0 ? 0 : index,
    );
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!mounted) return;
    setState(() {});
    if (_tabController.indexIsChanging) return;
    final tab = _tabs[_tabController.index];
    final target = AppRoutes.fiveSSettingsTab(tab);
    if (GoRouterState.of(context).uri.path != target) {
      context.replace(target);
    }
  }

  @override
  void didUpdateWidget(covariant FiveSSettingsHubPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final index = _tabs.indexOf(widget.initialTab);
      if (index >= 0 && index != _tabController.index) {
        _tabController.index = index;
      }
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.show5sAuditSettings) {
      return Scaffold(
        appBar: AppBar(title: const Text('5S Settings')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'You do not have permission to manage 5S audit settings.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final ctx = ref.watch(fiveSSettingsContextProvider);
    final ctxNotifier = ref.read(fiveSSettingsContextProvider.notifier);
    final needsType = _tabController.index >= 2; // sections / questions

    return Scaffold(
      appBar: AppBar(
        title: const Text('5S Settings'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.onPrimary,
          unselectedLabelColor: AppColors.onPrimary.withOpacity(0.72),
          indicatorColor: AppColors.onPrimary,
          tabs: const [
            Tab(text: 'Grades'),
            Tab(text: 'Audit types'),
            Tab(text: 'Sections'),
            Tab(text: 'Questions'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.actionPlanSettings),
            child: const Text('Due days', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.42,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  CompanyPicker(
                    value: ctx.company,
                    onChanged: ctxNotifier.selectCompany,
                  ),
                  const SizedBox(height: 12),
                  BranchFloorLocationCascade(
                    companyId: ctx.companyId,
                    branch: ctx.branch,
                    floor: ctx.floor,
                    location: ctx.location,
                    onBranchChanged: ctxNotifier.selectBranch,
                    onFloorChanged: ctxNotifier.selectFloor,
                    onLocationChanged: ctxNotifier.selectLocation,
                  ),
                  if (_tabController.index != 0) ...[
                    const SizedBox(height: 12),
                    AuditTypePicker(
                      companyId: ctx.companyId,
                      value: ctx.auditType,
                      onChanged: ctxNotifier.selectAuditType,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (needsType && !ctx.hasCompanyAndType)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                'Select company and audit type to manage this tab.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                FiveSGradesSettingsPage(),
                FiveSAuditTypesSettingsPage(),
                FiveSSectionsSettingsPage(),
                FiveSQuestionsSettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
