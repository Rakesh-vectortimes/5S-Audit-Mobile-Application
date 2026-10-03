/// Backend `CrmConversionType` (`app/common/enums.py`).
enum CrmConversionType {
  vectorTimes(1),
  industrialTraining(2),
  fiveSAudit(3),
  lma(4),
  dsr(5);

  const CrmConversionType(this.apiValue);
  final int apiValue;
}
