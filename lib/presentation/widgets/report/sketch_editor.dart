// lib/presentation/widgets/report/sketch_editor.dart

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:math' as math; // Importer math pour cos et sin
import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;

class SketchEditor extends StatefulWidget {
  final Function(String, Map<String, dynamic>) onSaved;
  
  const SketchEditor({
    super.key,
    required this.onSaved,
  });
  
  @override
  State<SketchEditor> createState() => _SketchEditorState();
}

class _SketchEditorState extends State<SketchEditor> {
  final List<DrawingPoint> _points = [];
  final List<DrawingPoint> _redoPoints = [];
  final double _selectedWidth = 3.0; // Maintenant final
  Color _selectedColor = Colors.black;
  DrawingMode _drawingMode = DrawingMode.freeform;
  DrawingObject _selectedObject = DrawingObject.none;
  bool _isDrawing = false;
  Offset? _startPoint;
  Offset? _endPoint;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Dessinez un croquis de l\'accident',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Barre d'outils
        _buildToolbar(),
        const SizedBox(height: 8),
        
        // Zone de dessin
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                height: 400,
                color: Colors.white,
                child: CustomPaint(
                  painter: SketchPainter(
                    points: _points,
                    drawingMode: _drawingMode,
                    startPoint: _startPoint,
                    endPoint: _endPoint,
                    selectedObject: _selectedObject,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        
        // Boutons d'action
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: _points.isEmpty ? null : _undo,
              icon: const Icon(Icons.undo),
              label: const Text('Annuler'),
            ),
            ElevatedButton.icon(
              onPressed: _redoPoints.isEmpty ? null : _redo,
              icon: const Icon(Icons.redo),
              label: const Text('Rétablir'),
            ),
            ElevatedButton.icon(
              onPressed: _points.isEmpty ? null : _clear,
              icon: const Icon(Icons.delete),
              label: const Text('Effacer'),
            ),
            ElevatedButton.icon(
              onPressed: _points.isEmpty ? null : _saveSketch,
              icon: const Icon(Icons.save),
              label: const Text('Enregistrer'),
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildToolbar() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // Modes de dessin
        ToggleButtons(
          isSelected: [
            _drawingMode == DrawingMode.freeform,
            _drawingMode == DrawingMode.line,
            _drawingMode == DrawingMode.object,
          ],
          onPressed: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _drawingMode = DrawingMode.freeform;
                  _selectedObject = DrawingObject.none;
                  break;
                case 1:
                  _drawingMode = DrawingMode.line;
                  _selectedObject = DrawingObject.none;
                  break;
                case 2:
                  _drawingMode = DrawingMode.object;
                  _selectedObject = DrawingObject.car;
                  break;
              }
            });
          },
          children: const [
            Tooltip(
              message: 'Dessin libre',
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.edit),
              ),
            ),
            Tooltip(
              message: 'Ligne droite',
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.show_chart),
              ),
            ),
            Tooltip(
              message: 'Objets',
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: Icon(Icons.directions_car),
              ),
            ),
          ],
        ),
        
        const SizedBox(width: 8),
        
        // Sélection d'objets (visible uniquement en mode objet)
        if (_drawingMode == DrawingMode.object)
          ToggleButtons(
            isSelected: [
              _selectedObject == DrawingObject.car,
              _selectedObject == DrawingObject.pedestrian,
              _selectedObject == DrawingObject.arrow,
            ],
            onPressed: (index) {
              setState(() {
                switch (index) {
                  case 0:
                    _selectedObject = DrawingObject.car;
                    break;
                  case 1:
                    _selectedObject = DrawingObject.pedestrian;
                    break;
                  case 2:
                    _selectedObject = DrawingObject.arrow;
                    break;
                }
              });
            },
            children: const [
              Tooltip(
                message: 'Voiture',
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.directions_car),
                ),
              ),
              Tooltip(
                message: 'Piéton',
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.directions_walk),
                ),
              ),
              Tooltip(
                message: 'Flèche',
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        
        const SizedBox(width: 8),
        
        // Sélection de couleur
        ToggleButtons(
          isSelected: [
            _selectedColor == Colors.black,
            _selectedColor == Colors.red,
            _selectedColor == Colors.blue,
            _selectedColor == Colors.green,
          ],
          onPressed: (index) {
            setState(() {
              switch (index) {
                case 0:
                  _selectedColor = Colors.black;
                  break;
                case 1:
                  _selectedColor = Colors.red;
                  break;
                case 2:
                  _selectedColor = Colors.blue;
                  break;
                case 3:
                  _selectedColor = Colors.green;
                  break;
              }
            });
          },
          children: [
            Tooltip(
              message: 'Noir',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'Rouge',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'Bleu',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: 'Vert',
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  void _onPanStart(DragStartDetails details) {
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _isDrawing = true;
      _startPoint = localPosition;
      
      if (_drawingMode == DrawingMode.freeform) {
        _points.add(
          DrawingPoint(
            point: localPosition,
            color: _selectedColor.toHex(), // Utiliser toHex() au lieu de .value
            width: _selectedWidth,
            mode: _drawingMode,
            object: _selectedObject,
          ),
        );
      }
    });
  }
  
  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;
    
    RenderBox renderBox = context.findRenderObject() as RenderBox;
    Offset localPosition = renderBox.globalToLocal(details.globalPosition);
    
    setState(() {
      _endPoint = localPosition;
      
      if (_drawingMode == DrawingMode.freeform) {
        _points.add(
          DrawingPoint(
            point: localPosition,
            color: _selectedColor.toHex(), // Utiliser toHex() au lieu de .value
            width: _selectedWidth,
            mode: _drawingMode,
            object: _selectedObject,
          ),
        );
      }
    });
  }
  
  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;
    
    setState(() {
      _isDrawing = false;
      
      if (_drawingMode != DrawingMode.freeform && _startPoint != null && _endPoint != null) {
        _points.add(
          DrawingPoint(
            point: _startPoint!,
            endPoint: _endPoint,
            color: _selectedColor.toHex(), // Utiliser toHex() au lieu de .value
            width: _selectedWidth,
            mode: _drawingMode,
            object: _selectedObject,
          ),
        );
      }
      
      _redoPoints.clear();
    });
  }
  
  void _undo() {
    if (_points.isEmpty) return;
    
    setState(() {
      if (_drawingMode == DrawingMode.freeform) {
        // Pour le dessin libre, on cherche le dernier point d'une séquence
        int lastIndex = _points.length - 1;
        Offset lastPoint = _points[lastIndex].point;
        
        // On remonte jusqu'au début de la séquence
        while (lastIndex > 0) {
          if (_points[lastIndex - 1].point != lastPoint &&
              !_arePointsClose(_points[lastIndex - 1].point, lastPoint)) {
            break;
          }
          lastIndex--;
          lastPoint = _points[lastIndex].point;
        }
        
        // On déplace tous les points de cette séquence vers redoPoints
        _redoPoints.addAll(_points.sublist(lastIndex));
        _points.removeRange(lastIndex, _points.length);
      } else {
        // Pour les lignes et objets, on retire simplement le dernier élément
        _redoPoints.add(_points.removeLast());
      }
    });
  }
  
  bool _arePointsClose(Offset a, Offset b) {
    const double threshold = 10.0;
    return (a - b).distance < threshold;
  }
  
  void _redo() {
    if (_redoPoints.isEmpty) return;
    
    setState(() {
      _points.add(_redoPoints.removeLast());
    });
  }
  
  void _clear() {
    setState(() {
      _points.clear();
      _redoPoints.clear();
      _startPoint = null;
      _endPoint = null;
    });
  }
  
  Future<void> _saveSketch() async {
    try {
      // Convertir le croquis en image
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = SketchPainter(
        points: _points,
        drawingMode: DrawingMode.freeform, // Mode n'est pas important ici
        startPoint: null,
        endPoint: null,
        selectedObject: DrawingObject.none,
      );
      
      const size = Size(800, 600);
      painter.paint(canvas, size);
      final picture = recorder.endRecording();
      final img = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      
      // Générer un nom de fichier unique
      final fileName = 'sketch_${const Uuid().v4()}.png';
      final ref = FirebaseStorage.instance
          .ref()
          .child('sketches')
          .child(fileName);
      
      // Télécharger l'image
      await ref.putData(buffer);
      final imageUrl = await ref.getDownloadURL();
      
      // Préparer les données du croquis pour la sauvegarde
      final sketchData = {
        'points': _points.map((point) => point.toJson()).toList(),
        'width': size.width,
        'height': size.height,
      };
      
      // Appeler le callback onSaved
      widget.onSaved(imageUrl, sketchData);
      
      // Afficher un message de succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Croquis enregistré avec succès')),
        );
      }
    } catch (e) {
      // Afficher un message d'erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
        );
      }
    }
  }
}

// Extension pour convertir Color en hexadécimal
extension ColorExtension on Color {
  String toHex() => '#${(value & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
}

enum DrawingMode {
  freeform,
  line,
  object,
}

enum DrawingObject {
  none,
  car,
  pedestrian,
  arrow,
}

class DrawingPoint {
  final Offset point;
  final Offset? endPoint;
  final String color;
  final double width;
  final DrawingMode mode;
  final DrawingObject object;
  
  DrawingPoint({
    required this.point,
    this.endPoint,
    required this.color,
    required this.width,
    required this.mode,
    required this.object,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'pointX': point.dx,
      'pointY': point.dy,
      'endPointX': endPoint?.dx,
      'endPointY': endPoint?.dy,
      'color': color,
      'width': width,
      'mode': mode.toString(),
      'object': object.toString(),
    };
  }
}

class SketchPainter extends CustomPainter {
  final List<DrawingPoint> points;
  final DrawingMode drawingMode;
  final Offset? startPoint;
  final Offset? endPoint;
  final DrawingObject selectedObject;
  
  SketchPainter({
    required this.points,
    required this.drawingMode,
    required this.startPoint,
    required this.endPoint,
    required this.selectedObject,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner un fond blanc
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    // Dessiner tous les points existants
    for (int i = 0; i < points.length; i++) {
      final point = points[i];
      
      switch (point.mode) {
        case DrawingMode.freeform:
          if (i > 0 && points[i - 1].mode == DrawingMode.freeform) {
            // Dessiner une ligne entre les points
            canvas.drawLine(
              points[i - 1].point,
              point.point,
              Paint()
                ..color = _hexToColor(point.color)
                ..strokeWidth = point.width
                ..strokeCap = StrokeCap.round,
            );
          } else {
            // Dessiner un point
            canvas.drawCircle(
              point.point,
              point.width / 2,
              Paint()..color = _hexToColor(point.color),
            );
          }
          break;
          
        case DrawingMode.line:
          if (point.endPoint != null) {
            // Dessiner une ligne
            canvas.drawLine(
              point.point,
              point.endPoint!,
              Paint()
                ..color = _hexToColor(point.color)
                ..strokeWidth = point.width
                ..strokeCap = StrokeCap.round,
            );
          }
          break;
          
        case DrawingMode.object:
          if (point.endPoint != null) {
            // Dessiner un objet
            _drawObject(
              canvas,
              point.object,
              point.point,
              point.endPoint!,
              _hexToColor(point.color),
              point.width,
            );
          }
          break;
      }
    }
    
    // Dessiner l'aperçu en cours de dessin
    if (startPoint != null && endPoint != null) {
      switch (drawingMode) {
        case DrawingMode.freeform:
          // Géré par les points ajoutés en temps réel
          break;
          
        case DrawingMode.line:
          // Dessiner une ligne d'aperçu
          canvas.drawLine(
            startPoint!,
            endPoint!,
            Paint()
              ..color = Colors.black.withOpacity(0.5)
              ..strokeWidth = 3.0
              ..strokeCap = StrokeCap.round,
          );
          break;
          
        case DrawingMode.object:
          // Dessiner un aperçu de l'objet
          _drawObject(
            canvas,
            selectedObject,
            startPoint!,
            endPoint!,
            Colors.black.withOpacity(0.5),
            3.0,
          );
          break;
      }
    }
  }
  
  void _drawObject(
    Canvas canvas,
    DrawingObject object,
    Offset start,
    Offset end,
    Color color,
    double width,
  ) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = width
      ..style = PaintingStyle.stroke;
    
    switch (object) {
      case DrawingObject.car:
        // Dessiner une voiture simplifiée
        final rect = Rect.fromPoints(start, end);
        final center = rect.center;
        final carWidth = rect.width;
        final carLength = rect.height;
        
        // Corps de la voiture
        canvas.drawRect(rect, paint);
        
        // Toit
        final roofRect = Rect.fromCenter(
          center: center,
          width: carWidth * 0.7,
          height: carLength * 0.4,
        );
        canvas.drawRect(roofRect, paint);
        
        // Roues
        final wheelRadius = math.min(carWidth, carLength) * 0.15;
        canvas.drawCircle(
          Offset(rect.left + carWidth * 0.25, rect.top + carLength * 0.2),
          wheelRadius,
          paint,
        );
        canvas.drawCircle(
          Offset(rect.right - carWidth * 0.25, rect.top + carLength * 0.2),
          wheelRadius,
          paint,
        );
        canvas.drawCircle(
          Offset(rect.left + carWidth * 0.25, rect.bottom - carLength * 0.2),
          wheelRadius,
          paint,
        );
        canvas.drawCircle(
          Offset(rect.right - carWidth * 0.25, rect.bottom - carLength * 0.2),
          wheelRadius,
          paint,
        );
        break;
        
      case DrawingObject.pedestrian:
        // Dessiner un piéton simplifié
        final center = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);
        final radius = (end - start).distance / 2;
        
        // Tête
        canvas.drawCircle(
          Offset(center.dx, center.dy - radius * 0.6),
          radius * 0.2,
          paint,
        );
        
        // Corps
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 0.4),
          Offset(center.dx, center.dy + radius * 0.2),
          paint,
        );
        
        // Bras
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 0.2),
          Offset(center.dx - radius * 0.3, center.dy),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy - radius * 0.2),
          Offset(center.dx + radius * 0.3, center.dy),
          paint,
        );
        
        // Jambes
        canvas.drawLine(
          Offset(center.dx, center.dy + radius * 0.2),
          Offset(center.dx - radius * 0.3, center.dy + radius * 0.6),
          paint,
        );
        canvas.drawLine(
          Offset(center.dx, center.dy + radius * 0.2),
          Offset(center.dx + radius * 0.3, center.dy + radius * 0.6),
          paint,
        );
        break;
        
      case DrawingObject.arrow:
        // Dessiner une flèche
        final dx = end.dx - start.dx;
        final dy = end.dy - start.dy;
        final angle = math.atan2(dy, dx);
        
        // Ligne principale
        canvas.drawLine(start, end, paint);
        
        // Pointe de la flèche
        final arrowSize = width * 3;
        final arrowAngle1 = angle + math.pi * 3/4;
        final arrowAngle2 = angle - math.pi * 3/4;
        
        final arrowPoint1 = Offset(
          end.dx + arrowSize * math.cos(arrowAngle1),
          end.dy + arrowSize * math.sin(arrowAngle1),
        );
        
        final arrowPoint2 = Offset(
          end.dx + arrowSize * math.cos(arrowAngle2),
          end.dy + arrowSize * math.sin(arrowAngle2),
        );
        
        canvas.drawLine(end, arrowPoint1, paint);
        canvas.drawLine(end, arrowPoint2, paint);
        break;
        
      case DrawingObject.none:
        // Ne rien dessiner
        break;
    }
  }
  
  Color _hexToColor(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}