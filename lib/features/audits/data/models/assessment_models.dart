import 'package:equatable/equatable.dart';

import '../../../../core/constants/audit_status.dart';
import '../../../../core/network/list_response.dart';

class CompanyBackground extends Equatable {
  const CompanyBackground({
    this.companyId,
    this.companyName,
    this.companyIntroduction,
    this.location,
    this.locationId,
    this.totalWorkforce,
    this.shiftOperation,
    this.workingHours,
    this.workingDays,
    this.currency,
    this.currencySymbol,
  });

  final String? companyId;
  final String? companyName;
  final String? companyIntroduction;
  final String? location;
  final String? locationId;
  final dynamic totalWorkforce;
  final dynamic shiftOperation;
  final String? workingHours;
  final dynamic workingDays;
  final String? currency;
  final String? currencySymbol;

  factory CompanyBackground.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const CompanyBackground();
    return CompanyBackground(
      companyId: normalizeEntityId(json['company_id']),
      companyName: json['company_name'] as String?,
      companyIntroduction: json['company_introduction'] as String?,
      location: json['location'] as String?,
      locationId: normalizeEntityId(json['location_id']),
      totalWorkforce: json['total_workforce'],
      shiftOperation: json['shift_operation'],
      workingHours: json['working_hours']?.toString(),
      workingDays: json['working_days'],
      currency: json['currency'] as String?,
      currencySymbol: json['currency_symbol'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'company_id': companyId,
        'company_name': companyName ?? '',
        'company_introduction': companyIntroduction ?? '',
        'location': location ?? '',
        'location_id': locationId,
        'total_workforce': totalWorkforce,
        'shift_operation': shiftOperation,
        'working_hours': workingHours ?? '',
        'working_days': workingDays,
        'currency': currency ?? '',
        'currency_symbol': currencySymbol ?? '',
      };

  CompanyBackground copyWith({
    String? companyId,
    String? companyName,
    String? companyIntroduction,
    String? location,
    String? locationId,
    dynamic totalWorkforce,
    dynamic shiftOperation,
    String? workingHours,
    dynamic workingDays,
    String? currency,
    String? currencySymbol,
  }) {
    return CompanyBackground(
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyIntroduction: companyIntroduction ?? this.companyIntroduction,
      location: location ?? this.location,
      locationId: locationId ?? this.locationId,
      totalWorkforce: totalWorkforce ?? this.totalWorkforce,
      shiftOperation: shiftOperation ?? this.shiftOperation,
      workingHours: workingHours ?? this.workingHours,
      workingDays: workingDays ?? this.workingDays,
      currency: currency ?? this.currency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
    );
  }

  @override
  List<Object?> get props => [companyId, locationId, companyName];
}

class ActionPlanAnswer extends Equatable {
  const ActionPlanAnswer({
    this.notes = '',
    this.assigneeIds = const [],
    this.assigneeNames = const [],
    this.assigneeId,
    this.assigneeName,
    this.priority = 'medium',
    this.dueDate = '',
    this.completed = false,
  });

  final String notes;
  final List<String> assigneeIds;
  final List<String> assigneeNames;
  final String? assigneeId;
  final String? assigneeName;
  final String priority;
  final String dueDate;
  final bool completed;

  bool get hasAssignees =>
      assigneeIds.isNotEmpty || (assigneeId != null && assigneeId!.isNotEmpty);

  bool get isFilled => notes.trim().isNotEmpty && hasAssignees;

  bool get hasContent => completed || isFilled;

  factory ActionPlanAnswer.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ActionPlanAnswer();
    final ids = _normalizeAssigneeIds(json['assignee_ids'], json['assignee_id']);
    final names = _normalizeAssigneeNames(json['assignee_names'], json['assignee_name']);
    return ActionPlanAnswer(
      notes: (json['notes'] as String?)?.trim() ?? '',
      assigneeIds: ids,
      assigneeNames: names,
      assigneeId: ids.isNotEmpty ? ids.first : normalizeEntityId(json['assignee_id']),
      assigneeName: names.join(', '),
      priority: (json['priority'] as String?)?.trim().isNotEmpty == true
          ? (json['priority'] as String).trim()
          : 'medium',
      dueDate: (json['due_date'] as String?)?.trim() ?? '',
      completed: json['completed'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    final ids = assigneeIds.isNotEmpty
        ? assigneeIds
        : (assigneeId != null && assigneeId!.isNotEmpty ? [assigneeId!] : <String>[]);
    final names = assigneeNames.isNotEmpty
        ? assigneeNames
        : (assigneeName != null && assigneeName!.trim().isNotEmpty
            ? assigneeName!.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
            : <String>[]);
    return {
      'notes': notes,
      'assignee_ids': ids,
      'assignee_names': names,
      'assignee_id': ids.isNotEmpty ? ids.first : null,
      'assignee_name': names.join(', '),
      'priority': priority,
      if (dueDate.trim().isNotEmpty) 'due_date': dueDate.trim(),
      // Backend publish check: action_plan.completed == true (not notes/assignees).
      'completed': completed || isFilled,
    };
  }

  ActionPlanAnswer copyWith({
    String? notes,
    List<String>? assigneeIds,
    List<String>? assigneeNames,
    String? assigneeId,
    String? assigneeName,
    String? priority,
    String? dueDate,
    bool? completed,
  }) {
    return ActionPlanAnswer(
      notes: notes ?? this.notes,
      assigneeIds: assigneeIds ?? this.assigneeIds,
      assigneeNames: assigneeNames ?? this.assigneeNames,
      assigneeId: assigneeId ?? this.assigneeId,
      assigneeName: assigneeName ?? this.assigneeName,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
    );
  }

  @override
  List<Object?> get props => [notes, assigneeIds, priority, dueDate, completed];
}

class AssessmentResponse extends Equatable {
  const AssessmentResponse({
    required this.questionId,
    required this.category,
    this.subCategory,
    this.score,
    this.optionIndex,
    this.question,
    this.selectedResponse,
    this.comments,
    this.actionPlan,
  });

  final int questionId;
  final String category;
  final String? subCategory;
  final num? score;
  final int? optionIndex;
  final String? question;
  final String? selectedResponse;
  final String? comments;
  final ActionPlanAnswer? actionPlan;

  bool get isAnswered => score != null;

  factory AssessmentResponse.fromJson(Map<String, dynamic> json) {
    final optionRaw = json['option_index'] ?? json['selected_option_index'];
    int? optionIndex;
    if (optionRaw != null) {
      final parsed = int.tryParse(optionRaw.toString());
      if (parsed != null && parsed >= 0) optionIndex = parsed;
    }

    return AssessmentResponse(
      questionId: int.tryParse('${json['question_id']}') ?? 0,
      category: (json['category'] as String?)?.trim() ?? '',
      subCategory: (json['sub_category'] as String?)?.trim(),
      score: json['score'] == null ? null : num.tryParse('${json['score']}'),
      optionIndex: optionIndex,
      question: json['question'] as String?,
      selectedResponse:
          (json['selected_response'] as String?) ?? (json['response_text'] as String?),
      comments: json['comments'] as String?,
      actionPlan: json['action_plan'] is Map
          ? ActionPlanAnswer.fromJson(Map<String, dynamic>.from(json['action_plan'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson({bool includeActionPlan = true}) {
    final map = <String, dynamic>{
      'question_id': questionId,
      'category': category,
      'score': score,
      'option_index': optionIndex,
      'selected_option_index': optionIndex,
      if (question != null) 'question': question,
      if (selectedResponse != null) 'selected_response': selectedResponse,
      if (comments != null && comments!.trim().isNotEmpty) 'comments': comments!.trim(),
      if (subCategory != null && subCategory!.trim().isNotEmpty) 'sub_category': subCategory,
    };
    if (includeActionPlan && actionPlan != null) {
      map['action_plan'] = actionPlan!.toJson();
    }
    return map;
  }

  AssessmentResponse copyWith({
    int? questionId,
    String? category,
    String? subCategory,
    num? score,
    int? optionIndex,
    String? question,
    String? selectedResponse,
    String? comments,
    ActionPlanAnswer? actionPlan,
    bool clearActionPlan = false,
    bool clearScore = false,
  }) {
    return AssessmentResponse(
      questionId: questionId ?? this.questionId,
      category: category ?? this.category,
      subCategory: subCategory ?? this.subCategory,
      score: clearScore ? null : (score ?? this.score),
      optionIndex: optionIndex ?? this.optionIndex,
      question: question ?? this.question,
      selectedResponse: selectedResponse ?? this.selectedResponse,
      comments: comments ?? this.comments,
      actionPlan: clearActionPlan ? null : (actionPlan ?? this.actionPlan),
    );
  }

  @override
  List<Object?> get props => [questionId, score, optionIndex, actionPlan];
}

class FiveSAuditRecord extends Equatable {
  const FiveSAuditRecord({
    required this.id,
    this.companyId,
    this.auditTypeId,
    this.auditTypeName,
    this.companyName,
    this.title,
    this.reportDate,
    this.preparedBy,
    this.createdByName,
    this.createdByRole,
    this.updatedBy,
    this.status = 'draft',
    this.summary = '',
    this.sign = false,
    this.declarationSignature,
    this.companyBackground,
    this.responses = const [],
    this.createdAt,
    this.updatedAt,
    this.createdBy,
  });

  final String id;
  final String? companyId;
  final String? auditTypeId;
  final String? auditTypeName;
  final String? companyName;
  final String? title;
  final String? reportDate;
  final String? preparedBy;
  final String? createdByName;
  final String? createdByRole;
  final String? updatedBy;
  final String status; // UI status
  final String summary;
  final bool sign;
  final String? declarationSignature;
  final CompanyBackground? companyBackground;
  final List<AssessmentResponse> responses;
  final String? createdAt;
  final String? updatedAt;
  final dynamic createdBy;

  String get displayTitle =>
      (title?.trim().isNotEmpty == true)
          ? title!.trim()
          : (companyName?.trim().isNotEmpty == true ? companyName! : '5S Audit');

  factory FiveSAuditRecord.fromNormalizedJson(Map<String, dynamic> json) {
    // Caller should pass already-normalized map from mapper.
    return FiveSAuditRecord(
      id: ListResponse.extractId(json, preferredKeys: const ['assessment_id']),
      companyId: normalizeEntityId(json['company_id']),
      auditTypeId: normalizeEntityId(json['audit_type_id'] ?? json['fk_audit_type_id']),
      auditTypeName: json['audit_type_name'] as String? ?? json['audit_name'] as String?,
      companyName: json['company_name'] as String?,
      title: json['title'] as String?,
      reportDate: _formatDate(json['report_date']),
      preparedBy: json['prepared_by'] as String? ?? json['created_by_name'] as String?,
      createdByName: json['created_by_name'] as String?,
      createdByRole: json['created_by_role'] as String? ?? json['creator_role'] as String?,
      updatedBy: json['updated_by'] as String? ?? json['updated_by_name'] as String?,
      status: AuditStatusMapper.toUi(json['status']?.toString()),
      summary: (json['summary'] as String?) ?? '',
      sign: json['sign'] == true,
      declarationSignature: json['declaration_signature']?.toString(),
      companyBackground: json['company_background'] is Map
          ? CompanyBackground.fromJson(
              Map<String, dynamic>.from(json['company_background'] as Map),
            )
          : null,
      responses: (json['responses'] as List?)
              ?.whereType<Map>()
              .map((e) => AssessmentResponse.fromJson(Map<String, dynamic>.from(e)))
              .toList() ??
          const [],
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      createdBy: json['created_by'] ?? json['createdBy'],
    );
  }

  @override
  List<Object?> get props => [id, status, companyId, auditTypeId, reportDate];
}

class PaginatedAssessments {
  const PaginatedAssessments({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  final List<FiveSAuditRecord> items;
  final int total;
  final int page;
  final int limit;
  final int pages;
}

List<String> _normalizeAssigneeIds(Object? ids, Object? fallbackId) {
  final fromArray = <String>[];
  if (ids is List) {
    for (final id in ids) {
      final n = normalizeEntityId(id);
      if (n != null && n.isNotEmpty) fromArray.add(n);
    }
  }
  if (fromArray.isNotEmpty) return fromArray.toSet().toList();
  final single = normalizeEntityId(fallbackId);
  return single == null || single.isEmpty ? const [] : [single];
}

List<String> _normalizeAssigneeNames(Object? names, Object? fallbackName) {
  if (names is List) {
    return names.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList();
  }
  final single = (fallbackName ?? '').toString().trim();
  if (single.isEmpty) return const [];
  return single.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

String? _formatDate(Object? value) {
  if (value == null) return null;
  return value.toString().split('T').first;
}
