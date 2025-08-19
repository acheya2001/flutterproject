import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🔑 Écran d'affichage des identifiants Agent
class AgentCredentialsDisplay extends StatelessWidget {
  final String email;
  final String password;
  final String codeAgent;
  final String agentName;
  final String agenceName;
  final String companyName;

  const AgentCredentialsDisplay({
    Key? key,
    required this.email,
    required this.password,
    required this.codeAgent,
    required this.agentName,
    required this.agenceName,
    required this.companyName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Agent Créé',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de succès
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            
            // Carte des identifiants
            _buildCredentialsCard(),
            const SizedBox(height: 24),
            
            // Instructions
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            
            // Boutons d'action
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// 🎉 En-tête de succès
  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF059669).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Agent Créé !',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Pour $agenceName',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔑 Carte des identifiants
  Widget _buildCredentialsCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key_rounded, color: Color(0xFF059669)),
              SizedBox(width: 8),
              Text(
                'Identifiants de connexion',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Nom de l'agent
          _buildInfoRow('👤 Nom', agentName),
          const SizedBox(height: 12),
          
          // Code agent
          _buildCopyableRow('🏷️ Code Agent', codeAgent),
          const SizedBox(height: 12),
          
          // Agence
          _buildInfoRow('🏢 Agence', agenceName),
          const SizedBox(height: 12),
          
          // Compagnie
          _buildInfoRow('🏛️ Compagnie', companyName),
          const SizedBox(height: 12),
          
          // Email
          _buildCopyableRow('📧 Email', email),
          const SizedBox(height: 12),
          
          // Mot de passe
          _buildCopyableRow('🔑 Mot de passe', password),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Builder(
                  builder: (context) => GestureDetector(
                    onTap: () => _copyToClipboardSimple(value, context),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Icon(
                        Icons.copy_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 📋 Carte d'instructions
  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD97706).withOpacity(0.3)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, color: Color(0xFF92400E)),
              SizedBox(width: 8),
              Text(
                'Instructions importantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '🔐 CONNEXION AUTOMATIQUE :\n'
            '• L\'agent peut se connecter immédiatement avec ces identifiants\n'
            '• Le système créera automatiquement son compte sécurisé\n'
            '• Accès direct à l\'application mobile agent\n\n'
            '📋 INSTRUCTIONS :\n'
            '• Transmettez ces identifiants à l\'agent concerné\n'
            '• Conservez ces informations en lieu sûr\n'
            '• L\'agent aura accès uniquement aux fonctionnalités agent\n'
            '• Il pourra créer des constats et gérer ses dossiers',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF92400E),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal - Copier tous les identifiants
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _copyAllCredentials(context),
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copier tous les identifiants'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton secondaire - Copier juste email/mot de passe
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _copySimpleCredentials(context),
            icon: const Icon(Icons.key_rounded),
            label: const Text('Copier Email + Mot de passe'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0369A1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Bouton retour
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded),
            label: const Text('Retour au Dashboard'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF059669),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _copyToClipboardSimple(String text, BuildContext context) {
    Clipboard.setData(ClipboardData(text: text));
    // Afficher un feedback visuel
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Copié !'),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _copySimpleCredentials(BuildContext context) {
    final simpleCredentials = '''Email: $email
Mot de passe: $password''';

    Clipboard.setData(ClipboardData(text: simpleCredentials));
    _showCopyFeedback(context, 'Identifiants de connexion copiés !');
  }

  void _copyAllCredentials(BuildContext context) {
    final credentials = '''Agent - $agenceName

👤 Nom: $agentName
🏷️ Code Agent: $codeAgent
🏢 Agence: $agenceName
🏛️ Compagnie: $companyName
📧 Email: $email
🔑 Mot de passe: $password

Instructions:
- Se connecter avec ces identifiants
- Accès à l'application mobile agent
- Créer et gérer les constats d'accidents
- Changer le mot de passe après la première connexion (recommandé)''';

    Clipboard.setData(ClipboardData(text: credentials));
    _showCopyFeedback(context, 'Tous les identifiants copiés !');
  }

  void _showCopyFeedback(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
