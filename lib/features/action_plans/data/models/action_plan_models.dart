import 'package:equatable/equatable.dart';

import '../../../../core/network/image_url.dart';
import '../../../../core/network/list_response.dart';
import '../action_plan_utils.dart';

class ActionPlanSummary extends Equatable {
  const ActionPlanSummary({
    this.open = 0,
    this.submitted = 0,
    this.overdue = 0,
    this.closed = 0,
  });

  final int open;
  final int submitted;
  final int overdue;
  final int closed;

  factory ActionPlanSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ActionPlanSummary();
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    return ActionPlanSummary(
      open: asInt(json['open']),
      submitted: asInt(json['submitted']),
      overdue: asInt(json['overdue']),
      closed: asInt(json['closed']),
    );
  }

  static ActionPlanSummary? extract(dynamic data) {
    if (data is! Map) return null;
    final map = Map<String, dynamic>.from(data);
    final summary = map['summary'];
    if (summary is! Map) return null;
    return ActionPlanSummary.fromJson(Map<String, dynamic>.from(summary));
  }

  @override
  List<Object?> get props => [open, submitted, overdue, closed];
}

class ActionPlanProofImage extends Equatable {
  const ActionPlanProofImage({
    this.fileName,
    this.uploadUrl,
    this.fileType,
    this.fileSize,
    this.imageUrl,
    this.capturedAt,
  });

  final String? fileName;
  final String? uploadUrl;
  final String? fileType;
  final int? fileSize;
  final String? imageUrl;
  final String? capturedAt;

  String get displayUrl => resolveMediaUrl({
        'image_url': imageUrl,
        'uploadurl': uploadUrl,
      });

  factory ActionPlanProofImage.fromJson(Map<String, dynamic> json) {
    final upload =
        (json['uploadurl'] ?? json['upload_url'])?.toString().trim() ?? '';
    final imageUrlRaw =
        (json['image_url'] ?? json['question_image_url'])?.toString().trim() ?? '';
    final built = imageUrlRaw.isNotEmpty
        ? imageUrlRaw
        : buildImageUrlFromUploadurl(upload);

    return ActionPlanProofImage(
      fileName: (json['file_name'] as String?)?.trim(),
      uploadUrl: upload.isEmpty ? null : upload,
      fileType: (json['file_type'] as String?)?.trim(),
      fileSize: json['file_size'] is num ? (json['file_size'] as num).toInt() : null,
      imageUrl: built.isEmpty ? null : built,
      capturedAt: (json['captured_at'] as String?)?.trim(),
    );
  }

  Map<String, dynamic> toUploadJson() => {
        if (fileName != null && fileName!.isNotEmpty) 'file_name': fileName,
        if (uploadUrl != null && uploadUrl!.isNotEmpty) 'uploadurl': uploadUrl,
        if (fileType != null && fileType!.isNotEmpty) 'file_type': fileType,
        if (fileSize != null) 'file_size': fileSize,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
        if (capturedAt != null && capturedAt!.isNotEmpty) 'captured_at': capturedAt,
      };

  @override
  List<Object?> get props => [fileName, uploadUrl, imageUrl, capturedAt];
}

class ActionPlanRecord extends Equatable {
  const ActionPlanRecord({
    required this.id,
    this.actionId,
    this.actionPlanCode,
    this.companyId,
    this.companyName,
    this.auditTypeId,
    this.auditTypeName,
    this.locationId,
    this.locationName,
    this.assessmentId,
    this.assessmentCode,
    this.questionId,
    this.questionText,
    this.sectionName,
    this.subSectionName,
    this.sectionOrderLabel,
    this.subSectionOrderLabel,
    this.status = ActionPlanStatus.open,
    this.priority,
    this.assigneeId,
    this.assigneeName,
    this.assigneeIds = const [],
    this.assigneeNames = const [],
    this.auditDate,
    this.dueDate,
    this.dueDateReason,
    this.delayedByDays,
    this.notes,
    this.defaultValue,
  });

  final String id;
  final String? actionId;
  final String? actionPlanCode;
  final String? companyId;
  final String? companyName;
  final String? auditTypeId;
  final String? auditTypeName;
  final String? locationId;
  final String? locationName;
  final String? assessmentId;
  final String? assessmentCode;
  final int? questionId;
  final String? questionText;
  final String? sectionName;
  final String? subSectionName;
  final String? sectionOrderLabel;
  final String? subSectionOrderLabel;
  final ActionPlanStatus status;
  final ActionPlanPriority? priority;
  final String? assigneeId;
  final String? assigneeName;
  final List<String> assigneeIds;
  final List<String> assigneeNames;
  final String? auditDate;
  final String? dueDate;
  final String? dueDateReason;
  final int? delayedByDays;
  final String? notes;
  final String? defaultValue;

  String get displayCode =>
      (actionPlanCode?.trim().isNotEmpty == true
          ? actionPlanCode!
          : (actionId?.trim().isNotEmpty == true ? actionId! : id));

  String get assigneesLabel {
    if (assigneeNames.isNotEmpty) return assigneeNames.join(', ');
    return assigneeName?.trim().isNotEmpty == true ? assigneeName! : '—';
  }

  factory ActionPlanRecord.fromJson(Map<String, dynamic> json) {
    final ids = normalizeAssigneeIds(json['assignee_ids'], json['assignee_id']);
    final names =
        normalizeAssigneeNames(json['assignee_names'], json['assignee_name']);
    return ActionPlanRecord(
      id: ListResponse.extractId(json),
      actionId: (json['action_plan_code'] as String?) ??
          (json['action_id'] as String?) ??
          (json['action_code'] as String?),
      actionPlanCode: json['action_plan_code'] as String?,
      companyId: normalizeEntityId(json['company_id']),
      companyName: json['company_name'] as String?,
      auditTypeId: normalizeEntityId(
        json['audit_type_id'] ?? json['fk_audit_type_id'],
      ),
      auditTypeName: (json['audit_type_name'] as String?) ??
          (json['audit_name'] as String?),
      locationId: normalizeEntityId(json['location_id']),
      locationName: json['location_name'] as String?,
      assessmentId: normalizeEntityId(json['assessment_id']),
      assessmentCode: (json['assessment_code'] as String?) ??
          (json['audit_code'] as String?) ??
          (json['audit_id'] as String?),
      questionId: json['question_id'] is num
          ? (json['question_id'] as num).toInt()
          : int.tryParse('${json['question_id']}'),
      questionText: json['question_text'] as String?,
      sectionName: _trimOrNull(
        json['main_section_name'] ?? json['section_name'] ?? json['category'],
      ),
      subSectionName:
          _trimOrNull(json['sub_section_name'] ?? json['sub_category']),
      sectionOrderLabel: json['section_order_label']?.toString(),
      subSectionOrderLabel: json['sub_section_order_label']?.toString(),
      status: ActionPlanStatusX.fromApi(json['status']),
      priority: ActionPlanPriorityX.fromApi(json['priority']),
      assigneeId: ids.isEmpty ? null : ids.first,
      assigneeName: names.isEmpty ? null : names.join(', '),
      assigneeIds: ids,
      assigneeNames: names,
      auditDate: _dateOrNull(json['audit_date']),
      dueDate: _dateOrNull(json['due_date']),
      dueDateReason: _trimOrNull(json['due_date_reason'] ?? json['reason']),
      delayedByDays: json['delayed_by_days'] is num
          ? (json['delayed_by_days'] as num).toInt()
          : int.tryParse('${json['delayed_by_days']}'),
      notes: json['notes'] as String?,
      defaultValue: json['default_value'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, status, dueDate, priority];
}

class ActionPlanDetail extends ActionPlanRecord {
  const ActionPlanDetail({
    required super.id,
    super.actionId,
    super.actionPlanCode,
    super.companyId,
    super.companyName,
    super.auditTypeId,
    super.auditTypeName,
    super.locationId,
    super.locationName,
    super.assessmentId,
    super.assessmentCode,
    super.questionId,
    super.questionText,
    super.sectionName,
    super.subSectionName,
    super.sectionOrderLabel,
    super.subSectionOrderLabel,
    super.status,
    super.priority,
    super.assigneeId,
    super.assigneeName,
    super.assigneeIds,
    super.assigneeNames,
    super.auditDate,
    super.dueDate,
    super.dueDateReason,
    super.delayedByDays,
    super.notes,
    super.defaultValue,
    this.questionComments,
    this.questionImages = const [],
    this.actionRequired,
    this.response,
    this.proofImages = const [],
    this.canUpdate,
  });

  final String? questionComments;
  final List<ActionPlanProofImage> questionImages;
  final String? actionRequired;
  final String? response;
  final List<ActionPlanProofImage> proofImages;
  final bool? canUpdate;

  factory ActionPlanDetail.fromJson(Map<String, dynamic> json) {
    final base = ActionPlanRecord.fromJson(json);
    final proofRaw = json['proof_images'];
    final proofImages = proofRaw is List
        ? proofRaw
            .whereType<Object>()
            .map((e) => ActionPlanProofImage.fromJson(
                  e is Map<String, dynamic>
                      ? e
                      : Map<String, dynamic>.from(e as Map),
                ))
            .toList()
        : <ActionPlanProofImage>[];

    List<ActionPlanProofImage> questionImages = const [];
    final qi = json['question_images'];
    if (qi is List) {
      questionImages = qi
          .whereType<Object>()
          .map((e) => ActionPlanProofImage.fromJson(
                e is Map<String, dynamic>
                    ? e
                    : Map<String, dynamic>.from(e as Map),
              ))
          .toList();
    }

    final canUpdateRaw = json['can_update'];
    bool? canUpdate;
    if (canUpdateRaw == true) canUpdate = true;
    if (canUpdateRaw == false) canUpdate = false;

    final actionRequired = _trimOrNull(
      json['action_required'] ??
          json['notes'] ??
          json['default_value'] ??
          base.notes ??
          base.defaultValue,
    );

    return ActionPlanDetail(
      id: base.id,
      actionId: base.actionId,
      actionPlanCode: base.actionPlanCode,
      companyId: base.companyId,
      companyName: base.companyName,
      auditTypeId: base.auditTypeId,
      auditTypeName: base.auditTypeName,
      locationId: base.locationId,
      locationName: base.locationName,
      assessmentId: base.assessmentId,
      assessmentCode: base.assessmentCode,
      questionId: base.questionId,
      questionText: base.questionText,
      sectionName: base.sectionName,
      subSectionName: base.subSectionName,
      sectionOrderLabel: base.sectionOrderLabel,
      subSectionOrderLabel: base.subSectionOrderLabel,
      status: base.status,
      priority: base.priority,
      assigneeId: base.assigneeId,
      assigneeName: base.assigneeName,
      assigneeIds: base.assigneeIds,
      assigneeNames: base.assigneeNames,
      auditDate: base.auditDate,
      dueDate: base.dueDate,
      dueDateReason: base.dueDateReason,
      delayedByDays: base.delayedByDays,
      notes: base.notes,
      defaultValue: base.defaultValue,
      questionComments: _trimOrNull(
        json['question_comments'] ?? json['comments'] ?? json['audit_comments'],
      ),
      questionImages: questionImages,
      actionRequired: actionRequired,
      response: _trimOrNull(json['response'] ?? json['assignee_response']),
      proofImages: proofImages,
      canUpdate: canUpdate,
    );
  }

  ActionPlanDetail copyWith({
    ActionPlanStatus? status,
    String? response,
    List<ActionPlanProofImage>? proofImages,
    String? dueDate,
    String? dueDateReason,
    int? delayedByDays,
    bool? canUpdate,
  }) {
    return ActionPlanDetail(
      id: id,
      actionId: actionId,
      actionPlanCode: actionPlanCode,
      companyId: companyId,
      companyName: companyName,
      auditTypeId: auditTypeId,
      auditTypeName: auditTypeName,
      locationId: locationId,
      locationName: locationName,
      assessmentId: assessmentId,
      assessmentCode: assessmentCode,
      questionId: questionId,
      questionText: questionText,
      sectionName: sectionName,
      subSectionName: subSectionName,
      sectionOrderLabel: sectionOrderLabel,
      subSectionOrderLabel: subSectionOrderLabel,
      status: status ?? this.status,
      priority: priority,
      assigneeId: assigneeId,
      assigneeName: assigneeName,
      assigneeIds: assigneeIds,
      assigneeNames: assigneeNames,
      auditDate: auditDate,
      dueDate: dueDate ?? this.dueDate,
      dueDateReason: dueDateReason ?? this.dueDateReason,
      delayedByDays: delayedByDays ?? this.delayedByDays,
      notes: notes,
      defaultValue: defaultValue,
      questionComments: questionComments,
      questionImages: questionImages,
      actionRequired: actionRequired,
      response: response ?? this.response,
      proofImages: proofImages ?? this.proofImages,
      canUpdate: canUpdate ?? this.canUpdate,
    );
  }
}

class ActionPlanAuditGroup extends Equatable {
  const ActionPlanAuditGroup({
    required this.assessmentId,
    required this.assessmentCode,
    this.companyId,
    this.companyName,
    this.auditTypeId,
    this.auditName,
    this.title,
    this.locationId,
    this.locationName,
    this.auditDate,
    this.actionPlanCount = 0,
    this.openCount = 0,
    this.submittedCount = 0,
    this.overdueCount = 0,
    this.closedCount = 0,
  });

  final String assessmentId;
  final String assessmentCode;
  final String? companyId;
  final String? companyName;
  final String? auditTypeId;
  final String? auditName;
  final String? title;
  final String? locationId;
  final String? locationName;
  final String? auditDate;
  final int actionPlanCount;
  final int openCount;
  final int submittedCount;
  final int overdueCount;
  final int closedCount;

  factory ActionPlanAuditGroup.fromJson(Map<String, dynamic> json) {
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse('$v') ?? 0;
    }

    final assessmentId = normalizeEntityId(
          json['assessment_id'] ?? json['_id'] ?? json['id'],
        ) ??
        '';
    return ActionPlanAuditGroup(
      assessmentId: assessmentId,
      assessmentCode: (json['assessment_code'] ??
              json['audit_code'] ??
              json['assessment_id'] ??
              assessmentId)
          .toString(),
      companyId: normalizeEntityId(json['company_id']),
      companyName: json['company_name'] as String?,
      auditTypeId: normalizeEntityId(
        json['audit_type_id'] ?? json['fk_audit_type_id'],
      ),
      auditName: (json['audit_name'] as String?) ??
          (json['audit_type_name'] as String?) ??
          (json['title'] as String?),
      title: json['title'] as String?,
      locationId: normalizeEntityId(json['location_id']),
      locationName: json['location_name'] as String?,
      auditDate: _dateOrNull(json['audit_date']),
      actionPlanCount: asInt(json['action_plan_count']),
      openCount: asInt(json['open_count']),
      submittedCount: asInt(json['submitted_count']),
      overdueCount: asInt(json['overdue_count']),
      closedCount: asInt(json['closed_count']),
    );
  }

  @override
  List<Object?> get props => [assessmentId, actionPlanCount];
}

class ActionPlanAuditSubSection {
  const ActionPlanAuditSubSection({
    required this.subSectionName,
    this.sectionOrderLabel,
    this.actionPlans = const [],
  });

  final String subSectionName;
  final String? sectionOrderLabel;
  final List<ActionPlanRecord> actionPlans;

  factory ActionPlanAuditSubSection.fromJson(Map<String, dynamic> json) {
    final plansRaw = json['action_plans'];
    return ActionPlanAuditSubSection(
      subSectionName:
          (json['sub_section_name'] ?? json['sub_category'] ?? '').toString().trim(),
      sectionOrderLabel: (json['section_order_label'] ??
              json['sub_section_order_label'])
          ?.toString(),
      actionPlans: plansRaw is List
          ? plansRaw
              .whereType<Object>()
              .map((e) => ActionPlanRecord.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }
}

class ActionPlanAuditSection {
  const ActionPlanAuditSection({
    required this.sectionName,
    this.sectionOrderLabel,
    this.subSections = const [],
    this.actionPlans = const [],
  });

  final String sectionName;
  final String? sectionOrderLabel;
  final List<ActionPlanAuditSubSection> subSections;
  final List<ActionPlanRecord> actionPlans;

  factory ActionPlanAuditSection.fromJson(Map<String, dynamic> json) {
    final subRaw = json['sub_sections'];
    final plansRaw = json['action_plans'];
    return ActionPlanAuditSection(
      sectionName: (json['section_name'] ??
              json['main_section_name'] ??
              json['category'] ??
              'General')
          .toString()
          .trim(),
      sectionOrderLabel: json['section_order_label']?.toString(),
      subSections: subRaw is List
          ? subRaw
              .whereType<Object>()
              .map((e) => ActionPlanAuditSubSection.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
      actionPlans: plansRaw is List
          ? plansRaw
              .whereType<Object>()
              .map((e) => ActionPlanRecord.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }
}

class ActionPlanAuditDetail {
  const ActionPlanAuditDetail({
    required this.assessmentId,
    required this.assessmentCode,
    this.companyId,
    this.companyName,
    this.auditTypeId,
    this.auditName,
    this.title,
    this.locationId,
    this.locationName,
    this.auditDate,
    this.actionPlanCount = 0,
    this.sections = const [],
  });

  final String assessmentId;
  final String assessmentCode;
  final String? companyId;
  final String? companyName;
  final String? auditTypeId;
  final String? auditName;
  final String? title;
  final String? locationId;
  final String? locationName;
  final String? auditDate;
  final int actionPlanCount;
  final List<ActionPlanAuditSection> sections;

  factory ActionPlanAuditDetail.fromJson(Map<String, dynamic> json) {
    final assessmentId = normalizeEntityId(
          json['assessment_id'] ?? json['_id'] ?? json['id'],
        ) ??
        '';
    final sectionsRaw = json['sections'];
    return ActionPlanAuditDetail(
      assessmentId: assessmentId,
      assessmentCode: (json['assessment_code'] ??
              json['audit_code'] ??
              json['assessment_id'] ??
              assessmentId)
          .toString(),
      companyId: normalizeEntityId(json['company_id']),
      companyName: json['company_name'] as String?,
      auditTypeId: normalizeEntityId(
        json['audit_type_id'] ?? json['fk_audit_type_id'],
      ),
      auditName: (json['audit_name'] as String?) ??
          (json['audit_type_name'] as String?) ??
          (json['title'] as String?),
      title: json['title'] as String?,
      locationId: normalizeEntityId(json['location_id']),
      locationName: json['location_name'] as String?,
      auditDate: _dateOrNull(json['audit_date']),
      actionPlanCount: json['action_plan_count'] is num
          ? (json['action_plan_count'] as num).toInt()
          : int.tryParse('${json['action_plan_count']}') ?? 0,
      sections: sectionsRaw is List
          ? sectionsRaw
              .whereType<Object>()
              .map((e) => ActionPlanAuditSection.fromJson(
                    e is Map<String, dynamic>
                        ? e
                        : Map<String, dynamic>.from(e as Map),
                  ))
              .toList()
          : const [],
    );
  }
}

class PaginatedActionPlanAudits {
  const PaginatedActionPlanAudits({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
    this.summary,
  });

  final List<ActionPlanAuditGroup> items;
  final int total;
  final int page;
  final int limit;
  final int pages;
  final ActionPlanSummary? summary;
}

Map<String, dynamic> buildActionPlanUpdatePayload({
  required ActionPlanWorkStatus status,
  String? response,
  List<ActionPlanProofImage>? proofImages,
  String? dueDate,
  String? dueDateReason,
}) {
  return {
    'status': status.apiValue,
    if (response != null) 'response': response,
    if (proofImages != null)
      'proof_images': proofImages
          .where((p) => (p.uploadUrl ?? '').isNotEmpty)
          .map((p) => p.toUploadJson())
          .toList(),
    if (dueDate != null) 'due_date': dueDate,
    if (dueDateReason != null) 'due_date_reason': dueDateReason,
  };
}

String? _trimOrNull(Object? value) {
  final s = value?.toString().trim() ?? '';
  return s.isEmpty ? null : s;
}

String? _dateOrNull(Object? value) {
  if (value == null) return null;
  final s = value.toString().trim();
  if (s.isEmpty) return null;
  return s.split('T').first;
}
