import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/action_plans/presentation/action_plan_audit_view_page.dart';
import '../../features/action_plans/presentation/action_plan_audits_list_page.dart';
import '../../features/action_plans/presentation/action_plan_detail_page.dart';
import '../../features/action_plans/presentation/action_plan_settings_page.dart';
import '../../features/audits/presentation/assessment_form_page.dart';
import '../../features/audits/presentation/assessment_list_page.dart';
import '../../features/audits/presentation/assessment_preview_page.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/home/presentation/home_shell.dart';
import '../../features/more/presentation/more_placeholder_page.dart';
import '../../features/schedules/presentation/schedule_form_page.dart';
import '../../features/schedules/presentation/schedule_list_page.dart';
import '../../features/settings/presentation/five_s_settings_hub_page.dart';
import 'app_routes.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      final onSplash = loc == AppRoutes.splash;
      final onLogin = loc == AppRoutes.login;

      switch (auth.status) {
        case AuthStatus.unknown:
          return onSplash ? null : AppRoutes.splash;
        case AuthStatus.loading:
          if (onSplash || onLogin) return null;
          return null;
        case AuthStatus.unauthenticated:
        case AuthStatus.error:
          return onLogin ? null : AppRoutes.login;
        case AuthStatus.authenticated:
          if (onSplash || onLogin) return AppRoutes.audits;
          return null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.auditCreate,
        builder: (context, state) => const AssessmentFormPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/audits/edit/:id',
        builder: (context, state) => AssessmentFormPage(
          assessmentId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/audits/preview/:id',
        builder: (context, state) => AssessmentPreviewPage(
          assessmentId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: AppRoutes.scheduleCreate,
        builder: (context, state) => const ScheduleFormPage(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/schedules/edit/:id',
        builder: (context, state) => ScheduleFormPage(
          scheduleId: state.pathParameters['id'],
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/action-plans/audits/:assessmentId',
        builder: (context, state) => ActionPlanAuditViewPage(
          assessmentId: state.pathParameters['assessmentId']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/action-plans/:id',
        builder: (context, state) => ActionPlanDetailPage(
          planId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/5s',
        redirect: (context, state) => AppRoutes.fiveSSettingsTab('grades'),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/5s/:tab',
        redirect: (context, state) {
          final auth = ref.read(authControllerProvider);
          if (!auth.isAuthenticated) return AppRoutes.login;
          if (!auth.show5sAuditSettings) return AppRoutes.more;
          final tab = state.pathParameters['tab'] ?? '';
          const allowed = {'grades', 'audit-types', 'sections', 'questions'};
          if (!allowed.contains(tab)) {
            return AppRoutes.fiveSSettingsTab('grades');
          }
          return null;
        },
        pageBuilder: (context, state) => NoTransitionPage<void>(
          key: const ValueKey('five-s-settings-hub'),
          child: FiveSSettingsHubPage(
            initialTab: state.pathParameters['tab'] ?? 'grades',
          ),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.audits,
                builder: (context, state) => const AssessmentListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.schedules,
                builder: (context, state) => const ScheduleListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.actionPlans,
                builder: (context, state) => const ActionPlanAuditsListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.more,
                builder: (context, state) => const MorePlaceholderPage(),
                routes: [
                  GoRoute(
                    path: 'action-plan-settings',
                    builder: (context, state) => const ActionPlanSettingsPage(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(this._ref) {
    _subscription = _ref.listen<AuthState>(
      authControllerProvider,
      (_, __) => notifyListeners(),
    );
  }

  final Ref _ref;
  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}
