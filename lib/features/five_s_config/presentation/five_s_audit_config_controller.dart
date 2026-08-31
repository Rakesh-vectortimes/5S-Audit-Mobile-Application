import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../data/five_s_config_repositories.dart';
import '../data/models/five_s_config_models.dart';
import '../domain/section_hierarchy.dart' as hierarchy;

enum FiveSConfigStatus { idle, loading, loaded, error }

class FiveSAuditConfigState extends Equatable {
  const FiveSAuditConfigState({
    this.status = FiveSConfigStatus.idle,
    this.companyId,
    this.auditTypeId,
    this.sections = const [],
    this.questionDocuments = const [],
    this.flatQuestions = const [],
    this.grades = const [],
    this.assessmentSteps = const [],
    this.errorMessage,
  });

  final FiveSConfigStatus status;
  final String? companyId;
  final String? auditTypeId;
  final List<FiveSAuditSection> sections;
  final List<FiveSAuditQuestionDocument> questionDocuments;
  final List<FlatAuditQuestion> flatQuestions;
  final List<FiveSAuditGrade> grades;
  final List<AssessmentStep> assessmentSteps;
  final String? errorMessage;

  FiveSAuditConfigState copyWith({
    FiveSConfigStatus? status,
    String? companyId,
    String? auditTypeId,
    List<FiveSAuditSection>? sections,
    List<FiveSAuditQuestionDocument>? questionDocuments,
    List<FlatAuditQuestion>? flatQuestions,
    List<FiveSAuditGrade>? grades,
    List<AssessmentStep>? assessmentSteps,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FiveSAuditConfigState(
      status: status ?? this.status,
      companyId: companyId ?? this.companyId,
      auditTypeId: auditTypeId ?? this.auditTypeId,
      sections: sections ?? this.sections,
      questionDocuments: questionDocuments ?? this.questionDocuments,
      flatQuestions: flatQuestions ?? this.flatQuestions,
      grades: grades ?? this.grades,
      assessmentSteps: assessmentSteps ?? this.assessmentSteps,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
        status,
        companyId,
        auditTypeId,
        sections,
        questionDocuments,
        flatQuestions,
        grades,
        assessmentSteps,
        errorMessage,
      ];
}

class FiveSAuditConfigController extends StateNotifier<FiveSAuditConfigState> {
  FiveSAuditConfigController(this._ref) : super(const FiveSAuditConfigState());

  final Ref _ref;

  Future<bool> load({
    required String companyId,
    required String auditTypeId,
    bool force = false,
  }) async {
    final normalizedCompanyId = companyId.trim();
    final normalizedAuditTypeId = auditTypeId.trim();

    if (normalizedCompanyId.isEmpty || normalizedAuditTypeId.isEmpty) {
      state = const FiveSAuditConfigState(
        status: FiveSConfigStatus.error,
        errorMessage:
            'Company and audit type are required to load 5S audit configuration.',
      );
      return false;
    }

    if (!force &&
        state.status == FiveSConfigStatus.loaded &&
        state.companyId == normalizedCompanyId &&
        state.auditTypeId == normalizedAuditTypeId) {
      return true;
    }

    state = state.copyWith(
      status: FiveSConfigStatus.loading,
      clearError: true,
      companyId: normalizedCompanyId,
      auditTypeId: normalizedAuditTypeId,
    );

    try {
      var loadError = '';
      List<FiveSAuditSection> sectionsRaw = const [];
      List<FiveSAuditQuestionDocument> questionDocuments = const [];
      List<FiveSAuditGrade> gradesRaw = const [];

      try {
        sectionsRaw = await _ref.read(fiveSAuditSectionRepositoryProvider).list(
              companyId: normalizedCompanyId,
              auditTypeId: normalizedAuditTypeId,
            );
      } catch (e) {
        loadError = e is ApiException ? e.message : 'Failed to load sections';
      }

      try {
        final repo = _ref.read(fiveSAuditQuestionRepositoryProvider);
        questionDocuments = await repo.list(
          companyId: normalizedCompanyId,
          auditTypeId: normalizedAuditTypeId,
        );
        if (questionDocuments.isEmpty && sectionsRaw.isNotEmpty) {
          final byId = <String, FiveSAuditQuestionDocument>{};
          for (final section in sectionsRaw) {
            try {
              final docs = await repo.list(
                companyId: normalizedCompanyId,
                auditTypeId: normalizedAuditTypeId,
                sectionId: section.id,
              );
              for (final doc in docs) {
                byId[doc.id.isEmpty ? section.id : doc.id] = doc;
              }
            } catch (_) {
              continue;
            }
          }
          questionDocuments = byId.values.toList();
        }
      } catch (e) {
        loadError = e is ApiException ? e.message : 'Failed to load questions';
      }

      try {
        gradesRaw = await _ref.read(fiveSAuditGradeRepositoryProvider).list();
      } catch (_) {
        // Grades are optional for answering questions.
      }

      final sections = List<FiveSAuditSection>.from(sectionsRaw)
        ..sort(hierarchy.compareSectionsByOrder);
      final grades = List<FiveSAuditGrade>.from(gradesRaw)
        ..sort((a, b) => (a.gradeOrder ?? 0).compareTo(b.gradeOrder ?? 0));

      final flatQuestions = hierarchy.mapFlatQuestions(
        sections: sections,
        documents: questionDocuments,
      );
      final steps = hierarchy.buildAssessmentSteps(
        sections: sections,
        flatQuestions: flatQuestions,
      );

      if (flatQuestions.isEmpty) {
        state = FiveSAuditConfigState(
          status: FiveSConfigStatus.error,
          companyId: normalizedCompanyId,
          auditTypeId: normalizedAuditTypeId,
          sections: sections,
          questionDocuments: questionDocuments,
          grades: grades,
          errorMessage: loadError.isNotEmpty
              ? loadError
              : 'No 5S audit questions configured for this audit type.',
        );
        return false;
      }

      state = FiveSAuditConfigState(
        status: FiveSConfigStatus.loaded,
        companyId: normalizedCompanyId,
        auditTypeId: normalizedAuditTypeId,
        sections: sections,
        questionDocuments: questionDocuments,
        flatQuestions: flatQuestions,
        grades: grades,
        assessmentSteps: steps,
      );
      return true;
    } on ApiException catch (e) {
      state = FiveSAuditConfigState(
        status: FiveSConfigStatus.error,
        errorMessage: e.message,
      );
      return false;
    } catch (_) {
      state = const FiveSAuditConfigState(
        status: FiveSConfigStatus.error,
        errorMessage: 'Failed to load 5S audit configuration.',
      );
      return false;
    }
  }

  void invalidate() {
    state = const FiveSAuditConfigState();
  }

  List<FlatAuditQuestion> questionsForStep(AssessmentStep step) {
    return hierarchy.questionsForStep(state.flatQuestions, step);
  }
}

final fiveSAuditConfigControllerProvider = StateNotifierProvider<
    FiveSAuditConfigController, FiveSAuditConfigState>((ref) {
  return FiveSAuditConfigController(ref);
});
