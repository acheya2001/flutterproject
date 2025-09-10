import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

/// 🎨 Widget de croquis interactif pour dessiner l'accident
class CroquisInteractifWidget extends StatefulWidget {
  final Function(Uint8List) onCroquisComplete;
  final Uint8List? croquisInitial;

  const CroquisInteractifWidget({
    super.key,
    required this.onCroquisComplete,
    this.croquisInitial,
  });

  @override
  State<CroquisInteractifWidget> createState() => _CroquisInteractifWidgetState();
}

class _CroquisInteractifWidgetState extends State<CroquisInteractifWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<Path> _paths = [];
  final List<Paint> _paints = [];
  Color _couleurActuelle = Colors.black;
  double _epaisseurActuelle = 3.0;
  bool _modeGomme = false;

  @override
  void initState() {
    super.initState();

    // Utiliser WidgetsBinding pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.croquisInitial != null) {
        _chargerCroquisInitial();
      }
    });
  }

  void _chargerCroquisInitial() {
    // TODO: Charger le croquis initial depuis les bytes
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre d'outils
        _buildBarreOutils(),
        
        // Zone de dessin
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: RepaintBoundary(
                key: _repaintBoundaryKey,
                child: Container(
                  color: Colors.white,
                  child: CustomPaint(
                    painter: CroquisPainter(_paths, _paints),
                    child: GestureDetector(
                      onPanStart: _onPanStart,
                      onPanUpdate: _onPanUpdate,
                      onPanEnd: _onPanEnd,
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        // Actions
        _buildActions(),
      ],
    );
  }

  Widget _buildBarreOutils() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Column(
        children: [
          // Couleurs
          Row(
            children: [
              const Text('Couleur: ', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...[
                Colors.black,
                Colors.red,
                Colors.blue,
                Colors.green,
                Colors.orange,
                Colors.purple,
              ].map((couleur) => GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _couleurActuelle = couleur;
                      _modeGomme = false;
                    });
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: couleur,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _couleurActuelle == couleur ? Colors.grey[800]! : Colors.grey[300]!,
                      width: _couleurActuelle == couleur ? 3 : 1,
                    ),
                  ),
                ),
              )),
              const Spacer(),
              // Gomme
              GestureDetector(
                onTap: () {
                  if (mounted) {
                    setState(() {
                      _modeGomme = !_modeGomme;
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _modeGomme ? Colors.red[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _modeGomme ? Colors.red : Colors.grey,
                    ),
                  ),
                  child: Icon(
                    Icons.cleaning_services,
                    color: _modeGomme ? Colors.red : Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Épaisseur
          Row(
            children: [
              const Text('Épaisseur: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: Slider(
                  value: _epaisseurActuelle,
                  min: 1.0,
                  max: 10.0,
                  divisions: 9,
                  label: _epaisseurActuelle.round().toString(),
                  onChanged: (value) {
                    if (mounted) {
                      setState(() {
                        _epaisseurActuelle = value;
                      });
                    }
                  },
                ),
              ),
              Text('${_epaisseurActuelle.round()}px'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _effacerTout,
              icon: const Icon(Icons.clear_all),
              label: const Text('Effacer tout'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _annulerDernierTrait,
              icon: const Icon(Icons.undo),
              label: const Text('Annuler'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: _sauvegarderCroquis,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save),
              label: const Text('Sauvegarder'),
            ),
          ),
        ],
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final path = Path();
    path.moveTo(details.localPosition.dx, details.localPosition.dy);
    
    final paint = Paint()
      ..color = _modeGomme ? Colors.white : _couleurActuelle
      ..strokeWidth = _modeGomme ? _epaisseurActuelle * 3 : _epaisseurActuelle
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (mounted) {
      setState(() {
        _paths.add(path);
        _paints.add(paint);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_paths.isNotEmpty) {
      if (mounted) {
        setState(() {
          _paths.last.lineTo(details.localPosition.dx, details.localPosition.dy);
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // Trait terminé
  }

  void _effacerTout() {
    if (mounted) {
      setState(() {
        _paths.clear();
        _paints.clear();
      });
    }
  }

  void _annulerDernierTrait() {
    if (_paths.isNotEmpty) {
      if (mounted) {
        setState(() {
          _paths.removeLast();
          _paints.removeLast();
        });
      }
    }
  }

  Future<void> _sauvegarderCroquis() async {
    try {
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        widget.onCroquisComplete(pngBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Croquis sauvegardé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// 🎨 Painter personnalisé pour dessiner les traits
class CroquisPainter extends CustomPainter {
  final List<Path> paths;
  final List<Paint> paints;

  CroquisPainter(this.paths, this.paints);

  @override
  void paint(Canvas canvas, Size size) {
    // Dessiner le fond avec une grille légère
    _dessinerGrille(canvas, size);
    
    // Dessiner tous les traits
    for (int i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], paints[i]);
    }
  }

  void _dessinerGrille(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[200]!
      ..strokeWidth = 0.5;

    const espacement = 20.0;

    // Lignes verticales
    for (double x = 0; x <= size.width; x += espacement) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Lignes horizontales
    for (double y = 0; y <= size.height; y += espacement) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// ✍️ Widget de signature électronique
class SignatureElectroniqueWidget extends StatefulWidget {
  final Function(Uint8List) onSignatureComplete;
  final String nomConducteur;

  const SignatureElectroniqueWidget({
    super.key,
    required this.onSignatureComplete,
    required this.nomConducteur,
  });

  @override
  State<SignatureElectroniqueWidget> createState() => _SignatureElectroniqueWidgetState();
}

class _SignatureElectroniqueWidgetState extends State<SignatureElectroniqueWidget> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final List<Path> _paths = [];
  bool _aDessinee = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Signature de ${widget.nomConducteur}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Signez dans la zone ci-dessous pour valider votre partie du constat',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        
        // Zone de signature
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: RepaintBoundary(
              key: _repaintBoundaryKey,
              child: Container(
                color: Colors.grey[50],
                child: CustomPaint(
                  painter: SignaturePainter(_paths),
                  child: GestureDetector(
                    onPanStart: _onPanStart,
                    onPanUpdate: _onPanUpdate,
                    onPanEnd: _onPanEnd,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: _paths.isEmpty
                          ? const Center(
                              child: Text(
                                'Signez ici',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 18,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _effacerSignature,
                icon: const Icon(Icons.clear),
                label: const Text('Effacer'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _aDessinee ? _validerSignature : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.check),
                label: const Text('Valider Signature'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    final path = Path();
    path.moveTo(details.localPosition.dx, details.localPosition.dy);
    
    if (mounted) {
      setState(() {
        _paths.add(path);
        _aDessinee = true;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_paths.isNotEmpty) {
      if (mounted) {
        setState(() {
          _paths.last.lineTo(details.localPosition.dx, details.localPosition.dy);
        });
      }
    }
  }

  void _onPanEnd(DragEndDetails details) {
    // Signature terminée
  }

  void _effacerSignature() {
    if (mounted) {
      setState(() {
        _paths.clear();
        _aDessinee = false;
      });
    }
  }

  Future<void> _validerSignature() async {
    try {
      final RenderRepaintBoundary boundary = _repaintBoundaryKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();
        widget.onSignatureComplete(pngBytes);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Signature validée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la validation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// ✍️ Painter pour la signature
class SignaturePainter extends CustomPainter {
  final List<Path> paths;

  SignaturePainter(this.paths);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


