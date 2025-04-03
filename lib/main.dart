import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const PocketPaintApp());
}

/// Main app widget, wrapped with [ChangeNotifierProvider]
/// so that the drawing model is accessible across the widget tree.
class PocketPaintApp extends StatelessWidget {
  const PocketPaintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => PaintModel(),
      child: MaterialApp(
        title: 'Pocket Paint Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.deepPurple,
          useMaterial3: true,
        ),
        home: const PocketPaintHomePage(),
      ),
    );
  }
}

/// Home page of the app with the drawing canvas and tool controls.
class PocketPaintHomePage extends StatelessWidget {
  const PocketPaintHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<PaintModel>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Pocket Paint Flutter Demo'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Main drawing area
          Expanded(
            child: GestureDetector(
              onPanUpdate: (details) {
                final localPosition =
                (context.findRenderObject() as RenderBox)
                    .globalToLocal(details.globalPosition);
                model.addPoint(localPosition);
              },
              onPanEnd: (_) => model.endStroke(),
              child: AnimatedBuilder(
                animation: model,
                builder: (context, _) {
                  return CustomPaint(
                    painter: PocketPaintCanvas(model.strokes),
                    child: const SizedBox.expand(),
                  );
                },
              ),
            ),
          ),

          // Brush and color controls
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              boxShadow: const [
                BoxShadow(blurRadius: 4, color: Colors.black12),
              ],
            ),
            child: Row(
              children: [
                // Color picker icon
                IconButton(
                  icon: const Icon(Icons.color_lens),
                  onPressed: () => _showColorPicker(context, model),
                  tooltip: 'Pick color',
                ),
                const SizedBox(width: 8),
                const Text('Brush size'),
                // Brush size slider
                Expanded(
                  child: Slider(
                    value: model.strokeWidth,
                    onChanged: model.setStrokeWidth,
                    min: 1.0,
                    max: 20.0,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.undo),
                  onPressed: model.undo,
                  tooltip: 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: model.clear,
                  tooltip: 'Clear',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the color picker dialog
  void _showColorPicker(BuildContext context, PaintModel model) {
    Color tempColor = model.selectedColor;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Select a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: model.selectedColor,
            onColorChanged: (color) => tempColor = color,
            showLabel: false,
            enableAlpha: false,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              model.setColor(tempColor);
              Navigator.of(context).pop();
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }
}

/// Custom painter that draws all strokes on the canvas
class PocketPaintCanvas extends CustomPainter {
  final List<Stroke> strokes;

  const PocketPaintCanvas(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        final p1 = stroke.points[i];
        final p2 = stroke.points[i + 1];
        if (p1 != null && p2 != null) {
          canvas.drawLine(p1, p2, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Represents a single drawing stroke (a list of points + paint style)
class Stroke {
  final List<Offset?> points;
  final double strokeWidth;
  final Color color;

  Stroke({
    required this.points,
    required this.strokeWidth,
    required this.color,
  });
}

/// The central state management model for all drawing logic.
class PaintModel extends ChangeNotifier {
  List<Stroke> strokes = [];
  Stroke? _currentStroke;

  double strokeWidth = 5.0;
  Color selectedColor = Colors.deepPurple;

  void setColor(Color color) {
    selectedColor = color;
    notifyListeners();
  }

  void setStrokeWidth(double value) {
    strokeWidth = value;
    notifyListeners();
  }

  void addPoint(Offset point) {
    _currentStroke ??= Stroke(
      points: [],
      strokeWidth: strokeWidth,
      color: selectedColor,
    );
    _currentStroke!.points.add(point);
    notifyListeners();
  }

  void endStroke() {
    if (_currentStroke != null) {
      strokes.add(_currentStroke!);
      _currentStroke = null;
      notifyListeners();
    }
  }

  void undo() {
    if (strokes.isNotEmpty) {
      strokes.removeLast();
      notifyListeners();
    }
  }

  void clear() {
    strokes.clear();
    _currentStroke = null;
    notifyListeners();
  }
}
