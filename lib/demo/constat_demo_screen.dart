import 'package:flutter/material.dart';
import '../conducteur/screens/constat_officiel_screen.dart';
import '../models/vehicule_model.dart';

/// 🎯 Écran de démonstration du nouveau constat officiel
class ConstatDemoScreen extends StatelessWidget {
  const ConstatDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démonstration Constat Officiel'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.description, color: Colors.blue[600], size: 28),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Nouveau Formulaire Conforme',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Formulaire de constat d\'accident conforme au modèle officiel tunisien avec toutes les sections requises.',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sections incluses
            const Text(
              'Sections incluses:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView(
                children: [
                  _buildSectionCard(
                    '📅 Cases 1-2',
                    'Date, Heure et Lieu',
                    'Sélection de date/heure et localisation GPS',
                    Icons.schedule,
                    Colors.blue,
                  ),
                  _buildSectionCard(
                    '🚑 Cases 3-4',
                    'Blessés et Dégâts',
                    'Déclaration des blessés et dégâts matériels',
                    Icons.local_hospital,
                    Colors.red,
                  ),
                  _buildSectionCard(
                    '👥 Case 5',
                    'Témoins',
                    'Ajout et gestion des témoins',
                    Icons.people,
                    Colors.orange,
                  ),
                  _buildSectionCard(
                    '🚗 Case 9',
                    'Identité des Véhicules',
                    'Marque, type, immatriculation, sens, origine/destination',
                    Icons.directions_car,
                    Colors.green,
                  ),
                  _buildSectionCard(
                    '🎯 Case 10',
                    'Point de Choc Initial',
                    'Schéma interactif pour localiser le point d\'impact',
                    Icons.my_location,
                    Colors.purple,
                  ),
                  _buildSectionCard(
                    '🔧 Case 11',
                    'Dégâts Apparents',
                    'Description et zones endommagées',
                    Icons.build,
                    Colors.brown,
                  ),
                  _buildSectionCard(
                    '📋 Case 12',
                    'Circonstances',
                    'Les 17 circonstances officielles avec compteur',
                    Icons.checklist,
                    Colors.indigo,
                  ),
                  _buildSectionCard(
                    '💬 Case 14',
                    'Observations',
                    'Observations par véhicule et générales',
                    Icons.comment,
                    Colors.teal,
                  ),
                  _buildSectionCard(
                    '✍️ Case 15',
                    'Signatures',
                    'Signatures des conducteurs avec acceptation de responsabilité',
                    Icons.draw,
                    Colors.pink,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Bouton de démonstration
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _ouvrirDemo(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'Tester le Formulaire Conforme',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String numero,
    String titre,
    String description,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$numero: $titre',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.check_circle,
              color: Colors.green[600],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _ouvrirDemo(BuildContext context) {
    // Créer un véhicule de démonstration
    final vehiculeDemo = VehiculeModel(
      id: 'demo_vehicle_001',
      conducteurId: 'demo_user_001',
      marque: 'Peugeot',
      modele: '208',
      numeroImmatriculation: '123 TUN 456',
      numeroSerie: 'VF3C56HZ8JS123456',
      annee: 2020,
      couleur: 'Blanc',
      typeCarburant: 'Essence',
      numeroMoteur: 'ENG123456',
      numeroChassiss: 'CHA789012',
      compagnieAssurance: 'STAR Assurances',
      numeroPolice: 'POL-2024-001',
      agenceId: 'agence_tunis_001',
      dateDebutAssurance: DateTime(2024, 1, 1),
      dateFinAssurance: DateTime(2024, 12, 31),
      contratActif: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConstatOfficielScreen(
          vehiculeSelectionne: vehiculeDemo,
        ),
      ),
    );
  }
}
