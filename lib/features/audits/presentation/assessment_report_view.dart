import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../five_s_config/data/models/five_s_config_models.dart';
import '../data/audit_report_score.dart';
import '../data/models/assessment_models.dart';

const _reportRed = Color(0xFFC62828);
const _reportNavy = Color(0xFF1B3A4B);
const _reportBar = Color(0xFF1E4E79);
const _reportSummary = Color(0xFF5E7C8A);

class AssessmentReportView extends StatelessWidget {
  const AssessmentReportView({
    super.key,
    required this.record,
    required this.auditTypeName,
    required this.questions,
    required this.sectionOrder,
  });

  final FiveSAuditRecord record;
  final String? auditTypeName;
  final List<FlatAuditQuestion> questions;
  final List<String> sectionOrder;

  @override
  Widget build(BuildContext context) {
    final score = buildAuditReportScore(
      responses: record.responses,
      questions: questions,
      sectionOrder: sectionOrder,
    );
    final company = (record.companyName ??
            record.companyBackground?.companyName ??
            record.displayTitle)
        .trim();
    final typeName = (auditTypeName ?? record.auditTypeName ?? '').trim();
    final location = (record.companyBackground?.location ?? '').trim();
    final date = _parseDate(record.reportDate);
    final summary = record.summary.trim();

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE3E8EE)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        company.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          height: 1.25,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'assets/branding/app_icon.png',
                      width: 54,
                      height: 54,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox(width: 54, height: 54),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (typeName.isNotEmpty)
                  Text(
                    typeName.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _reportRed,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    location.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: _reportRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Text(
                  _headlineDate(date, record.reportDate),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 16),
                if (score.hasQuestionMax && score.max > 0) ...[
                  Text(
                    '${score.percent} %',
                    style: const TextStyle(
                      color: _reportRed,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '(${formatReportNumber(score.total)}/${formatReportNumber(score.max)})',
                    style: const TextStyle(
                      color: _reportRed,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ] else
                  Text(
                    formatReportNumber(score.total),
                    style: const TextStyle(
                      color: _reportRed,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                if (score.hasQuestionMax && score.max > 0) ...[
                  const SizedBox(height: 22),
                  const _Band(label: 'HISTORY', color: _reportNavy),
                  const SizedBox(height: 8),
                  _HistoryChart(
                    percent: score.percent,
                    label: _axisDate(date, record.reportDate),
                  ),
                ],
                const SizedBox(height: 18),
                const _Band(label: 'SUMMARY', color: _reportSummary),
                Container(
                  width: double.infinity,
                  color: const Color(0xFFF4F7F8),
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    summary.isEmpty ? 'No summary' : summary,
                    style: const TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF24303A)),
                  ),
                ),
                if (score.sections.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _Band(label: 'SCORE BY SECTION', color: _reportNavy),
                  const SizedBox(height: 10),
                  _SectionScoreChart(sections: score.sections),
                ],
                if (record.responses.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  const _Band(label: 'RESPONSES', color: _reportNavy),
                  const SizedBox(height: 8),
                  ..._responseGroups(record.responses, score.sections).map(
                    (group) => _ResponseGroup(group: group),
                  ),
                ],
                if ((record.declarationSignature ?? '').isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _Band(label: 'SIGNATURE', color: _reportNavy),
                  const SizedBox(height: 8),
                  _Signature(value: record.declarationSignature!),
                ],
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        date == null
                            ? (record.reportDate ?? '')
                            : DateFormat('dd MMMM yyyy').format(date),
                        style: const TextStyle(fontSize: 11, color: Color(0xFF60707A)),
                      ),
                    ),
                    const Text(
                      '5S Audit Report',
                      style: TextStyle(fontSize: 11, color: Color(0xFF60707A)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Band extends StatelessWidget {
  const _Band({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.6,
          fontSize: 13,
        ),
      ),
    );
  }
}

class _HistoryChart extends StatelessWidget {
  const _HistoryChart({required this.percent, required this.label});

  final int percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    const chartHeight = 150.0;
    final clamped = percent.clamp(0, 100);
    return SizedBox(
      height: chartHeight + 36,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: chartHeight,
            width: 28,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('100', style: TextStyle(fontSize: 10)),
                Text('80', style: TextStyle(fontSize: 10)),
                Text('60', style: TextStyle(fontSize: 10)),
                Text('40', style: TextStyle(fontSize: 10)),
                Text('20', style: TextStyle(fontSize: 10)),
                Text('0', style: TextStyle(fontSize: 10)),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                SizedBox(
                  height: chartHeight,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(
                              left: BorderSide(color: Color(0xFFB0BEC5)),
                              bottom: BorderSide(color: Color(0xFFB0BEC5)),
                            ),
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$clamped%',
                              style: const TextStyle(
                                color: _reportBar,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: 72,
                              height: math.max(0, (chartHeight - 18) * (clamped / 100)),
                              color: _reportBar,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionScoreChart extends StatelessWidget {
  const _SectionScoreChart({required this.sections});

  final List<AuditSectionScore> sections;

  @override
  Widget build(BuildContext context) {
    final highest = sections.fold<num>(
      0,
      (max, section) => math.max(max, math.max(section.score, section.maxScore)),
    );
    final axisMax = _axisMax(highest);
    return Column(
      children: [
        for (final section in sections)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 108,
                  child: Text(
                    section.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final fraction = axisMax <= 0 ? 0.0 : (section.score / axisMax).clamp(0, 1);
                      return Stack(
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(height: 18, color: const Color(0xFFE8EEF2)),
                          Container(
                            height: 18,
                            width: constraints.maxWidth * fraction.toDouble(),
                            color: _reportBar,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 28,
                  child: Text(
                    formatReportNumber(section.score),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        Row(
          children: [
            const SizedBox(width: 108),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var tick = 0; tick <= axisMax; tick += _tickStep(axisMax))
                    Text('$tick', style: const TextStyle(fontSize: 10, color: Color(0xFF60707A))),
                ],
              ),
            ),
            const SizedBox(width: 34),
          ],
        ),
      ],
    );
  }
}

class _ResponseGroup extends StatelessWidget {
  const _ResponseGroup({required this.group});

  final _GroupedResponses group;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            group.name,
            style: const TextStyle(
              color: _reportNavy,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 6),
          for (final response in group.responses)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE3E8EE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    response.question ?? 'Question ${response.questionId}',
                    style: const TextStyle(fontWeight: FontWeight.w600, height: 1.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if ((response.subCategory ?? '').trim().isNotEmpty) response.subCategory!.trim(),
                      'Score: ${response.score == null ? '-' : formatReportNumber(response.score!)}',
                      if ((response.selectedResponse ?? '').trim().isNotEmpty)
                        response.selectedResponse!.trim(),
                    ].join(' · '),
                    style: const TextStyle(fontSize: 12, color: Color(0xFF455A64), height: 1.35),
                  ),
                  if ((response.comments ?? '').trim().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        response.comments!.trim(),
                        style: const TextStyle(fontSize: 12, color: Color(0xFF455A64)),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Signature extends StatelessWidget {
  const _Signature({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    if (value.startsWith('data:image')) {
      final data = Uri.parse(value).data;
      if (data == null) return const SizedBox.shrink();
      return Image.memory(data.contentAsBytes(), height: 90, fit: BoxFit.contain);
    }
    if (value.startsWith('http')) {
      return Image.network(value, height: 90, fit: BoxFit.contain);
    }
    return const Text('Signed');
  }
}

class _GroupedResponses {
  const _GroupedResponses(this.name, this.responses);

  final String name;
  final List<AssessmentResponse> responses;
}

List<_GroupedResponses> _responseGroups(
  List<AssessmentResponse> responses,
  List<AuditSectionScore> sections,
) {
  final order = sections.map((section) => section.name).toList();
  final groups = <String, List<AssessmentResponse>>{};
  for (final response in responses) {
    final name = response.category.trim().isEmpty ? 'General' : response.category.trim();
    groups.putIfAbsent(name, () => []).add(response);
    if (!order.contains(name)) order.add(name);
  }
  return [
    for (final name in order)
      if (groups[name] != null) _GroupedResponses(name, groups[name]!),
  ];
}

DateTime? _parseDate(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  return DateTime.tryParse(raw.trim());
}

String _headlineDate(DateTime? date, String? raw) {
  if (date == null) return (raw ?? '').toUpperCase();
  final weekday = DateFormat('EEEE').format(date).toUpperCase();
  final month = DateFormat('MMMM').format(date).toUpperCase();
  return '$weekday ${_ordinal(date.day)} $month ${date.year}';
}

String _axisDate(DateTime? date, String? raw) {
  if (date == null) return raw ?? '';
  return DateFormat('dd-MMM-yy').format(date).toUpperCase();
}

String _ordinal(int day) {
  if (day >= 11 && day <= 13) return '${day}TH';
  switch (day % 10) {
    case 1:
      return '${day}ST';
    case 2:
      return '${day}ND';
    case 3:
      return '${day}RD';
    default:
      return '${day}TH';
  }
}

double _axisMax(num highest) {
  if (highest <= 0) return 10;
  final padded = highest * 1.15;
  final step = padded <= 50 ? 10 : (padded <= 120 ? 20 : 25);
  return (padded / step).ceil() * step.toDouble();
}

int _tickStep(double axisMax) {
  if (axisMax <= 50) return 10;
  if (axisMax <= 120) return 20;
  return 25;
}
