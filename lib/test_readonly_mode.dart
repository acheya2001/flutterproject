import 'package:flutter/material.dart';
import 'conducteur/screens/modern_single_accident_info_screen.dart';

class TestReadOnlyModePage extends StatelessWidget {
  const TestReadOnlyModePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Mode Lecture Seule'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Test du Mode Lecture Seule',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 30),
            
            const Text(
              'Choisissez le mode pour tester l\'écran de déclaration d\'accident :',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),
            
            // Mode édition
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernSingleAccidentInfoScreen(
                      typeAccident: 'Collision frontale',
                      estModeReadOnly: false, // Mode édition
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
              label: const Text('Mode Édition (Normal)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Mode lecture seule
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ModernSingleAccidentInfoScreen(
                      typeAccident: 'Collision frontale',
                      estModeReadOnly: true, // Mode lecture seule
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Mode Lecture Seule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Fonctionnalités du Mode Lecture Seule :',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text('• Tous les champs de saisie sont désactivés'),
                  Text('• Les boutons d\'action sont masqués ou désactivés'),
                  Text('• Badge "🔒 Mode lecture seule" visible'),
                  Text('• Icônes de verrouillage sur les champs'),
                  Text('• Texte d\'aide "Lecture seule" dans les champs'),
                  Text('• Boutons de navigation adaptés'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
