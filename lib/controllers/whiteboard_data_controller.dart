import 'package:collab/models/drawing_point.dart';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WhiteboardDataController {
  static final WhiteboardDataController _instance = WhiteboardDataController._internal();
  factory WhiteboardDataController() => _instance;

  WhiteboardDataController._internal();

  late Directory _localDir;
  Map<String, dynamic>? _currentBoardData;
  String? _currentBoardId;
  List<DrawingPoint?> points = [];

  void addPoint(DrawingPoint point) {
    points.add(point);
    _updateElementsAndSave();
  }

  void endStroke() {
    points.add(null); // Null signifies stroke break
    _updateElementsAndSave();
  }

  void clear() {
    points.clear();
    _updateElementsAndSave();
  }

  void _updateElementsAndSave() {
    if (_currentBoardData != null) {
      _currentBoardData!['elements'] = points.map((p) => p == null ? null : p.toJson()).toList();
      saveCurrentBoard();
    }
  }

  Future<void> init() async {
    _localDir = await getApplicationDocumentsDirectory();
  }

  Future<List<String>> listBoards() async {
    final files = _localDir.listSync().where((file) => file.path.endsWith('.json'));
    return files.map((f) => f.path.split('/').last.replaceAll('.json', '')).toList();
  }

  Future<void> createNewBoard(String boardId) async {
    final file = File('${_localDir.path}/$boardId.json');

    final initialData = {
      'id': boardId,
      'createdAt': DateTime.now().toIso8601String(),
      'elements': [],
      'collaborators': [],
    };

    await file.writeAsString(jsonEncode(initialData));
    _currentBoardData = initialData;
    _currentBoardId = boardId;
    points = [];
  }

  Future<Map<String, dynamic>> loadBoard(String boardId) async {
    final file = File('${_localDir.path}/$boardId.json');
    if (!await file.exists()) throw Exception("Board not found");

    final contents = await file.readAsString();
    final data = jsonDecode(contents);
    _currentBoardData = data;
    _currentBoardId = boardId;
    // Load points from elements
    if (data['elements'] != null) {
      points = (data['elements'] as List)
          .map((e) => e == null ? null : DrawingPoint.fromJson(e as Map<String, dynamic>))
          .toList();
    } else {
      points = [];
    }
    return data;
  }

  Map<String, dynamic>? get currentBoard => _currentBoardData;
  String? get currentBoardId => _currentBoardId;

  Future<void> saveCurrentBoard() async {
    if (_currentBoardId == null || _currentBoardData == null) return;
    final file = File('${_localDir.path}/$_currentBoardId.json');
    await file.writeAsString(jsonEncode(_currentBoardData));
  }
}
