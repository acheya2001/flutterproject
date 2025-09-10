import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/collaborative_session_service.dart';
import '../../services/conducteur_data_service.dart';
import 'session_invitation_screen.dart';
import 'modern_single_accident_info_screen.dart';

/// 🚗 Écran de sélection du nombre de véhicules pour mode collaboratif
class CollaborativeVehicleCountScreen extends StatefulWidget {
  final String typeAccident;

  const CollaborativeVehicleCountScreen({
    super.key,
    required this.typeAccident,
  });

  @override
  State<CollaborativeVehicleCountScreen> createState() => _CollaborativeVehicleCountScreenState();
}

class _CollaborativeVehicleCountScreenState extends State<CollaborativeVehicleCountScreen>with TickerProviderStateMixin  {
  int _nombreVehicules = 2;
  bool _isLoading = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.indigo[600]!,
              Colors.blue[700]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: _buildContenu(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Accident collaboratif',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.group, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Collaboratif',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContenu() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          
          // Illustration
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(
              Icons.directions_car,
              size: 60,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Titre et description
          const Text(
            'Combien de véhicules ?',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 12),
          
          Text(
            'Sélectionnez le nombre total de véhicules impliqués dans cet accident',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 40),
          
          // Sélecteur de nombre
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.indigo[600]),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Nombre de véhicules',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Compteur avec boutons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _nombreVehicules > 2 ? _decrementer : null,
                        icon: const Icon(Icons.remove),
                        color: Colors.indigo[800],
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.indigo[600],
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$_nombreVehicules',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 24),
                    
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: _nombreVehicules < 15 ? _incrementer : null,
                        icon: const Icon(Icons.add),
                        color: Colors.indigo[800],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                Text(
                  'Min: 2 véhicules - Max: 15 véhicules',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Aperçu des rôles
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rôles des véhicules :',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(_nombreVehicules, (index) {
                          final roles = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O'];
                          final role = index < roles.length ? roles[index] : '?';
                          final isCreator = index == 0;
                          
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isCreator ? Colors.indigo[100] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Véhicule $role',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isCreator ? Colors.indigo[800] : Colors.grey[700],
                                  ),
                                ),
                                if (isCreator) ...[
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.star,
                                    size: 12,
                                    color: Colors.indigo[800],
                                  ),
                                ],
                              ],
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Bouton créer session
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _creerSession,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.indigo[800],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Créer la session collaborative',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Information
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Colors.white.withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      'Comment ça marche ?',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Vous serez le créateur (Véhicule A)\n'
                  '• Un code de session sera généré\n'
                  '• Partagez ce code aux autres conducteurs\n'
                  '• Chacun remplit sa partie du constat\n'
                  '• Vous dessinez le croquis pour tous\n'
                  '• Signatures électroniques pour finaliser',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _incrementer() {
    if (_nombreVehicules < 15) {
      setState(() => _nombreVehicules++);
    }
  }

  void _decrementer() {
    if (_nombreVehicules > 2) {
      setState(() => _nombreVehicules--);
    }
  }

  Future<void> _creerSession() async {
    setState(() => _isLoading = true);

    try {
      print('🚀 Début création session...');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      print('✅ Utilisateur connecté: ${user.uid}');

      // Obtenir les données du conducteur
      print('📋 Récupération données conducteur...');
      final donneesUtilisateur = await ConducteurDataService.recupererDonneesConducteur();
      print('✅ Données récupérées: $donneesUtilisateur');

      // Créer la session collaborative
      print('🎯 Création session collaborative...');
      final session = await CollaborativeSessionService.creerSessionCollaborative(
        typeAccident: widget.typeAccident,
        nombreVehicules: _nombreVehicules,
        nomCreateur: donneesUtilisateur?['nom'] ?? 'Nom',
        prenomCreateur: donneesUtilisateur?['prenom'] ?? 'Prénom',
        emailCreateur: donneesUtilisateur?['email'] ?? user.email ?? '',
        telephoneCreateur: donneesUtilisateur?['telephone'] ?? '',
      );
      print('✅ Session créée: ${session.id}');

      // Naviguer vers l'écran d'invitation
      print('🔄 Navigation vers écran invitation...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SessionInvitationScreen(session: session),
        ),
      );
      print('✅ Navigation terminée');
    } catch (e) {
      print('❌ Erreur création session: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('Erreur: $e')),
            ],
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}
