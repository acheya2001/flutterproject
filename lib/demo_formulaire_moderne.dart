import 'package:flutter/material.dart';
import 'conducteur/screens/modern_single_accident_info_screen.dart';
import 'models/vehicule_model.dart';

/// 🎨 Écran de démonstration du formulaire modernisé
class DemoFormulaireModerne extends StatelessWidget {
  const DemoFormulaireModerne({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 Formulaire Modernisé'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[600]!.withOpacity(0.1),
              Colors.white,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header de démonstration
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Formulaire Modernisé',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                              Text(
                                'Design moderne avec GPS fonctionnel',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF7F8C8D),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Liste des améliorations
              Expanded(
                child: ListView(
                  children: [
                    _buildAmeliorationCard(
                      '🔧',
                      'GPS Fonctionnel',
                      'Bouton GPS avec feedback visuel complet',
                      Colors.blue,
                    ),
                    _buildAmeliorationCard(
                      '🎨',
                      'Design Moderne',
                      'Interface élégante avec couleurs thématiques',
                      Colors.purple,
                    ),
                    _buildAmeliorationCard(
                      '📱',
                      'UX Optimisée',
                      'Guidage utilisateur et feedback immédiat',
                      Colors.green,
                    ),
                    _buildAmeliorationCard(
                      '⚡',
                      'Performance',
                      'Chargement rapide et animations fluides',
                      Colors.orange,
                    ),
                    _buildAmeliorationCard(
                      '🛡️',
                      'Gestion d\'Erreurs',
                      'Messages clairs avec actions correctives',
                      Colors.red,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bouton de test
              ElevatedButton.icon(
                onPressed: () {
                  // Créer un véhicule de test
                  final vehiculeTest = VehiculeModel(
                    id: 'test-123',
                    conducteurId: 'test-conducteur',
                    marque: 'Peugeot',
                    modele: '208',
                    numeroImmatriculation: '123 TUN 456',
                    couleur: 'Blanc',
                    annee: 2023,
                    typeCarburant: 'Essence',
                    numeroPolice: 'POL-2023-001',
                    compagnieAssurance: 'Assurance Elite Tunisie',
                    agenceNom: 'Agence Centrale Tunis',
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ModernSingleAccidentInfoScreen(
                        typeAccident: 'Sortie de route',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Tester le Formulaire Modernisé'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Bouton info
              OutlinedButton.icon(
                onPressed: () {
                  _showInfoDialog(context);
                },
                icon: const Icon(Icons.info),
                label: const Text('Voir les Détails Techniques'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmeliorationCard(String emoji, String titre, String description, Color couleur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: couleur.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: couleur.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: couleur,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.check_circle,
            color: couleur,
            size: 20,
          ),
        ],
      ),
    );
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎨 Détails Techniques'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔧 Améliorations GPS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Gestion robuste des permissions'),
              Text('• Timeout de 15 secondes'),
              Text('• Feedback visuel complet'),
              Text('• Bouton de réessai automatique'),
              Text('• Affichage des coordonnées précises'),
              SizedBox(height: 12),
              Text(
                '🎨 Design Moderne:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Couleurs thématiques par section'),
              Text('• Cards avec ombres et élévations'),
              Text('• Typography hiérarchisée'),
              Text('• Dégradés et animations'),
              Text('• Interface responsive'),
              SizedBox(height: 12),
              Text(
                '📱 UX Optimisée:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Guidage utilisateur intuitif'),
              Text('• Feedback immédiat sur actions'),
              Text('• Gestion d\'erreurs claire'),
              Text('• Navigation fluide'),
              Text('• Accessibilité améliorée'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
