import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:math' as math;

/// 🎨 Widget de croquis moderne pour accidents
class ModernSketchWidget extends StatefulWidget {
  final double width;
  final double height;
  final Function(List<SketchElement>)? onSketchChanged;
  final List<SketchElement>? initialElements;
  final bool isReadOnly;

  const ModernSketchWidget({
    super.key,
    required this.width,
    required this.height,
    this.onSketchChanged,
    this.initialElements,
    this.isReadOnly = false,
  });

  @override
  State<ModernSketchWidget> createState() => _ModernSketchWidgetState();
}

class _ModernSketchWidgetState extends State<ModernSketchWidget> {
  List<SketchElement> _elements = [];
  SketchTool _currentTool = SketchTool.vehicle;
  Color _currentColor = Colors.blue;
  double _strokeWidth = 3.0;
  Offset? _startPoint;
  SketchElement? _currentElement;

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
        // Barre d'outils moderne compacte (seulement si pas en lecture seule)
        if (!widget.isReadOnly) ...[
          _buildCompactToolbar(),
          const SizedBox(height: 8),
        ],

        // Zone de dessin - prend tout l'espace disponible
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
                        painter: SketchPainter(_elements, _currentElement),
                        size: Size(constraints.maxWidth, constraints.maxHeight),
                        child: Container(), // Zone de dessin transparente
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Actions compactes (seulement si pas en lecture seule)
        if (!widget.isReadOnly) ...[
          const SizedBox(height: 8),
          _buildCompactActionButtons(),
        ],
      ],
    );
  }

  Widget _buildModernToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Outils principaux
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: SketchTool.values.map((tool) {
              final isSelected = _currentTool == tool;
              return GestureDetector(
                onTap: () => setState(() => _currentTool = tool),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? tool.color.withOpacity(0.2) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? tool.color : Colors.grey[300]!,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        tool.icon,
                        color: isSelected ? tool.color : Colors.grey[600],
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tool.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? tool.color : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          
          // Contrôles avancés
          Row(
            children: [
              // Couleurs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Couleur',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Colors.blue,
                        Colors.red,
                        Colors.green,
                        Colors.orange,
                        Colors.purple,
                        Colors.black,
                      ].map((color) {
                        final isSelected = _currentColor == color;
                        return GestureDetector(
                          onTap: () => setState(() => _currentColor = color),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey[300]!,
                                width: isSelected ? 3 : 1,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Épaisseur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Épaisseur: ${_strokeWidth.toInt()}px',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Slider(
                      value: _strokeWidth,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      onChanged: (value) => setState(() => _strokeWidth = value),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton.icon(
          onPressed: _elements.isNotEmpty ? _undo : null,
          icon: const Icon(Icons.undo),
          label: const Text('Annuler'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[600],
            foregroundColor: Colors.white,
          ),
        ),

        ElevatedButton.icon(
          onPressed: _elements.isNotEmpty ? _clear : null,
          icon: const Icon(Icons.clear),
          label: const Text('Effacer'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red[600],
            foregroundColor: Colors.white,
          ),
        ),

        ElevatedButton.icon(
          onPressed: _saveSketch,
          icon: const Icon(Icons.save),
          label: const Text('Sauvegarder'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactToolbar() {
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
            // Outils de dessin
            ...SketchTool.values.map((tool) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildCompactToolButton(tool),
            )),

            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Colors.grey[300]),
            const SizedBox(width: 8),

            // Couleurs
            ...[Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple]
                .map((color) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildCompactColorButton(color),
            )),

            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Colors.grey[300]),
            const SizedBox(width: 8),

            // Épaisseur
            ...[1.0, 3.0, 5.0, 8.0].map((width) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _buildCompactStrokeButton(width),
            )),
          ],
        ),
      ),
    );
  }



  Widget _buildCompactActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildCompactActionButton(
          icon: Icons.undo,
          onPressed: _elements.isNotEmpty ? _undo : null,
          color: Colors.orange[600]!,
        ),
        _buildCompactActionButton(
          icon: Icons.clear,
          onPressed: _elements.isNotEmpty ? _clear : null,
          color: Colors.red[600]!,
        ),
        _buildCompactActionButton(
          icon: Icons.save,
          onPressed: _saveSketch,
          color: Colors.green[600]!,
        ),
      ],
    );
  }

  Widget _buildCompactToolButton(SketchTool tool) {
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

  Widget _buildCompactColorButton(Color color) {
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

  Widget _buildCompactStrokeButton(double width) {
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

  Widget _buildCompactActionButton({
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
        // Outils de dessin libre
        _currentElement = SketchElement(
          type: _currentTool,
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _strokeWidth,
        );
        break;
      case SketchTool.arrow:
        // Flèche - commence par un point
        _currentElement = SketchElement(
          type: _currentTool,
          points: [localPosition],
          color: _currentColor,
          strokeWidth: _strokeWidth,
        );
        break;
      default:
        // Autres outils (véhicule, panneau, texte) - placement direct
        break;
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentElement != null) {
      setState(() {
        switch (_currentTool) {
          case SketchTool.pen:
          case SketchTool.road:
            // Ajouter des points pour le dessin libre
            _currentElement!.points.add(details.localPosition);
            break;
          case SketchTool.arrow:
            // Mettre à jour le point final de la flèche
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
        // Outils de placement - créer un élément au point de tap
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
        // Ouvrir une boîte de dialogue pour saisir le texte
        _showTextDialog(localPosition);
        break;
      default:
        // Autres outils ne réagissent pas au tap
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  hintText: 'Entrez votre texte...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text('Couleur: '),
                  const SizedBox(width: 8),
                  ...[Colors.black, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple]
                      .map((color) => GestureDetector(
                    onTap: () => setState(() => _currentColor = color),
                    child: Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _currentColor == color ? Colors.black : Colors.grey,
                          width: _currentColor == color ? 2 : 1,
                        ),
                      ),
                    ),
                  )),
                ],
              ),
            ],
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
class SketchPainter extends CustomPainter {
  final List<SketchElement> elements;
  final SketchElement? currentElement;

  SketchPainter(this.elements, [this.currentElement]);

  @override
  void paint(Canvas canvas, Size size) {
    // 🎨 Dessiner le fond blanc d'abord
    final backgroundPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

    // Dessiner tous les éléments du croquis
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

  void _drawVehicle(Canvas canvas, Offset position, Paint paint) {
    final rect = Rect.fromCenter(center: position, width: 40, height: 20);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
  }

  void _drawArrow(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;
    
    final start = points.first;
    final end = points.last;
    
    // Ligne principale
    canvas.drawLine(start, end, paint);
    
    // Pointe de flèche
    final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    final arrowLength = 15.0;
    final arrowAngle = math.pi / 6;
    
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

  void _drawSign(Canvas canvas, Offset position, Paint paint) {
    final path = Path();
    path.moveTo(position.dx, position.dy - 15);
    path.lineTo(position.dx - 13, position.dy + 15);
    path.lineTo(position.dx + 13, position.dy + 15);
    path.close();
    canvas.drawPath(path, paint);
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
