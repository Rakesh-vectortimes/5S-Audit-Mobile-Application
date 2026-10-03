import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Signature capture that works inside a scrolling form on Android and iOS.
///
/// Uses an eager pan recognizer so the parent [ListView] cannot steal the
/// stroke, and exports by painting into a [PictureRecorder] (avoids
/// [RepaintBoundary.toImage] races on some devices).
class SignaturePad extends StatefulWidget {
  const SignaturePad({
    super.key,
    required this.onChanged,
    this.height = 180,
  });

  final ValueChanged<String> onChanged;
  final double height;

  @override
  State<SignaturePad> createState() => SignaturePadState();
}

class SignaturePadState extends State<SignaturePad> {
  final _strokes = <List<Offset>>[];
  final _drawKey = GlobalKey();
  int _exportToken = 0;

  bool get _hasInk => _strokes.any((stroke) => stroke.isNotEmpty);

  void clear() {
    setState(() {
      _strokes.clear();
    });
    widget.onChanged('');
  }

  /// Call before submit so the latest stroke is in state even if pan-end
  /// export was dropped on a slower device.
  Future<void> flushExport() => _export();

  void _beginStroke(Offset point) {
    setState(() => _strokes.add([_clamp(point)]));
  }

  void _appendStroke(Offset point) {
    if (_strokes.isEmpty) {
      _beginStroke(point);
      return;
    }
    setState(() => _strokes.last.add(_clamp(point)));
  }

  void _endStroke() {
    if (_strokes.isNotEmpty && _strokes.last.isEmpty) {
      _strokes.removeLast();
    }
    _export();
  }

  Offset _clamp(Offset point) {
    final box = _drawKey.currentContext?.findRenderObject() as RenderBox?;
    final size = box?.size;
    if (size == null || size.isEmpty) return point;
    return Offset(
      point.dx.clamp(0.0, size.width),
      point.dy.clamp(0.0, size.height),
    );
  }

  Future<void> _export() async {
    final token = ++_exportToken;
    if (!_hasInk) {
      widget.onChanged('');
      return;
    }

    // Wait until the last stroke is painted and layout is stable.
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || token != _exportToken) return;

    final box = _drawKey.currentContext?.findRenderObject() as RenderBox?;
    final logicalSize = box?.size;
    if (logicalSize == null || logicalSize.width < 1 || logicalSize.height < 1) {
      return;
    }

    try {
      final pixelRatio =
          (MediaQuery.maybeDevicePixelRatioOf(context) ?? 2.0).clamp(1.0, 3.0);
      final width = (logicalSize.width * pixelRatio).round().clamp(1, 4096);
      final height = (logicalSize.height * pixelRatio).round().clamp(1, 4096);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.scale(pixelRatio);
      canvas.drawRect(
        Offset.zero & logicalSize,
        Paint()..color = Colors.white,
      );
      paintSignatureStrokes(canvas, _strokes);

      final picture = recorder.endRecording();
      final image = await picture.toImage(width, height);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      picture.dispose();
      image.dispose();
      if (bytes == null || !mounted || token != _exportToken) return;

      final b64 = base64Encode(bytes.buffer.asUint8List());
      widget.onChanged('data:image/png;base64,$b64');
    } catch (error, stack) {
      debugPrint('Signature export failed: $error\n$stack');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: _drawKey,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: RawGestureDetector(
            behavior: HitTestBehavior.opaque,
            gestures: <Type, GestureRecognizerFactory>{
              _EagerPanGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<_EagerPanGestureRecognizer>(
                _EagerPanGestureRecognizer.new,
                (recognizer) {
                  recognizer.onStart = (details) {
                    _beginStroke(details.localPosition);
                  };
                  recognizer.onUpdate = (details) {
                    _appendStroke(details.localPosition);
                  };
                  recognizer.onEnd = (_) {
                    _endStroke();
                  };
                  recognizer.onCancel = _endStroke;
                },
              ),
            },
            child: CustomPaint(
              painter: _SignaturePainter(_strokes),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: clear,
            child: const Text('Clear signature'),
          ),
        ),
      ],
    );
  }
}

void paintSignatureStrokes(Canvas canvas, List<List<Offset>> strokes) {
  final strokePaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 2.6
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round
    ..style = PaintingStyle.stroke
    ..isAntiAlias = true;
  final dotPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill
    ..isAntiAlias = true;

  for (final stroke in strokes) {
    if (stroke.isEmpty) continue;
    if (stroke.length == 1) {
      canvas.drawCircle(stroke.first, 1.4, dotPaint);
      continue;
    }
    final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
    for (var i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, strokePaint);
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.strokes);

  final List<List<Offset>> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    paintSignatureStrokes(canvas, strokes);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

/// Accepts the pointer immediately so a parent [Scrollable] cannot treat a
/// signature stroke as a scroll (common on iOS and some Android devices).
class _EagerPanGestureRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => 'eager signature pan';
}
