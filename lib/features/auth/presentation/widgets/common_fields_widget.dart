import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/modern_theme.dart';

/// 📝 Widget pour les champs communs du formulaire de demande
class CommonFieldsWidget extends StatelessWidget {
  final TextEditingController nomCompletController;
  final TextEditingController emailController;
  final TextEditingController telController;
  final TextEditingController cinController;

  const CommonFieldsWidget({
    super.key,
    required this.nomCompletController,
    required this.emailController,
    required this.telController,
    required this.cinController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Nom complet
        _buildTextField(
          controller: nomCompletController,
          label: 'Nom complet',
          hint: 'Prénom et nom',
          icon: Icons.person,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom complet est obligatoire';
            }
            if (value.trim().length < 3) {
              return 'Le nom doit contenir au moins 3 caractères';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Email professionnel
        _buildTextField(
          controller: emailController,
          label: 'Email professionnel',
          hint: 'votre.email@entreprise.com',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'email est obligatoire';
            }
            if (!_isValidEmail(value.trim())) {
              return 'Veuillez saisir un email valide';
            }
            return null;
          },
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Numéro de téléphone
        _buildTextField(
          controller: telController,
          label: 'Numéro de téléphone',
          hint: '21612345678',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(11),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le numéro de téléphone est obligatoire';
            }
            if (!_isValidTunisianPhone(value.trim())) {
              return 'Numéro de téléphone tunisien invalide (ex: 21612345678)';
            }
            return null;
          },
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // CIN / Passeport
        _buildTextField(
          controller: cinController,
          label: 'CIN / Passeport',
          hint: '12345678',
          icon: Icons.badge,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
            LengthLimitingTextInputFormatter(12),
          ],
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le CIN ou passeport est obligatoire';
            }
            if (value.trim().length < 8) {
              return 'Le CIN doit contenir au moins 8 caractères';
            }
            return null;
          },
          textCapitalization: TextCapitalization.characters,
        ),
        
        const SizedBox(height: ModernTheme.spacingL),
        
        // Note d'information
        _buildInfoNote(),
      ],
    );
  }

  /// 🔧 Construire un champ de texte
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec icône
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: ModernTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: ModernTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textDark,
              ),
            ),
            Text(
              ' *',
              style: TextStyle(
                color: ModernTheme.errorColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: ModernTheme.spacingS),
        
        // Champ de texte
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ModernTheme.textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.borderColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.errorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.errorColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spacingM,
              vertical: ModernTheme.spacingM,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: ModernTheme.primaryColor,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📋 Note d'information
  Widget _buildInfoNote() {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: BoxDecoration(
        color: ModernTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: ModernTheme.primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: ModernTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: ModernTheme.spacingS),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informations importantes',
                  style: ModernTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: ModernTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• Utilisez votre email professionnel pour faciliter la validation\n'
                  '• Assurez-vous que vos informations sont exactes\n'
                  '• Votre demande sera examinée par un administrateur\n'
                  '• Vous recevrez une notification par email',
                  style: ModernTheme.bodySmall.copyWith(
                    color: ModernTheme.textDark,
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

  /// ✅ Valider l'email
  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

  /// ✅ Valider le numéro de téléphone tunisien
  bool _isValidTunisianPhone(String phone) {
    // Format tunisien: 216XXXXXXXX (11 chiffres) ou XXXXXXXX (8 chiffres)
    if (phone.length == 8) {
      return RegExp(r'^[2-9][0-9]{7}$').hasMatch(phone);
    } else if (phone.length == 11) {
      return RegExp(r'^216[2-9][0-9]{7}$').hasMatch(phone);
    }
    return false;
  }
}

/// 🎯 Widget de champ de texte personnalisé réutilisable
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final int maxLines;
  final bool isRequired;
  final Widget? suffix;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.maxLines = 1,
    this.isRequired = true,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec icône
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: ModernTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: ModernTheme.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: ModernTheme.textDark,
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  color: ModernTheme.errorColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: ModernTheme.spacingS),
        
        // Champ de texte
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          textCapitalization: textCapitalization,
          obscureText: obscureText,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: ModernTheme.textLight,
              fontSize: 14,
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.borderColor,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.borderColor,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.errorColor,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(
                color: ModernTheme.errorColor,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spacingM,
              vertical: ModernTheme.spacingM,
            ),
            prefixIcon: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              ),
              child: Icon(
                icon,
                color: ModernTheme.primaryColor,
                size: 20,
              ),
            ),
            suffixIcon: suffix,
          ),
        ),
      ],
    );
  }
}
