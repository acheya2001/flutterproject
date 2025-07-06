import 'package:flutter/material.dart';
import '../widgets/ai_integration_demo.dart';

/// 🎯 Écran de démonstration de l'IA pour PFE
/// Parfait pour présenter la fonctionnalité lors de la soutenance
class AIDemoScreen extends StatelessWidget {
  const AIDemoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🤖 Démonstration IA'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade50,
              Colors.white,
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête de présentation
              _buildPresentationHeader(),
              const SizedBox(height: 24),

              // Avantages de la solution
              _buildAdvantages(),
              const SizedBox(height: 24),

              // Boutons de démonstration
              _buildDemoButtons(context),
              const SizedBox(height: 24),

              // Technologies utilisées
              _buildTechnologies(),
              const SizedBox(height: 24),

              // Note pour le jury
              _buildJuryNote(),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 En-tête de présentation
  Widget _buildPresentationHeader() {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade400],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Analyse IA d\'Accidents',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Solution 100% gratuite pour PFE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Cette fonctionnalité révolutionnaire utilise l\'intelligence artificielle pour analyser automatiquement les photos d\'accidents et générer des rapports détaillés.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Avantages de la solution
  Widget _buildAdvantages() {
    final advantages = [
      {
        'icon': Icons.speed,
        'title': 'Analyse Rapide',
        'description': 'Traitement en quelques secondes',
        'color': Colors.green,
      },
      {
        'icon': Icons.money_off,
        'title': '100% Gratuit',
        'description': 'Aucun coût pour l\'étudiant',
        'color': Colors.blue,
      },
      {
        'icon': Icons.smart_toy,
        'title': 'IA Avancée',
        'description': 'Algorithmes intelligents',
        'color': Colors.purple,
      },
      {
        'icon': Icons.cloud_upload,
        'title': 'Sauvegarde Auto',
        'description': 'Stockage sécurisé Firebase',
        'color': Colors.orange,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎯 Avantages de la solution',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
          ),
          itemCount: advantages.length,
          itemBuilder: (context, index) {
            final advantage = advantages[index];
            return Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      advantage['icon'] as IconData,
                      color: advantage['color'] as Color,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      advantage['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      advantage['description'] as String,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 🚀 Boutons de démonstration
  Widget _buildDemoButtons(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🚀 Démonstrations disponibles',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Démonstration individuelle
        _buildDemoButton(
          context: context,
          title: 'Analyse Individuelle',
          subtitle: 'Test avec un seul conducteur',
          icon: Icons.person,
          color: Colors.blue,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIIntegrationDemo(
                sessionId: 'demo_individual',
                isCollaborative: false,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Démonstration collaborative
        _buildDemoButton(
          context: context,
          title: 'Analyse Collaborative',
          subtitle: 'Test avec plusieurs conducteurs',
          icon: Icons.group,
          color: Colors.green,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AIIntegrationDemo(
                sessionId: 'demo_collaborative',
                isCollaborative: true,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDemoButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
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
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// 🛠️ Technologies utilisées
  Widget _buildTechnologies() {
    final technologies = [
      'Flutter & Dart',
      'Firebase Firestore',
      'Firebase Storage',
      'Algorithmes de traitement d\'image',
      'Reconnaissance vocale native',
      'Analyse de texte basique',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Technologies utilisées',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...technologies.map((tech) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 12),
                  Text(tech),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 👨‍🎓 Note pour le jury
  Widget _buildJuryNote() {
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.school, color: Colors.amber.shade700, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Note pour le jury de PFE',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Cette fonctionnalité démontre l\'innovation et la créativité dans le développement d\'une solution complète. '
              'L\'utilisation de technologies gratuites montre la capacité à créer des solutions accessibles et pratiques.',
              style: TextStyle(
                color: Colors.amber.shade800,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
