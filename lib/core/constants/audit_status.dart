/// Backend 5S audit status values (`draft` | `published`).
/// Submitted audits are stored as [AuditStatus.published].
enum AuditStatus {
  draft,
  published,
  archived,
  completed;

  /// Value stored/sent by the API.
  String get apiValue {
    switch (this) {
      case AuditStatus.draft:
        return 'draft';
      case AuditStatus.published:
        return 'published';
      case AuditStatus.archived:
        return 'archived';
      case AuditStatus.completed:
        return 'completed';
    }
  }

  /// UI label. Backend `published` is shown as Submitted.
  String get label {
    switch (this) {
      case AuditStatus.draft:
        return 'Draft';
      case AuditStatus.published:
        return 'Submitted';
      case AuditStatus.archived:
        return 'Archived';
      case AuditStatus.completed:
        return 'Completed';
    }
  }

  /// UI filter / mapper string (`submitted` for published).
  String get uiValue =>
      this == AuditStatus.published ? AuditStatusMapper.submitted : apiValue;

  bool get isSubmitted =>
      this == AuditStatus.published || this == AuditStatus.completed;

  bool get canEdit => this == AuditStatus.draft;

  static AuditStatus fromApi(Object? value) {
    switch ((value ?? '').toString().toLowerCase().trim()) {
      case 'published':
      case 'submitted':
        return AuditStatus.published;
      case 'archived':
        return AuditStatus.archived;
      case 'completed':
        return AuditStatus.completed;
      case 'draft':
      default:
        return AuditStatus.draft;
    }
  }
}

/// Maps UI audit status labels to API values.
/// UI "submitted" ↔ API "published"; drafts use "draft".
abstract final class AuditStatusMapper {
  static const draft = 'draft';
  static const published = 'published';
  static const submitted = 'submitted';

  static String toApi(String? uiStatus) => AuditStatus.fromApi(uiStatus).apiValue;

  static String toUi(String? apiStatus) => AuditStatus.fromApi(apiStatus).uiValue;

  /// List filter: UI `submitted` → API `published`.
  static String? toApiFilter(String? uiStatus) {
    if (uiStatus == null || uiStatus.isEmpty || uiStatus.toLowerCase() == 'all') {
      return null;
    }
    return toApi(uiStatus);
  }

  static bool isSubmitted(Object? status) {
    if (status is AuditStatus) return status.isSubmitted;
    return AuditStatus.fromApi(status).isSubmitted;
  }
}
