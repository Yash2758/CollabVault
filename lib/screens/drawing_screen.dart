import 'package:collab/models/team_data.dart';
import 'package:collab/screens/collab_sidebar.dart';
import 'package:flutter/material.dart';
import 'package:collab/controllers/whiteboard_data_controller.dart';
import 'package:collab/models/drawing_point.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

enum ToolMode { pen, eraser, text, shape }
class DrawingScreen extends StatefulWidget {

  final Paint _defaultPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 4.0
    ..strokeCap = StrokeCap.round;

  @override
  _DrawingScreenState createState() => _DrawingScreenState();
}

class _DrawingScreenState extends State<DrawingScreen> {

  ToolMode currentTool = ToolMode.pen;

  // ✅ Enum definition


  // other state variables...
  final WhiteboardDataController _controller = WhiteboardDataController();
  Color selectedColor = Colors.black;
  double strokeWidth = 4.0;

  @override
  void initState() {
    super.initState();
    // Ensure points reflect the loaded board
    setState(() {
      // This will already be set by loadBoard, but ensures UI updates
      // _controller.points = _controller.points; // No-op, but can trigger setState
    });
  }


  Widget _buildControlsRow() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.color_lens, color: selectedColor),
            onPressed: () async {
              Color? color = await showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: Text("Pick a color"),
                  content: SingleChildScrollView(
                    child: BlockPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (c) => Navigator.pop(context, c),
                    ),
                  ),
                ),
              );
              if (color != null) setState(() => selectedColor = color);
            },
          ),
          Text("Stroke"),
          Expanded(
            child: Slider(
              value: strokeWidth,
              min: 1.0,
              max: 10.0,
              onChanged: (value) => setState(() => strokeWidth = value),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // For demo: use first two team members for avatars
    final mainAvatar = teamMembers.isNotEmpty ? teamMembers[0] : null;
    // Remove shadowAvatar logic
    
    bool showSidebar = false;
    bool isPressed = false;

    return StatefulBuilder(
      builder: (context, setOverlayState) {
        return Scaffold(
          appBar: AppBar(
            title: Text("Whiteboard"),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTapDown: (_) => setOverlayState(() => isPressed = true),
                    onTapUp: (_) => setOverlayState(() => isPressed = false),
                    onTapCancel: () => setOverlayState(() => isPressed = false),
                    child: AnimatedScale(
                      scale: isPressed ? 0.93 : 1.0,
                      duration: const Duration(milliseconds: 100),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        elevation: 0,
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: () => setOverlayState(() => showSidebar = !showSidebar),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              // No boxShadow
                            ),
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor: Colors.blue,
                              child: mainAvatar != null
                                  ? Text(
                                      mainAvatar.name[0],
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                    )
                                  : const Icon(Icons.person, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // drawer: const DrawerMenu(),
          body: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  return Column(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            RenderBox box = context.findRenderObject() as RenderBox;
                            Offset point = box.globalToLocal(details.globalPosition);
                            setState(() {
                              _controller.addPoint(
                                DrawingPoint(
                                  point: point,
                                  color: selectedColor,
                                  strokeWidth: strokeWidth,
                                ),
                              );
                            });
                          },
                          onPanEnd: (_) => setState(() => _controller.endStroke()),
                          child: CustomPaint(
                            painter: _DrawingPainter(_controller.points),
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                          ),
                        ),
                      ),
                      _buildControlsRow(),
                    ],
                  );
                },
              ),
              // Miro-style Side Toolbar
              Positioned(
                top: 80,
                left: 10,
                child: Column(
                  children: [
                    _toolButton(Icons.edit, "Pen", onTap: () {}),
                    SizedBox(height: 10),
                    _toolButton(Icons.cleaning_services, "Eraser", onTap: () {}),
                    SizedBox(height: 10),
                    _toolButton(Icons.text_fields, "Text", onTap: () {}),
                    SizedBox(height: 10),
                    _toolButton(Icons.format_shapes, "Shape", onTap: () {}),
                  ],
                ),
              ),
              // Sidebar overlay (slide in from right)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.ease,
                top: 0,
                bottom: 0,
                right: showSidebar ? 0 : -280,
                width: 280,
                child: Material(
                  elevation: 8,
                  color: Colors.white,
                  child: Stack(
                    children: [
                      CollabSideBar(teamMembers: teamMembers),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => setOverlayState(() => showSidebar = false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Tap outside to close sidebar
              if (showSidebar)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setOverlayState(() => showSidebar = false),
                    child: Container(
                      color: Colors.black.withOpacity(0.2),
                    ),
                  ),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            child: Icon(Icons.clear),
            onPressed: () => setState(() => _controller.clear()),
          ),
        );
      },
    );
  }



}
Widget _toolButton(IconData icon, String tooltip, {required VoidCallback onTap}) {
  return FloatingActionButton(
    heroTag: tooltip,
    mini: true,
    tooltip: tooltip,
    backgroundColor: Colors.white,
    foregroundColor: Colors.black,
    onPressed: onTap,
    child: Icon(icon),
  );
}


class _DrawingPainter extends CustomPainter {
  final List<DrawingPoint?> points;

  _DrawingPainter(this.points);


  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        final paint = Paint()
          ..color = points[i]!.color
          ..strokeWidth = points[i]!.strokeWidth
          ..strokeCap = StrokeCap.round;

        canvas.drawLine(points[i]!.point, points[i + 1]!.point, paint);
      }
    }
  }


  @override
  bool shouldRepaint(_DrawingPainter oldDelegate) => true;
}
