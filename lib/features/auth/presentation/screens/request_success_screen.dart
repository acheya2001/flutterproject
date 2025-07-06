import 'package:flutter/material.dart';
import '../../../../core/theme/modern_theme.dart';

/// ✅ Écran de succès après soumission de demande
class RequestSuccessScreen extends StatelessWidget {
  const RequestSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernTheme.backgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(ModernTheme.spacingL),
          child: Column(
            children: [
              // Bouton retour en haut à gauche
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (route) => false,
                  ),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: ModernTheme.textDark,
                  ),
                ),
              ),
              
              // Contenu principal centré
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animation de succès
                    _buildSuccessAnimation(),
                    
                    const SizedBox(height: ModernTheme.spacingXL),
                    
                    // Titre de succès
                    Text(
                      'Demande envoyée avec succès !',
                      style: ModernTheme.headingLarge.copyWith(
                        color: ModernTheme.successColor,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: ModernTheme.spacingM),
                    
                    // Message explicatif
                    Text(
                      'Votre demande de compte professionnel a été transmise à nos équipes.',
                      style: ModernTheme.bodyLarge.copyWith(
                        color: ModernTheme.textDark,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: ModernTheme.spacingM),

                    // Message d'attente élégant
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ModernTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: ModernTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: ModernTheme.primaryColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.hourglass_empty,
                              color: ModernTheme.primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Veuillez patienter pendant l\'analyse de votre demande par nos administrateurs.',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: ModernTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: ModernTheme.spacingXL),
                    
                    // Informations sur les prochaines étapes
                    _buildNextStepsCard(),
                    
                    const SizedBox(height: ModernTheme.spacingXL),
                    
                    // Informations de contact
                    _buildContactInfo(),
                  ],
                ),
              ),
              
              // Boutons d'action en bas
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎬 Animation de succès
  Widget _buildSuccessAnimation() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: ModernTheme.successColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: ModernTheme.successColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 80,
            color: ModernTheme.successColor,
          ),
        ),
      ),
    );
  }

  /// 📋 Carte des prochaines étapes
  Widget _buildNextStepsCard() {
    return Container(
      padding: const EdgeInsets.all(ModernTheme.spacingL),
      decoration: ModernTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ModernTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
                ),
                child: Icon(
                  Icons.timeline,
                  color: ModernTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: ModernTheme.spacingM),
              Text(
                'Prochaines étapes',
                style: ModernTheme.headingSmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: ModernTheme.spacingL),
          
          // Liste des étapes
          _buildStep(
            number: '1',
            title: 'Examen de votre dossier',
            description: 'Nos équipes vont examiner votre demande et vérifier les informations fournies.',
            isCompleted: true,
          ),
          
          const SizedBox(height: ModernTheme.spacingM),
          
          _buildStep(
            number: '2',
            title: 'Validation administrative',
            description: 'Un administrateur validera votre demande sous 2-3 jours ouvrables.',
            isCompleted: false,
          ),
          
          const SizedBox(height: ModernTheme.spacingM),
          
          _buildStep(
            number: '3',
            title: 'Création de votre compte',
            description: 'Une fois approuvée, votre compte sera créé et vous recevrez vos identifiants.',
            isCompleted: false,
          ),
        ],
      ),
    );
  }

  /// 📝 Étape du processus
  Widget _buildStep({
    required String number,
    required String title,
    required String description,
    required bool isCompleted,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Numéro de l'étape
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted 
                ? ModernTheme.successColor
                : ModernTheme.primaryColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: isCompleted 
                ? null
                : Border.all(
                    color: ModernTheme.primaryColor,
                    width: 2,
                  ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : Text(
                    number,
                    style: TextStyle(
                      color: ModernTheme.primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        
        const SizedBox(width: ModernTheme.spacingM),
        
        // Contenu de l'étape
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: ModernTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isCompleted 
                      ? ModernTheme.successColor
                      : ModernTheme.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: ModernTheme.bodySmall.copyWith(
                  color: ModernTheme.textLight,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📞 Informations de contact
  Widget _buildContactInfo() {
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
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.support_agent,
                color: ModernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: ModernTheme.spacingS),
              Text(
                'Besoin d\'aide ?',
                style: ModernTheme.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: ModernTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: ModernTheme.spacingS),
          Text(
            'Si vous avez des questions concernant votre demande, n\'hésitez pas à nous contacter.',
            style: ModernTheme.bodySmall.copyWith(
              color: ModernTheme.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: ModernTheme.spacingM),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildContactButton(
                icon: Icons.email,
                label: 'Email',
                onTap: () {
                  // TODO: Ouvrir l'application email
                },
              ),
              _buildContactButton(
                icon: Icons.phone,
                label: 'Téléphone',
                onTap: () {
                  // TODO: Ouvrir l'application téléphone
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📞 Bouton de contact
  Widget _buildContactButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: ModernTheme.spacingM,
          vertical: ModernTheme.spacingS,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
          border: Border.all(
            color: ModernTheme.primaryColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: ModernTheme.primaryColor,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: ModernTheme.primaryColor,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Bouton principal
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            ),
            icon: const Icon(Icons.login),
            label: const Text('Retour à la connexion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: ModernTheme.spacingM),
        
        // Bouton secondaire
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(
              context,
              '/professional-request',
              (route) => false,
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle demande'),
            style: OutlinedButton.styleFrom(
              foregroundColor: ModernTheme.primaryColor,
              side: BorderSide(color: ModernTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: ModernTheme.spacingM),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(ModernTheme.radiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
