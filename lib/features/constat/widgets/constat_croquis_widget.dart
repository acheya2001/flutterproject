import 'package:flutter/material.dart';
import '../models/constat_officiel_model.dart';

/// 🎨 Widget pour le croquis de l'accident
class ConstatCroquisWidget extends StatefulWidget {
  final ConstatOfficielModel constat;
  final Function(ConstatOfficielModel) onChanged;

  const ConstatCroquisWidget({
    super.key,
    required this.constat,
    required this.onChanged,
  });

  @override
  State<ConstatCroquisWidget> createState() => _ConstatCroquisWidgetState();
}

class _ConstatCroquisWidgetState extends State<ConstatCroquisWidget> {
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _descriptionController.text = widget.constat.croquis?.description ?? '';
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '13. Croquis de l\'accident',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Zone de dessin
        _buildDrawingArea(),
        
        const SizedBox(height: 16),
        
        // Légende des véhicules
        _buildVehicleLegend(),
        
        const SizedBox(height: 16),
        
        // Description
        _buildDescriptionSection(),
        
        const SizedBox(height: 16),
        
        // Instructions
        _buildInstructions(),
      ],
    );
  }

  Widget _buildDrawingArea() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Zone de dessin',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[50],
              ),
              child: Stack(
                children: [
                  // Grille de fond
                  _buildGrid(),
                  
                  // Véhicules positionnés
                  ..._buildVehiclePositions(),
                  
                  // Instructions de dessin
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Dessinez le croquis de l\'accident',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Positionnez les véhicules et ajoutez les détails',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Outils de dessin
            _buildDrawingTools(),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return CustomPaint(
      size: const Size(double.infinity, 300),
      painter: GridPainter(),
    );
  }

  List<Widget> _buildVehiclePositions() {
    final positions = widget.constat.croquis?.vehiculePositions ?? [];
    
    return positions.map((position) {
      final color = _getPartieColor(position.partieId);
      
      return Positioned(
        left: position.x,
        top: position.y,
        child: Transform.rotate(
          angle: position.rotation,
          child: GestureDetector(
            onPanUpdate: (details) {
              _updateVehiclePosition(position, details.delta);
            },
            child: Container(
              width: 60,
              height: 30,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  position.partieId,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildDrawingTools() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildToolButton(
          icon: Icons.directions_car,
          label: 'Véhicule',
          onPressed: _addVehicle,
        ),
        _buildToolButton(
          icon: Icons.linear_scale,
          label: 'Ligne',
          onPressed: _addLine,
        ),
        _buildToolButton(
          icon: Icons.text_fields,
          label: 'Texte',
          onPressed: _addText,
        ),
        _buildToolButton(
          icon: Icons.clear,
          label: 'Effacer',
          onPressed: _clearDrawing,
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon),
          style: IconButton.styleFrom(
            backgroundColor: Colors.blue[50],
            foregroundColor: Colors.blue[700],
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildVehicleLegend() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Légende des véhicules',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: widget.constat.parties.map((partie) {
                final color = _getPartieColor(partie.partieId);
                
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 30,
                      height: 20,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          partie.partieId,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${partie.numeroImmatriculation ?? 'N/A'} - ${partie.marqueVehicule ?? 'Véhicule'} ${partie.typeVehicule ?? ''}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Description de l\'accident',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                hintText: 'Décrivez les circonstances de l\'accident...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: _updateDescription,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Text(
                'Instructions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Positionnez les véhicules en les faisant glisser\n'
            '• Ajoutez des éléments pour clarifier la situation\n'
            '• Indiquez le sens de circulation avec des flèches\n'
            '• Marquez les points d\'impact',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPartieColor(String partieId) {
    switch (partieId) {
      case 'A':
        return Colors.blue;
      case 'B':
        return Colors.green;
      case 'C':
        return Colors.orange;
      case 'D':
        return Colors.purple;
      case 'E':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _updateVehiclePosition(ConstatVehiculePosition position, Offset delta) {
    // TODO: Implémenter la mise à jour de position
    final updatedPosition = ConstatVehiculePosition(
      partieId: position.partieId,
      x: (position.x + delta.dx).clamp(0.0, 300.0),
      y: (position.y + delta.dy).clamp(0.0, 270.0),
      rotation: position.rotation,
      color: position.color,
    );
    
    _updateCroquis();
  }

  void _addVehicle() {
    // TODO: Implémenter l'ajout de véhicule
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à implémenter')),
    );
  }

  void _addLine() {
    // TODO: Implémenter l'ajout de ligne
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à implémenter')),
    );
  }

  void _addText() {
    // TODO: Implémenter l'ajout de texte
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à implémenter')),
    );
  }

  void _clearDrawing() {
    // TODO: Implémenter l'effacement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Fonctionnalité à implémenter')),
    );
  }

  void _updateDescription(String value) {
    _updateCroquis();
  }

  void _updateCroquis() {
    final updatedCroquis = ConstatCroquisModel(
      croquisData: widget.constat.croquis?.croquisData,
      vehiculePositions: widget.constat.croquis?.vehiculePositions ?? [],
      description: _descriptionController.text,
    );
    
    final updatedConstat = widget.constat.copyWith(croquis: updatedCroquis);
    widget.onChanged(updatedConstat);
  }
}

/// Painter pour la grille de fond
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.5;

    const gridSize = 20.0;

    // Lignes verticales
    for (double x = 0; x <= size.width; x += gridSize) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }

    // Lignes horizontales
    for (double y = 0; y <= size.height; y += gridSize) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


