import 'package:flutter/material.dart';

/// 🚗 Écran de sélection du point de choc initial (Section 10)
class VehicleDamageScreen extends StatefulWidget {
  final String participantId;
  final Map<String, dynamic>? existingDamageData;

  const VehicleDamageScreen({
    Key? key,
    required this.participantId,
    this.existingDamageData,
  }) : super(key: key);

  @override
  State<VehicleDamageScreen> createState() => _VehicleDamageScreenState();
}

class _VehicleDamageScreenState extends State<VehicleDamageScreen> {
  Set<String> _selectedDamagePoints = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingDamageData != null) {
      _selectedDamagePoints = Set<String>.from(
        widget.existingDamageData!['selectedPoints'] ?? [],
      );
    }
  }

  /// 💾 Sauvegarder les points de choc
  Future<void> _saveDamagePoints() async {
    if (_selectedDamagePoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner au moins un point de choc'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Sauvegarder dans Firestore
      final damageData = {
        'selectedPoints': _selectedDamagePoints.toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Simuler la sauvegarde
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Points de choc sauvegardés avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context, damageData);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Point de Choc Initial',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.orange[600],
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveDamagePoints,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.orange[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Section 10 - Point de choc initial',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Indiquez par une flèche le point de choc initial sur votre véhicule.\n'
                    'Tapez sur les zones endommagées du schéma ci-dessous.',
                    style: TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Schéma du véhicule (vue de dessus)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Vue de dessus du véhicule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildVehicleTopView(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Schéma du véhicule (vue de côté)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Vue de côté du véhicule',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildVehicleSideView(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Points sélectionnés
            if (_selectedDamagePoints.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[600],
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Points de choc sélectionnés:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _selectedDamagePoints.map((point) {
                        return Chip(
                          label: Text(_getDamagePointLabel(point)),
                          backgroundColor: Colors.green[100],
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedDamagePoints.remove(point);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Bouton de sauvegarde
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _saveDamagePoints,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Sauvegarder les points de choc'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚗 Vue de dessus du véhicule
  Widget _buildVehicleTopView() {
    return Container(
      width: 200,
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Avant
          _buildDamagePoint('front', 0, 10, 200, 30, 'Avant'),
          // Arrière
          _buildDamagePoint('rear', 0, 260, 200, 30, 'Arrière'),
          // Côté gauche
          _buildDamagePoint('left', 0, 40, 30, 220, 'Côté gauche'),
          // Côté droit
          _buildDamagePoint('right', 170, 40, 30, 220, 'Côté droit'),
          // Avant gauche
          _buildDamagePoint('front_left', 0, 10, 50, 50, 'Avant gauche'),
          // Avant droit
          _buildDamagePoint('front_right', 150, 10, 50, 50, 'Avant droit'),
          // Arrière gauche
          _buildDamagePoint('rear_left', 0, 240, 50, 50, 'Arrière gauche'),
          // Arrière droit
          _buildDamagePoint('rear_right', 150, 240, 50, 50, 'Arrière droit'),
        ],
      ),
    );
  }

  /// 🚗 Vue de côté du véhicule
  Widget _buildVehicleSideView() {
    return Container(
      width: 300,
      height: 150,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[400]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          // Toit
          _buildDamagePoint('roof', 50, 0, 200, 30, 'Toit'),
          // Capot
          _buildDamagePoint('hood', 0, 30, 80, 60, 'Capot'),
          // Pare-brise
          _buildDamagePoint('windshield', 80, 30, 40, 60, 'Pare-brise'),
          // Portières
          _buildDamagePoint('doors', 120, 30, 80, 60, 'Portières'),
          // Lunette arrière
          _buildDamagePoint('rear_window', 200, 30, 40, 60, 'Lunette arrière'),
          // Coffre
          _buildDamagePoint('trunk', 240, 30, 60, 60, 'Coffre'),
          // Bas de caisse
          _buildDamagePoint('bottom', 50, 90, 200, 60, 'Bas de caisse'),
        ],
      ),
    );
  }

  /// 📍 Point de dégât cliquable
  Widget _buildDamagePoint(
    String pointId,
    double left,
    double top,
    double width,
    double height,
    String label,
  ) {
    final isSelected = _selectedDamagePoints.contains(pointId);

    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isSelected) {
              _selectedDamagePoints.remove(pointId);
            } else {
              _selectedDamagePoints.add(pointId);
            }
          });
        },
        child: Container(
          decoration: BoxDecoration(
            color: isSelected 
                ? Colors.red.withOpacity(0.7) 
                : Colors.transparent,
            border: Border.all(
              color: isSelected ? Colors.red : Colors.grey[300]!,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: isSelected
                ? const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
        ),
      ),
    );
  }

  /// 🏷️ Libellé du point de dégât
  String _getDamagePointLabel(String pointId) {
    switch (pointId) {
      case 'front':
        return 'Avant';
      case 'rear':
        return 'Arrière';
      case 'left':
        return 'Côté gauche';
      case 'right':
        return 'Côté droit';
      case 'front_left':
        return 'Avant gauche';
      case 'front_right':
        return 'Avant droit';
      case 'rear_left':
        return 'Arrière gauche';
      case 'rear_right':
        return 'Arrière droit';
      case 'roof':
        return 'Toit';
      case 'hood':
        return 'Capot';
      case 'windshield':
        return 'Pare-brise';
      case 'doors':
        return 'Portières';
      case 'rear_window':
        return 'Lunette arrière';
      case 'trunk':
        return 'Coffre';
      case 'bottom':
        return 'Bas de caisse';
      default:
        return pointId;
    }
  }
}
