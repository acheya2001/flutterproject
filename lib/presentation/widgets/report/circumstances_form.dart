// lib/presentation/widgets/report/circumstances_form.dart

import 'package:flutter/material.dart';
import 'package:constat_tunisie/data/models/accident_report_model.dart';

class CircumstancesForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final Function(Map<String, dynamic>) onSaved;
  final Map<String, dynamic> initialData;

  const CircumstancesForm({
    Key? key,
    required this.formKey,
    required this.onSaved,
    required this.initialData,
  }) : super(key: key);

  @override
  State<CircumstancesForm> createState() => _CircumstancesFormState();
}

class _CircumstancesFormState extends State<CircumstancesForm> {
  final TextEditingController _observationsController = TextEditingController();
  final List<bool> _selectedCircumstances = List.filled(17, false);
  final List<String> _circumstanceLabels = [
    'En stationnement',
    'Quittait un stationnement',
    'Prenait un stationnement',
    'Sortait d\'un parking, d\'un lieu privé, d\'un chemin de terre',
    'S\'engageait dans un parking, un lieu privé, un chemin de terre',
    'S\'engageait sur une place à sens giratoire',
    'Roulait sur une place à sens giratoire',
    'Heurtait à l\'arrière en roulant dans le même sens et sur une même file',
    'Roulait dans le même sens et sur une file différente',
    'Changeait de file',
    'Doublait',
    'Virait à droite',
    'Virait à gauche',
    'Reculait',
    'Empiétait sur une voie réservée à la circulation en sens inverse',
    'Venait de droite (dans un carrefour)',
    'N\'avait pas observé un signal de priorité ou un feu rouge',
  ];
  
  int? _selectedImpactPoint;
  final List<String> _impactPointLabels = [
    'Avant',
    'Avant droit',
    'Milieu droit',
    'Arrière droit',
    'Arrière',
    'Arrière gauche',
    'Milieu gauche',
    'Avant gauche',
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialiser les contrôleurs avec les données existantes
    _observationsController.text = widget.initialData['observationsA'] ?? '';
    
    // Initialiser les circonstances sélectionnées
    final List<int>? circumstances = widget.initialData['circumstancesA'];
    if (circumstances != null) {
      for (int i = 0; i < circumstances.length; i++) {
        final index = circumstances[i];
        if (index >= 0 && index < _selectedCircumstances.length) {
          _selectedCircumstances[index] = true;
        }
      }
    }
    
    // Initialiser le point d'impact
    _selectedImpactPoint = widget.initialData['initialImpact'];
  }

  @override
  void dispose() {
    _observationsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Circonstances de l\'accident',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          const Text(
            'Cochez les cases correspondant aux circonstances de l\'accident:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          // Liste des circonstances
          ...List.generate(_circumstanceLabels.length, (index) {
            return CheckboxListTile(
              title: Text(_circumstanceLabels[index]),
              value: _selectedCircumstances[index],
              onChanged: (bool? value) {
                setState(() {
                  _selectedCircumstances[index] = value ?? false;
                });
              },
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            );
          }),
          
          const Divider(height: 32),
          
          const Text(
            'Point d\'impact initial sur votre véhicule:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          // Schéma du véhicule pour sélectionner le point d'impact
          Container(
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                // Image du véhicule (à remplacer par votre propre image)
                Center(
                  child: Image.asset(
                    'assets/images/vehicle_outline.png',
                    fit: BoxFit.contain,
                  ),
                ),
                
                // Points d'impact
                ...List.generate(_impactPointLabels.length, (index) {
                  // Positions relatives des points d'impact
                  final positions = [
                    const Offset(0.5, 0.1),  // Avant
                    const Offset(0.8, 0.2),  // Avant droit
                    const Offset(0.9, 0.5),  // Milieu droit
                    const Offset(0.8, 0.8),  // Arrière droit
                    const Offset(0.5, 0.9),  // Arrière
                    const Offset(0.2, 0.8),  // Arrière gauche
                    const Offset(0.1, 0.5),  // Milieu gauche
                    const Offset(0.2, 0.2),  // Avant gauche
                  ];
                  
                  return Positioned(
                    left: positions[index].dx * 200,
                    top: positions[index].dy * 200,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedImpactPoint = index;
                        });
                      },
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedImpactPoint == index
                              ? Colors.red
                              : Colors.grey.withOpacity(0.5),
                          border: Border.all(
                            color: _selectedImpactPoint == index
                                ? Colors.red.shade800
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: TextStyle(
                              color: _selectedImpactPoint == index
                                  ? Colors.white
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Légende des points d'impact
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(_impactPointLabels.length, (index) {
              return Chip(
                label: Text('${index + 1}: ${_impactPointLabels[index]}'),
                backgroundColor: _selectedImpactPoint == index
                    ? Colors.red.shade100
                    : Colors.grey.shade200,
              );
            }),
          ),
          
          const SizedBox(height: 16),
          
          TextFormField(
            controller: _observationsController,
            decoration: const InputDecoration(
              labelText: 'Observations',
              hintText: 'Précisez les circonstances ou dommages...',
              alignLabelWithHint: true,
            ),
            maxLines: 4,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Cette méthode est appelée lorsque le formulaire est soumis
  void save() {
    // Convertir les circonstances sélectionnées en liste d'indices
    final List<int> circumstances = [];
    for (int i = 0; i < _selectedCircumstances.length; i++) {
      if (_selectedCircumstances[i]) {
        circumstances.add(i);
      }
    }
    
    final data = {
      'circumstancesA': circumstances,
      'initialImpact': _selectedImpactPoint,
      'observationsA': _observationsController.text,
    };
    widget.onSaved(data);
  }
}