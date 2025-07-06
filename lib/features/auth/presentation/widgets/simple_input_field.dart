import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 🎯 Widget de champ de saisie simple et fonctionnel
class SimpleInputField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final bool obscureText;
  final int maxLines;

  const SimpleInputField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.obscureText = false,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: Colors.blue.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Champ de saisie
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            validator: validator,
            obscureText: obscureText,
            maxLines: maxLines,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
              height: 1.2,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.grey.shade300,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Colors.blue.shade600,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 1,
                ),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 🎯 Widget de formulaire simple avec champs de base
class SimpleFormWidget extends StatelessWidget {
  final TextEditingController nomCompletController;
  final TextEditingController emailController;
  final TextEditingController telController;
  final TextEditingController cinController;

  const SimpleFormWidget({
    super.key,
    required this.nomCompletController,
    required this.emailController,
    required this.telController,
    required this.cinController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre
          const Text(
            'Informations personnelles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Veuillez remplir vos informations',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          // Champs de saisie
          SimpleInputField(
            controller: nomCompletController,
            label: 'Nom complet',
            hint: 'Entrez votre nom et prénom',
            icon: Icons.person,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom complet est requis';
              }
              return null;
            },
          ),

          SimpleInputField(
            controller: emailController,
            label: 'Email',
            hint: 'exemple@email.com',
            icon: Icons.email,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'email est requis';
              }
              if (!value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),

          SimpleInputField(
            controller: telController,
            label: 'Téléphone',
            hint: '+216 XX XXX XXX',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s-]')),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le téléphone est requis';
              }
              return null;
            },
          ),

          SimpleInputField(
            controller: cinController,
            label: 'CIN',
            hint: 'Numéro de carte d\'identité',
            icon: Icons.credit_card,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(8),
            ],
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le CIN est requis';
              }
              if (value.length != 8) {
                return 'Le CIN doit contenir 8 chiffres';
              }
              return null;
            },
          ),

          const SizedBox(height: 20),
          
          // Bouton de test
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Test des valeurs
                print('=== TEST DES VALEURS ===');
                print('Nom: ${nomCompletController.text}');
                print('Email: ${emailController.text}');
                print('Tel: ${telController.text}');
                print('CIN: ${cinController.text}');
                print('========================');
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Valeurs saisies:\n'
                      'Nom: ${nomCompletController.text}\n'
                      'Email: ${emailController.text}\n'
                      'Tel: ${telController.text}\n'
                      'CIN: ${cinController.text}',
                    ),
                    duration: const Duration(seconds: 3),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Tester les valeurs',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
