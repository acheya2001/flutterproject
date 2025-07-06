import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/modern_theme.dart';
import '../../../admin/models/professional_request_model_final.dart';
import 'common_fields_widget.dart';

/// 🎯 Widget pour les champs spécifiques selon le rôle sélectionné
class SpecificFieldsWidget extends StatelessWidget {
  final String selectedRole;
  final Map<String, TextEditingController> controllers;

  const SpecificFieldsWidget({
    super.key,
    required this.selectedRole,
    required this.controllers,
  });

  @override
  Widget build(BuildContext context) {
    switch (selectedRole) {
      case 'agent_agence':
        return _buildAgentAgenceFields();
      case 'expert_auto':
        return _buildExpertAutoFields();
      case 'admin_compagnie':
        return _buildAdminCompagnieFields();
      case 'admin_agence':
        return _buildAdminAgenceFields();
      default:
        return const SizedBox.shrink();
    }
  }

  /// 🧍‍💼 Champs pour Agent d'agence
  Widget _buildAgentAgenceFields() {
    return Column(
      children: [
        // En-tête du rôle
        _buildRoleHeader(
          'Agent d\'Agence',
          'Renseignez les informations de votre agence et compagnie d\'assurance',
          Icons.person_outline,
          ModernTheme.primaryColor,
        ),
        
        const SizedBox(height: 32),
        
        // Nom de l'agence
        CustomTextField(
          controller: controllers['nom_agence']!,
          label: 'Nom de l\'agence',
          hint: 'Agence El Menzah 6',
          icon: Icons.store,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom de l\'agence est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: 24),
        
        // Compagnie d'assurance
        _buildCompagnieDropdown(controllers['compagnie']!),

        const SizedBox(height: 24),
        
        // Adresse de l'agence
        CustomTextField(
          controller: controllers['adresse_agence']!,
          label: 'Adresse de l\'agence',
          hint: 'Avenue Hédi Nouira, Tunis',
          icon: Icons.location_on,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'adresse de l\'agence est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Matricule interne (optionnel)
        CustomTextField(
          controller: controllers['matricule_interne']!,
          label: 'Matricule interne',
          hint: 'AG455 (optionnel)',
          icon: Icons.badge,
          isRequired: false,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  /// 🧑‍🔧 Champs pour Expert auto
  Widget _buildExpertAutoFields() {
    return Column(
      children: [
        // En-tête du rôle
        _buildRoleHeader(
          'Expert Automobile',
          'Renseignez vos qualifications et zone d\'intervention',
          Icons.engineering,
          ModernTheme.secondaryColor,
        ),
        
        const SizedBox(height: ModernTheme.spacingL),
        
        // Numéro d'agrément
        CustomTextField(
          controller: controllers['num_agrement']!,
          label: 'Numéro d\'agrément professionnel',
          hint: 'EXP2024001',
          icon: Icons.verified,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le numéro d\'agrément est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.characters,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Compagnie d'assurance liée
        _buildCompagnieDropdown(controllers['compagnie']!),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Zone d'intervention
        _buildGouvernoratDropdown(controllers['zone_intervention']!),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Expérience (optionnel)
        CustomTextField(
          controller: controllers['experience_annees']!,
          label: 'Années d\'expérience',
          hint: '5 (optionnel)',
          icon: Icons.timeline,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(2),
          ],
          isRequired: false,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Nom de l'agence (optionnel)
        CustomTextField(
          controller: controllers['nom_agence']!,
          label: 'Nom de l\'agence',
          hint: 'Agence Lac 2 (si intégré)',
          icon: Icons.store,
          isRequired: false,
          textCapitalization: TextCapitalization.words,
        ),
      ],
    );
  }

  /// 🧑‍💼 Champs pour Admin compagnie
  Widget _buildAdminCompagnieFields() {
    return Column(
      children: [
        // En-tête du rôle
        _buildRoleHeader(
          'Admin Compagnie',
          'Renseignez les informations de votre compagnie et fonction',
          Icons.business,
          ModernTheme.accentColor,
        ),
        
        const SizedBox(height: ModernTheme.spacingL),
        
        // Nom de la compagnie
        _buildCompagnieDropdown(controllers['nom_compagnie']!, isCompanyName: true),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Fonction/Poste
        CustomTextField(
          controller: controllers['fonction']!,
          label: 'Fonction / Poste',
          hint: 'Directeur Régional',
          icon: Icons.work,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'La fonction est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Adresse siège social
        CustomTextField(
          controller: controllers['adresse_siege']!,
          label: 'Adresse du siège social',
          hint: 'Avenue Habib Bourguiba, Tunis',
          icon: Icons.location_city,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'adresse du siège est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Numéro d'autorisation (optionnel)
        CustomTextField(
          controller: controllers['num_autorisation']!,
          label: 'Numéro d\'autorisation',
          hint: 'AUTH2024GAT (optionnel)',
          icon: Icons.security,
          isRequired: false,
          textCapitalization: TextCapitalization.characters,
        ),
      ],
    );
  }

  /// 🏢 Champs pour Admin agence
  Widget _buildAdminAgenceFields() {
    return Column(
      children: [
        // En-tête du rôle
        _buildRoleHeader(
          'Admin Agence',
          'Renseignez les informations de votre agence',
          Icons.store,
          ModernTheme.warningColor,
        ),
        
        const SizedBox(height: ModernTheme.spacingL),
        
        // Nom de l'agence
        CustomTextField(
          controller: controllers['nom_agence']!,
          label: 'Nom de l\'agence',
          hint: 'Agence Comar Sfax Centre',
          icon: Icons.store,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Le nom de l\'agence est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Compagnie d'assurance
        _buildCompagnieDropdown(controllers['compagnie']!),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Ville/Gouvernorat
        _buildGouvernoratDropdown(controllers['ville']!),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Adresse de l'agence
        CustomTextField(
          controller: controllers['adresse_agence']!,
          label: 'Adresse de l\'agence',
          hint: 'Rue Mongi Slim, Sfax',
          icon: Icons.location_on,
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'L\'adresse de l\'agence est obligatoire';
            }
            return null;
          },
          textCapitalization: TextCapitalization.words,
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Téléphone de l'agence (optionnel)
        CustomTextField(
          controller: controllers['tel_agence']!,
          label: 'Téléphone de l\'agence',
          hint: '74123456 (optionnel)',
          icon: Icons.phone_in_talk,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(8),
          ],
          isRequired: false,
        ),
      ],
    );
  }

  /// 🎯 En-tête de rôle
  Widget _buildRoleHeader(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingM),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: ModernTheme.spacingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ModernTheme.headingSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: ModernTheme.bodySmall.copyWith(
                    color: ModernTheme.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🏢 Dropdown pour les compagnies d'assurance
  Widget _buildCompagnieDropdown(TextEditingController controller, {bool isCompanyName = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.business,
              size: 20,
              color: ModernTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              isCompanyName ? 'Nom de la compagnie' : 'Compagnie d\'assurance',
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
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(
            hintText: 'Sélectionnez une compagnie',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(color: ModernTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(color: ModernTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(color: ModernTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spacingM,
              vertical: ModernTheme.spacingM,
            ),
          ),
          items: ProfessionalRequestConstants.compagniesAssurance.map((compagnie) {
            return DropdownMenuItem(
              value: compagnie,
              child: Text(compagnie),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.text = value;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner une compagnie';
            }
            return null;
          },
        ),
      ],
    );
  }

  /// 📍 Dropdown pour les gouvernorats
  Widget _buildGouvernoratDropdown(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on,
              size: 20,
              color: ModernTheme.primaryColor,
            ),
            const SizedBox(width: 8),
            Text(
              'Gouvernorat / Zone d\'intervention',
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
        DropdownButtonFormField<String>(
          value: controller.text.isEmpty ? null : controller.text,
          decoration: InputDecoration(
            hintText: 'Sélectionnez un gouvernorat',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(color: ModernTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(color: ModernTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              borderSide: BorderSide(color: ModernTheme.primaryColor, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: ModernTheme.spacingM,
              vertical: ModernTheme.spacingM,
            ),
          ),
          items: ProfessionalRequestConstants.gouvernorats.map((gouvernorat) {
            return DropdownMenuItem(
              value: gouvernorat,
              child: Text(gouvernorat),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              controller.text = value;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Veuillez sélectionner un gouvernorat';
            }
            return null;
          },
        ),
      ],
    );
  }
}
