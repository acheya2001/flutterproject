import 'package:flutter/material.dart';
import 'conducteur/screens/modern_single_accident_info_screen.dart';

/// 🧪 Écran de test pour les nouvelles sections du constat
class TestNouvellesSections extends StatelessWidget {
  const TestNouvellesSections({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Nouvelles Sections'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '🎯 Test des nouvelles sections du constat papier',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            
            const Text(
              'Nouvelles sections ajoutées:',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF34495E),
              ),
            ),
            const SizedBox(height: 12),
            
            _buildSectionCard('📍', 'Section 10', 'Point de choc initial', 'Position et description du choc'),
            _buildSectionCard('💥', 'Section 11', 'Dégâts apparents', 'Types de dégâts et photos'),
            _buildSectionCard('🎨', 'Section 13', 'Croquis de l\'accident', 'Dessin et annotations'),
            _buildSectionCard('📝', 'Section 14', 'Observations', 'Remarques et observations'),
            
            const SizedBox(height: 30),
            
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ModernSingleAccidentInfoScreen(
                      typeAccident: 'sortie_route',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('Tester l\'écran de constat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                _showInfoDialog(context);
              },
              icon: const Icon(Icons.info),
              label: const Text('Informations sur les corrections'),
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
    );
  }

  Widget _buildSectionCard(String emoji, String numero, String titre, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$numero: $titre',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50),
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
          const Icon(
            Icons.check_circle,
            color: Colors.green,
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
        title: const Text('✅ Corrections apportées'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔧 Problèmes corrigés:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bouton GPS fonctionnel avec gestion d\'erreurs'),
              Text('• Ajout des sections manquantes du constat papier'),
              Text('• Section 10: Point de choc initial'),
              Text('• Section 11: Dégâts apparents avec photos'),
              Text('• Section 14: Observations et remarques'),
              SizedBox(height: 12),
              Text(
                '📋 Basé sur le constat papier officiel:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Respect de la structure officielle'),
              Text('• Numérotation conforme'),
              Text('• Champs obligatoires identifiés'),
              Text('• Interface moderne et intuitive'),
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
