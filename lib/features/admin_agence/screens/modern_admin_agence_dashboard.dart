import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_service.dart';
import '../../../services/admin_agence_diagnostic_service.dart';
import '../widgets/alerts_panel.dart';
import 'agence_info_screen.dart';
import 'agents_management_screen.dart';
import 'experts_management_screen.dart';
import 'bi_dashboard_screen.dart';
import 'contract_management_screen.dart';
import 'demandes_contrats_screen.dart';
import '../../agent/screens/pending_vehicles_management_screen.dart';

/// 🎨 Dashboard Admin Agence - Design Ultra Moderne
class ModernAdminAgenceDashboard extends StatefulWidget {
  final Map<String, dynamic>? userData;

  const ModernAdminAgenceDashboard({
    Key? key,
    this.userData,
  }) : super(key: key);

  @override
  State<ModernAdminAgenceDashboard> createState() => _ModernAdminAgenceDashboardState();
}

class _ModernAdminAgenceDashboardState extends State<ModernAdminAgenceDashboard>with TickerProviderStateMixin  {
  int _selectedIndex = 0;
  Map<String, dynamic>? _agenceData;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _agents = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 📊 Charger toutes les données
  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);

    try {
      debugPrint('[MODERN_ADMIN_AGENCE] 🔄 Début chargement données...');
      debugPrint('[MODERN_ADMIN_AGENCE] 👤 UserData: ${widget.userData}');
      
      // Charger les informations de l'agence
      debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Recherche agence pour UID: ${widget.userData!['uid']}');
      debugPrint('[MODERN_ADMIN_AGENCE] 📋 UserData agenceId: ${widget.userData!['agenceId']}');

      Map<String, dynamic>? agenceInfo;

      // Essayer d'abord avec l'agenceId des userData
      final agenceId = widget.userData!['agenceId'];
      if (agenceId != null) {
        debugPrint('[MODERN_ADMIN_AGENCE] 🎯 Recherche directe avec agenceId: $agenceId');
        agenceInfo = await _getAgenceDirectly(agenceId);
      }

      // Si pas trouvé, utiliser la méthode classique
      if (agenceInfo == null) {
        debugPrint('[MODERN_ADMIN_AGENCE] 🔄 Recherche classique par UID...');
        agenceInfo = await AdminAgenceService.getAgenceInfo(widget.userData!['uid']);
      }

      if (agenceInfo != null) {
        debugPrint('[MODERN_ADMIN_AGENCE] ✅ Agence trouvée: ${agenceInfo['nom']}');
        debugPrint('[MODERN_ADMIN_AGENCE] 🏢 CompagnieInfo: ${agenceInfo['compagnieInfo']}');

        _agenceData = agenceInfo;
        
        // Charger les statistiques
        debugPrint('[MODERN_ADMIN_AGENCE] 📊 Appel getAgenceStats avec ID: ${agenceInfo['id']}');
        final stats = await AdminAgenceService.getAgenceStats(agenceInfo['id']);
        debugPrint('[MODERN_ADMIN_AGENCE] 📈 Stats reçues: $stats');

        // Si les stats sont vides, essayer avec l'agenceId des userData
        if (stats['totalAgents'] == 0 && widget.userData!['agenceId'] != null) {
          debugPrint('[MODERN_ADMIN_AGENCE] 🔄 Stats vides, essai avec agenceId userData: ${widget.userData!['agenceId']}');
          final alternativeStats = await AdminAgenceService.getAgenceStats(widget.userData!['agenceId']);
          debugPrint('[MODERN_ADMIN_AGENCE] 📈 Stats alternatives: $alternativeStats');
          if (alternativeStats['totalAgents'] > 0) {
            _stats = alternativeStats;
          } else {
            _stats = stats;
          }
        } else {
          _stats = stats;
        }
        
        // Charger les agents
        debugPrint('[MODERN_ADMIN_AGENCE] 👥 Appel getAgentsOfAgence avec ID: ${agenceInfo['id']}');
        final agents = await AdminAgenceService.getAgentsOfAgence(agenceInfo['id']);
        debugPrint('[MODERN_ADMIN_AGENCE] 👥 Agents reçus: ${agents.length}');
        _agents = agents;

        // Recalculer les stats à partir des agents récupérés si nécessaire
        if (_stats['totalAgents'] == 0 && agents.isNotEmpty) {
          debugPrint('[MODERN_ADMIN_AGENCE] 🔄 Recalcul des stats à partir des agents récupérés');
          final activeAgents = agents.where((agent) => agent['isActive'] == true).length;
          _stats = {
            'totalAgents': agents.length,
            'activeAgents': activeAgents,
            'inactiveAgents': agents.length - activeAgents,
            'recentActions': [],
          };
          debugPrint('[MODERN_ADMIN_AGENCE] 📈 Stats recalculées: $_stats');
        }
        
        // Démarrer l'animation
        _animationController.forward();
      } else {
        debugPrint('[MODERN_ADMIN_AGENCE] ❌ Aucune agence trouvée pour cet admin');
      }

    } catch (e, stackTrace) {
      debugPrint('[MODERN_ADMIN_AGENCE] ❌ Erreur chargement données: $e');
      debugPrint('[MODERN_ADMIN_AGENCE] 📍 StackTrace: $stackTrace');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 🎯 Récupérer l'agence directement par ID
  Future<Map<String, dynamic>?> _getAgenceDirectly(String agenceId) async {
    try {
      debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Récupération directe agence: $agenceId');

      final agenceDoc = await FirebaseFirestore.instance.collection('agences').doc(agenceId).get();

      if (!agenceDoc.exists) {
        debugPrint('[MODERN_ADMIN_AGENCE] ❌ Agence non trouvée: $agenceId');
        return null;
      }

      final agenceData = agenceDoc.data()!;
      agenceData['id'] = agenceDoc.id;

      debugPrint('[MODERN_ADMIN_AGENCE] 📋 Données agence complètes: $agenceData');

      // Récupérer les informations de la compagnie mère
      final compagnieId = agenceData['compagnieId'];
      debugPrint('[MODERN_ADMIN_AGENCE] 🏢 CompagnieId trouvé: $compagnieId');
      debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Type compagnieId: ${compagnieId.runtimeType}');

      if (compagnieId != null) {
        debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Recherche compagnie avec ID: $compagnieId');

        // Vérifier d'abord si la collection existe
        final compagniesSnapshot = await FirebaseFirestore.instance.collection('compagnies_assurance').limit(1).get();
        debugPrint('[MODERN_ADMIN_AGENCE] 📊 Collection compagnies_assurance existe: ${compagniesSnapshot.docs.isNotEmpty}');

        // Essayer plusieurs collections possibles
        Map<String, dynamic>? compagnieData;
        final collectionsToTry = ['compagnies_assurance', 'compagnies', 'companies'];

        for (String collectionName in collectionsToTry) {
          debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Essai collection: $collectionName');
          try {
            final compagnieDoc = await FirebaseFirestore.instance.collection(collectionName).doc(compagnieId).get();
            debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Doc exists dans $collectionName: ${compagnieDoc.exists}');

            if (compagnieDoc.exists) {
              compagnieData = compagnieDoc.data()!;
              debugPrint('[MODERN_ADMIN_AGENCE] ✅ Compagnie trouvée dans $collectionName: ${compagnieData['nom']}');
              break;
            }
          } catch (e) {
            debugPrint('[MODERN_ADMIN_AGENCE] ❌ Erreur collection $collectionName: $e');
          }
        }

        if (compagnieData != null) {
          agenceData['compagnieInfo'] = compagnieData;
          debugPrint('[MODERN_ADMIN_AGENCE] 📋 Données compagnie finales: $compagnieData');
        } else {
          debugPrint('[MODERN_ADMIN_AGENCE] ❌ Aucune compagnie trouvée dans toutes les collections');

          // Lister les collections disponibles
          for (String collectionName in collectionsToTry) {
            try {
              final snapshot = await FirebaseFirestore.instance.collection(collectionName).limit(3).get();
              debugPrint('[MODERN_ADMIN_AGENCE] 📋 Collection $collectionName: ${snapshot.docs.length} docs');
              for (var doc in snapshot.docs) {
                debugPrint('[MODERN_ADMIN_AGENCE] 📄 Doc ${doc.id}: ${doc.data()}');
              }
            } catch (e) {
              debugPrint('[MODERN_ADMIN_AGENCE] ❌ Collection $collectionName inaccessible: $e');
            }
          }
        }
      } else {
        debugPrint('[MODERN_ADMIN_AGENCE] ❌ Aucun compagnieId dans l\'agence');
        debugPrint('[MODERN_ADMIN_AGENCE] 🔍 Clés disponibles dans agence: ${agenceData.keys.toList()}');
      }

      debugPrint('[MODERN_ADMIN_AGENCE] ✅ Agence récupérée directement: ${agenceData['nom']}');
      return agenceData;

    } catch (e) {
      debugPrint('[MODERN_ADMIN_AGENCE] ❌ Erreur récupération directe: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: _isLoading ? _buildLoadingScreen() : _buildMainContent(),
    );
  }

  /// 🔄 Écran de chargement moderne
  Widget _buildLoadingScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
            Color(0xFF6B73FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo animé
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.rotate(
                  angle: value * 2 * 3.14159,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.business_center,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
            const Text(
              'Chargement de votre espace',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Préparation du dashboard...',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 40),
            // Barre de progression moderne
            Container(
              width: 200,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 3),
                builder: (context, value, child) {
                  return Container(
                    width: 200 * value,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    if (_agenceData == null) {
      return _buildErrorScreen();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Header moderne
          _buildModernHeader(),
          
          // Contenu avec navigation
          Expanded(
            child: _buildContentWithNavigation(),
          ),
        ],
      ),
    );
  }

  /// 🎨 Header moderne
  Widget _buildModernHeader() {
    final compagnieInfo = _agenceData!['compagnieInfo'] as Map<String, dynamic>?;

    // Fallback : utiliser les données utilisateur si compagnieInfo est null
    final compagnieNom = compagnieInfo?['nom'] ??
                        widget.userData!['compagnieNom'] ??
                        'Non défini';

    debugPrint('[MODERN_ADMIN_AGENCE] 🏢 Affichage compagnie: $compagnieNom');
    debugPrint('[MODERN_ADMIN_AGENCE] 📋 CompagnieInfo: $compagnieInfo');
    debugPrint('[MODERN_ADMIN_AGENCE] 👤 UserData compagnieNom: ${widget.userData!['compagnieNom']}');

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ligne du haut avec salutation et actions
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour ${widget.userData!['prenom']} 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Admin Agence',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Actions
                  Row(
                    children: [
                      _buildHeaderAction(Icons.refresh_rounded, _loadAllData),
                      const SizedBox(width: 12),
                      _buildHeaderAction(Icons.notifications_outlined, () {}),
                      const SizedBox(width: 12),
                      _buildHeaderAction(Icons.settings_outlined, () {}),
                      const SizedBox(width: 12),
                      _buildHeaderAction(Icons.logout_rounded, _showLogoutDialog),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 16),

              // Informations de l'agence et compagnie
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      'Agence',
                      _agenceData!['nom'] ?? 'Non défini',
                      Icons.business_outlined,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildInfoCard(
                      'Compagnie',
                      compagnieNom,
                      Icons.corporate_fare_outlined,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎯 Action du header
  Widget _buildHeaderAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  /// 📋 Carte d'information
  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu avec navigation
  Widget _buildContentWithNavigation() {
    return Column(
      children: [
        // Navigation horizontale moderne
        _buildModernNavigation(),

        // Contenu de la page
        Expanded(
          child: _buildPageContent(),
        ),
      ],
    );
  }

  /// 🧭 Navigation moderne
  Widget _buildModernNavigation() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildNavItem(0, 'Accueil', Icons.dashboard_rounded),
          _buildNavItem(1, 'Mon Agence', Icons.business_rounded),
          _buildNavItem(2, 'Agents', Icons.people_rounded),
          _buildNavItem(3, 'Experts', Icons.engineering_rounded),
          _buildNavItem(4, 'Statistiques', Icons.analytics_rounded),
          _buildNavItem(5, 'Contrats', Icons.description_rounded),
        ],
      ),
    );
  }

  /// 🎯 Item de navigation
  Widget _buildNavItem(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF667EEA) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 18,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📄 Contenu de la page
  Widget _buildPageContent() {
    switch (_selectedIndex) {
      case 0:
        return _buildHomeContent();
      case 1:
        return AgenceInfoScreen(
          agenceData: _agenceData!,
          onAgenceUpdated: _loadAllData,
        );
      case 2:
        return AgentsManagementScreen(
          agenceData: _agenceData!,
          userData: widget.userData!,
          onAgentUpdated: _loadAllData, // Rafraîchir quand un agent est modifié
        );
      case 3:
        return ExpertsManagementScreen(
          agenceData: _agenceData!,
          userData: widget.userData!,
          onExpertUpdated: _loadAllData, // Rafraîchir quand un expert est modifié
        );
      case 4:
        return BIDashboardScreen(
          agenceId: _agenceData!['id'] ?? '',
          agenceData: _agenceData!,
        );
      case 5:
        return ContractManagementScreen(
          agenceId: _agenceData!['id'] ?? '',
          agenceData: _agenceData!,
        );
      case 6:
        return DemandesContratsScreen(
          agenceId: _agenceData!['id'] ?? '',
          agenceData: _agenceData!,
        );
      default:
        return _buildHomeContent();
    }
  }

  /// 🏠 Contenu de l'accueil
  Widget _buildHomeContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques principales
          _buildStatsGrid(),
          const SizedBox(height: 30),

          // Actions rapides
          _buildQuickActions(),
          const SizedBox(height: 30),

          // Alertes et notifications
          _buildAlertsSection(),
          const SizedBox(height: 30),

          // Véhicules en attente
          _buildPendingVehiclesSection(),
          const SizedBox(height: 30),

          // Informations détaillées
          _buildDetailedInfo(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// 📊 Grille de statistiques
  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            // Bouton de diagnostic
            if (_stats['totalAgents'] == 0 && _agents.isNotEmpty)
              TextButton.icon(
                onPressed: _forceRecalculateStats,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Recalculer', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Agents',
                '${_stats['totalAgents'] ?? 0}',
                Icons.people_rounded,
                const Color(0xFF10B981),
                'Agents dans votre agence',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                'Agents Actifs',
                '${_stats['activeAgents'] ?? 0}',
                Icons.person_rounded,
                const Color(0xFF3B82F6),
                'Agents en service',
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 📈 Carte de statistique compacte
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16), // Réduit de 24 à 16
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Réduit de 20 à 16
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12, // Réduit de 20 à 12
            offset: const Offset(0, 2), // Réduit de 4 à 2
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min, // Ajouté pour compacter
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8), // Réduit de 12 à 8
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
                ),
                child: Icon(icon, color: color, size: 20), // Réduit de 24 à 20
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24, // Réduit de 32 à 24
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12), // Réduit de 16 à 12
          Text(
            title,
            style: const TextStyle(
              fontSize: 15, // Réduit de 16 à 15
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 2), // Réduit de 4 à 2
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13, // Réduit de 14 à 13
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// ⚡ Actions rapides
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions Rapides',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Ajouter Agent',
                'Créer un nouveau compte agent',
                Icons.person_add_rounded,
                const Color(0xFF8B5CF6),
                () => setState(() => _selectedIndex = 2),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Modifier Agence',
                'Mettre à jour les informations',
                Icons.edit_rounded,
                const Color(0xFF06B6D4),
                () => setState(() => _selectedIndex = 1),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Statistiques',
                'Tableaux de bord et analytics',
                Icons.analytics_rounded,
                const Color(0xFF10B981),
                () => setState(() => _selectedIndex = 3),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                'Gérer Contrats',
                'Voir tous les contrats de l\'agence',
                Icons.description_rounded,
                const Color(0xFF3B82F6),
                () => setState(() => _selectedIndex = 4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                'Demandes Contrats',
                'Gérer les nouvelles demandes',
                Icons.request_page_rounded,
                const Color(0xFFEF4444),
                () => setState(() => _selectedIndex = 5),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(), // Espace vide pour équilibrer
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 Carte d'action compacte
  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16), // Réduit de 20 à 16
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14), // Réduit de 16 à 14
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 8, // Réduit de 10 à 8
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Ajouté pour compacter
          children: [
            Container(
              padding: const EdgeInsets.all(10), // Réduit de 12 à 10
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10), // Réduit de 12 à 10
              ),
              child: Icon(icon, color: color, size: 20), // Réduit de 24 à 20
            ),
            const SizedBox(height: 12), // Réduit de 16 à 12
            Text(
              title,
              style: const TextStyle(
                fontSize: 15, // Réduit de 16 à 15
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 3), // Réduit de 4 à 3
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13, // Réduit de 14 à 13
                color: Colors.grey.shade600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 🚨 Section des alertes
  Widget _buildAlertsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Alertes & Notifications',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        AlertsPanel(
          agenceId: _agenceData!['id'] ?? '',
          onAlertTap: () {
            // TODO: Naviguer vers l'écran détaillé des alertes
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Écran détaillé des alertes - À implémenter'),
                backgroundColor: Colors.blue,
              ),
            );
          },
        ),
      ],
    );
  }

  /// 📋 Informations détaillées
  Widget _buildDetailedInfo() {
    final compagnieInfo = _agenceData!['compagnieInfo'] as Map<String, dynamic>?;

    // Utiliser les données utilisateur comme fallback
    final compagnieNom = compagnieInfo?['nom'] ?? widget.userData!['compagnieNom'] ?? 'Non défini';
    final compagnieCode = compagnieInfo?['code'] ?? 'Non défini';
    final compagnieType = compagnieInfo?['type'] ?? 'Non défini';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations Détaillées',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
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
            children: [
              _buildDetailRow('Nom de l\'agence', _agenceData!['nom'] ?? 'Non défini'),
              _buildDetailRow('Code agence', _agenceData!['code'] ?? 'Non défini'),
              _buildDetailRow('Compagnie mère', compagnieNom),
              _buildDetailRow('Code compagnie', compagnieCode),
              _buildDetailRow('Type compagnie', compagnieType),
              _buildDetailRow('Adresse', _agenceData!['adresse'] ?? 'Non défini'),
              _buildDetailRow('Téléphone', _agenceData!['telephone'] ?? 'Non défini'),
              _buildDetailRow('Email', _agenceData!['email'] ?? 'Non défini', isLast: true),
            ],
          ),
        ),
      ],
    );
  }

  /// 📄 Ligne de détail
  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
          ],
        ),
        if (!isLast) ...[
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200, height: 1),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  /// ❌ Écran d'erreur moderne
  Widget _buildErrorScreen() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.white,
                size: 80,
              ),
              const SizedBox(height: 30),
              const Text(
                'Configuration Manquante',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                'Votre compte admin agence n\'est pas encore configuré.',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _repairConfiguration,
                icon: const Icon(Icons.build_rounded),
                label: const Text('Réparer Automatiquement'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🔧 Réparer la configuration
  Future<void> _repairConfiguration() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 20),
              Text('Réparation en cours...'),
            ],
          ),
        ),
      );

      final success = await AdminAgenceDiagnosticService.repairAdminAgence(widget.userData!['uid']);

      if (mounted) Navigator.pop(context);

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Configuration réparée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
        await _loadAllData();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Réparation impossible'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      debugPrint('[MODERN_ADMIN_AGENCE] ❌ Erreur réparation: $e');
    }
  }

  /// 🔄 Forcer le recalcul des statistiques
  void _forceRecalculateStats() {
    debugPrint('[MODERN_ADMIN_AGENCE] 🔄 Recalcul forcé des statistiques');
    debugPrint('[MODERN_ADMIN_AGENCE] 👥 Agents disponibles: ${_agents.length}');

    if (_agents.isNotEmpty) {
      final activeAgents = _agents.where((agent) => agent['isActive'] == true).length;
      setState(() {
        _stats = {
          'totalAgents': _agents.length,
          'activeAgents': activeAgents,
          'inactiveAgents': _agents.length - activeAgents,
          'recentActions': [],
        };
      });

      debugPrint('[MODERN_ADMIN_AGENCE] ✅ Stats recalculées: $_stats');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Statistiques recalculées: ${_agents.length} agents'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  /// 🚪 Dialogue de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Colors.red),
            SizedBox(width: 12),
            Text('Déconnexion'),
          ],
        ),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/user-type-selection',
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 🚗 Section des véhicules en attente
  Widget _buildPendingVehiclesSection() {
    final agenceId = _agenceData?['id'];
    if (agenceId == null) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicules')
          .where('etatCompte', isEqualTo: 'En attente')
          .where('agenceAssuranceId', isEqualTo: agenceId)
          .snapshots(), // Suppression de orderBy pour éviter l'erreur d'index
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print('❌ Erreur stream véhicules admin agence: ${snapshot.error}');
          return const SizedBox.shrink();
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Chargement des véhicules...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          );
        }

        final vehicules = snapshot.data?.docs ?? [];
        print('📊 Admin Agence: ${vehicules.length} véhicules en attente trouvés pour agence $agenceId');

        // Debug: afficher tous les véhicules trouvés
        for (var doc in vehicules) {
          final data = doc.data() as Map<String, dynamic>;
          print('🚗 [ADMIN_AGENCE] Véhicule trouvé: ${doc.id} - ${data['marque']} ${data['modele']} - agenceId: ${data['agenceAssuranceId']} - etat: ${data['etatCompte']}');
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.orange.shade600, Colors.orange.shade800],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.pending_actions,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Véhicules en Attente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        Text(
                          '${vehicules.length} véhicule${vehicules.length > 1 ? 's' : ''} à traiter',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton Historique toujours visible
                  IconButton(
                    onPressed: () => _showVehiclesHistory(),
                    icon: Icon(
                      Icons.history,
                      color: Colors.blue.shade600,
                      size: 24,
                    ),
                    tooltip: 'Voir l\'historique',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.blue.shade50,
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              if (vehicules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 64,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun véhicule en attente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tous les véhicules sont traités par vos agents',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () => _showVehiclesHistory(),
                          icon: const Icon(Icons.history, size: 20),
                          label: const Text('Voir l\'historique'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Afficher les véhicules en attente - Vue compacte
                ...vehicules.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildCompactVehicleCard(data, doc.id);
                }).toList(),

                if (vehicules.length > 3) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade600, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '+${vehicules.length - 3} autres véhicules',
                          style: TextStyle(
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Boutons d'action
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAllVehiclesManagement(vehicules),
                        icon: const Icon(Icons.manage_accounts, size: 20),
                        label: Text(
                          vehicules.length > 3
                              ? 'Gérer (${vehicules.length})'
                              : 'Gérer en attente',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showVehiclesHistory(),
                        icon: const Icon(Icons.history, size: 20),
                        label: const Text('Historique'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// 🚗 Construire une carte compacte pour un véhicule (dashboard)
  Widget _buildCompactVehicleCard(Map<String, dynamic> data, String vehicleId) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône du véhicule
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade700],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Informations principales
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nom du véhicule
                Text(
                  '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),

                const SizedBox(height: 4),

                // Immatriculation
                Text(
                  'Immat: ${data['numeroImmatriculation'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 4),

                // Propriétaire
                Text(
                  'Propriétaire: ${data['nomProprietaire'] ?? 'N/A'} ${data['prenomProprietaire'] ?? ''}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),

                if (createdAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Ajouté le ${_formatDate(createdAt)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Badge "NOUVEAU" et actions
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.shade600,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'NOUVEAU',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Bouton "Voir plus"
              GestureDetector(
                onTap: () {
                  // TODO: Ouvrir la vue détaillée
                  _showVehicleDetails(data, vehicleId);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Text(
                    'Voir plus',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 🚗 Construire une carte détaillée pour un véhicule (page de gestion)
  Widget _buildDetailedVehicleCard(Map<String, dynamic> data, String vehicleId) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.orange.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du véhicule
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade600, Colors.orange.shade700],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.directions_car,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Immatriculation: ${data['numeroImmatriculation'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'NOUVEAU',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu détaillé
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations du véhicule
                _buildSectionTitle('🚗 Informations du Véhicule'),
                const SizedBox(height: 12),
                _buildInfoGrid([
                  _buildInfoItem('Marque', data['marque']),
                  _buildInfoItem('Modèle', data['modele']),
                  _buildInfoItem('Année', data['annee']?.toString()),
                  _buildInfoItem('Couleur', data['couleur']),
                  _buildInfoItem('Carburant', data['carburant']),
                  _buildInfoItem('Genre', data['genre']),
                  _buildInfoItem('Usage', data['usage']),
                  _buildInfoItem('Nombre de places', data['nombrePlaces']?.toString()),
                ]),

                const SizedBox(height: 20),

                // Informations techniques
                _buildSectionTitle('⚙️ Caractéristiques Techniques'),
                const SizedBox(height: 12),
                _buildInfoGrid([
                  _buildInfoItem('Puissance fiscale', data['puissanceFiscale']?.toString()),
                  _buildInfoItem('Cylindrée', data['cylindree']?.toString()),
                  _buildInfoItem('Poids', data['poids']?.toString()),
                  _buildInfoItem('N° de série', data['numeroSerie']),
                  _buildInfoItem('N° carte grise', data['numeroCarteGrise']),
                  _buildInfoItem('Type véhicule', data['typeVehicule']),
                ]),

                const SizedBox(height: 20),

                // Informations du propriétaire
                _buildSectionTitle('👤 Propriétaire'),
                const SizedBox(height: 12),
                _buildInfoGrid([
                  _buildInfoItem('Nom', data['nomProprietaire']),
                  _buildInfoItem('Prénom', data['prenomProprietaire']),
                  _buildInfoItem('Adresse', data['adresseProprietaire']),
                ]),

                const SizedBox(height: 20),

                // Informations du permis
                _buildSectionTitle('🪪 Permis de Conduire'),
                const SizedBox(height: 12),
                _buildInfoGrid([
                  _buildInfoItem('N° permis', data['numeroPermis']),
                  _buildInfoItem('Catégorie', data['categoriePermis']),
                  _buildInfoItem('Date obtention', _formatDate(data['dateObtentionPermis'])),
                  _buildInfoItem('Date expiration', _formatDate(data['dateExpirationPermis'])),
                ]),

                const SizedBox(height: 20),

                // Informations d'assurance
                _buildSectionTitle('🛡️ Assurance'),
                const SizedBox(height: 12),
                _buildInfoGrid([
                  _buildInfoItem('Assuré', data['estAssure'] == true ? 'Oui' : 'Non'),
                  _buildInfoItem('N° contrat', data['numeroContratAssurance']),
                  _buildInfoItem('Type assurance', data['typeAssurance']),
                  _buildInfoItem('Compagnie', data['compagnieAssuranceNom']),
                  _buildInfoItem('Agence', data['agenceAssuranceNom']),
                  _buildInfoItem('Date début', _formatDate(data['dateDebutAssurance'])),
                  _buildInfoItem('Date fin', _formatDate(data['dateFinAssurance'])),
                ]),

                const SizedBox(height: 20),

                // Dates importantes
                _buildSectionTitle('📅 Dates Importantes'),
                const SizedBox(height: 12),
                _buildInfoGrid([
                  _buildInfoItem('Mise en circulation', _formatDate(data['dateMiseEnCirculation'])),
                  _buildInfoItem('1ère immatriculation', _formatDate(data['datePremiereImmatriculation'])),
                  _buildInfoItem('Prochain contrôle', _formatDate(data['dateProchainControle'])),
                  _buildInfoItem('Contrôle valide', data['controleValide'] == true ? 'Oui' : 'Non'),
                  _buildInfoItem('Ajouté le', createdAt != null ? _formatDate(createdAt) : 'N/A'),
                ]),

                const SizedBox(height: 24),

                // Images
                if (data['imageCarteGriseUrl'] != null || data['imagePermisUrl'] != null) ...[
                  _buildSectionTitle('📄 Documents'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (data['imageCarteGriseUrl'] != null)
                        Expanded(
                          child: _buildImagePreview(
                            'Carte Grise',
                            data['imageCarteGriseUrl'],
                            Icons.description,
                          ),
                        ),
                      if (data['imageCarteGriseUrl'] != null && data['imagePermisUrl'] != null)
                        const SizedBox(width: 12),
                      if (data['imagePermisUrl'] != null)
                        Expanded(
                          child: _buildImagePreview(
                            'Permis',
                            data['imagePermisUrl'],
                            Icons.credit_card,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // Boutons d'action
                Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _approveVehicle(vehicleId, data);
                            },
                            icon: const Icon(Icons.check_circle, size: 20),
                            label: const Text('Approuver & Affecter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              _rejectVehicle(vehicleId, data);
                            },
                            icon: const Icon(Icons.cancel, size: 20),
                            label: const Text('Rejeter'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _assignToAgent(vehicleId, data);
                        },
                        icon: const Icon(Icons.assignment_ind, size: 20),
                        label: const Text('Réaffecter'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return 'N/A';
    }

    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  /// 📋 Construire un titre de section
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1F2937),
      ),
    );
  }

  /// 📊 Construire une grille d'informations
  Widget _buildInfoGrid(List<Widget> items) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: items,
    );
  }

  /// 📜 Construire une carte pour l'historique des véhicules
  Widget _buildHistoryVehicleCard(Map<String, dynamic> data, String vehicleId) {
    final etat = data['etatCompte'] as String;
    final isApproved = etat == 'Actif';
    final isRejected = etat == 'Rejeté';

    final approvedAt = data['approvedAt'] as Timestamp?;
    final rejectedAt = data['rejectedAt'] as Timestamp?;
    final actionDate = isApproved ? approvedAt?.toDate() : rejectedAt?.toDate();

    final actionBy = isApproved
        ? data['approvedByEmail'] as String?
        : data['rejectedByEmail'] as String?;

    final rejectionReason = data['rejectionReason'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved ? Colors.green.shade200 : Colors.red.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isApproved
                    ? [Colors.green.shade600, Colors.green.shade700]
                    : [Colors.red.shade600, Colors.red.shade700],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isApproved ? Icons.check_circle : Icons.cancel,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Immat: ${data['numeroImmatriculation'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isApproved ? 'APPROUVÉ' : 'REJETÉ',
                    style: TextStyle(
                      color: isApproved ? Colors.green.shade700 : Colors.red.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informations de base
                Row(
                  children: [
                    Expanded(
                      child: _buildHistoryInfoItem(
                        'Propriétaire',
                        '${data['nomProprietaire'] ?? 'N/A'} ${data['prenomProprietaire'] ?? ''}',
                        Icons.person,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildHistoryInfoItem(
                        'Année',
                        data['annee']?.toString() ?? 'N/A',
                        Icons.calendar_today,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Informations d'action
                _buildHistoryInfoItem(
                  isApproved ? 'Approuvé par' : 'Rejeté par',
                  actionBy ?? 'N/A',
                  Icons.person_outline,
                ),

                const SizedBox(height: 8),

                _buildHistoryInfoItem(
                  isApproved ? 'Date d\'approbation' : 'Date de rejet',
                  actionDate != null ? _formatDate(actionDate) : 'N/A',
                  Icons.access_time,
                ),

                // Raison du rejet si applicable
                if (isRejected && rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.red.shade600, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Raison du rejet',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          rejectionReason,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Bouton voir détails
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showVehicleDetails(data, vehicleId),
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('Voir les détails'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Construire un élément d'information pour l'historique
  Widget _buildHistoryInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📝 Construire un élément d'information
  Widget _buildInfoItem(String label, String? value) {
    return Container(
      width: (MediaQuery.of(context).size.width - 80) / 2, // 2 colonnes
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
        ],
      ),
    );
  }

  /// 🖼️ Construire un aperçu d'image
  Widget _buildImagePreview(String title, String? imageUrl, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: Colors.blue.shade600,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            imageUrl != null ? 'Disponible' : 'Non fourni',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          if (imageUrl != null) ...[
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                // TODO: Ouvrir l'image en plein écran
                _showImageDialog(imageUrl, title);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Voir',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// ✅ Approuver et affecter un véhicule automatiquement
  Future<void> _approveVehicle(String vehicleId, [Map<String, dynamic>? data]) async {
    try {
      // D'abord, charger les agents et leur charge de travail
      final agents = await _loadAgentsWithWorkload();

      if (agents.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Aucun agent disponible dans cette agence'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Trouver l'agent avec la charge de travail la plus faible
      final bestAgent = _findBestAgent(agents);

      // Afficher dialog de confirmation avec agent recommandé
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(child: Text('Approuver et Affecter')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data != null) ...[
                Text('Véhicule: ${data['marque']} ${data['modele']}'),
                Text('Propriétaire: ${data['prenomProprietaire']} ${data['nomProprietaire']}'),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Agent recommandé (charge minimale):',
                            style: TextStyle(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('👤 ${bestAgent['prenom']} ${bestAgent['nom']}'),
                    Text('📊 Charge actuelle: ${bestAgent['workload']} dossiers'),
                    Text('📧 ${bestAgent['email']}'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Le véhicule sera approuvé et automatiquement affecté à cet agent.',
                style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Approuver et Affecter', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Afficher loading
      _showLoadingDialog('Approbation et affectation en cours...');

      // 1. Approuver le véhicule ET l'affecter en une seule transaction
      await FirebaseFirestore.instance
          .collection('vehicules')
          .doc(vehicleId)
          .update({
        'etatCompte': 'Affecté à Agent',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': widget.userData?['uid'] ?? 'unknown',
        'approvedByEmail': widget.userData?['email'] ?? 'unknown',
        'approvedByRole': 'admin_agence',
        'agentAffecteId': bestAgent['id'],
        'agentAffecteNom': '${bestAgent['prenom']} ${bestAgent['nom']}',
        'agentAffecteEmail': bestAgent['email'],
        'dateAffectation': FieldValue.serverTimestamp(),
        'affectePar': widget.userData?['uid'] ?? 'unknown',
        'affecteParNom': widget.userData?['email'] ?? 'unknown',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Mettre à jour les statistiques de l'agent
      await _updateAgentWorkload(bestAgent['id'], 1);

      // Fermer loading
      Navigator.pop(context);

      // Afficher succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('✅ Véhicule approuvé et affecté à ${bestAgent['prenom']} ${bestAgent['nom']}'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          duration: Duration(seconds: 4),
        ),
      );

      print('✅ [MODERN_APPROVE] Véhicule $vehicleId approuvé et affecté à ${bestAgent['email']} par ${widget.userData?['email'] ?? 'unknown'}');

    } catch (e) {
      // Fermer loading si ouvert
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Afficher erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur lors de l\'approbation: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: Duration(seconds: 5),
        ),
      );

      print('❌ [APPROVE] Erreur: $e');
    }
  }

  /// ❌ Rejeter un véhicule
  Future<void> _rejectVehicle(String vehicleId, [Map<String, dynamic>? data]) async {
    try {
      // Demander la raison du rejet
      final reason = await _showRejectReasonDialog();
      if (reason == null || reason.trim().isEmpty) return;

      // Afficher dialog de confirmation
      final confirmed = await _showConfirmationDialog(
        title: 'Rejeter le véhicule',
        message: 'Êtes-vous sûr de vouloir rejeter ce véhicule ?\n\nRaison: $reason',
        confirmText: 'Rejeter',
        confirmColor: Colors.red,
        icon: Icons.cancel,
      );

      if (!confirmed) return;

      // Afficher loading
      _showLoadingDialog('Rejet en cours...');

      // Mettre à jour le statut dans Firestore
      await FirebaseFirestore.instance
          .collection('vehicules')
          .doc(vehicleId)
          .update({
        'etatCompte': 'Rejeté',
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': widget.userData?['uid'] ?? 'unknown',
        'rejectedByEmail': widget.userData?['email'] ?? 'unknown',
        'rejectedByRole': 'admin_agence',
        'rejectionReason': reason.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Fermer loading
      Navigator.pop(context);

      // Afficher succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.cancel, color: Colors.white),
              SizedBox(width: 8),
              Text('Véhicule rejeté'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: Duration(seconds: 3),
        ),
      );

      print('❌ [REJECT] Véhicule $vehicleId rejeté par ${widget.userData?['email'] ?? 'unknown'} - Raison: $reason');

    } catch (e) {
      // Fermer loading si ouvert
      if (Navigator.canPop(context)) Navigator.pop(context);

      // Afficher erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Erreur lors du rejet: $e'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: Duration(seconds: 5),
        ),
      );

      print('❌ [REJECT] Erreur: $e');
    }
  }

  /// 📜 Afficher l'historique des véhicules traités
  void _showVehiclesHistory() {
    final agenceId = widget.userData?['agenceId'] as String?;
    if (agenceId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Historique des Véhicules'),
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('vehicules')
                  .where('agenceAssuranceId', isEqualTo: agenceId)
                  .where('etatCompte', whereIn: ['Actif', 'Rejeté'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 64, color: Colors.red),
                        SizedBox(height: 16),
                        Text('Erreur: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.blue.shade600),
                        SizedBox(height: 16),
                        Text('Chargement de l\'historique...'),
                      ],
                    ),
                  );
                }

                final vehicules = snapshot.data?.docs ?? [];

                if (vehicules.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Aucun véhicule traité',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Les véhicules approuvés ou rejetés apparaîtront ici',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: vehicules.length,
                  itemBuilder: (context, index) {
                    final doc = vehicules[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildHistoryVehicleCard(data, doc.id);
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 🚗 Afficher la page de gestion de tous les véhicules
  void _showAllVehiclesManagement(List<QueryDocumentSnapshot> vehicules) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text('Gestion des Véhicules en Attente'),
            backgroundColor: Colors.orange.shade600,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange.shade50,
                  Colors.white,
                ],
              ),
            ),
            child: vehicules.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green),
                        SizedBox(height: 16),
                        Text(
                          'Aucun véhicule en attente',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tous les véhicules ont été traités',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehicules.length,
                    itemBuilder: (context, index) {
                      final doc = vehicules[index];
                      final data = doc.data() as Map<String, dynamic>;
                      return _buildDetailedVehicleCard(data, doc.id);
                    },
                  ),
          ),
        ),
      ),
    );
  }

  /// 📋 Afficher les détails complets d'un véhicule
  void _showVehicleDetails(Map<String, dynamic> data, String vehicleId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          width: double.maxFinite,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade700],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Contenu détaillé
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: _buildDetailedVehicleContent(data, vehicleId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Construire le contenu détaillé d'un véhicule
  Widget _buildDetailedVehicleContent(Map<String, dynamic> data, String vehicleId) {
    final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Informations du véhicule
        _buildSectionTitle('🚗 Informations du Véhicule'),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem('Marque', data['marque']),
          _buildInfoItem('Modèle', data['modele']),
          _buildInfoItem('Année', data['annee']?.toString()),
          _buildInfoItem('Couleur', data['couleur']),
          _buildInfoItem('Carburant', data['carburant']),
          _buildInfoItem('Genre', data['genre']),
          _buildInfoItem('Usage', data['usage']),
          _buildInfoItem('Nombre de places', data['nombrePlaces']?.toString()),
        ]),

        const SizedBox(height: 20),

        // Informations techniques
        _buildSectionTitle('⚙️ Caractéristiques Techniques'),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem('Puissance fiscale', data['puissanceFiscale']?.toString()),
          _buildInfoItem('Cylindrée', data['cylindree']?.toString()),
          _buildInfoItem('Poids', data['poids']?.toString()),
          _buildInfoItem('N° de série', data['numeroSerie']),
          _buildInfoItem('N° carte grise', data['numeroCarteGrise']),
          _buildInfoItem('Type véhicule', data['typeVehicule']),
        ]),

        const SizedBox(height: 20),

        // Informations du propriétaire
        _buildSectionTitle('👤 Propriétaire'),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem('Nom', data['nomProprietaire']),
          _buildInfoItem('Prénom', data['prenomProprietaire']),
          _buildInfoItem('Adresse', data['adresseProprietaire']),
        ]),

        const SizedBox(height: 20),

        // Informations du permis
        _buildSectionTitle('🪪 Permis de Conduire'),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem('N° permis', data['numeroPermis']),
          _buildInfoItem('Catégorie', data['categoriePermis']),
          _buildInfoItem('Date obtention', _formatDate(data['dateObtentionPermis'])),
          _buildInfoItem('Date expiration', _formatDate(data['dateExpirationPermis'])),
        ]),

        const SizedBox(height: 20),

        // Informations d'assurance
        _buildSectionTitle('🛡️ Assurance'),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem('Assuré', data['estAssure'] == true ? 'Oui' : 'Non'),
          _buildInfoItem('N° contrat', data['numeroContratAssurance']),
          _buildInfoItem('Type assurance', data['typeAssurance']),
          _buildInfoItem('Compagnie', data['compagnieAssuranceNom']),
          _buildInfoItem('Agence', data['agenceAssuranceNom']),
          _buildInfoItem('Date début', _formatDate(data['dateDebutAssurance'])),
          _buildInfoItem('Date fin', _formatDate(data['dateFinAssurance'])),
        ]),

        const SizedBox(height: 20),

        // Dates importantes
        _buildSectionTitle('📅 Dates Importantes'),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem('Mise en circulation', _formatDate(data['dateMiseEnCirculation'])),
          _buildInfoItem('1ère immatriculation', _formatDate(data['datePremiereImmatriculation'])),
          _buildInfoItem('Prochain contrôle', _formatDate(data['dateProchainControle'])),
          _buildInfoItem('Contrôle valide', data['controleValide'] == true ? 'Oui' : 'Non'),
          _buildInfoItem('Ajouté le', createdAt != null ? _formatDate(createdAt) : 'N/A'),
        ]),

        const SizedBox(height: 24),

        // Images
        if (data['imageCarteGriseUrl'] != null || data['imagePermisUrl'] != null) ...[
          _buildSectionTitle('📄 Documents'),
          const SizedBox(height: 12),
          Row(
            children: [
              if (data['imageCarteGriseUrl'] != null)
                Expanded(
                  child: _buildImagePreview(
                    'Carte Grise',
                    data['imageCarteGriseUrl'],
                    Icons.description,
                  ),
                ),
              if (data['imageCarteGriseUrl'] != null && data['imagePermisUrl'] != null)
                const SizedBox(width: 12),
              if (data['imagePermisUrl'] != null)
                Expanded(
                  child: _buildImagePreview(
                    'Permis',
                    data['imagePermisUrl'],
                    Icons.credit_card,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
        ],

        // Boutons d'action
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _approveVehicle(vehicleId);
                },
                icon: const Icon(Icons.check_circle, size: 20),
                label: const Text('Approuver & Affecter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _rejectVehicle(vehicleId);
                },
                icon: const Icon(Icons.cancel, size: 20),
                label: const Text('Rejeter'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// ⚠️ Afficher dialog de confirmation
  Future<bool> _showConfirmationDialog({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required IconData icon,
  }) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(icon, color: confirmColor, size: 28),
            SizedBox(width: 12),
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(message, style: TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: confirmColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    ) ?? false;
  }

  /// 📝 Afficher dialog pour saisir la raison du rejet
  Future<String?> _showRejectReasonDialog() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.edit_note, color: Colors.orange.shade600, size: 28),
            SizedBox(width: 12),
            Text('Raison du rejet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Veuillez indiquer la raison du rejet de ce véhicule :',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Ex: Documents manquants, informations incorrectes...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.orange.shade600, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () {
              final reason = controller.text.trim();
              if (reason.isNotEmpty) {
                Navigator.pop(context, reason);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Veuillez saisir une raison'),
                    backgroundColor: Colors.orange.shade600,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Confirmer'),
          ),
        ],
      ),
    );
  }

  /// ⏳ Afficher dialog de loading
  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange.shade600),
            SizedBox(height: 16),
            Text(message, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  /// 🖼️ Afficher une image en plein écran
  void _showImageDialog(String imageUrl, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title),
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  padding: const EdgeInsets.all(20),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red),
                      SizedBox(height: 16),
                      Text('Erreur de chargement de l\'image'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 👤 Affecter un véhicule à un agent
  Future<void> _assignToAgent(String vehicleId, Map<String, dynamic> data) async {
    try {
      // Charger la liste des agents de l'agence
      final agents = await _loadAgenceAgents();

      if (agents.isEmpty) {
        if (mounted) {
          _showInfoDialog(
            title: 'Aucun agent disponible',
            message: 'Aucun agent n\'est disponible dans cette agence pour traiter ce dossier.',
            icon: Icons.info_outline,
            color: Colors.orange,
          );
        }
        return;
      }

      String? selectedAgentId;

      final shouldAssign = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.assignment_ind, color: Colors.blue.shade600),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Réaffecter à un autre agent',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                Text('Sélectionnez un agent pour traiter ce dossier :'),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.directions_car, color: Colors.blue.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${data['marque']} ${data['modele']}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Propriétaire: ${data['prenomProprietaire']} ${data['nomProprietaire']}'),
                      Text('Immatriculation: ${data['numeroImmatriculation']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: selectedAgentId,
                  decoration: const InputDecoration(
                    labelText: 'Agent responsable *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  items: agents.map((agent) {
                    return DropdownMenuItem<String>(
                      value: agent['id'],
                      child: Text(
                        '${agent['prenom']} ${agent['nom']}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (mounted) setState(() {
                      selectedAgentId = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Boutons d'action
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: selectedAgentId != null
                          ? () => Navigator.of(context).pop(true)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Affecter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

      if (shouldAssign == true && selectedAgentId != null) {
        final selectedAgent = agents.firstWhere((agent) => agent['id'] == selectedAgentId);

        await FirebaseFirestore.instance
            .collection('vehicules')
            .doc(vehicleId)
            .update({
          'etatCompte': 'Affecté à Agent',
          'agentAffecteId': selectedAgentId,
          'agentAffecteNom': '${selectedAgent['prenom']} ${selectedAgent['nom']}',
          'agentAffecteEmail': selectedAgent['email'],
          'dateAffectation': FieldValue.serverTimestamp(),
          'affectePar': _agenceData!['id'],
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Véhicule affecté à ${selectedAgent['prenom']} ${selectedAgent['nom']}'),
              backgroundColor: Colors.blue.shade600,
              action: SnackBarAction(
                label: 'Voir',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Naviguer vers les véhicules affectés
                },
              ),
            ),
          );

          // Fermer la page de gestion si elle est ouverte
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      print('❌ [ASSIGN] Erreur: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'affectation: $e'),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  /// 👥 Charger la liste des agents de l'agence
  Future<List<Map<String, dynamic>>> _loadAgenceAgents() async {
    try {
      final agenceId = _agenceData!['id'];
      print('🔍 [DEBUG] Recherche agents pour agence: $agenceId');

      // D'abord, cherchons tous les agents avec le role 'agent'
      final allAgentsQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .get();

      print('🔍 [DEBUG] Total agents trouvés avec role "agent": ${allAgentsQuery.docs.length}');

      // Affichons tous les agents pour debug
      for (final doc in allAgentsQuery.docs) {
        final data = doc.data();
        print('🔍 [DEBUG] Agent trouvé: ${doc.id} - ${data['prenom']} ${data['nom']} - agenceId: ${data['agenceId']} - statut: ${data['statut']} - isActive: ${data['isActive']}');
      }

      // Maintenant filtrons par agenceId
      final agentsForAgence = allAgentsQuery.docs.where((doc) {
        final data = doc.data();
        return data['agenceId'] == agenceId;
      }).toList();

      print('🔍 [DEBUG] Agents pour cette agence ($agenceId): ${agentsForAgence.length}');

      // Filtrons par statut actif (essayons plusieurs variantes)
      final activeAgents = agentsForAgence.where((doc) {
        final data = doc.data();
        final statut = data['statut'];
        final isActive = data['isActive'];

        // Accepter plusieurs variantes de statut actif
        final isStatusActive = statut == 'actif' ||
                              statut == 'Actif' ||
                              statut == 'active' ||
                              statut == 'Active' ||
                              isActive == true;

        print('🔍 [DEBUG] Agent ${data['prenom']} ${data['nom']}: statut="$statut", isActive=$isActive, considéré actif: $isStatusActive');

        return isStatusActive;
      }).toList();

      print('🔍 [DEBUG] Agents actifs: ${activeAgents.length}');

      final agents = <Map<String, dynamic>>[];

      for (final doc in activeAgents) {
        final agentData = doc.data();
        agentData['id'] = doc.id;
        agents.add(agentData);
        print('✅ [DEBUG] Agent ajouté: ${agentData['prenom']} ${agentData['nom']} (${agentData['email']})');
      }

      print('🎯 [DEBUG] Total agents disponibles pour affectation: ${agents.length}');

      // Si aucun agent trouvé avec les critères stricts, essayons une approche plus permissive
      if (agents.isEmpty) {
        print('⚠️ [DEBUG] Aucun agent trouvé avec critères stricts, essai approche permissive...');
        return await _loadAgenceAgentsPermissive();
      }

      return agents;
    } catch (e) {
      print('❌ Erreur chargement agents: $e');
      // En cas d'erreur, essayons l'approche permissive
      return await _loadAgenceAgentsPermissive();
    }
  }

  /// 👥 Charger les agents avec critères permissifs (fallback)
  Future<List<Map<String, dynamic>>> _loadAgenceAgentsPermissive() async {
    try {
      final agenceId = _agenceData!['id'];
      print('🔄 [DEBUG] Chargement permissif pour agence: $agenceId');

      // Charger tous les utilisateurs et filtrer côté client
      final allUsersQuery = await FirebaseFirestore.instance
          .collection('users')
          .get();

      print('🔍 [DEBUG] Total utilisateurs dans la base: ${allUsersQuery.docs.length}');

      final agents = <Map<String, dynamic>>[];

      for (final doc in allUsersQuery.docs) {
        final data = doc.data();
        final role = data['role'];
        final userAgenceId = data['agenceId'];

        // Filtrer les agents de cette agence (peu importe le statut)
        if ((role == 'agent' || role == 'Agent') && userAgenceId == agenceId) {
          data['id'] = doc.id;
          agents.add(data);
          print('✅ [DEBUG] Agent permissif ajouté: ${data['prenom']} ${data['nom']} - statut: ${data['statut']} - isActive: ${data['isActive']}');
        }
      }

      print('🎯 [DEBUG] Total agents permissifs trouvés: ${agents.length}');
      return agents;
    } catch (e) {
      print('❌ Erreur chargement agents permissif: $e');
      return [];
    }
  }

  /// 💬 Afficher un dialog d'information
  void _showInfoDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Compris'),
          ),
        ],
      ),
    );
  }

  /// 📊 Charger les agents avec leur charge de travail
  Future<List<Map<String, dynamic>>> _loadAgentsWithWorkload() async {
    try {
      // Récupérer tous les agents actifs de l'agence
      final agentsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: widget.userData?['agenceId'])
          .where('status', isEqualTo: 'actif')
          .get();

      List<Map<String, dynamic>> agentsWithWorkload = [];

      for (final agentDoc in agentsSnapshot.docs) {
        final agentData = agentDoc.data();

        // Compter les véhicules affectés mais non traités
        final vehiculesAffectesSnapshot = await FirebaseFirestore.instance
            .collection('vehicules')
            .where('agentAffecteId', isEqualTo: agentDoc.id)
            .where('etatCompte', isEqualTo: 'Affecté à Agent')
            .get();

        // Compter les contrats actifs gérés par l'agent
        final contratsActifsSnapshot = await FirebaseFirestore.instance
            .collection('contrats')
            .where('agentId', isEqualTo: agentDoc.id)
            .where('statutContrat', isEqualTo: 'Actif')
            .get();

        // Calculer la charge totale
        final workload = vehiculesAffectesSnapshot.docs.length + contratsActifsSnapshot.docs.length;

        agentsWithWorkload.add({
          'id': agentDoc.id,
          'nom': agentData['nom'],
          'prenom': agentData['prenom'],
          'email': agentData['email'],
          'workload': workload,
          'vehiculesAffectes': vehiculesAffectesSnapshot.docs.length,
          'contratsActifs': contratsActifsSnapshot.docs.length,
        });
      }

      // Trier par charge de travail croissante
      agentsWithWorkload.sort((a, b) => a['workload'].compareTo(b['workload']));

      print('🔍 [MODERN_WORKLOAD] Agents avec charge de travail:');
      for (final agent in agentsWithWorkload) {
        print('🔍 [MODERN_WORKLOAD] ${agent['prenom']} ${agent['nom']}: ${agent['workload']} dossiers (${agent['vehiculesAffectes']} véhicules + ${agent['contratsActifs']} contrats)');
      }

      return agentsWithWorkload;
    } catch (e) {
      print('❌ [MODERN_WORKLOAD] Erreur chargement agents: $e');
      return [];
    }
  }

  /// 🎯 Trouver le meilleur agent (charge minimale)
  Map<String, dynamic> _findBestAgent(List<Map<String, dynamic>> agents) {
    // L'agent avec la charge la plus faible est déjà en premier (trié)
    final bestAgent = agents.first;

    print('🎯 [MODERN_BEST_AGENT] Agent sélectionné: ${bestAgent['prenom']} ${bestAgent['nom']} (${bestAgent['workload']} dossiers)');

    return bestAgent;
  }

  /// 📈 Mettre à jour la charge de travail d'un agent
  Future<void> _updateAgentWorkload(String agentId, int increment) async {
    try {
      final agentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(agentId)
          .get();

      if (agentDoc.exists) {
        final currentWorkload = agentDoc.data()?['workload'] ?? 0;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(agentId)
            .update({
          'workload': currentWorkload + increment,
          'lastAssignedAt': FieldValue.serverTimestamp(),
        });

        print('📈 [MODERN_WORKLOAD] Agent $agentId: workload mis à jour (+$increment)');
      }
    } catch (e) {
      print('❌ [MODERN_WORKLOAD] Erreur mise à jour workload: $e');
    }
  }
}
