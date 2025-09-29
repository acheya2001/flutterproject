import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📝 Méthodes auxiliaires pour le formulaire combiné des invités
/// Ce fichier contient les méthodes pour les étapes restantes et les fonctions utilitaires

/// 🚨 ÉTAPE 6: Informations accident
Widget buildStep6AccidentInfo(
  BuildContext context,
  TextEditingController lieuAccidentController,
  TextEditingController villeAccidentController,
  TextEditingController descriptionAccidentController,
  DateTime? dateAccident,
  TimeOfDay? heureAccident,
  Function(BuildContext, String) selectDate,
  Function(BuildContext) selectTime,
) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.red[50]!, Colors.red[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🚨 Informations de l\'Accident',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Détails du lieu et des circonstances de l\'accident',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Date et heure de l'accident
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () => selectDate(context, 'accident'),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date de l\'accident *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    dateAccident != null
                        ? '${dateAccident.day}/${dateAccident.month}/${dateAccident.year}'
                        : 'Sélectionner la date',
                    style: TextStyle(
                      color: dateAccident != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: () => selectTime(context),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Heure de l\'accident *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  child: Text(
                    heureAccident != null
                        ? '${heureAccident.hour.toString().padLeft(2, '0')}:${heureAccident.minute.toString().padLeft(2, '0')}'
                        : 'Sélectionner l\'heure',
                    style: TextStyle(
                      color: heureAccident != null ? Colors.black : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Lieu de l'accident
        TextFormField(
          controller: lieuAccidentController,
          decoration: const InputDecoration(
            labelText: 'Lieu de l\'accident *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
            hintText: 'Adresse précise ou description du lieu',
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le lieu de l\'accident est obligatoire';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Ville de l'accident
        TextFormField(
          controller: villeAccidentController,
          decoration: const InputDecoration(
            labelText: 'Ville *',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_city),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La ville est obligatoire';
            }
            return null;
          },
        ),

        const SizedBox(height: 16),

        // Description de l'accident
        TextFormField(
          controller: descriptionAccidentController,
          decoration: const InputDecoration(
            labelText: 'Description de l\'accident',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Décrivez brièvement ce qui s\'est passé...',
          ),
          maxLines: 4,
        ),

        const SizedBox(height: 32),
      ],
    ),
  );
}

/// 💥 ÉTAPE 7: Dégâts et points de choc
Widget buildStep7DamageInfo(
  BuildContext context,
  List<String> pointsChocSelectionnes,
  List<String> degatsApparents,
  TextEditingController descriptionDegatsController,
  Function(String) togglePointChoc,
  Function(String) toggleDegat,
) {
  final pointsChocDisponibles = [
    'Avant gauche',
    'Avant centre',
    'Avant droit',
    'Côté gauche',
    'Côté droit',
    'Arrière gauche',
    'Arrière centre',
    'Arrière droit',
    'Toit',
    'Dessous',
  ];

  final degatsDisponibles = [
    'Rayures',
    'Bosses',
    'Éclats de peinture',
    'Phares cassés',
    'Pare-brise fissuré',
    'Rétroviseurs endommagés',
    'Pare-chocs déformé',
    'Portières enfoncées',
    'Capot déformé',
    'Coffre endommagé',
    'Pneus crevés',
  ];

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.orange[50]!, Colors.orange[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.build, color: Colors.orange[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '💥 Dégâts et Points de Choc',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Indiquez les zones endommagées et les types de dégâts',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Points de choc
        const Text(
          'Points de choc',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pointsChocDisponibles.map((point) {
            final isSelected = pointsChocSelectionnes.contains(point);
            return FilterChip(
              label: Text(point),
              selected: isSelected,
              onSelected: (selected) => togglePointChoc(point),
              selectedColor: Colors.orange[100],
              checkmarkColor: Colors.orange[700],
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Dégâts apparents
        const Text(
          'Dégâts apparents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: degatsDisponibles.map((degat) {
            final isSelected = degatsApparents.contains(degat);
            return FilterChip(
              label: Text(degat),
              selected: isSelected,
              onSelected: (selected) => toggleDegat(degat),
              selectedColor: Colors.red[100],
              checkmarkColor: Colors.red[700],
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Description détaillée des dégâts
        TextFormField(
          controller: descriptionDegatsController,
          decoration: const InputDecoration(
            labelText: 'Description détaillée des dégâts',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            hintText: 'Décrivez précisément les dégâts observés...',
          ),
          maxLines: 4,
        ),

        const SizedBox(height: 32),
      ],
    ),
  );
}

/// 📋 ÉTAPE 8: Circonstances
Widget buildStep8Circumstances(
  BuildContext context,
  List<String> circonstancesSelectionnees,
  TextEditingController observationsController,
  Function(String) toggleCirconstance,
) {
  final circonstancesDisponibles = [
    'Stationnait, était arrêté',
    'Quittait un stationnement, sortait d\'un parking',
    'Prenait un stationnement, entrait dans un parking',
    'Sortait d\'un chemin privé, d\'un lieu non ouvert à la circulation',
    'S\'engageait dans un chemin privé, dans un lieu non ouvert à la circulation',
    'S\'engageait sur une place à sens giratoire',
    'Circulait sur une place à sens giratoire',
    'Heurtait par l\'arrière dans le même sens de circulation',
    'Circulait dans le même sens et sur la même file',
    'Changeait de file',
    'Doublait',
    'Virait à droite',
    'Virait à gauche',
    'Reculait',
    'Empiétait sur une voie réservée à la circulation en sens inverse',
  ];

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // En-tête
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[50]!, Colors.blue[100]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.list_alt, color: Colors.blue[700], size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '📋 Circonstances de l\'Accident',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sélectionnez les circonstances qui correspondent à votre situation',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        const Text(
          'Circonstances (sélection multiple possible)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 16),

        ...circonstancesDisponibles.asMap().entries.map((entry) {
          final index = entry.key;
          final circonstance = entry.value;
          final isSelected = circonstancesSelectionnees.contains(circonstance);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: CheckboxListTile(
              title: Text(
                '${index + 1}. $circonstance',
                style: const TextStyle(fontSize: 14),
              ),
              value: isSelected,
              onChanged: (value) => toggleCirconstance(circonstance),
              activeColor: Colors.blue[600],
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
            ),
          );
        }).toList(),

        const SizedBox(height: 24),

        // Observations
        TextFormField(
          controller: observationsController,
          decoration: const InputDecoration(
            labelText: 'Observations personnelles',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.note),
            hintText: 'Ajoutez vos observations ou précisions...',
          ),
          maxLines: 4,
        ),

        const SizedBox(height: 32),
      ],
    ),
  );
}
