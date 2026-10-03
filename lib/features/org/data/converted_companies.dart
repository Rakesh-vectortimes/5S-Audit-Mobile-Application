import '../../../core/network/list_response.dart';
import 'models/org_models.dart';

/// Maps CRM deal-dependency rows onto `/companies` records.
List<Company> resolveConvertedCompanies({
  required List<Map<String, dynamic>> deals,
  required List<Company> catalog,
}) {
  final byId = <String, Company>{};
  final byOrgId = <String, Company>{};
  final byName = <String, Company>{};

  for (final company in catalog) {
    if (company.id.isNotEmpty) byId[company.id] = company;
    final orgId = company.orgCompanyId?.trim() ?? '';
    if (orgId.isNotEmpty) byOrgId[orgId] = company;
    final name = company.companyName.trim().toLowerCase();
    if (name.isNotEmpty) byName[name] = company;
  }

  final seen = <String>{};
  final resolved = <Company>[];

  for (final deal in deals) {
    final name = (deal['company_name'] as String?)?.trim() ??
        (deal['name'] as String?)?.trim() ??
        '';
    final companyId = normalizeEntityId(deal['company_id']);
    final orgCompanyId = normalizeEntityId(deal['org_company_id']);

    Company? match;
    if (companyId != null && companyId.isNotEmpty) {
      match = byId[companyId] ?? byOrgId[companyId];
    }
    if (match == null && orgCompanyId != null && orgCompanyId.isNotEmpty) {
      match = byId[orgCompanyId] ?? byOrgId[orgCompanyId];
    }
    if (match == null && name.isNotEmpty) {
      match = byName[name.toLowerCase()];
    }
    if (match == null && companyId != null && companyId.isNotEmpty) {
      match = Company(id: companyId, companyName: name);
    }
    if (match == null || match.id.isEmpty) continue;
    if (!seen.add(match.id)) continue;
    resolved.add(match);
  }

  resolved.sort(
    (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );
  return resolved;
}
