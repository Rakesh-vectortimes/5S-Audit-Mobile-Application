import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_get_helper.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/network/list_response.dart';
import 'models/org_models.dart';

class CompanyRepository with ApiGetHelper {
  CompanyRepository(this.dio);

  @override
  final Dio dio;

  Future<List<Company>> list({
    int page = 1,
    int limit = 100,
    String? search,
    String? status,
  }) {
    return getList(
      '/companies',
      queryParameters: {
        'page': page,
        'limit': limit,
        'search': search,
        'status': status,
      },
      fromJson: Company.fromJson,
      fallbackMessage: 'Failed to load companies',
    );
  }

  Future<Company> getById(String id) {
    return getObject(
      '/companies/$id',
      fromJson: Company.fromJson,
      fallbackMessage: 'Failed to load company',
    );
  }
}

class BranchRepository with ApiGetHelper {
  BranchRepository(this.dio);

  @override
  final Dio dio;

  Future<List<Branch>> listDependency({
    required String companyId,
    String? search,
    String status = 'active',
  }) {
    return getList(
      '/branches/dependency',
      queryParameters: {
        'company_id': companyId,
        'search': search,
        'status': status,
      },
      fromJson: Branch.fromJson,
      fallbackMessage: 'Failed to load branches',
    );
  }
}

class FloorRepository with ApiGetHelper {
  FloorRepository(this.dio);

  @override
  final Dio dio;

  Future<List<Floor>> listDependency({
    String? companyId,
    String? branchId,
    String? search,
    String status = 'active',
  }) {
    return getList(
      '/floors/dependency',
      queryParameters: {
        'company_id': companyId,
        'branch_id': branchId,
        'search': search,
        'status': status,
      },
      fromJson: Floor.fromJson,
      fallbackMessage: 'Failed to load floors',
    );
  }
}

class LocationRepository with ApiGetHelper {
  LocationRepository(this.dio);

  @override
  final Dio dio;

  Future<List<Location>> listDependency({
    String? companyId,
    String? branchId,
    String? floorId,
    String? search,
    String status = 'active',
  }) {
    return getList(
      '/locations/dependency',
      queryParameters: {
        'company_id': companyId,
        'branch_id': branchId,
        'floor_id': floorId,
        'search': search,
        'status': status,
      },
      fromJson: Location.fromJson,
      fallbackMessage: 'Failed to load locations',
    );
  }
}

class ClientEmployeeRepository with ApiGetHelper {
  ClientEmployeeRepository(this.dio);

  @override
  final Dio dio;

  Future<List<AssigneeUser>> listDependency({
    String? clientCompanyId,
    String status = 'active',
    String? search,
  }) async {
    final raw = await getRawData(
      '/client-company-employees/dependency',
      queryParameters: {
        'client_company_id': clientCompanyId,
        'status': status,
        'search': search,
      },
      fallbackMessage: 'Failed to load assignees',
    );
    return ListResponse.flattenAssigneeGroups(raw)
        .map(AssigneeUser.fromJson)
        .toList();
  }
}

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository(ref.watch(dioProvider));
});

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository(ref.watch(dioProvider));
});

final floorRepositoryProvider = Provider<FloorRepository>((ref) {
  return FloorRepository(ref.watch(dioProvider));
});

final locationRepositoryProvider = Provider<LocationRepository>((ref) {
  return LocationRepository(ref.watch(dioProvider));
});

final clientEmployeeRepositoryProvider = Provider<ClientEmployeeRepository>((ref) {
  return ClientEmployeeRepository(ref.watch(dioProvider));
});
