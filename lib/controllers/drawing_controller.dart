import 'package:collab/models/drawing_point.dart';

class DrawingController {
  List<DrawingPoint?> points = [];

  void addPoint(DrawingPoint point) {
    points.add(point);
  }

  void endStroke() {
    points.add(null); // Null signifies stroke break
  }

  void clear() {
    points.clear();
  }
}
