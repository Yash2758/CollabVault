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

  Map<String, dynamic> toJson() => {
    'dx': point.dx,
    'dy': point.dy,
    'color': color.value,
    'strokeWidth': strokeWidth,
  };

  static DrawingPoint fromJson(Map<String, dynamic> json) => DrawingPoint(
    point: Offset(json['dx'], json['dy']),
    color: Color(json['color']),
    strokeWidth: (json['strokeWidth'] as num).toDouble(),
  );
}
