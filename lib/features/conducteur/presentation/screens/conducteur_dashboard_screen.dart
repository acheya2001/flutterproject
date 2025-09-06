import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/conducteur_workaround_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../conducteur/screens/accident_declaration_screen.dart';
import '../../../sinistre/screens/sinistre_choix_rapide_screen.dart';

/// 🚗 Dashboard moderne du conducteur
class ConducteurDashboardScreen extends StatefulWidget {
  const ConducteurDashboardScreen({Key? key}) : super(key: key);

  @override
  State<ConducteurDashboardScreen> createState() => _ConducteurDashboardScreenState();
}

class _ConducteurDashboardScreenState extends State<ConducteurDashboardScreen> {
  Map<String, dynamic>? _userData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Timeout de sécurité pour forcer l'affichage
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isLoading) {
        print('[CONDUCTEUR_DASHBOARD] ⏰ Timeout - forçage affichage');
        setState(() {
          _isLoading = false;
          _userData ??= {
            'uid': 'default',
            'email': 'conducteur@test.com',
            'nom': 'Conducteur',
            'prenom': 'Test',
            'telephone': '+216 98 123 456',
            'cin': '12345678',
            'adresse': 'Tunis, Tunisie',
            'userType': 'conducteur',
            'createdAt': DateTime.now().toIso8601String(),
          };
        });
      }
    });
  }

  /// 📊 Charger les données utilisateur (avec contournement)
  Future<void> _loadUserData() async {
    try {
      print('[CONDUCTEUR_DASHBOARD] 🔄 Chargement données utilisateur...');

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        print('[CONDUCTEUR_DASHBOARD] 👤 Utilisateur Firebase: ${user.uid}');

        // Essayer d'abord les données locales
        final prefs = await SharedPreferences.getInstance();
        final dataString = prefs.getString('conducteur_${user.uid}');

        if (dataString != null) {
          print('[CONDUCTEUR_DASHBOARD] ✅ Données locales trouvées');
          final userData = json.decode(dataString) as Map<String, dynamic>;
          setState(() {
            _userData = userData;
            _isLoading = false;
          });
          return;
        }

        print('[CONDUCTEUR_DASHBOARD] ⚠️ Pas de données locales, création profil basique...');

        // Créer un profil basique
        final basicUserData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'nom': 'Conducteur',
          'prenom': user.displayName ?? 'Test',
          'telephone': '+216 98 123 456',
          'cin': '12345678',
          'adresse': 'Tunis, Tunisie',
          'userType': 'conducteur',
          'createdAt': DateTime.now().toIso8601String(),
        };

        print('[CONDUCTEUR_DASHBOARD] ✅ Profil basique créé: ${basicUserData['prenom']} ${basicUserData['nom']}');

        setState(() {
          _userData = basicUserData;
          _isLoading = false;
        });

        // Sauvegarder le profil basique
        await prefs.setString('conducteur_${user.uid}', json.encode(basicUserData));

      } else {
        print('[CONDUCTEUR_DASHBOARD] ❌ Aucun utilisateur Firebase');

        // Essayer de trouver des données locales sans UID
        final prefs = await SharedPreferences.getInstance();
        final keys = prefs.getKeys().where((key) => key.startsWith('conducteur_'));

        if (keys.isNotEmpty) {
          final dataString = prefs.getString(keys.first);
          if (dataString != null) {
            print('[CONDUCTEUR_DASHBOARD] ✅ Données locales trouvées sans Firebase Auth');
            final userData = json.decode(dataString) as Map<String, dynamic>;
            setState(() {
              _userData = userData;
              _isLoading = false;
            });
            return;
          }
        }

        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('[CONDUCTEUR_DASHBOARD] ❌ Erreur chargement données: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2563EB),
              Color(0xFF1E40AF),
              Color(0xFF1E3A8A),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : Column(
                  children: [
                    // En-tête avec profil
                    _buildHeader(),

                    // Contenu principal
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(30),
                            topRight: Radius.circular(30),
                          ),
                        ),
                        child: _buildMainContent(),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  /// 📱 En-tête avec informations utilisateur
  Widget _buildHeader() {
    final prenom = _userData?['prenom'] ?? 'Conducteur';
    final nom = _userData?['nom'] ?? '';
    final email = _userData?['email'] ?? '';

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Barre de navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Espace Conducteur',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  _showLogoutDialog();
                },
                icon: const Icon(
                  Icons.logout,
                  color: Colors.white,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Profil utilisateur
          Row(
            children: [
              // Avatar
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(35),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    '${prenom[0]}${nom.isNotEmpty ? nom[0] : ''}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Informations
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bienvenue,',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$prenom $nom',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📋 Contenu principal du dashboard
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statistiques rapides
          _buildQuickStats(),

          const SizedBox(height: 24),

          // Actions principales
          const Text(
            'Actions Principales',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildMainActions(),

          const SizedBox(height: 24),

          // Section Constat Collaboratif
          const Text(
            'Constat Collaboratif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildCollaborativeActions(),

          const SizedBox(height: 24),

          // Mes véhicules
          const Text(
            'Mes Véhicules',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildVehicleSection(),

          const SizedBox(height: 24),

          const SizedBox(height: 24),

          // Historique récent
          const Text(
            'Activité Récente',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  /// 📊 Statistiques rapides
  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.directions_car,
            title: 'Véhicules',
            value: '2',
            color: const Color(0xFF059669),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.assignment,
            title: 'Constats',
            value: '0',
            color: const Color(0xFF2563EB),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.pending_actions,
            title: 'En cours',
            value: '0',
            color: const Color(0xFFF59E0B),
          ),
        ),
      ],
    );
  }

  /// 📈 Carte de statistique
  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎯 Actions principales
  Widget _buildMainActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.add_circle_outline,
                title: 'Déclarer un Accident',
                subtitle: 'Créer un nouveau constat',
                color: const Color(0xFFDC2626),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SinistreChoixRapideScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.directions_car_outlined,
                title: 'Ajouter un Véhicule',
                subtitle: 'Enregistrer un nouveau véhicule',
                color: const Color(0xFF059669),
                onTap: () {
                  Navigator.pushNamed(context, '/conducteur/add-vehicle');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                title: 'Mes Constats',
                subtitle: 'Consulter l\'historique',
                color: const Color(0xFF2563EB),
                onTap: () {
                  Navigator.pushNamed(context, '/conducteur/accidents');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.support_agent,
                title: 'Assistance',
                subtitle: 'Contacter le support',
                color: const Color(0xFFF59E0B),
                onTap: () {
                  // TODO: Navigation vers assistance
                  _showComingSoon('Assistance');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🤝 Actions collaboratives
  Widget _buildCollaborativeActions() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.group_add,
                title: 'Créer Session',
                subtitle: 'Inviter d\'autres conducteurs',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pushNamed(context, '/professional/session');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.login,
                title: 'Rejoindre Session',
                subtitle: 'Entrer un code de session',
                color: const Color(0xFF06B6D4),
                onTap: () {
                  Navigator.pushNamed(context, '/join/session');
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.email,
                title: 'Mes Invitations',
                subtitle: 'Sessions reçues par email',
                color: const Color(0xFFEC4899),
                onTap: () {
                  Navigator.pushNamed(context, '/conducteur/invitations');
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.description,
                title: 'Constat Officiel',
                subtitle: 'Formulaire conforme',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.pushNamed(context, '/constat/demo');
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 🎯 Carte d'action
  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🚗 Section véhicules
  Widget _buildVehicleSection() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.directions_car,
                color: const Color(0xFF059669),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aucun véhicule enregistré',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/conducteur/add-vehicle');
              },
              icon: const Icon(Icons.add),
              label: const Text('Ajouter mon premier véhicule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📋 Activité récente
  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Row(
            children: [
              Icon(
                Icons.history,
                color: const Color(0xFF2563EB),
                size: 24,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Aucune activité récente',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Vos dernières actions apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚪 Dialogue de déconnexion
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/user-type-selection',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnecter'),
          ),

        ],
      ),
    );
  }



  /// 🔜 Message "Bientôt disponible"
  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Bientôt disponible !'),
        backgroundColor: const Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
