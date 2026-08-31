import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Simple signature capture that exports a PNG data-URL.
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
  final _points = <Offset?>[];
  final _boundaryKey = GlobalKey();

  void clear() {
    setState(() => _points.clear());
    widget.onChanged('');
  }

  Future<void> _export() async {
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return;
    final b64 = base64Encode(bytes.buffer.asUint8List());
    widget.onChanged('data:image/png;base64,$b64');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(10),
            color: Colors.white,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: RepaintBoundary(
              key: _boundaryKey,
              child: GestureDetector(
                onPanStart: (d) => setState(() => _points.add(d.localPosition)),
                onPanUpdate: (d) => setState(() => _points.add(d.localPosition)),
                onPanEnd: (_) async {
                  setState(() => _points.add(null));
                  await _export();
                },
                child: CustomPaint(
                  painter: _SignaturePainter(_points),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: clear, child: const Text('Clear signature')),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  _SignaturePainter(this.points);

  final List<Offset?> points;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
