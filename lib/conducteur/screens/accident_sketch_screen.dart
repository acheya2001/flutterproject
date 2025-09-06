import 'package:flutter/material.dart';
import 'package:signature/signature.dart';

/// 🎨 Écran de croquis d'accident (Section 13)
class AccidentSketchScreen extends StatefulWidget {
  final String sessionId;
  final Map<String, dynamic>? existingSketchData;

  const AccidentSketchScreen({
    Key? key,
    required this.sessionId,
    this.existingSketchData,
  }) : super(key: key);

  @override
  State<AccidentSketchScreen> createState() => _AccidentSketchScreenState();
}

class _AccidentSketchScreenState extends State<AccidentSketchScreen> {
  late SignatureController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = SignatureController(
      penStrokeWidth: 2.0,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );

    // Charger le croquis existant si disponible
    if (widget.existingSketchData != null) {
      // TODO: Charger les données existantes
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 💾 Sauvegarder le croquis
  Future<void> _saveSketch() async {
    if (_controller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez dessiner le croquis avant de sauvegarder'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final signature = await _controller.toPngBytes();
      
      if (signature != null) {
        // TODO: Sauvegarder dans Firebase Storage et mettre à jour la session
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Croquis sauvegardé avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 🗑️ Effacer le croquis
  void _clearSketch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer le croquis'),
        content: const Text('Êtes-vous sûr de vouloir effacer le croquis ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              _controller.clear();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Effacer'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Croquis de l\'Accident',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue[600],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _clearSketch,
            icon: const Icon(Icons.clear),
            tooltip: 'Effacer',
          ),
          IconButton(
            onPressed: _isLoading ? null : _saveSketch,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.save),
            tooltip: 'Sauvegarder',
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue[50],
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Section 13 - Croquis de l\'accident',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Dessinez un schéma simple de l\'accident en indiquant :\n'
                  '• La position des véhicules avant l\'impact\n'
                  '• Le sens de circulation\n'
                  '• Les éléments de la route (feux, panneaux, etc.)',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Zone de dessin
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Signature(
                  controller: _controller,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          // Outils de dessin
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Épaisseur du trait:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Slider(
                        value: 2.0, // Valeur fixe pour l'instant
                        min: 1.0,
                        max: 5.0,
                        divisions: 4,
                        onChanged: (value) {
                          // TODO: Implémenter le changement d'épaisseur
                        },
                      ),
                    ),
                    const Text('2px'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text(
                      'Couleur:',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    _buildColorButton(Colors.black),
                    const SizedBox(width: 8),
                    _buildColorButton(Colors.red),
                    const SizedBox(width: 8),
                    _buildColorButton(Colors.blue),
                    const SizedBox(width: 8),
                    _buildColorButton(Colors.green),
                    const SizedBox(width: 8),
                    _buildColorButton(Colors.orange),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _clearSketch,
                        icon: const Icon(Icons.clear),
                        label: const Text('Effacer'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveSketch,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Sauvegarder'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[600],
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorButton(Color color) {
    final isSelected = color == Colors.black; // Couleur par défaut

    return GestureDetector(
      onTap: () {
        // TODO: Implémenter le changement de couleur
      },
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.grey[800]! : Colors.grey[300]!,
            width: isSelected ? 3 : 1,
          ),
        ),
      ),
    );
  }
}
