import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../core/network/image_url.dart';
import '../../../core/theme/app_theme.dart';
import '../data/action_plan_utils.dart';
import '../data/models/action_plan_models.dart';
import 'action_plan_detail_controller.dart';

class ActionPlanDetailPage extends ConsumerStatefulWidget {
  const ActionPlanDetailPage({super.key, required this.planId});

  final String planId;

  @override
  ConsumerState<ActionPlanDetailPage> createState() => _ActionPlanDetailPageState();
}

class _ActionPlanDetailPageState extends ConsumerState<ActionPlanDetailPage> {
  final _responseController = TextEditingController();
  bool _seeded = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  void _sync(ActionPlanDetailState state) {
    if (_seeded || state.loading || state.detail == null) return;
    _responseController.text = state.response;
    _seeded = true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(actionPlanDetailControllerProvider(widget.planId));
    final controller =
        ref.read(actionPlanDetailControllerProvider(widget.planId).notifier);
    _sync(state);
    final detail = state.detail;
    final canUpdate = controller.canUpdate;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.displayCode ?? 'Action plan'),
        actions: [
          if (canUpdate)
            TextButton(
              onPressed: state.saving
                  ? null
                  : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await controller.save();
                      if (!mounted) return;
                      final latest = ref.read(
                        actionPlanDetailControllerProvider(widget.planId),
                      );
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            ok
                                ? 'Action plan saved'
                                : (latest.errorMessage ?? 'Save failed'),
                          ),
                        ),
                      );
                    },
              child: state.saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: state.loading && detail == null
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null && detail == null
              ? Center(child: Text(state.errorMessage!))
              : detail == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (state.errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              state.errorMessage!,
                              style: const TextStyle(color: AppColors.error),
                            ),
                          ),
                        _meta(context, 'Company', detail.companyName ?? detail.companyId),
                        _meta(context, 'Audit', detail.auditTypeName),
                        _meta(context, 'Location', detail.locationName ?? detail.locationId),
                        _meta(context, 'Question', detail.questionText),
                        if (detail.questionImages.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          const Text('Question images', style: TextStyle(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          _ImageStrip(images: detail.questionImages),
                        ],
                        _meta(context, 'Action required', detail.actionRequired ?? detail.notes),
                        _meta(context, 'Comments', detail.questionComments),
                        _meta(context, 'Status', detail.status.label),
                        _meta(context, 'Priority', detail.priority?.label),
                        _meta(context, 'Assignees', detail.assigneesLabel),
                        _meta(
                          context,
                          'Due date',
                          [
                            detail.dueDate ?? '—',
                            if (detail.delayedByDays != null && detail.delayedByDays! > 0)
                              '(+${detail.delayedByDays} days)',
                          ].join(' '),
                        ),
                        if (detail.dueDateReason != null)
                          _meta(context, 'Due date reason', detail.dueDateReason),
                        const Divider(height: 28),
                        if (!canUpdate)
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Read-only — you are not an assignee on this plan.',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        if (canUpdate) ...[
                          Text('Work status', style: Theme.of(context).textTheme.titleMedium),
                          for (final option in ActionPlanWorkStatus.values)
                            RadioListTile<ActionPlanWorkStatus>(
                              contentPadding: EdgeInsets.zero,
                              title: Text(option.label),
                              value: option,
                              groupValue: state.workStatus,
                              onChanged: (v) {
                                if (v != null) controller.setWorkStatus(v);
                              },
                            ),
                          TextFormField(
                            controller: _responseController,
                            decoration: const InputDecoration(
                              labelText: 'Response',
                              alignLabelWithHint: true,
                            ),
                            minLines: 3,
                            maxLines: 6,
                            onChanged: controller.setResponse,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text('Proof images', style: Theme.of(context).textTheme.titleMedium),
                              const Spacer(),
                              if (state.uploading)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                PopupMenuButton<ImageSource>(
                                  onSelected: (source) => _pickProof(source),
                                  itemBuilder: (_) => const [
                                    PopupMenuItem(
                                      value: ImageSource.camera,
                                      child: Text('Camera'),
                                    ),
                                    PopupMenuItem(
                                      value: ImageSource.gallery,
                                      child: Text('Gallery'),
                                    ),
                                  ],
                                  child: const Padding(
                                    padding: EdgeInsets.all(8),
                                    child: Icon(Icons.add_a_photo_outlined),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          _ImageStrip(
                            images: state.proofImages,
                            onRemove: canUpdate ? controller.removeProofAt : null,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: state.updatingDueDate
                                ? null
                                : () => _changeDueDate(detail),
                            icon: const Icon(Icons.event),
                            label: const Text('Change due date'),
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: state.saving
                                ? null
                                : () async {
                                    final messenger = ScaffoldMessenger.of(context);
                                    final ok = await controller.save();
                                    if (!mounted) return;
                                    final latest = ref.read(
                                      actionPlanDetailControllerProvider(widget.planId),
                                    );
                                    messenger.showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? 'Action plan saved'
                                              : (latest.errorMessage ?? 'Save failed'),
                                        ),
                                      ),
                                    );
                                  },
                            child: state.saving
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Save changes'),
                          ),
                        ] else ...[
                          _meta(context, 'Response', detail.response),
                          if (detail.proofImages.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text('Proof images', style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 6),
                            _ImageStrip(images: detail.proofImages),
                          ],
                        ],
                      ],
                    ),
    );
  }

  Widget _meta(BuildContext context, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value),
        ],
      ),
    );
  }

  Future<void> _pickProof(ImageSource source) async {
    final controller =
        ref.read(actionPlanDetailControllerProvider(widget.planId).notifier);
    if (!controller.canUpdate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot update this action plan.')),
      );
      return;
    }

    final currentCount =
        ref.read(actionPlanDetailControllerProvider(widget.planId)).proofImages.length;
    final remaining = maxProofImagesPerActionPlan - currentCount;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You can upload up to $maxProofImagesPerActionPlan images.'),
        ),
      );
      return;
    }

    final pickerFiles = <({String path, String? name, String? mime, int size})>[];
    if (source == ImageSource.gallery) {
      final picked = await _picker.pickMultiImage(imageQuality: 85);
      for (final file in picked.take(remaining)) {
        pickerFiles.add((
          path: file.path,
          name: file.name,
          mime: _guessMime(file.path, file.mimeType),
          size: await file.length(),
        ));
      }
    } else {
      final file = await _picker.pickImage(source: source, imageQuality: 85);
      if (file != null) {
        pickerFiles.add((
          path: file.path,
          name: file.name,
          mime: _guessMime(file.path, file.mimeType),
          size: await file.length(),
        ));
      }
    }

    for (final file in pickerFiles) {
      final error = await controller.uploadProof(
        filePath: file.path,
        fileName: file.name,
        mimeType: file.mime,
        sizeBytes: file.size,
      );
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        break;
      }
    }
  }

  String? _guessMime(String path, String? mimeType) {
    if (mimeType != null && mimeType.isNotEmpty) return mimeType;
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return null;
  }

  Future<void> _changeDueDate(ActionPlanDetail detail) async {
    final controller =
        ref.read(actionPlanDetailControllerProvider(widget.planId).notifier);
    final reasonController = TextEditingController();
    DateTime selected = DateTime.tryParse(detail.dueDate ?? '') ?? DateTime.now();

    final result = await showDialog<({String date, String reason})>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: const Text('Change due date'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('New due date'),
                    subtitle: Text(DateFormat('yyyy-MM-dd').format(selected)),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selected,
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                      );
                      if (picked != null) setLocal(() => selected = picked);
                    },
                  ),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason *',
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.isEmpty) return;
                    final ymd =
                        '${selected.year.toString().padLeft(4, '0')}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
                    Navigator.pop(context, (date: ymd, reason: reason));
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
    reasonController.dispose();
    if (result == null) return;
    final ok = await controller.updateDueDate(
      dueDate: result.date,
      reason: result.reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Due date updated' : 'Failed to update due date'),
      ),
    );
  }
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.images, this.onRemove});

  final List<ActionPlanProofImage> images;
  final void Function(int index)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const Text('No images', style: TextStyle(color: AppColors.textSecondary));
    }
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final url = images[index].displayUrl;
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.isEmpty
                    ? Container(
                        width: 96,
                        height: 96,
                        color: AppColors.divider,
                        child: const Icon(Icons.broken_image_outlined),
                      )
                    : Image.network(
                        url,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 96,
                          height: 96,
                          color: AppColors.divider,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              if (onRemove != null)
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    iconSize: 18,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(4),
                      minimumSize: const Size(28, 28),
                    ),
                    onPressed: () => onRemove!(index),
                    icon: const Icon(Icons.close),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
