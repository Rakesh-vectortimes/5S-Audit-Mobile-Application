/// Maps UI audit status labels to API values.
/// UI "submitted" ↔ API "published"; drafts use "draft".
abstract final class AuditStatusMapper {
  static const draft = 'draft';
  static const published = 'published';
  static const submitted = 'submitted';

  static String toApi(String? uiStatus) {
    final status = (uiStatus ?? '').toLowerCase().trim();
    if (status == submitted || status == published) {
      return published;
    }
    return draft;
  }

  static String toUi(String? apiStatus) {
    final status = (apiStatus ?? '').toLowerCase().trim();
    if (status == published) return submitted;
    if (status == draft || status == 'archived' || status == 'completed') {
      return status == draft ? draft : status;
    }
    return draft;
  }

  /// List filter: UI `submitted` → API `published`.
  static String? toApiFilter(String? uiStatus) {
    if (uiStatus == null || uiStatus.isEmpty || uiStatus.toLowerCase() == 'all') {
      return null;
    }
    return toApi(uiStatus);
  }
}
