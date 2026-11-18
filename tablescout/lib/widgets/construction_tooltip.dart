import 'package:flutter/material.dart';
import 'package:tablescout/theme/app_colours.dart';

class ConstructionTooltip extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;

  const ConstructionTooltip({
    super.key,
    this.title = 'Under Construction',
    this.message = 'This feature is currently being developed. Check back soon!',
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColours.primary,
        border: Border.all(
          color: AppColours.accent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColours.accent,
            size: 28,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColours.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  message,
                  style: const TextStyle(
                    color: AppColours.accent,
                    fontSize: 14,
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

class ConstructionBackground extends StatelessWidget {
  final Widget child;

  const ConstructionBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConstructionTapePainter(),
      child: child,
    );
  }
}

class _ConstructionTapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tapeWidth = 55.0;
    const stripeLength = 45.0;

    final yellowPaint = Paint()
      ..color = const Color(0xFFFFD21F)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tapeWidth;

    final blackPaint = Paint()
      ..color = const Color(0xFF171717)
      ..style = PaintingStyle.stroke
      ..strokeWidth = tapeWidth;

    void drawTape(Offset start, Offset end) {
      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..lineTo(end.dx, end.dy);

      final metrics = path.computeMetrics().first;
      double distance = 0;
      bool yellow = true;

      while (distance < metrics.length) {
        final segmentLength = stripeLength.clamp(
          0.0,
          metrics.length - distance,
        );

        final segment = metrics.extractPath(
          distance,
          distance + segmentLength,
        );

        canvas.drawPath(
          segment,
          yellow ? yellowPaint : blackPaint,
        );

        distance += segmentLength;
        yellow = !yellow;
      }
    }

    // Extend the tape beyond all four edges.
    final diagonalLength = size.width + size.height;

    drawTape(
      Offset(-diagonalLength, -diagonalLength),
      Offset(size.width + diagonalLength, size.height + diagonalLength),
    );

    drawTape(
      Offset(size.width + diagonalLength, -diagonalLength),
      Offset(-diagonalLength, size.height + diagonalLength),
    );
  }

  @override
  bool shouldRepaint(covariant _ConstructionTapePainter oldDelegate) {
    return false;
  }
}