import 'package:equatable/equatable.dart';

import '../../../../core/network/list_response.dart';

class Company extends Equatable {
  const Company({
    required this.id,
    required this.companyName,
    this.location,
    this.address,
    this.currency,
    this.currencySymbol,
    this.totalWorkforce,
    this.shiftOperation,
    this.workingHours,
    this.workingDays,
    this.status,
    this.orgCompanyId,
  });

  final String id;
  final String companyName;
  final String? location;
  final String? address;
  final String? currency;
  final String? currencySymbol;
  final int? totalWorkforce;
  final String? shiftOperation;
  final String? workingHours;
  final dynamic workingDays;
  final String? status;
  final String? orgCompanyId;

  String get displayName => companyName.isEmpty ? id : companyName;

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: ListResponse.extractId(json, preferredKeys: const ['company_id']),
      companyName: (json['company_name'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          '',
      location: json['location'] as String?,
      address: json['address'] as String?,
      currency: json['currency'] as String?,
      currencySymbol: json['currency_symbol'] as String?,
      totalWorkforce: _asInt(json['total_workforce']),
      shiftOperation: json['shift_operation']?.toString(),
      workingHours: json['working_hours']?.toString(),
      workingDays: json['working_days'],
      status: json['status']?.toString(),
      orgCompanyId: normalizeEntityId(json['org_company_id']),
    );
  }

  @override
  List<Object?> get props => [id, companyName];
}

class Branch extends Equatable {
  const Branch({
    required this.id,
    required this.companyId,
    required this.branchName,
    this.branchCode,
    this.status,
  });

  final String id;
  final String companyId;
  final String branchName;
  final String? branchCode;
  final String? status;

  String get displayName => branchName.isEmpty ? id : branchName;

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: ListResponse.extractId(json, preferredKeys: const ['branch_id']),
      companyId: normalizeEntityId(json['company_id']) ?? '',
      branchName: (json['branch_name'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          '',
      branchCode: (json['branch_code'] as String?) ?? (json['code'] as String?),
      status: json['status']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, companyId, branchName];
}

class Floor extends Equatable {
  const Floor({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.floorName,
    this.floorCode,
    this.status,
  });

  final String id;
  final String companyId;
  final String branchId;
  final String floorName;
  final String? floorCode;
  final String? status;

  String get displayName => floorName.isEmpty ? id : floorName;

  factory Floor.fromJson(Map<String, dynamic> json) {
    return Floor(
      id: ListResponse.extractId(json, preferredKeys: const ['floor_id']),
      companyId: normalizeEntityId(json['company_id']) ?? '',
      branchId: normalizeEntityId(json['branch_id']) ?? '',
      floorName: (json['floor_name'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          '',
      floorCode: (json['floor_code'] as String?) ?? (json['code'] as String?),
      status: json['status']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, branchId, floorName];
}

class Location extends Equatable {
  const Location({
    required this.id,
    required this.companyId,
    required this.locationName,
    this.branchId,
    this.floorId,
    this.locationCode,
    this.timezone,
    this.fullAddress,
    this.status,
  });

  final String id;
  final String companyId;
  final String? branchId;
  final String? floorId;
  final String locationName;
  final String? locationCode;
  final String? timezone;
  final String? fullAddress;
  final String? status;

  String get displayName => locationName.isEmpty ? id : locationName;

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      id: ListResponse.extractId(json, preferredKeys: const ['location_id']),
      companyId: normalizeEntityId(json['company_id']) ?? '',
      branchId: normalizeEntityId(json['branch_id']),
      floorId: normalizeEntityId(json['floor_id']),
      locationName: (json['location_name'] as String?)?.trim() ??
          (json['name'] as String?)?.trim() ??
          '',
      locationCode:
          (json['location_code'] as String?) ?? (json['code'] as String?),
      timezone: json['timezone'] as String?,
      fullAddress: json['full_address'] as String?,
      status: json['status']?.toString(),
    );
  }

  @override
  List<Object?> get props => [id, companyId, locationName];
}

class AssigneeUser extends Equatable {
  const AssigneeUser({
    required this.id,
    required this.name,
    this.email,
    this.clientCompanyId,
    this.role,
    this.status,
    this.employeeId,
  });

  final String id;
  final String name;
  final String? email;
  final String? clientCompanyId;
  final String? role;
  final String? status;
  final String? employeeId;

  String get displayName {
    if (name.isNotEmpty) return name;
    if (email != null && email!.isNotEmpty) return email!;
    return id;
  }

  factory AssigneeUser.fromJson(Map<String, dynamic> json) {
    return AssigneeUser(
      id: ListResponse.extractId(
        json,
        preferredKeys: const ['user_id', 'employee_id'],
      ),
      name: (json['name'] as String?)?.trim() ?? '',
      email: json['email'] as String?,
      clientCompanyId: normalizeEntityId(json['client_company_id']),
      role: json['role']?.toString(),
      status: json['status']?.toString(),
      employeeId: normalizeEntityId(json['employee_id']),
    );
  }

  @override
  List<Object?> get props => [id, name, clientCompanyId];
}

int? _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
