import 'package:flutter/material.dart';

/// 🚗 Widget pour sélectionner les points de choc sur un véhicule
class VehiculePointChocWidget extends StatefulWidget {
  final Function(List<String>) onPointsChocChanged;
  final List<String> pointsChocInitiaux;

  const VehiculePointChocWidget({
    Key? key,
    required this.onPointsChocChanged,
    this.pointsChocInitiaux = const [],
  }) : super(key: key);

  @override
  State<VehiculePointChocWidget> createState() => _VehiculePointChocWidgetState();
}

class _VehiculePointChocWidgetState extends State<VehiculePointChocWidget> {
  List<String> _pointsChocSelectionnes = [];

  @override
  void initState() {
    super.initState();
    _pointsChocSelectionnes = List.from(widget.pointsChocInitiaux);
  }

  void _togglePointChoc(String point) {
    setState(() {
      if (_pointsChocSelectionnes.contains(point)) {
        _pointsChocSelectionnes.remove(point);
      } else {
        _pointsChocSelectionnes.add(point);
      }
    });
    widget.onPointsChocChanged(_pointsChocSelectionnes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app,
                  color: Colors.red[600],
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Points de Choc Initial',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Touchez les zones endommagées sur le véhicule',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF7F8C8D),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Véhicule avec points de choc
          Container(
            width: double.infinity,
            height: 350,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue[300]!, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Véhicule (vue de dessus) - ULTRA VISIBLE
                Center(
                  child: Container(
                    width: 160,
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.grey[100]!, Colors.white],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.black87, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          spreadRadius: 3,
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Étiquette AVANT
                        Positioned(
                          top: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🚗 AVANT',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        // Pare-brise avant
                        Positioned(
                          top: 50,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.lightBlue[300],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue[600]!, width: 1),
                            ),
                          ),
                        ),

                        // Étiquette ARRIÈRE
                        Positioned(
                          bottom: 20,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[600],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '🚗 ARRIÈRE',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),

                        // Pare-brise arrière
                        Positioned(
                          bottom: 50,
                          left: 20,
                          right: 20,
                          child: Container(
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.lightBlue[300],
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.blue[600]!, width: 1),
                            ),
                          ),
                        ),
                        // Étiquette CÔTÉ GAUCHE
                        Positioned(
                          top: 120,
                          left: -40,
                          child: Transform.rotate(
                            angle: -1.57, // -90 degrés
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.orange[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '⬅️ GAUCHE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Étiquette CÔTÉ DROIT
                        Positioned(
                          top: 120,
                          right: -40,
                          child: Transform.rotate(
                            angle: 1.57, // 90 degrés
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple[600],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '➡️ DROIT',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Roues avant gauche
                        Positioned(
                          top: 80,
                          left: -8,
                          child: Container(
                            width: 16,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!, width: 1),
                            ),
                          ),
                        ),
                        // Roues avant droite
                        Positioned(
                          top: 80,
                          right: -8,
                          child: Container(
                            width: 16,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!, width: 1),
                            ),
                          ),
                        ),
                        // Roues arrière gauche
                        Positioned(
                          bottom: 80,
                          left: -8,
                          child: Container(
                            width: 16,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!, width: 1),
                            ),
                          ),
                        ),
                        // Roues arrière droite
                        Positioned(
                          bottom: 80,
                          right: -8,
                          child: Container(
                            width: 16,
                            height: 25,
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[400]!, width: 1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Points de choc cliquables
                ..._buildPointsChoc(),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Légende des points sélectionnés
          if (_pointsChocSelectionnes.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Points de choc sélectionnés:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: _pointsChocSelectionnes.map((point) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          point,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[800],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildPointsChoc() {
    final points = [
      {'nom': '🚗 Avant', 'top': 10.0, 'left': 140.0},
      {'nom': '🚗 Arrière', 'bottom': 10.0, 'left': 140.0},
      {'nom': '⬅️ Côté Gauche', 'top': 150.0, 'left': 50.0},
      {'nom': '➡️ Côté Droit', 'top': 150.0, 'right': 50.0},
      {'nom': '↖️ Avant Gauche', 'top': 80.0, 'left': 80.0},
      {'nom': '↗️ Avant Droit', 'top': 80.0, 'right': 80.0},
      {'nom': '↙️ Arrière Gauche', 'bottom': 80.0, 'left': 80.0},
      {'nom': '↘️ Arrière Droit', 'bottom': 80.0, 'right': 80.0},
    ];

    return points.map((point) {
      final nom = point['nom'] as String;
      final isSelected = _pointsChocSelectionnes.contains(nom);

      return Positioned(
        top: point['top'] as double?,
        bottom: point['bottom'] as double?,
        left: point['left'] as double?,
        right: point['right'] as double?,
        child: GestureDetector(
          onTap: () {
            _togglePointChoc(nom);
            // Feedback haptique
            // HapticFeedback.lightImpact(); // Décommentez si vous voulez du feedback tactile
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isSelected ? 55 : 50,
            height: isSelected ? 55 : 50,
            decoration: BoxDecoration(
              color: isSelected ? Colors.red[600] : Colors.white,
              border: Border.all(
                color: isSelected ? Colors.red[800]! : Colors.blue[400]!,
                width: isSelected ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(isSelected ? 27.5 : 25),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                    ? Colors.red.withOpacity(0.4)
                    : Colors.blue.withOpacity(0.2),
                  spreadRadius: isSelected ? 3 : 1,
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              isSelected ? Icons.close : Icons.add,
              color: isSelected ? Colors.white : Colors.blue[600],
              size: isSelected ? 28 : 24,
            ),
          ),
        ),
      );
    }).toList();
  }
}
