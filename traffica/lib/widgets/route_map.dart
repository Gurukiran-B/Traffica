import 'package:flutter/material.dart';

class RouteMap extends StatelessWidget {
  final List<String> nodes;
  const RouteMap({super.key, required this.nodes});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: CustomPaint(
          painter: _RoutePainter(nodes: nodes, color: Theme.of(context).colorScheme.primary),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  final List<String> nodes;
  final Color color;
  _RoutePainter({required this.nodes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (nodes.isEmpty) return;
    final padding = 24.0;
    final usableW = size.width - padding * 2;
    final usableH = size.height - padding * 2;
    final stepX = nodes.length > 1 ? usableW / (nodes.length - 1) : 0;
    final centerY = padding + usableH / 2;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()..color = color;

    Offset? prev;
    for (int i = 0; i < nodes.length; i++) {
      final p = Offset(padding + stepX * i, centerY + (i % 2 == 0 ? -16 : 16));
      if (prev != null) {
        canvas.drawLine(prev!, p, linePaint);
      }
      canvas.drawCircle(p, 6, dotPaint);
      prev = p;
    }
  }

  @override
  bool shouldRepaint(covariant _RoutePainter oldDelegate) {
    return oldDelegate.nodes != nodes || oldDelegate.color != color;
  }
}


