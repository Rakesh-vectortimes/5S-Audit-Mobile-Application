import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../five_s_config/data/models/five_s_config_models.dart';
import '../../five_s_config/presentation/five_s_audit_config_controller.dart';
import '../../org/data/models/org_models.dart';

class FiveSSettingsContextState extends Equatable {
  const FiveSSettingsContextState({
    this.company,
    this.branch,
    this.floor,
    this.location,
    this.auditType,
  });

  final Company? company;
  final Branch? branch;
  final Floor? floor;
  final Location? location;
  final FiveSAuditType? auditType;

  String? get companyId => company?.id;
  String? get auditTypeId => auditType?.id;

  bool get hasCompany => companyId != null && companyId!.isNotEmpty;
  bool get hasCompanyAndType =>
      hasCompany && auditTypeId != null && auditTypeId!.isNotEmpty;

  FiveSSettingsContextState copyWith({
    Company? company,
    Branch? branch,
    Floor? floor,
    Location? location,
    FiveSAuditType? auditType,
    bool clearCompany = false,
    bool clearBranch = false,
    bool clearFloor = false,
    bool clearLocation = false,
    bool clearAuditType = false,
  }) {
    return FiveSSettingsContextState(
      company: clearCompany ? null : (company ?? this.company),
      branch: clearBranch ? null : (branch ?? this.branch),
      floor: clearFloor ? null : (floor ?? this.floor),
      location: clearLocation ? null : (location ?? this.location),
      auditType: clearAuditType ? null : (auditType ?? this.auditType),
    );
  }

  @override
  List<Object?> get props => [company, branch, floor, location, auditType];
}

class FiveSSettingsContextController
    extends StateNotifier<FiveSSettingsContextState> {
  FiveSSettingsContextController(this._ref)
      : super(const FiveSSettingsContextState());

  final Ref _ref;

  void selectCompany(Company? company) {
    state = state.copyWith(
      company: company,
      clearCompany: company == null,
      clearBranch: true,
      clearFloor: true,
      clearLocation: true,
      clearAuditType: true,
    );
  }

  void selectBranch(Branch? branch) {
    state = state.copyWith(
      branch: branch,
      clearBranch: branch == null,
      clearFloor: true,
      clearLocation: true,
    );
  }

  void selectFloor(Floor? floor) {
    state = state.copyWith(
      floor: floor,
      clearFloor: floor == null,
      clearLocation: true,
    );
  }

  void selectLocation(Location? location) {
    state = state.copyWith(
      location: location,
      clearLocation: location == null,
    );
  }

  void selectAuditType(FiveSAuditType? type) {
    state = state.copyWith(
      auditType: type,
      clearAuditType: type == null,
    );
  }

  /// Invalidate assessment config cache after settings mutations.
  Future<void> refreshConfigCache() async {
    final companyId = state.companyId;
    final auditTypeId = state.auditTypeId;
    final config = _ref.read(fiveSAuditConfigControllerProvider.notifier);
    config.invalidate();
    if (companyId != null &&
        companyId.isNotEmpty &&
        auditTypeId != null &&
        auditTypeId.isNotEmpty) {
      await config.load(
        companyId: companyId,
        auditTypeId: auditTypeId,
        force: true,
      );
    }
  }
}

final fiveSSettingsContextProvider =
    StateNotifierProvider<FiveSSettingsContextController, FiveSSettingsContextState>(
  (ref) => FiveSSettingsContextController(ref),
);
