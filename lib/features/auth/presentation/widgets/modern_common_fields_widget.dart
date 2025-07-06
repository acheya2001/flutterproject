import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/modern_theme.dart';

/// 📝 Widget moderne pour les champs communs du formulaire
class ModernCommonFieldsWidget extends StatelessWidget {
  final TextEditingController nomCompletController;
  final TextEditingController emailController;
  final TextEditingController telController;
  final TextEditingController cinController;

  const ModernCommonFieldsWidget({
    super.key,
    required this.nomCompletController,
    required this.emailController,
    required this.telController,
    required this.cinController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20), // Padding très visible
      decoration: BoxDecoration(
        color: Colors.yellow.withValues(alpha: 0.1), // Fond jaune pour voir
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange, width: 2), // Bordure orange
      ),
      child: Column(
        children: [
        _buildModernTextField(
          controller: nomCompletController,
          label: 'Nom complet',
          hint: 'Votre nom et prénom',
          icon: Icons.person,
          gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom complet est obligatoire';
            }
            if (value.trim().length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
        ),

        const SizedBox(height: 32),

        _buildModernTextField(
          controller: emailController,
          label: 'Adresse email',
          hint: 'votre.email@exemple.com',
          icon: Icons.email,
          gradient: const [Color(0xFF11998E), Color(0xFF38EF7D)],
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'email est obligatoire';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Format d\'email invalide';
            }
            return null;
          },
        ),

        const SizedBox(height: 32),

        _buildModernTextField(
          controller: telController,
          label: 'Numéro de téléphone',
          hint: '21612345678 ou 12345678',
          icon: Icons.phone,
          gradient: const [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
          keyboardType: TextInputType.phone,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le téléphone est obligatoire';
            }
            if (!RegExp(r'^(216)?[0-9]{8}$').hasMatch(value)) {
              return 'Format invalide (ex: 21612345678 ou 12345678)';
            }
            return null;
          },
        ),

        const SizedBox(height: 32),

        _buildModernTextField(
          controller: cinController,
          label: 'Numéro CIN',
          hint: 'Votre numéro de carte d\'identité',
          icon: Icons.badge,
          gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le numéro CIN est obligatoire';
            }
            if (value.trim().length < 8) {
              return 'Le CIN doit contenir au moins 8 caractères';
            }
            return null;
          },
        ),

        const SizedBox(height: 40),
        
        // Note d'information
        _buildInfoNote(),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required List<Color> gradient,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec icône
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: ModernTheme.textDark,
              ),
            ),
            const Text(
              ' *',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Champ de texte avec style forcé pour visibilité maximale
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            style: const TextStyle(
              fontSize: 18, // Taille plus grande
              fontWeight: FontWeight.w700, // Plus gras
              color: Color(0xFF000000), // Noir absolu
              decoration: TextDecoration.none,
            ),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: TextStyle(
                color: gradient.first,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF999999), // Gris clair
                fontSize: 16,
              ),
              prefixIcon: Icon(
                icon,
                color: gradient.first,
                size: 20,
              ),
              filled: true,
              fillColor: const Color(0xFFFFFFFF), // Blanc absolu
              border: InputBorder.none, // Pas de bordure par défaut
              enabledBorder: InputBorder.none,
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: gradient.first, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFE2E8F0)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.info_outline,
              color: Color(0xFF667EEA),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations importantes',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vos données sont sécurisées et ne seront utilisées que pour la création de votre compte professionnel.',
                  style: TextStyle(
                    fontSize: 12,
                    color: ModernTheme.textLight,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
