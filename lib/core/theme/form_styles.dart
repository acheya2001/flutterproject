import 'package:flutter/material.dart';

/// 🎨 Styles pour les formulaires - Écriture claire et lisible
class FormStyles {
  
  /// 📝 Style pour les champs de texte - Écriture claire
  static InputDecoration getInputDecoration({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool isRequired = false,
  }) {
    return InputDecoration(
      labelText: isRequired ? '$labelText *' : labelText,
      hintText: hintText,
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF667EEA)) : null,
      suffixIcon: suffixIcon,
      
      // Style du texte
      labelStyle: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1F2937),
        letterSpacing: 0.3,
      ),
      hintStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF6B7280), // Plus foncé pour meilleur contraste
        letterSpacing: 0.3,
      ),
      
      // Style des bordures
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
      
      // Padding et remplissage
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      filled: true,
      fillColor: Colors.white, // Fond blanc pur pour maximum de contraste
    );
  }

  /// 📝 Style pour les TextFormField - Texte très lisible
  static TextStyle getInputTextStyle() {
    return const TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: Color(0xFF000000), // Noir pur pour maximum de contraste
      letterSpacing: 0.3,
      height: 1.5,
    );
  }

  /// 🏷️ Style pour les labels
  static TextStyle getLabelStyle() {
    return const TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      color: Color(0xFF1F2937), // Plus foncé pour meilleur contraste
      letterSpacing: 0.3,
    );
  }

  /// ❌ Style pour les messages d'erreur
  static TextStyle getErrorStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.red,
      letterSpacing: 0.3,
    );
  }

  /// ✅ Style pour les messages de succès
  static TextStyle getSuccessStyle() {
    return const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: Colors.green,
      letterSpacing: 0.3,
    );
  }

  /// 🔘 Style pour les boutons principaux
  static ButtonStyle getPrimaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: const Color(0xFF667EEA),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      elevation: 2,
    );
  }

  /// 🔘 Style pour les boutons secondaires
  static ButtonStyle getSecondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: const Color(0xFF667EEA),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: const BorderSide(color: Color(0xFF667EEA), width: 1.5),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  /// 📱 Widget TextFormField personnalisé avec style amélioré
  static Widget buildTextFormField({
    required String labelText,
    String? hintText,
    IconData? prefixIcon,
    Widget? suffixIcon,
    bool isRequired = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String?)? onSaved,
    void Function(String)? onChanged,
    TextEditingController? controller,
    String? initialValue,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label avec style amélioré
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            isRequired ? '$labelText *' : labelText,
            style: getLabelStyle(),
          ),
        ),
        
        // Champ de texte avec style amélioré
        TextFormField(
          controller: controller,
          initialValue: initialValue,
          style: getInputTextStyle(),
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onSaved: onSaved,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: enabled,
          decoration: getInputDecoration(
            labelText: '',
            hintText: hintText,
            prefixIcon: prefixIcon,
            suffixIcon: suffixIcon,
          ).copyWith(
            // Supprimer le label car on l'affiche séparément
            labelText: null,
            floatingLabelBehavior: FloatingLabelBehavior.never,
          ),
        ),
      ],
    );
  }

  /// 📋 Widget pour les sections de formulaire
  static Widget buildFormSection({
    required String title,
    required List<Widget> children,
    IconData? icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre de la section
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: const Color(0xFF667EEA), size: 24),
                const SizedBox(width: 12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Contenu de la section
          ...children,
        ],
      ),
    );
  }

  /// 📏 Espacement standard entre les champs
  static const SizedBox fieldSpacing = SizedBox(height: 20);
  
  /// 📏 Espacement entre les sections
  static const SizedBox sectionSpacing = SizedBox(height: 24);
}
