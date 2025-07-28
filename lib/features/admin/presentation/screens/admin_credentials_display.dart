import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 📩 Écran d'affichage des identifiants générés pour l'Admin Compagnie
class AdminCredentialsDisplay extends StatelessWidget {
  final String email;
  final String password;
  final String companyName;
  final String adminName;

  const AdminCredentialsDisplay({
    Key? key,
    required this.email,
    required this.password,
    required this.companyName,
    required this.adminName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Identifiants Générés',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Pas de bouton retour
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF059669), Color(0xFF047857)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSuccessHeader(),
            const SizedBox(height: 24),
            _buildCredentialsCard(),
            const SizedBox(height: 24),
            _buildInstructionsCard(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// ✅ En-tête de succès
  Widget _buildSuccessHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.white,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Compte Admin Compagnie créé avec succès !',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Admin: $adminName\nCompagnie: $companyName',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔐 Carte des identifiants
  Widget _buildCredentialsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF059669).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.key_rounded,
                    color: Color(0xFF059669),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Identifiants de Connexion',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Email
            _buildCredentialField(
              icon: Icons.email_rounded,
              label: 'Email',
              value: email,
              iconColor: const Color(0xFF3B82F6),
            ),
            
            const SizedBox(height: 16),
            
            // Mot de passe
            _buildCredentialField(
              icon: Icons.lock_rounded,
              label: 'Mot de passe',
              value: password,
              iconColor: const Color(0xFFEF4444),
              isPassword: true,
            ),
            
            const SizedBox(height: 16),
            
            // Compagnie
            _buildCredentialField(
              icon: Icons.business_rounded,
              label: 'Compagnie',
              value: companyName,
              iconColor: const Color(0xFF059669),
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Champ d'identifiant avec copie
  Widget _buildCredentialField({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    bool isPassword = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: isPassword ? 16 : 14,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    fontFamily: isPassword ? 'monospace' : null,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => _copyToClipboard(value, label),
                icon: const Icon(
                  Icons.copy_rounded,
                  size: 18,
                  color: Color(0xFF6B7280),
                ),
                tooltip: 'Copier $label',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Instructions
  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.info_rounded,
                  color: Color(0xFFF59E0B),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Instructions importantes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '🔐 CONNEXION AUTOMATIQUE :\n'
            '• L\'admin peut se connecter immédiatement avec ces identifiants\n'
            '• Le système créera automatiquement son compte sécurisé\n'
            '• Accès direct au dashboard de sa compagnie\n\n'
            '📋 INSTRUCTIONS :\n'
            '• Transmettez ces identifiants à l\'administrateur concerné\n'
            '• Conservez ces informations en lieu sûr\n'
            '• L\'admin aura accès uniquement aux données de sa compagnie',
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
        // Bouton copier tout
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _copyAllCredentials(),
            icon: const Icon(Icons.copy_all_rounded),
            label: const Text('Copier tous les identifiants'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Bouton terminer
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            icon: const Icon(Icons.check_rounded),
            label: const Text('Terminer'),
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
      ],
    );
  }

  /// 📋 Copier dans le presse-papiers
  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    // Note: Le SnackBar sera géré par le widget parent
  }

  /// 📋 Copier tous les identifiants
  void _copyAllCredentials() {
    final credentials = '''
Identifiants Admin Compagnie

📧 Email: $email
🔐 Mot de passe: $password
🏢 Compagnie: $companyName
👤 Admin: $adminName

Merci de transmettre ces identifiants à l'administrateur concerné.
''';
    
    Clipboard.setData(ClipboardData(text: credentials));
  }
}
