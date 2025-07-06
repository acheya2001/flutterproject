import 'package:flutter/material.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../conducteur/screens/conducteur_declaration_screen.dart';
import 'session_creation_screen.dart';
import 'join_session_screen.dart';

class ConstatTypeSelectionScreen extends StatelessWidget {
  const ConstatTypeSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Nouveau constat',
        backgroundColor: Color(0xFF0369A1),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Type de constat',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            const Text(
              'Veuillez sélectionner le type de constat que vous souhaitez remplir',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            _buildOptionCard(
              context,
              title: 'Constat individuel',
              description: 'Vous êtes le seul conducteur impliqué dans l\'accident',
              icon: Icons.person,
              color: const Color(0xFF0369A1),
              onTap: () => _navigateToIndividualConstat(context),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              title: 'Créer un constat collaboratif',
              description: 'Créez une session et invitez les autres conducteurs impliqués',
              icon: Icons.group_add,
              color: const Color(0xFF047857),
              onTap: () => _navigateToCreateSession(context),
            ),
            const SizedBox(height: 20),
            _buildOptionCard(
              context,
              title: 'Rejoindre un constat collaboratif',
              description: 'Rejoignez une session créée par un autre conducteur',
              icon: Icons.login,
              color: const Color(0xFFB45309),
              onTap: () => _navigateToJoinSession(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: color,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToIndividualConstat(BuildContext context) {
    // Pour le constat individuel, nous n'avons pas besoin de sessionId ou conducteurPosition
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ConducteurDeclarationScreen(
          conducteurPosition: 'A',
        ),
      ),
    );
  }

  void _navigateToCreateSession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SessionCreationScreen(),
      ),
    );
  }

  void _navigateToJoinSession(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const JoinSessionScreen(),
      ),
    );
  }
}