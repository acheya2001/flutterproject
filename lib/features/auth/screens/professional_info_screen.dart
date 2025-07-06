import 'package:flutter/material.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/config/app_routes.dart';

class ProfessionalInfoScreen extends StatelessWidget {
  final String userType;
  
  const ProfessionalInfoScreen({
    Key? key,
    required this.userType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isAgent = userType == 'agent';
    
    return Scaffold(
      appBar: CustomAppBar(
        title: isAgent ? 'Compte Agent d\'Assurance' : 'Compte Expert',
        showBackButton: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône principale
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isAgent ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isAgent ? Icons.business : Icons.assignment_ind,
                size: 80,
                color: isAgent ? Colors.blue[600] : Colors.orange[600],
              ),
            ),
            const SizedBox(height: 32),

            // Titre
            Text(
              isAgent 
                ? 'Compte Agent d\'Assurance' 
                : 'Compte Expert',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isAgent ? Colors.blue[800] : Colors.orange[800],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Message principal
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 48,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isAgent
                        ? 'Les comptes agents d\'assurance sont créés par votre responsable d\'agence ou administrateur système.'
                        : 'Les comptes experts sont créés par l\'administrateur système.',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Étapes à suivre
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isAgent ? Colors.blue[50] : Colors.orange[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pour obtenir votre compte :',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isAgent ? Colors.blue[800] : Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  if (isAgent) ...[
                    _buildStep(
                      '1.',
                      'Contactez votre responsable d\'agence',
                      'Demandez la création de votre compte professionnel',
                      Colors.blue[600]!,
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '2.',
                      'Fournissez vos informations',
                      'Nom, prénom, email, téléphone, matricule',
                      Colors.blue[600]!,
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '3.',
                      'Recevez vos identifiants',
                      'Votre responsable vous communiquera vos accès',
                      Colors.blue[600]!,
                    ),
                  ] else ...[
                    _buildStep(
                      '1.',
                      'Contactez l\'administrateur système',
                      'Demandez la création de votre compte expert',
                      Colors.orange[600]!,
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '2.',
                      'Fournissez vos informations',
                      'Nom, prénom, email, cabinet, agrément',
                      Colors.orange[600]!,
                    ),
                    const SizedBox(height: 12),
                    _buildStep(
                      '3.',
                      'Recevez vos identifiants',
                      'L\'administrateur vous communiquera vos accès',
                      Colors.orange[600]!,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Informations de contact
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.contact_support,
                    color: Colors.grey[600],
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Besoin d\'aide ?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAgent
                        ? 'Contactez votre agence d\'assurance ou appelez le support technique'
                        : 'Contactez l\'administrateur système ou le support technique',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Boutons d'action
            Column(
              children: [
                // Bouton connexion
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (isAgent) {
                        Navigator.pushReplacementNamed(context, AppRoutes.agentLogin);
                      } else {
                        Navigator.pushReplacementNamed(context, AppRoutes.login);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAgent ? Colors.blue[600] : Colors.orange[600],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isAgent ? 'Se connecter en tant qu\'agent' : 'Se connecter en tant qu\'expert',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Bouton retour
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.userTypeSelection);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey[400]!),
                    ),
                    child: const Text(
                      'Retour au choix du type de compte',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String title, String description, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
