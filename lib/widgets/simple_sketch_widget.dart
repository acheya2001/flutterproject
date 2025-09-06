import 'package:flutter/material.dart';
import 'dart:math' as math;

/// 🎨 Widget de croquis simple pour les accidents
class SimpleSketchWidget extends StatefulWidget {
  final double width;
  final double height;
  final Function(List<SketchElement>)? onSketchChanged;
  final List<SketchElement>? initialElements;
  final bool isReadOnly;

  const SimpleSketchWidget({
    super.key,
    required this.width,
    required this.height,
    this.onSketchChanged,
    this.initialElements,
    this.isReadOnly = false,
  });

  @override
  State<SimpleSketchWidget> createState() => _SimpleSketchWidgetState();
}

class _SimpleSketchWidgetState extends State<SimpleSketchWidget> {
  List<SketchElement> _elements = [];
  SketchElement? _currentElement;
  SketchTool _currentTool = SketchTool.pen;
  Color _currentColor = Colors.black;
  double _strokeWidth = 3.0;
  Offset? _startPoint;

  @override
  void initState() {
    super.initState();
    if (widget.initialElements != null) {
      _elements = List.from(widget.initialElements!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'outils (seulement si pas en lecture seule)
        if (!widget.isReadOnly) ...[
          _buildToolbar(),
          const SizedBox(height: 8),
        ],
        
        // Zone de dessin
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    onPanStart: widget.isReadOnly ? null : _onPanStart,
                    onPanUpdate: widget.isReadOnly ? null : _onPanUpdate,
                    onPanEnd: widget.isReadOnly ? null : _onPanEnd,
                    onTapUp: widget.isReadOnly ? null : _onTap,
                    child: Container(
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      child: CustomPaint(
                        painter: SimpleSketchPainter(_elements, _currentElement),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        child: Container(),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        
        // Actions (seulement si pas en lecture seule)
        if (!widget.isReadOnly) ...[
          const SizedBox(height: 8),
          _buildActionButtons(),
        ],
      ],
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Outils
            ...SketchTool.values.map((tool) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildToolButton(tool),
            )),
            
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Colors.grey[300]),
            const SizedBox(width: 8),
            
            // Couleurs
            ...[Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange]
                .map((color) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildColorButton(color),
            )),
            
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Colors.grey[300]),
            const SizedBox(width: 8),
            
            // Épaisseur
            ...[1.0, 3.0, 5.0, 8.0].map((width) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildStrokeButton(width),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildToolButton(SketchTool tool) {
    final isSelected = _currentTool == tool;
    return GestureDetector(
      onTap: () => setState(() => _currentTool = tool),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? tool.color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? tool.color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Icon(
          tool.icon,
          color: isSelected ? tool.color : Colors.grey[600],
          size: 18,
        ),
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = _currentColor == color;
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStrokeButton(double width) {
    final isSelected = _strokeWidth == width;
    return GestureDetector(
      onTap: () => setState(() => _strokeWidth = width),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Container(
            width: width * 2,
            height: width,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(width / 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildActionButton(
          icon: Icons.undo,
          onPressed: _elements.isNotEmpty ? _undo : null,
          color: Colors.orange[600]!,
        ),
        _buildActionButton(
          icon: Icons.clear,
          onPressed: _elements.isNotEmpty ? _clear : null,
          color: Colors.red[600]!,
        ),
        _buildActionButton(
          icon: Icons.save,
          onPressed: _saveSketch,
          color: Colors.green[600]!,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: onPressed != null ? color : Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final localPosition = details.localPosition;
    _startPoint = localPosition;
    
    switch (_currentTool) {
      case SketchTool.pen:
      case SketchTool.road:
        _currentElement = SketchElement(
          type: _currentTool,
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _strokeWidth,
        );
        break;
      case SketchTool.arrow:
        _currentElement = SketchElement(
          type: _currentTool,
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _strokeWidth,
        );
        break;
      default:
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentElement != null) {
      setState(() {
        switch (_currentTool) {
          case SketchTool.pen:
          case SketchTool.road:
            _currentElement!.points.add(details.localPosition);
            break;
          case SketchTool.arrow:
            if (_currentElement!.points.length == 1) {
              _currentElement!.points.add(details.localPosition);
            } else {
              _currentElement!.points[1] = details.localPosition;
            }
            break;
          default:
            break;
        }
      });
    }
  }

  void _onPanEnd(DragEndDetails details) {
    if (_currentElement != null) {
      setState(() {
        _elements.add(_currentElement!);
        _currentElement = null;
      });
      widget.onSketchChanged?.call(_elements);
    }
  }

  void _onTap(TapUpDetails details) {
    final localPosition = details.localPosition;
    
    switch (_currentTool) {
      case SketchTool.vehicle:
        final element = SketchElement(
          type: _currentTool,
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _strokeWidth,
        );
        setState(() {
          _elements.add(element);
        });
        widget.onSketchChanged?.call(_elements);
        break;
      case SketchTool.text:
        _showTextDialog(localPosition);
        break;
      default:
        break;
    }
  }

  void _undo() {
    if (_elements.isNotEmpty) {
      setState(() {
        _elements.removeLast();
      });
      widget.onSketchChanged?.call(_elements);
    }
  }

  void _clear() {
    setState(() {
      _elements.clear();
    });
    widget.onSketchChanged?.call(_elements);
  }

  void _saveSketch() {
    widget.onSketchChanged?.call(_elements);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Croquis sauvegardé'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showTextDialog(Offset position) {
    final textController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Ajouter du texte'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Entrez votre texte...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (textController.text.isNotEmpty) {
                  final element = SketchElement(
                    type: SketchTool.text,
                    points: [position],
                    color: _currentColor,
                    strokeWidth: _strokeWidth,
                    text: textController.text,
                  );
                  setState(() {
                    _elements.add(element);
                  });
                  widget.onSketchChanged?.call(_elements);
                }
                Navigator.of(context).pop();
              },
              child: const Text('Ajouter'),
            ),
          ],
        );
      },
    );
  }
}

/// Énumération des outils de dessin
enum SketchTool {
  vehicle(Icons.directions_car, 'Véhicule', Colors.blue),
  road(Icons.timeline, 'Route', Colors.grey),
  pen(Icons.edit, 'Crayon', Colors.black),
  arrow(Icons.arrow_forward, 'Flèche', Colors.red),
  text(Icons.text_fields, 'Texte', Colors.purple);

  const SketchTool(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;
}

/// Élément du croquis
class SketchElement {
  final SketchTool type;
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final String? text;

  SketchElement({
    required this.type,
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.text,
  });
}

/// Painter pour dessiner le croquis
class SimpleSketchPainter extends CustomPainter {
  final List<SketchElement> elements;
  final SketchElement? currentElement;

  SimpleSketchPainter(this.elements, [this.currentElement]);

  @override
  void paint(Canvas canvas, Size size) {
    final allElements = [...elements];
    if (currentElement != null) {
      allElements.add(currentElement!);
    }
    
    for (final element in allElements) {
      final paint = Paint()
        ..color = element.color
        ..strokeWidth = element.strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      switch (element.type) {
        case SketchTool.pen:
        case SketchTool.road:
          _drawPath(canvas, element.points, paint);
          break;
        case SketchTool.vehicle:
          if (element.points.isNotEmpty) {
            _drawVehicle(canvas, element.points.first, paint);
          }
          break;
        case SketchTool.arrow:
          _drawArrow(canvas, element.points, paint);
          break;
        case SketchTool.text:
          if (element.points.isNotEmpty) {
            _drawText(canvas, element.points.first, element.text ?? '', paint);
          }
          break;
      }
    }
  }

  void _drawPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    
    canvas.drawPath(path, paint);
  }

  void _drawVehicle(Canvas canvas, Offset center, Paint paint) {
    final rect = Rect.fromCenter(center: center, width: 30, height: 15);
    canvas.drawRect(rect, paint);
    
    final wheelPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(center.dx - 10, center.dy + 8), 3, wheelPaint);
    canvas.drawCircle(Offset(center.dx + 10, center.dy + 8), 3, wheelPaint);
  }

  void _drawArrow(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    
    final start = points.first;
    final end = points.last;
    
    canvas.drawLine(start, end, paint);
    
    final arrowLength = 10.0;
    final arrowAngle = math.pi / 6;
    
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    
    final arrowPoint1 = Offset(
      end.dx - arrowLength * math.cos(angle - arrowAngle),
      end.dy - arrowLength * math.sin(angle - arrowAngle),
    );
    
    final arrowPoint2 = Offset(
      end.dx - arrowLength * math.cos(angle + arrowAngle),
      end.dy - arrowLength * math.sin(angle + arrowAngle),
    );
    
    canvas.drawLine(end, arrowPoint1, paint);
    canvas.drawLine(end, arrowPoint2, paint);
  }

  void _drawText(Canvas canvas, Offset position, String text, Paint paint) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: paint.color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, position);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
