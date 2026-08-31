import 'package:equatable/equatable.dart';

/// Authenticated user + permission flags from `/auth/me` and login payload.
class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.mobileNumber,
    this.role,
    this.status,
    this.companyId,
    this.parentCompanyId,
    this.childCompanyId,
    this.clientCompanyId,
    this.companyType,
    this.canWriteReports = false,
    this.canViewReports = false,
    this.show5sAuditSettings = false,
    this.showActionPlanSettings = false,
    this.showBranches = false,
    this.canManageBranches = false,
    this.showFloors = false,
    this.canManageFloors = false,
    this.showLeaveCalendarSettings = false,
    this.canManageLeaveCalendar = false,
    this.showScheduleAudits = true,
    this.canManageScheduleAudits = false,
    this.customRoleId,
    this.permissions,
    this.permissionOverrides,
    this.isClientCompanyEmployee = false,
    this.profileImage,
    this.digitalSignature,
  });

  final String id;
  final String name;
  final String email;
  final String? mobileNumber;
  final String? role;
  final String? status;
  final String? companyId;
  final String? parentCompanyId;
  final String? childCompanyId;
  final String? clientCompanyId;
  final String? companyType;
  final bool canWriteReports;
  final bool canViewReports;
  final bool show5sAuditSettings;
  final bool showActionPlanSettings;
  final bool showBranches;
  final bool canManageBranches;
  final bool showFloors;
  final bool canManageFloors;
  final bool showLeaveCalendarSettings;
  final bool canManageLeaveCalendar;
  final bool showScheduleAudits;
  final bool canManageScheduleAudits;
  final String? customRoleId;
  final dynamic permissions;
  final Map<String, dynamic>? permissionOverrides;
  final bool isClientCompanyEmployee;
  final String? profileImage;
  final String? digitalSignature;

  bool get showAnySettings => show5sAuditSettings || showActionPlanSettings;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _readId(json),
      name: (json['name'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      mobileNumber: json['mobile_number'] as String?,
      role: json['role'] as String?,
      status: json['status'] as String?,
      companyId: _asString(json['company_id']),
      parentCompanyId: _asString(json['parent_company_id']),
      childCompanyId: _asString(json['child_company_id']),
      clientCompanyId: _asString(json['client_company_id']),
      companyType: json['company_type'] as String?,
      canWriteReports: _asBool(json['can_write_reports']),
      canViewReports: _asBool(json['can_view_reports']),
      show5sAuditSettings: _asBool(json['show_5s_audit_settings']),
      showActionPlanSettings: _asBool(json['show_action_plan_settings']),
      showBranches: _asBool(json['show_branches']),
      canManageBranches: _asBool(json['can_manage_branches']),
      showFloors: _asBool(json['show_floors']),
      canManageFloors: _asBool(json['can_manage_floors']),
      showLeaveCalendarSettings: _asBool(json['show_leave_calendar_settings']),
      canManageLeaveCalendar: _asBool(json['can_manage_leave_calendar']),
      showScheduleAudits: json.containsKey('show_schedule_audits')
          ? _asBool(json['show_schedule_audits'])
          : true,
      canManageScheduleAudits: json.containsKey('can_manage_schedule_audits')
          ? _asBool(json['can_manage_schedule_audits'])
          : _asBool(json['can_write_reports']),
      customRoleId: _asString(json['custom_role_id']),
      permissions: json['permissions'],
      permissionOverrides: _asStringKeyedMap(json['permission_overrides']),
      isClientCompanyEmployee: _asBool(json['is_client_company_employee']),
      profileImage: json['profile_image'] as String?,
      digitalSignature: json['digital_signature'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'mobile_number': mobileNumber,
        'role': role,
        'status': status,
        'company_id': companyId,
        'parent_company_id': parentCompanyId,
        'child_company_id': childCompanyId,
        'client_company_id': clientCompanyId,
        'company_type': companyType,
        'can_write_reports': canWriteReports,
        'can_view_reports': canViewReports,
        'show_5s_audit_settings': show5sAuditSettings,
        'show_action_plan_settings': showActionPlanSettings,
        'show_branches': showBranches,
        'can_manage_branches': canManageBranches,
        'show_floors': showFloors,
        'can_manage_floors': canManageFloors,
        'show_leave_calendar_settings': showLeaveCalendarSettings,
        'can_manage_leave_calendar': canManageLeaveCalendar,
        'show_schedule_audits': showScheduleAudits,
        'can_manage_schedule_audits': canManageScheduleAudits,
        'custom_role_id': customRoleId,
        'permissions': permissions,
        'permission_overrides': permissionOverrides,
        'is_client_company_employee': isClientCompanyEmployee,
        'profile_image': profileImage,
        'digital_signature': digitalSignature,
      };

  static String _readId(Map<String, dynamic> json) {
    final id = json['id'] ?? json['_id'];
    if (id == null) return '';
    return id.toString();
  }

  static String? _asString(Object? value) {
    if (value == null) return null;
    final s = value.toString();
    return s.isEmpty ? null : s;
  }

  static bool _asBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final lower = value.toLowerCase();
      return lower == 'true' || lower == '1';
    }
    return false;
  }

  static Map<String, dynamic>? _asStringKeyedMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return null;
  }

  @override
  List<Object?> get props => [id, email, role, companyId, canWriteReports, canViewReports];
}

/// Tokens (+ optional user) returned by login / refresh.
class AuthTokens extends Equatable {
  const AuthTokens({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    this.user,
  });

  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final User? user;

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    return AuthTokens(
      accessToken: json['access_token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String? ?? 'bearer',
      user: userRaw is Map<String, dynamic>
          ? User.fromJson(userRaw)
          : userRaw is Map
              ? User.fromJson(Map<String, dynamic>.from(userRaw))
              : null,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, user];
}
