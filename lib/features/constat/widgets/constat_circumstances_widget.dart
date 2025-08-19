import 'package:flutter/material.dart';
import '../models/constat_officiel_model.dart';

/// 📝 Widget pour les circonstances de l'accident
class ConstatCircumstancesWidget extends StatefulWidget {
  final ConstatOfficielModel constat;
  final Function(ConstatOfficielModel) onChanged;

  const ConstatCircumstancesWidget({
    super.key,
    required this.constat,
    required this.onChanged,
  });

  @override
  State<ConstatCircumstancesWidget> createState() => _ConstatCircumstancesWidgetState();
}

class _ConstatCircumstancesWidgetState extends State<ConstatCircumstancesWidget> {
  // Circonstances prédéfinies selon le formulaire officiel
  final List<String> _circumstances = [
    'Se garait',
    'Sortait d\'un stationnement',
    'Prenait un stationnement',
    'Sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
    'S\'engageait dans un parking, un lieu privé, un chemin de terre',
    'S\'engageait sur une place à sens giratoire',
    'Circulait sur une place à sens giratoire',
    'Heurtait par l\'arrière',
    'Circulait dans le même sens et sur la même file',
    'Changeait de file',
    'Doublait',
    'Virait à droite',
    'Virait à gauche',
    'Reculait',
    'Empiétait sur une voie réservée à la circulation en sens inverse',
    'Venait de droite (dans un carrefour)',
    'N\'avait pas observé un signal d\'arrêt ou de cédez le passage',
  ];

  Map<String, Map<String, bool>> _selectedCircumstances = {};

  @override
  void initState() {
    super.initState();
    _initializeCircumstances();
  }

  void _initializeCircumstances() {
    // Initialiser les circonstances pour chaque partie
    for (final partie in widget.constat.parties) {
      _selectedCircumstances[partie.partieId] = {};
      
      // Récupérer les circonstances sauvegardées
      final savedCircumstances = widget.constat.circumstances[partie.partieId] as Map<String, dynamic>?;
      
      for (final circumstance in _circumstances) {
        _selectedCircumstances[partie.partieId]![circumstance] = 
            savedCircumstances?[circumstance] ?? false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '12. Circonstances de l\'accident',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Cochez les cases correspondant aux circonstances de l\'accident pour chaque véhicule',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 16),
        
        // Instructions
        _buildInstructions(),
        
        const SizedBox(height: 16),
        
        // Tableau des circonstances
        _buildCircumstancesTable(),
        
        const SizedBox(height: 16),
        
        // Résumé des circonstances sélectionnées
        _buildSummary(),
      ],
    );
  }

  Widget _buildInstructions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.amber[700]),
              const SizedBox(width: 8),
              Text(
                'Instructions importantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• Cochez toutes les cases qui correspondent à la situation de chaque véhicule\n'
            '• Plusieurs circonstances peuvent être cochées pour un même véhicule\n'
            '• Soyez précis et honnête dans vos déclarations\n'
            '• En cas de doute, laissez la case vide',
            style: TextStyle(
              fontSize: 14,
              color: Colors.amber[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircumstancesTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // En-tête du tableau
            _buildTableHeader(),
            
            const SizedBox(height: 8),
            
            // Lignes du tableau
            ..._circumstances.asMap().entries.map((entry) {
              final index = entry.key;
              final circumstance = entry.value;
              return _buildTableRow(index + 1, circumstance);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 40,
            child: Text(
              'N°',
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          const Expanded(
            flex: 3,
            child: Text(
              'Circonstances',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ...widget.constat.parties.map((partie) {
            final color = _getPartieColor(partie.partieId);
            return Expanded(
              child: Column(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        partie.partieId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    partie.numeroImmatriculation ?? 'N/A',
                    style: const TextStyle(fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTableRow(int number, String circumstance) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              number.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              circumstance,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          ...widget.constat.parties.map((partie) {
            final isSelected = _selectedCircumstances[partie.partieId]?[circumstance] ?? false;
            final canEdit = partie.isEditable;
            
            return Expanded(
              child: Center(
                child: Checkbox(
                  value: isSelected,
                  onChanged: canEdit ? (value) {
                    setState(() {
                      _selectedCircumstances[partie.partieId]![circumstance] = value ?? false;
                    });
                    _updateCircumstances();
                  } : null,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Résumé des circonstances',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            ...widget.constat.parties.map((partie) {
              final selectedCircumstances = _selectedCircumstances[partie.partieId]
                  ?.entries
                  .where((entry) => entry.value)
                  .map((entry) => entry.key)
                  .toList() ?? [];
              
              final color = _getPartieColor(partie.partieId);
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              partie.partieId,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${partie.numeroImmatriculation ?? 'N/A'} - ${partie.nomConducteur ?? 'Conducteur'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (selectedCircumstances.isEmpty)
                      Text(
                        'Aucune circonstance sélectionnée',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...selectedCircumstances.map((circumstance) {
                        final index = _circumstances.indexOf(circumstance) + 1;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '$index. $circumstance',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }),
                  ],
                ),
              );
            }),
          ],
        ),
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

  void _updateCircumstances() {
    final updatedCircumstances = <String, dynamic>{};
    
    for (final partie in widget.constat.parties) {
      updatedCircumstances[partie.partieId] = _selectedCircumstances[partie.partieId] ?? {};
    }
    
    final updatedConstat = widget.constat.copyWith(circumstances: updatedCircumstances);
    widget.onChanged(updatedConstat);
  }
}


