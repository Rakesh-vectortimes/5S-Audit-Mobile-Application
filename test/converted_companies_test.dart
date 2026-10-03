import 'package:flutter_test/flutter_test.dart';
import 'package:five_s_audit/core/constants/crm_conversion_type.dart';
import 'package:five_s_audit/features/org/data/converted_companies.dart';
import 'package:five_s_audit/features/org/data/models/org_models.dart';

void main() {
  const catalog = [
    Company(id: 'c1', companyName: 'AFFAN SHOES'),
    Company(id: 'c2', companyName: 'KH Exports India (P) Ltd - FWD'),
    Company(id: 'c3', companyName: 'Not converted'),
  ];

  test('matches CRM deals to companies by id then name', () {
    final resolved = resolveConvertedCompanies(
      deals: const [
        {
          'deal_id': 'd1',
          'company_id': 'c2',
          'company_name': 'KH Exports India (P) Ltd - FWD',
          'converted_to': 3,
        },
        {
          'deal_id': 'd2',
          'company_name': 'affan shoes',
          'converted_to': 3,
        },
        {
          'deal_id': 'd3',
          'company_name': 'Unknown Co',
          'converted_to': 3,
        },
      ],
      catalog: catalog,
    );

    expect(resolved.map((c) => c.id), ['c1', 'c2']);
  });

  test('uses company_id when the catalog does not have that row', () {
    final resolved = resolveConvertedCompanies(
      deals: const [
        {
          'company_id': 'crm-9',
          'company_name': 'Cup Couture',
          'converted_to': 3,
        },
      ],
      catalog: catalog,
    );
    expect(resolved, hasLength(1));
    expect(resolved.single.id, 'crm-9');
    expect(resolved.single.companyName, 'Cup Couture');
  });

  test('5S Audit conversion type is backend value 3', () {
    expect(CrmConversionType.fiveSAudit.apiValue, 3);
  });
}
