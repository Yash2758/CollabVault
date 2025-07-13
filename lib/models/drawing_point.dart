import 'package:flutter/material.dart';

class DrawingPoint {
  final Offset point;
  final Color color;
  final double strokeWidth;

  DrawingPoint({
    required this.point,
    required this.color,
    required this.strokeWidth,
  });
}
