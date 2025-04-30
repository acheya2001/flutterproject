// lib/presentation/widgets/report/signature_pad.dart

import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:constat_tunisie/data/services/report_service.dart';

class SignaturePad extends StatefulWidget {
  final Function(String) onSaved;
  
  const SignaturePad({
    super.key,
    required this.onSaved,
  });

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<DrawingPoint> _points = [];
  bool _isLoading = false;
  final ReportService _reportService = ReportService();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Signature',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Signez dans la zone ci-dessous pour valider le constat.',
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        
        // Zone de signature
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          width: double.infinity,
          height: 200,
          child: GestureDetector(
            onPanStart: (details) {
              setState(() {
                _points.add(
                  DrawingPoint(
                    offset: details.localPosition,
                    paint: Paint()
                      ..color = Colors.black
                      ..strokeWidth = 3.0
                      ..strokeCap = StrokeCap.round,
                  ),
                );
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _points.add(
                  DrawingPoint(
                    offset: details.localPosition,
                    paint: Paint()
                      ..color = Colors.black
                      ..strokeWidth = 3.0
                      ..strokeCap = StrokeCap.round,
                  ),
                );
              });
            },
            child: CustomPaint(
              painter: SignaturePainter(points: _points),
              size: Size.infinite,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _points.isEmpty ? null : _clearSignature,
                icon: const Icon(Icons.clear),
                label: const Text('Effacer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _points.isEmpty || _isLoading ? null : _saveSignature,
                icon: const Icon(Icons.save),
                label: _isLoading
                    ? const Text('Sauvegarde en cours...')
                    : const Text('Sauvegarder'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _clearSignature() {
    setState(() {
      _points.clear();
    });
  }

  Future<void> _saveSignature() async {
    if (_points.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez signer avant de sauvegarder')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Convertir la signature en image
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final painter = SignaturePainter(points: _points);
      painter.paint(canvas, const Size(400, 200));
      final picture = recorder.endRecording();
      final img = await picture.toImage(400, 200);
      final byteData = await img.toByteData(format: ImageByteFormat.png);
      final buffer = byteData!.buffer.asUint8List();
      
      // Sauvegarder l'image temporairement
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/signature.png');
      await file.writeAsBytes(buffer);
      
      // Uploader l'image
      final signatureUrl = await _reportService.uploadImage(
        file,
        'temp', // Sera remplacé par l'ID du rapport lors de la création
        'signature',
      );
      
      // Appeler le callback pour sauvegarder l'URL
      widget.onSaved(signatureUrl);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signature sauvegardée avec succès')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la sauvegarde: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

class DrawingPoint {
  final Offset offset;
  final Paint paint;
  
  DrawingPoint({
    required this.offset,
    required this.paint,
  });
}

class SignaturePainter extends CustomPainter {
  final List<DrawingPoint> points;
  
  SignaturePainter({required this.points});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner le fond
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );
    
    // Dessiner la signature
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i + 1] != null) {
        canvas.drawLine(
          points[i].offset,
          points[i + 1].offset,
          points[i].paint,
        );
      }
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}