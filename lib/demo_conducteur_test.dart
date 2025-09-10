import 'package:flutter/material.dart';
import 'conducteur/screens/modern_single_accident_info_screen.dart';

/// 🧪 Écran de test pour la gestion du conducteur
class DemoConducteurTest extends StatelessWidget {
  const DemoConducteurTest({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Gestion Conducteur'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // En-tête
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.drive_eta,
                        size: 48,
                        color: Colors.blue[600],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Test Gestion du Conducteur',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Testez la nouvelle fonctionnalité de gestion du conducteur avec permis',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Fonctionnalités testées
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✅ Fonctionnalités testées :',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...[
                        '👤 Identification du conducteur (propriétaire ou autre)',
                        '📋 Informations complètes si autre conducteur',
                        '🪪 Question du permis pour TOUS les conducteurs',
                        '📸 Photos recto/verso du permis',
                        '⚠️ Alerte si conduite sans permis',
                        '🎨 Interface moderne et intuitive',
                      ].map((feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          feature,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.green[700],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),

                const Spacer(),

                // Bouton de test
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ModernSingleAccidentInfoScreen(
                          typeAccident: 'Test - Gestion Conducteur',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_arrow, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Tester le Formulaire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Testez les deux scénarios : propriétaire qui conduit et autre conducteur',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
