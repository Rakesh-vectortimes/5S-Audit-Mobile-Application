/// Named route paths for go_router.
abstract final class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const home = '/home';
  static const audits = '/home/audits';
  static const schedules = '/home/schedules';
  static const actionPlans = '/home/action-plans';
  static const more = '/home/more';

  static const auditCreate = '/audits/create';
  static String auditEditPath(String id) => '/audits/edit/$id';
  static String auditPreviewPath(String id) => '/audits/preview/$id';

  static const scheduleCreate = '/schedules/create';
  static String scheduleEditPath(String id) => '/schedules/edit/$id';

  static String actionPlanAuditPath(String assessmentId) =>
      '/action-plans/audits/$assessmentId';
  static String actionPlanDetailPath(String id) => '/action-plans/$id';
  static const actionPlanSettings = '/home/more/action-plan-settings';

  static const fiveSSettings = '/settings/5s';
  static String fiveSSettingsTab(String tab) => '/settings/5s/$tab';
}
