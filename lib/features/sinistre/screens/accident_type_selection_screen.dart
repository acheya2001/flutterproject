import 'package:flutter/material.dart';
import '../../../common/widgets/gradient_background.dart';
import '../../../common/widgets/custom_app_bar.dart';
import 'vehicle_count_selection_screen.dart';
import '../../../conducteur/screens/accident_invitation_screen.dart';
import '../../../conducteur/screens/constat_complet_screen.dart';

/// 🚗💥 Écran de sélection du type d'accident - Design moderne
class AccidentTypeSelectionScreen extends StatefulWidget {
  final String? sinistreId;
  final Map<String, dynamic>? vehiculeSelectionne;

  const AccidentTypeSelectionScreen({
    Key? key,
    this.sinistreId,
    this.vehiculeSelectionne,
  }) : super(key: key);

  @override
  State<AccidentTypeSelectionScreen> createState() => _AccidentTypeSelectionScreenState();
}

class _AccidentTypeSelectionScreenState extends State<AccidentTypeSelectionScreen>
    with TickerProviderStateMixin {
  String? _selectedType;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<AccidentType> _accidentTypes = [
    AccidentType(
      id: 'collision_deux_vehicules',
      title: 'Collision entre deux véhicules',
      icon: '⚡',
      color: const Color(0xFF3B82F6), // Bleu
      description: 'Accident impliquant exactement 2 véhicules',
      defaultVehicleCount: 2,
    ),
    AccidentType(
      id: 'carambolage',
      title: 'Carambolage (3+ véhicules)',
      icon: '🚗💥🚙',
      color: const Color(0xFFEF4444), // Rouge
      description: 'Accident en chaîne avec plusieurs véhicules',
      defaultVehicleCount: 3,
    ),
    AccidentType(
      id: 'sortie_route',
      title: 'Sortie de route',
      icon: '🛣️',
      color: const Color(0xFFF59E0B), // Orange
      description: 'Véhicule ayant quitté la chaussée',
      defaultVehicleCount: 1,
    ),
    AccidentType(
      id: 'collision_objet_fixe',
      title: 'Collision avec objet fixe',
      icon: '🛑',
      color: const Color(0xFF8B5CF6), // Violet
      description: 'Mur, poteau, arbre, etc.',
      defaultVehicleCount: 1,
    ),
    AccidentType(
      id: 'accident_pieton_cycliste',
      title: 'Accident avec piéton ou cycliste',
      icon: '🚴‍♂️',
      color: const Color(0xFF10B981), // Vert
      description: 'Impliquant un piéton ou cycliste',
      defaultVehicleCount: 1,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        colors: [
          const Color(0xFF667eea),
          const Color(0xFF764ba2),
          const Color(0xFFf093fb),
        ],
        child: SafeArea(
          child: Column(
            children: [
              CustomAppBar(
                title: 'Type d\'accident',
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: _buildAccidentTypesList(),
                      ),
                    ],
                  ),
                ),
              ),
              _buildContinueButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.9),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '🚗💥',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Quel est le type d\'accident ?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Sélectionnez le type qui correspond le mieux à votre situation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccidentTypesList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _accidentTypes.length,
      itemBuilder: (context, index) {
        final type = _accidentTypes[index];
        final isSelected = _selectedType == type.id;
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 16),
          child: Hero(
            tag: 'accident_type_${type.id}',
            child: Material(
              color: Colors.transparent,
              child: _buildAccidentTypeCard(type, isSelected),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccidentTypeCard(AccidentType type, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  type.color.withOpacity(0.8),
                  type.color,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? type.color : Colors.grey.withOpacity(0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected 
                ? type.color.withOpacity(0.3)
                : Colors.black.withOpacity(0.1),
            blurRadius: isSelected ? 15 : 8,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAccidentType(type),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icône
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? Colors.white.withOpacity(0.2)
                        : type.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Center(
                    child: Text(
                      type.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : const Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        type.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: isSelected 
                              ? Colors.white.withOpacity(0.9)
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Indicateur de sélection
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.grey,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 16,
                          color: type.color,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: AnimatedOpacity(
        opacity: _selectedType != null ? 1.0 : 0.5,
        duration: const Duration(milliseconds: 200),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            gradient: _selectedType != null
                ? const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [Colors.grey[400]!, Colors.grey[500]!],
                  ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: _selectedType != null
                ? [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : [],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _selectedType != null ? _continueToNextStep : null,
              borderRadius: BorderRadius.circular(16),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Continuer',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectAccidentType(AccidentType type) {
    setState(() {
      _selectedType = type.id;
    });
    
    // Animation légère
    _animationController.reset();
    _animationController.forward();
  }

  void _continueToNextStep() {
    if (_selectedType == null) return;

    final selectedType = _accidentTypes.firstWhere((type) => type.id == _selectedType);

    // 🚗 Collision 2 véhicules : aller directement à l'invitation (pas besoin de demander le nombre)
    if (_selectedType == 'collision_deux_vehicules') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccidentInvitationScreen(
            sinistreId: widget.sinistreId!,
            vehiculeSelectionne: widget.vehiculeSelectionne!,
            accidentType: _selectedType!,
            vehicleCount: 2, // Fixe à 2 véhicules
          ),
        ),
      );
      return;
    }

    // 🛣️ Sortie de route ou 🛑 Objet fixe : 1 seul véhicule, aller au formulaire
    if (_selectedType == 'sortie_route' || _selectedType == 'collision_objet_fixe') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConstatCompletScreen(
            sinistreId: widget.sinistreId,
            vehiculeSelectionne: widget.vehiculeSelectionne,
            accidentType: _selectedType!,
            vehicleCount: 1, // 1 seul véhicule
            isCollaborative: false,
            sessionData: null, // Pas de session collaborative
          ),
        ),
      );
      return;
    }

    // 🚗💥🚙 Carambolage ou 🚴‍♂️ Piéton/cycliste : demander le nombre
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VehicleCountSelectionScreen(
          accidentType: selectedType,
          sinistreId: widget.sinistreId,
          vehiculeSelectionne: widget.vehiculeSelectionne,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
      ),
    );
  }
}

/// 📋 Modèle pour les types d'accident
class AccidentType {
  final String id;
  final String title;
  final String icon;
  final Color color;
  final String description;
  final int defaultVehicleCount;

  AccidentType({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    required this.defaultVehicleCount,
  });
}
