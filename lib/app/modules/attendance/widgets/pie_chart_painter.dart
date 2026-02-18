import 'package:flutter/material.dart';
import 'dart:math' as math;

class PieChartPainter extends CustomPainter {
  final double presentPercentage;
  final double absentPercentage;
  final Color presentColor;
  final Color absentColor;

  PieChartPainter({
    required this.presentPercentage,
    required this.absentPercentage,
    required this.presentColor,
    required this.absentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, radius, backgroundPaint);

    // Present arc
    if (presentPercentage > 0) {
      final presentPaint = Paint()
        ..color = presentColor
        ..style = PaintingStyle.fill;

      final presentSweepAngle = (presentPercentage / 100) * 2 * math.pi;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2, // Start from top
        presentSweepAngle,
        true,
        presentPaint,
      );
    }

    // Absent arc
    if (absentPercentage > 0) {
      final absentPaint = Paint()
        ..color = absentColor
        ..style = PaintingStyle.fill;

      final presentSweepAngle = (presentPercentage / 100) * 2 * math.pi;
      final absentSweepAngle = (absentPercentage / 100) * 2 * math.pi;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2 + presentSweepAngle, // Start after present arc
        absentSweepAngle,
        true,
        absentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}