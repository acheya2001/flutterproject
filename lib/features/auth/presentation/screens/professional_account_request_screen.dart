import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfessionalAccountRequestScreen extends ConsumerStatefulWidget {
  const ProfessionalAccountRequestScreen({super.key});

  @override
  ConsumerState<ProfessionalAccountRequestScreen> createState() => _ProfessionalAccountRequestScreenState();
}

class _ProfessionalAccountRequestScreenState extends ConsumerState<ProfessionalAccountRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Contrôleurs pour les champs communs
  final _nomCompletController = TextEditingController();
  final _emailController = TextEditingController();
  final _telController = TextEditingController();
  final _cinController = TextEditingController();
  
  // État de l'interface
  int _currentStep = 0;
  String? _selectedRole;
  bool _isSubmitting = false;
  
  // Contrôleurs pour les champs spécifiques
  final Map<String, TextEditingController> _specificControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeSpecificControllers();
  }

  @override
  void dispose() {
    _nomCompletController.dispose();
    _emailController.dispose();
    _telController.dispose();
    _cinController.dispose();
    for (final controller in _specificControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 🎯 Initialiser les contrôleurs spécifiques
  void _initializeSpecificControllers() {
    // Contrôleurs pour agent_agence
    _specificControllers['nom_agence'] = TextEditingController();
    _specificControllers['adresse_agence'] = TextEditingController();
    _specificControllers['code_agence'] = TextEditingController();
    
    // Contrôleurs pour expert_auto
    _specificControllers['numero_licence'] = TextEditingController();
    _specificControllers['specialite'] = TextEditingController();
    _specificControllers['experience'] = TextEditingController();
    
    // Contrôleurs pour admin_compagnie
    _specificControllers['nom_compagnie'] = TextEditingController();
    _specificControllers['code_compagnie'] = TextEditingController();
    _specificControllers['adresse_siege'] = TextEditingController();
    
    // Contrôleurs pour admin_agence
    _specificControllers['nom_agence'] = TextEditingController();
    _specificControllers['code_agence'] = TextEditingController();
    _specificControllers['ville'] = TextEditingController();
    _specificControllers['tel_agence'] = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23), // Fond sombre moderne
      resizeToAvoidBottomInset: false, // Désactiver pour contrôle total
      body: _buildModernInterface(),
    );
  }

  /// 🚀 INTERFACE ULTRA-MODERNE SANS OVERFLOW
  Widget _buildModernInterface() {
    final screenHeight = MediaQuery.of(context).size.height;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

    // Calcul précis des hauteurs
    final headerHeight = 90.0;
    final progressHeight = 60.0;
    final navigationHeight = 70.0;
    final availableHeight = screenHeight - safeAreaTop - safeAreaBottom - headerHeight - progressHeight - navigationHeight - keyboardHeight;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F0F23), // Bleu très sombre
            Color(0xFF1A1A2E), // Bleu sombre
            Color(0xFF16213E), // Bleu moyen
          ],
        ),
      ),
      child: Column(
        children: [
          // SafeArea top
          SizedBox(height: safeAreaTop),

          // En-tête moderne
          _buildModernHeader(),

          // Indicateur de progression moderne
          _buildModernProgress(),

          // Contenu principal avec hauteur calculée et sécurisée
          SizedBox(
            height: availableHeight > 200 ? availableHeight : 200,
            child: _buildModernContent(),
          ),

          // Navigation moderne
          _buildModernNavigation(),

          // SafeArea bottom
          SizedBox(height: safeAreaBottom),
        ],
      ),
    );
  }

  /// 🎨 En-tête ultra-moderne
  Widget _buildModernHeader() {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          // Bouton retour moderne
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              padding: EdgeInsets.zero,
            ),
          ),

          const SizedBox(width: 16),

          // Titre moderne
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '✨ Compte Professionnel',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Créez votre profil en ${4 - _currentStep} étapes',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Badge d'étape moderne
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '${_currentStep + 1}/4',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Indicateur de progression ultra-moderne
  Widget _buildModernProgress() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;

          return Expanded(
            child: Row(
              children: [
                // Cercle moderne avec animation
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: isCompleted || isActive
                        ? const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          )
                        : null,
                    color: !isCompleted && !isActive
                        ? Colors.white.withValues(alpha: 0.2)
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: isActive ? [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ] : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          )
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),

                // Ligne de connexion moderne
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 3,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        gradient: index < _currentStep
                            ? const LinearGradient(
                                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                              )
                            : null,
                        color: index >= _currentStep
                            ? Colors.white.withValues(alpha: 0.2)
                            : null,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 📱 Contenu moderne avec carte flottante
  Widget _buildModernContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: _buildStepContent(),
      ),
    );
  }

  /// 🚀 Navigation ultra-moderne
  Widget _buildModernNavigation() {
    return Container(
      height: 70,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Bouton Précédent moderne
          if (_currentStep > 0)
            Expanded(
              child: _buildModernButton(
                onPressed: _previousStep,
                icon: Icons.arrow_back_ios_new,
                label: 'Précédent',
                isPrimary: false,
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 16),

          // Bouton Suivant moderne
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: _buildModernButton(
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _currentStep == 3 ? Icons.check_rounded : Icons.arrow_forward_ios,
              label: _currentStep == 3 ? 'Soumettre' : 'Suivant',
              isPrimary: true,
              isLoading: _isSubmitting,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Bouton moderne réutilisable
  Widget _buildModernButton({
    required VoidCallback? onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              )
            : null,
        color: !isPrimary ? Colors.white.withValues(alpha: 0.2) : null,
        borderRadius: BorderRadius.circular(15),
        border: !isPrimary
            ? Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              )
            : null,
        boxShadow: isPrimary ? [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(15),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  /// 📱 En-tête fixe compact
  Widget _buildFixedHeader() {
    return Container(
      height: 100, // Réduit de 120 à 100
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Bouton retour
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              
              const SizedBox(width: 12),
              
              // Titre et sous-titre
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎯 Compte Professionnel',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Créez votre compte en quelques étapes',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📊 Indicateur de progression compact
  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Réduit le padding
      color: Colors.white,
      child: Row(
        children: List.generate(4, (index) {
          final isActive = index <= _currentStep;
          final isCompleted = index < _currentStep;
          
          return Expanded(
            child: Row(
              children: [
                // Cercle d'étape plus petit
                Container(
                  width: 28, // Réduit de 32 à 28
                  height: 28,
                  decoration: BoxDecoration(
                    color: isCompleted 
                        ? const Color(0xFF4CAF50)
                        : isActive 
                            ? const Color(0xFF667EEA)
                            : Colors.grey.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 16)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey[600],
                              fontWeight: FontWeight.w600,
                              fontSize: 12, // Réduit la taille de police
                            ),
                          ),
                  ),
                ),
                
                // Ligne de connexion (sauf pour le dernier)
                if (index < 3)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.symmetric(horizontal: 6), // Réduit la marge
                      color: index < _currentStep 
                          ? const Color(0xFF4CAF50)
                          : Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }

  /// 📋 Contenu de l'étape actuelle
  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildRoleSelectionStep();
      case 1:
        return _buildCommonFieldsStep();
      case 2:
        return _buildSpecificFieldsStep();
      case 3:
        return _buildConfirmationStep();
      default:
        return _buildRoleSelectionStep();
    }
  }

  /// 🔽 Navigation ULTRA-COMPACTE - SOLUTION RADICALE
  Widget _buildBottomNavigation() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8, // Adaptation SafeArea manuelle
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Bouton Précédent
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: const Text('Précédent', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                ),
              ),
            ),

          if (_currentStep > 0) const SizedBox(width: 12),

          // Bouton Suivant/Soumettre
          Expanded(
            flex: _currentStep == 0 ? 1 : 1,
            child: ElevatedButton.icon(
              onPressed: _isSubmitting ? null : _nextStep,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(_currentStep == 3 ? Icons.check : Icons.arrow_forward, size: 16),
              label: Text(
                _currentStep == 3 ? 'Soumettre' : 'Suivant',
                style: const TextStyle(fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF667EEA),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 ÉTAPE 1: Sélection du rôle ultra-moderne
  Widget _buildRoleSelectionStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre moderne avec gradient
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ).createShader(bounds),
            child: const Text(
              '✨ Choisissez votre rôle',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Sélectionnez le rôle qui correspond à votre fonction professionnelle',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 32),

          // Grille de rôles compacte
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.2,
            children: [
              _buildModernRoleCard(
                'agent_agence',
                '🏢 Agent d\'Agence',
                'Gérez les contrats et clients',
                Icons.business_center_rounded,
                const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
              ),
              _buildModernRoleCard(
                'expert_auto',
                '🔧 Expert Auto',
                'Expertise véhicules',
                Icons.engineering_rounded,
                const LinearGradient(colors: [Color(0xFF4CAF50), Color(0xFF45A049)]),
              ),
              _buildModernRoleCard(
                'admin_compagnie',
                '🏛️ Admin Compagnie',
                'Administration générale',
                Icons.admin_panel_settings_rounded,
                const LinearGradient(colors: [Color(0xFFFF9800), Color(0xFFFF8F00)]),
              ),
              _buildModernRoleCard(
                'admin_agence',
                '🏪 Admin Agence',
                'Gestion d\'agence',
                Icons.store_rounded,
                const LinearGradient(colors: [Color(0xFF9C27B0), Color(0xFF8E24AA)]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🎨 Carte de rôle ultra-moderne
  Widget _buildModernRoleCard(String roleId, String title, String description, IconData icon, LinearGradient gradient) {
    final isSelected = _selectedRole == roleId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: isSelected ? gradient : null,
          color: !isSelected ? Colors.grey.withValues(alpha: 0.05) : null,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.grey.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: gradient.colors.last.withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 16),
            ),
          ] : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 28,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 12),

            // Titre
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.grey[800],
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 6),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 11,
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.grey[600],
                height: 1.3,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 🎨 Carte de rôle compacte
  Widget _buildRoleCard(String roleId, String title, String description, IconData icon, Color color) {
    final isSelected = _selectedRole == roleId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = roleId;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : Colors.grey.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: isSelected ? Colors.white : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : Colors.grey[800],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            Text(
              description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 ÉTAPE 2: Champs communs ultra-modernes
  Widget _buildCommonFieldsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre avec gradient
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ).createShader(bounds),
              child: const Text(
                '📋 Vos informations',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Renseignez vos données personnelles avec précision',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            _buildCompactTextField(
              controller: _nomCompletController,
              label: 'Nom complet',
              icon: Icons.person,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le nom complet est obligatoire';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildCompactTextField(
              controller: _emailController,
              label: 'Adresse email',
              icon: Icons.email,
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

            const SizedBox(height: 16),

            _buildCompactTextField(
              controller: _telController,
              label: 'Numéro de téléphone',
              icon: Icons.phone,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le téléphone est obligatoire';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            _buildCompactTextField(
              controller: _cinController,
              label: 'Numéro CIN',
              icon: Icons.badge,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Le CIN est obligatoire';
                }
                return null;
              },
            ),

            // Espace supplémentaire pour éviter que le clavier cache le dernier champ
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  /// 🎨 Champ de texte ultra-moderne avec animations
  Widget _buildCompactTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF667EEA), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          labelStyle: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            color: Color(0xFF667EEA),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// 🔧 ÉTAPE 3: Champs spécifiques (optimisée)
  Widget _buildSpecificFieldsStep() {
    if (_selectedRole == null) {
      return const Center(
        child: Text('Veuillez d\'abord sélectionner un rôle'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '⚙️ Détails professionnels',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Informations spécifiques à votre rôle',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
              height: 1.3,
            ),
          ),

          const SizedBox(height: 24),

          ..._buildSpecificFields(),

          // Espace supplémentaire pour éviter l'overflow
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// 🎯 Construire les champs spécifiques selon le rôle
  List<Widget> _buildSpecificFields() {
    switch (_selectedRole) {
      case 'agent_agence':
        return [
          _buildCompactTextField(
            controller: _specificControllers['nom_agence']!,
            label: 'Nom de l\'agence',
            icon: Icons.business,
            validator: (value) => value?.isEmpty == true ? 'Nom d\'agence requis' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['adresse_agence']!,
            label: 'Adresse de l\'agence',
            icon: Icons.location_on,
            validator: (value) => value?.isEmpty == true ? 'Adresse requise' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['code_agence']!,
            label: 'Code agence',
            icon: Icons.numbers,
            validator: (value) => value?.isEmpty == true ? 'Code agence requis' : null,
          ),
        ];

      case 'expert_auto':
        return [
          _buildCompactTextField(
            controller: _specificControllers['numero_licence']!,
            label: 'Numéro de licence',
            icon: Icons.card_membership,
            validator: (value) => value?.isEmpty == true ? 'Numéro de licence requis' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['specialite']!,
            label: 'Spécialité',
            icon: Icons.engineering,
            validator: (value) => value?.isEmpty == true ? 'Spécialité requise' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['experience']!,
            label: 'Années d\'expérience',
            icon: Icons.timeline,
            keyboardType: TextInputType.number,
            validator: (value) => value?.isEmpty == true ? 'Expérience requise' : null,
          ),
        ];

      case 'admin_compagnie':
        return [
          _buildCompactTextField(
            controller: _specificControllers['nom_compagnie']!,
            label: 'Nom de la compagnie',
            icon: Icons.domain,
            validator: (value) => value?.isEmpty == true ? 'Nom de compagnie requis' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['code_compagnie']!,
            label: 'Code compagnie',
            icon: Icons.business_center,
            validator: (value) => value?.isEmpty == true ? 'Code compagnie requis' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['adresse_siege']!,
            label: 'Adresse du siège',
            icon: Icons.location_city,
            validator: (value) => value?.isEmpty == true ? 'Adresse du siège requise' : null,
          ),
        ];

      case 'admin_agence':
        return [
          _buildCompactTextField(
            controller: _specificControllers['nom_agence']!,
            label: 'Nom de l\'agence',
            icon: Icons.store,
            validator: (value) => value?.isEmpty == true ? 'Nom d\'agence requis' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['code_agence']!,
            label: 'Code agence',
            icon: Icons.numbers,
            validator: (value) => value?.isEmpty == true ? 'Code agence requis' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['ville']!,
            label: 'Ville',
            icon: Icons.location_city,
            validator: (value) => value?.isEmpty == true ? 'Ville requise' : null,
          ),
          const SizedBox(height: 16),
          _buildCompactTextField(
            controller: _specificControllers['tel_agence']!,
            label: 'Téléphone agence',
            icon: Icons.phone_in_talk,
            keyboardType: TextInputType.phone,
            validator: (value) => value?.isEmpty == true ? 'Téléphone agence requis' : null,
          ),
        ];

      default:
        return [
          const Text('Rôle non reconnu'),
        ];
    }
  }

  /// ✅ ÉTAPE 4: Confirmation ultra-moderne
  Widget _buildConfirmationStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre avec gradient et animation
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
            ).createShader(bounds),
            child: const Text(
              '✅ Confirmation',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Vérifiez vos informations avant de soumettre votre demande',
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[600],
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 24),

          _buildCompactSummaryCard(
            'Informations personnelles',
            Icons.person,
            [
              'Nom: ${_nomCompletController.text}',
              'Email: ${_emailController.text}',
              'Téléphone: ${_telController.text}',
              'CIN: ${_cinController.text}',
            ],
          ),

          const SizedBox(height: 12),

          _buildCompactSummaryCard(
            'Rôle sélectionné',
            Icons.work,
            [_getRoleDisplayName(_selectedRole ?? '')],
          ),

          const SizedBox(height: 12),

          if (_selectedRole != null)
            _buildCompactSummaryCard(
              'Détails professionnels',
              Icons.business_center,
              _getSpecificFieldsSummary(),
            ),

          const SizedBox(height: 20),

          // Message d'information moderne
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF667EEA).withValues(alpha: 0.1),
                  const Color(0xFF764BA2).withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF667EEA).withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667EEA).withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Demande en cours de traitement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Votre demande sera examinée par nos équipes. Vous recevrez une réponse par email sous 24-48h.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Espace supplémentaire pour éviter l'overflow
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  /// 📋 Carte de résumé ultra-moderne
  Widget _buildCompactSummaryCard(String title, IconData icon, List<String> items) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFF5F5F5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF667EEA).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.1),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône gradient
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A1A),
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Items avec style moderne
            ...items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  /// 📝 Résumé des champs spécifiques
  List<String> _getSpecificFieldsSummary() {
    switch (_selectedRole) {
      case 'agent_agence':
        return [
          'Agence: ${_specificControllers['nom_agence']?.text ?? ''}',
          'Adresse: ${_specificControllers['adresse_agence']?.text ?? ''}',
          'Code: ${_specificControllers['code_agence']?.text ?? ''}',
        ];
      case 'expert_auto':
        return [
          'Licence: ${_specificControllers['numero_licence']?.text ?? ''}',
          'Spécialité: ${_specificControllers['specialite']?.text ?? ''}',
          'Expérience: ${_specificControllers['experience']?.text ?? ''} ans',
        ];
      case 'admin_compagnie':
        return [
          'Compagnie: ${_specificControllers['nom_compagnie']?.text ?? ''}',
          'Code: ${_specificControllers['code_compagnie']?.text ?? ''}',
          'Siège: ${_specificControllers['adresse_siege']?.text ?? ''}',
        ];
      case 'admin_agence':
        return [
          'Agence: ${_specificControllers['nom_agence']?.text ?? ''}',
          'Code: ${_specificControllers['code_agence']?.text ?? ''}',
          'Ville: ${_specificControllers['ville']?.text ?? ''}',
          'Tél: ${_specificControllers['tel_agence']?.text ?? ''}',
        ];
      default:
        return [];
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'agent_agence': return '🏢 Agent d\'Agence';
      case 'expert_auto': return '🔧 Expert Automobile';
      case 'admin_compagnie': return '🏛️ Admin Compagnie';
      case 'admin_agence': return '🏪 Admin Agence';
      default: return role;
    }
  }

  /// ⬅️ Étape précédente
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// ➡️ Étape suivante
  void _nextStep() {
    if (_currentStep < 3) {
      if (_validateCurrentStep()) {
        setState(() {
          _currentStep++;
        });
      }
    } else {
      _submitRequest();
    }
  }

  /// ✅ Valider l'étape actuelle
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0:
        if (_selectedRole == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez sélectionner un rôle'),
              backgroundColor: Colors.orange,
            ),
          );
          return false;
        }
        return true;

      case 1:
        if (!(_formKey.currentState?.validate() ?? false)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Veuillez corriger les erreurs dans le formulaire'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
        return true;

      case 2:
        return _validateSpecificFields();

      default:
        return true;
    }
  }

  /// 🎯 Valider les champs spécifiques
  bool _validateSpecificFields() {
    List<String> requiredFields = [];

    switch (_selectedRole) {
      case 'agent_agence':
        requiredFields = ['nom_agence', 'adresse_agence', 'code_agence'];
        break;
      case 'expert_auto':
        requiredFields = ['numero_licence', 'specialite', 'experience'];
        break;
      case 'admin_compagnie':
        requiredFields = ['nom_compagnie', 'code_compagnie', 'adresse_siege'];
        break;
      case 'admin_agence':
        requiredFields = ['nom_agence', 'code_agence', 'ville', 'tel_agence'];
        break;
    }

    for (String field in requiredFields) {
      if (_specificControllers[field]?.text.trim().isEmpty ?? true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez remplir tous les champs obligatoires'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }

    return true;
  }

  /// 📤 Soumettre la demande
  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Préparer les données communes
      Map<String, dynamic> commonData = {
        'nom_complet': _nomCompletController.text.trim(),
        'email': _emailController.text.trim(),
        'telephone': _telController.text.trim(),
        'cin': _cinController.text.trim(),
        'role': _selectedRole,
        'status': 'en_attente',
        'date_demande': DateTime.now().toIso8601String(),
      };

      // Ajouter les données spécifiques
      Map<String, dynamic> specificData = {};
      switch (_selectedRole) {
        case 'agent_agence':
          specificData = {
            'nom_agence': _specificControllers['nom_agence']?.text.trim(),
            'adresse_agence': _specificControllers['adresse_agence']?.text.trim(),
            'code_agence': _specificControllers['code_agence']?.text.trim(),
          };
          break;
        case 'expert_auto':
          specificData = {
            'numero_licence': _specificControllers['numero_licence']?.text.trim(),
            'specialite': _specificControllers['specialite']?.text.trim(),
            'experience': _specificControllers['experience']?.text.trim(),
          };
          break;
        case 'admin_compagnie':
          specificData = {
            'nom_compagnie': _specificControllers['nom_compagnie']?.text.trim(),
            'code_compagnie': _specificControllers['code_compagnie']?.text.trim(),
            'adresse_siege': _specificControllers['adresse_siege']?.text.trim(),
          };
          break;
        case 'admin_agence':
          specificData = {
            'nom_agence': _specificControllers['nom_agence']?.text.trim(),
            'code_agence': _specificControllers['code_agence']?.text.trim(),
            'ville': _specificControllers['ville']?.text.trim(),
            'tel_agence': _specificControllers['tel_agence']?.text.trim(),
          };
          break;
      }

      // Combiner toutes les données
      Map<String, dynamic> requestData = {...commonData, ...specificData};

      // TODO: Envoyer à Firebase
      // await FirebaseFirestore.instance
      //     .collection('demandes_professionnels')
      //     .add(requestData);

      // Simulation pour le moment
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande soumise avec succès !'),
            backgroundColor: Colors.green,
          ),
        );

        // Rediriger vers l'écran d'attente
        Navigator.pushReplacementNamed(context, '/waiting_approval');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de la soumission: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
