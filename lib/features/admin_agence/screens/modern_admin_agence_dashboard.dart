import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/admin_agence_service.dart';
import '../../../services/admin_agence_diagnostic_service.dart';
import 'agence_info_screen.dart';
import 'agents_management_screen.dart';

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

class _ModernAdminAgenceDashboardState extends State<ModernAdminAgenceDashboard>
    with TickerProviderStateMixin {
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _loadAllData();
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
}