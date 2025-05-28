// lib/features/language/screens/language_selection_screen.dart
import 'package:flutter/material.dart';

import '../../../core/config/app_routes.dart';
import '../../../core/config/app_theme.dart';
import '../../../core/widgets/custom_button.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = 'fr';

  void _selectLanguage(String language) {
    setState(() {
      _selectedLanguage = language;
    });
  }

  void _continue() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),
              Text(
                'Choisissez votre langue',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Sélectionnez la langue que vous souhaitez utiliser dans l\'application',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 40),
              _buildLanguageOption(
                language: 'fr',
                name: 'Français',
                flag: '🇫🇷',
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                language: 'ar',
                name: 'العربية',
                flag: '🇹🇳',
              ),
              const SizedBox(height: 16),
              _buildLanguageOption(
                language: 'en',
                name: 'English',
                flag: '🇬🇧',
              ),
              const Spacer(),
              CustomButton(
                text: 'Continuer',
                onPressed: _continue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String language,
    required String name,
    required String flag,
  }) {
    final isSelected = _selectedLanguage == language;
    
    return InkWell(
      onTap: () => _selectLanguage(language),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(width: 16),
            Text(
              name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : Colors.black,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppTheme.primaryColor,
              ),
          ],
        ),
      ),
    );
  }
}