import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/connectivity_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_state.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vehicule/models/vehicule_model.dart';
import '../../vehicule/providers/vehicule_provider.dart';
import '../../vehicule/screens/vehicule_detail_screen.dart';
import '../../vehicule/screens/vehicule_form_screen.dart';

class ConducteurVehiculesScreen extends StatefulWidget {
  final String? conducteurId;

  const ConducteurVehiculesScreen({
    Key? key,
    this.conducteurId,
  }) : super(key: key);

  @override
  State<ConducteurVehiculesScreen> createState() => _ConducteurVehiculesScreenState();
}

class _ConducteurVehiculesScreenState extends State<ConducteurVehiculesScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  String? _errorMessage;
  List<VehiculeModel> _vehicules = [];
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadVehicules();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicules() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Vérifier la connexion Internet
      final connectivityUtils = ConnectivityUtils();
      final isConnected = await connectivityUtils.checkConnection();
      
      if (!isConnected) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _errorMessage = 'Pas de connexion Internet. Veuillez vérifier votre connexion et réessayer.';
        });
        return;
      }

      // Récupérer l'ID du conducteur
      String userId;
      
      if (widget.conducteurId != null) {
        userId = widget.conducteurId!;
      } else {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (!mounted) return;
        
        if (authProvider.currentUser == null) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Utilisateur non connecté. Veuillez vous connecter pour voir vos véhicules.';
          });
          return;
        }
        
        userId = authProvider.currentUser!.id;
      }

      // Récupérer les véhicules du conducteur
      final vehiculeProvider = Provider.of<VehiculeProvider>(context, listen: false);
      if (!mounted) return;
      
      await vehiculeProvider.fetchVehiculesByProprietaireId(userId);
      
      if (!mounted) return;
      setState(() {
        _vehicules = vehiculeProvider.vehicules;
        _isLoading = false;
      });
      
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Erreur lors du chargement des véhicules: $e';
      });
    }
  }

  Future<void> _addVehicule() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (!mounted) return;
    
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Text('Vous devez être connecté pour ajouter un véhicule'),
            ],
          ),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const VehiculeFormScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      await _loadVehicules();
    }
  }

  Future<void> _viewVehiculeDetails(VehiculeModel vehicule) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => VehiculeDetailScreen(
          vehicule: vehicule,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut)),
            child: child,
          );
        },
      ),
    );

    if (result == true && mounted) {
      await _loadVehicules();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Mes véhicules',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2D3748)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _loadVehicules,
              icon: const Icon(Icons.refresh_rounded, size: 22),
              style: IconButton.styleFrom(
                backgroundColor: const Color(0xFFF7FAFC),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingState(message: 'Chargement des véhicules...')
          : _errorMessage != null
              ? ErrorState(
                  message: _errorMessage!,
                  onRetry: _loadVehicules,
                )
              : _vehicules.isEmpty
                  ? _buildEmptyState()
                  : _buildVehiculesList(),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF4299E1), Color(0xFF3182CE)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4299E1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _addVehicule,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFEBF8FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 64,
                color: Color(0xFF4299E1),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucun véhicule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'Vous n\'avez pas encore ajouté de véhicule. Ajoutez votre premier véhicule en cliquant sur le bouton +',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehiculesList() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: RefreshIndicator(
        onRefresh: _loadVehicules,
        color: const Color(0xFF4299E1),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _vehicules.length,
          itemBuilder: (context, index) {
            return AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                final slideAnimation = Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _animationController,
                  curve: Interval(
                    (index * 0.1).clamp(0.0, 1.0),
                    ((index * 0.1) + 0.3).clamp(0.0, 1.0),
                    curve: Curves.easeOut,
                  ),
                ));

                return SlideTransition(
                  position: slideAnimation,
                  child: FadeTransition(
                    opacity: _animationController,
                    child: _buildVehiculeCard(_vehicules[index], index),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildVehiculeCard(VehiculeModel vehicule, int index) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final now = DateTime.now();
    final isExpired = vehicule.dateFinValidite != null && vehicule.dateFinValidite!.isBefore(now);
    final expiresInDays = vehicule.dateFinValidite != null
        ? vehicule.dateFinValidite!.difference(now).inDays
        : 0;
    final isExpiringSoon = !isExpired && expiresInDays <= 30;

    // Couleurs alternées pour les cartes
    final cardColors = [
      [const Color(0xFFF0FFF4), const Color(0xFF68D391)], // Vert menthe
      [const Color(0xFFFFF5F5), const Color(0xFFFC8181)], // Rose corail
      [const Color(0xFFF7FAFC), const Color(0xFF4299E1)], // Bleu ciel
      [const Color(0xFFFFFAF0), const Color(0xFFED8936)], // Orange pêche
    ];
    
    final colorIndex = index % cardColors.length;
    final backgroundColor = cardColors[colorIndex][0];
    final accentColor = cardColors[colorIndex][1];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        child: InkWell(
          onTap: () => _viewVehiculeDetails(vehicule),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header avec statut et immatriculation
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accentColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isExpired
                                ? Icons.error_outline_rounded
                                : isExpiringSoon
                                    ? Icons.warning_amber_rounded
                                    : Icons.check_circle_outline_rounded,
                            size: 14,
                            color: isExpired
                                ? const Color(0xFFE53E3E)
                                : isExpiringSoon
                                    ? const Color(0xFFD69E2E)
                                    : const Color(0xFF38A169),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isExpired
                                ? 'Expiré'
                                : isExpiringSoon
                                    ? 'Expire bientôt'
                                    : 'Valide',
                            style: TextStyle(
                              color: isExpired
                                  ? const Color(0xFFE53E3E)
                                  : isExpiringSoon
                                      ? const Color(0xFFD69E2E)
                                      : const Color(0xFF38A169),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        vehicule.immatriculation,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Informations du véhicule
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Marque',
                        vehicule.marque.isNotEmpty ? vehicule.marque : 'Non spécifié',
                        Icons.branding_watermark_rounded,
                        accentColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Modèle',
                        vehicule.modele.isNotEmpty ? vehicule.modele : 'Non spécifié',
                        Icons.model_training_rounded,
                        accentColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoItem(
                        'Assureur',
                        vehicule.compagnieAssurance.isNotEmpty 
                            ? vehicule.compagnieAssurance 
                            : 'Non spécifié',
                        Icons.security_rounded,
                        accentColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        'Validité',
                        vehicule.dateFinValidite != null
                            ? dateFormat.format(vehicule.dateFinValidite!)
                            : 'Non spécifiée',
                        Icons.calendar_today_rounded,
                        isExpired
                            ? const Color(0xFFE53E3E)
                            : isExpiringSoon
                                ? const Color(0xFFD69E2E)
                                : accentColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Bouton d'action
                Container(
                  width: double.infinity,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accentColor.withOpacity(0.8), accentColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _viewVehiculeDetails(vehicule),
                      borderRadius: BorderRadius.circular(12),
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.visibility_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Voir les détails',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 14,
              color: color.withOpacity(0.7),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF718096),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF2D3748),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
