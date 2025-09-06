import 'package:flutter/material.dart';
import 'modern_vehicle_count_screen.dart';
import 'session_invitation_screen.dart';
import 'modern_single_accident_info_screen.dart';
import 'modern_single_accident_info_screen.dart';
import 'modern_invitation_screen.dart';


/// 🎨 Interface moderne de sélection du type d'accident
class ModernAccidentTypeScreen extends StatefulWidget {
  const ModernAccidentTypeScreen({super.key});

  @override
  State<ModernAccidentTypeScreen> createState() => _ModernAccidentTypeScreenState();
}

class _ModernAccidentTypeScreenState extends State<ModernAccidentTypeScreen> 
    with TickerProviderStateMixin {
  String? _typeAccidentSelectionne;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> _typesAccidents = [
    {
      'id': 'collision_deux_vehicules',
      'titre': 'Collision entre deux véhicules',
      'description': 'Accident impliquant exactement 2 véhicules',
      'icon': '⚡',
      'couleur': Colors.blue,
      'nombreVehicules': 2,
    },
    {
      'id': 'carambolage',
      'titre': 'Carambolage',
      'description': '3 véhicules ou plus impliqués',
      'icon': '🚗💥🚙',
      'couleur': Colors.red,
      'nombreVehicules': null, // Sera choisi dans l'écran suivant
    },
    {
      'id': 'sortie_route',
      'titre': 'Sortie de route',
      'description': 'Véhicule seul, sortie de chaussée',
      'icon': '🛣️',
      'couleur': Colors.orange,
      'nombreVehicules': 1,
    },
    {
      'id': 'collision_objet_fixe',
      'titre': 'Collision avec objet fixe',
      'description': 'Mur, poteau, arbre, etc.',
      'icon': '🛑',
      'couleur': Colors.purple,
      'nombreVehicules': 1,
    },
    {
      'id': 'accident_pieton_cycliste',
      'titre': 'Accident avec piéton ou cycliste',
      'description': 'Impliquant un piéton ou cycliste',
      'icon': '🚴‍♂️',
      'couleur': Colors.green,
      'nombreVehicules': 1,
    },
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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[400]!,
              Colors.purple[600]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header avec titre et icône
              _buildHeader(),
              
              // Liste des types d'accidents
              Expanded(
                child: Container(
                  margin: const EdgeInsets.only(top: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 30),
                      
                      // Liste des cartes
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _typesAccidents.length,
                          itemBuilder: (context, index) {
                            final type = _typesAccidents[index];
                            return _buildAccidentTypeCard(type, index);
                          },
                        ),
                      ),
                      
                      // Bouton continuer
                      _buildContinueButton(),
                      
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Icône principale
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(40),
            ),
            child: const Center(
              child: Text(
                '🚗💥',
                style: TextStyle(fontSize: 40),
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Titre principal
          const Text(
            'Quel est le type d\'accident ?',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 10),
          
          const Text(
            'Sélectionnez le type qui correspond à votre situation',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAccidentTypeCard(Map<String, dynamic> type, int index) {
    final isSelected = _typeAccidentSelectionne == type['id'];
    
    return AnimatedContainer(
      duration: Duration(milliseconds: 200 + (index * 50)),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(bottom: 16),
      child: Hero(
        tag: 'accident_card_${type['id']}',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _selectionnerType(type),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected 
                    ? type['couleur'].withOpacity(0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected 
                      ? type['couleur']
                      : Colors.grey[300]!,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isSelected 
                        ? type['couleur'].withOpacity(0.3)
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: isSelected ? 3 : 1,
                    blurRadius: isSelected ? 10 : 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icône
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: type['couleur'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        type['icon'],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          type['titre'],
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected 
                                ? type['couleur']
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          type['description'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Indicateur de sélection
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? type['couleur']
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? type['couleur']
                            : Colors.grey[400]!,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: _typeAccidentSelectionne != null ? _continuer : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _typeAccidentSelectionne != null 
                ? Colors.blue[600]
                : Colors.grey[300],
            foregroundColor: Colors.white,
            elevation: _typeAccidentSelectionne != null ? 8 : 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Continuer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _typeAccidentSelectionne != null 
                      ? Colors.white
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward,
                color: _typeAccidentSelectionne != null 
                    ? Colors.white
                    : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectionnerType(Map<String, dynamic> type) {
    setState(() {
      _typeAccidentSelectionne = type['id'];
    });
    
    // Animation de feedback
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
    
    // Vibration légère (optionnel)
    // HapticFeedback.lightImpact();
  }

  void _continuer() {
    if (_typeAccidentSelectionne == null) return;
    
    final typeSelectionne = _typesAccidents.firstWhere(
      (type) => type['id'] == _typeAccidentSelectionne,
    );
    
    // Navigation selon le type d'accident
    if (typeSelectionne['nombreVehicules'] != null) {
      // Nombre de véhicules fixe - aller directement à la sélection de véhicule
      _naviguerVersSelectionVehicule(typeSelectionne);
    } else {
      // Nombre de véhicules variable - aller à l'écran de sélection du nombre
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => 
              ModernVehicleCountScreen(
                typeAccident: typeSelectionne,
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

  void _naviguerVersSelectionVehicule(Map<String, dynamic> typeAccident) {
    final String titre = typeAccident['titre'];

    // Vérifier si c'est un accident nécessitant une invitation
    final bool necessiteInvitation = titre.toLowerCase().contains('collision') ||
                                   titre.toLowerCase().contains('carambolage') ||
                                   titre.toLowerCase().contains('entre') ||
                                   titre.toLowerCase().contains('multiple');

    if (necessiteInvitation) {
      // Naviguer vers l'interface d'invitation moderne
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ModernInvitationScreen(
                typeAccident: titre,
                nombreVehicules: typeAccident['nombreVehicules'] ?? 2,
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
    } else {
      // Naviguer vers le formulaire normal
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              ModernSingleAccidentInfoScreen(
                typeAccident: titre,
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

  /// Détermine si un type d'accident nécessite une invitation d'autres conducteurs
  bool _necessiteInvitation(String typeAccident) {
    final typesUniques = [
      'Sortie de route',
      'Collision avec objet fixe',
      'Accident avec piéton ou cycliste',
    ];

    return !typesUniques.contains(typeAccident);
  }
}
