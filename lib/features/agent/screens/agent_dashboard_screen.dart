import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../services/contract_service.dart';
import '../../../services/contract_number_service.dart';
import '../../../services/notification_service.dart';
import '../../../services/agent_notification_service.dart';
import '../widgets/agent_notification_widget.dart';
import 'pending_contracts_screen.dart';
import 'pending_vehicles_screen.dart';
import 'pending_vehicles_management_screen.dart';

/// 🏠 Dashboard principal de l'agent
class AgentDashboardScreen extends StatefulWidget {
  const AgentDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AgentDashboardScreen> createState() => _AgentDashboardScreenState();
}

class _AgentDashboardScreenState extends State<AgentDashboardScreen> {
  String? _agentId;
  String? _agenceId;
  Map<String, dynamic>? _agentInfo;
  Map<String, dynamic>? _agenceInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAgentInfo();
  }

  Future<void> _loadAgentInfo() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      _agentId = currentUser.uid;

      // Récupérer les infos de l'agent depuis la collection 'users' (cohérent avec le système)
      final agentDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_agentId!)
          .get();

      if (agentDoc.exists) {
        _agentInfo = agentDoc.data()!;
        _agenceId = _agentInfo!['agenceId'];

        // Récupérer les infos de l'agence
        if (_agenceId != null) {
          final agenceDoc = await FirebaseFirestore.instance
              .collection('agences')
              .doc(_agenceId!)
              .get();

          if (agenceDoc.exists) {
            _agenceInfo = agenceDoc.data();

            // Récupérer les infos de la compagnie
            final compagnieId = _agenceInfo!['compagnieId'];
            if (compagnieId != null) {
              final compagnieDoc = await FirebaseFirestore.instance
                  .collection('compagnies')
                  .doc(compagnieId)
                  .get();

              if (compagnieDoc.exists) {
                _agenceInfo!['compagnieInfo'] = compagnieDoc.data();
              }
            }
          }
        }

        // Marquer comme première connexion terminée
        if (_agentInfo!['isFirstLogin'] == true) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_agentId!)
              .update({
            'isFirstLogin': false,
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('❌ Erreur chargement agent: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_agentInfo == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erreur'),
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Erreur: Informations agent non trouvées'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_pin_circle,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_agentInfo!['prenom']} ${_agentInfo!['nom']}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    '🏢 ${_agentInfo!['compagnieNom'] ?? 'Compagnie'} • 🏪 ${_agentInfo!['agenceNom'] ?? 'Agence'}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 80,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
              ],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        actions: [
          // Notifications
          StreamBuilder<int>(
            stream: AgentNotificationService.streamPendingVehiclesCount(_agenceId ?? ''),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    onPressed: () => _showNotifications(),
                    icon: const Icon(Icons.notifications),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Menu
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'profile':
                  _showProfile();
                  break;
                case 'logout':
                  _logout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text('Profil'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Déconnexion'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF667EEA),
              Colors.white,
            ],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Informations agence
            _buildAgenceInfo(),

            const SizedBox(height: 24),

            // 🔔 Notifications temps réel
            AgentNotificationWidget(
              agentId: _agentId!,
              agencyId: _agenceId,
            ),

            const SizedBox(height: 24),

            // Statistiques rapides
            _buildQuickStats(),

            const SizedBox(height: 24),

            // Actions principales
            _buildMainActions(),

            const SizedBox(height: 24),



            // Véhicules en attente (aperçu)
            _buildPendingVehiclesPreview(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAgenceInfo() {
    final compagnieInfo = _agenceInfo?['compagnieInfo'] as Map<String, dynamic>?;
    final compagnieNom = compagnieInfo?['nom'] ??
                        _agentInfo?['compagnieNom'] ??
                        'Compagnie non définie';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.business_center,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Mon Espace Professionnel',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Actif',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Informations de la compagnie
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.corporate_fare_rounded,
                    label: 'Compagnie d\'Assurance',
                    value: compagnieNom,
                    color: Colors.purple.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations de l'agence
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    icon: Icons.location_city_rounded,
                    label: 'Agence',
                    value: _agenceInfo?['nom'] ?? 'Agence non définie',
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),

            if (_agenceInfo?['adresse'] != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _agenceInfo!['adresse'],
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 📋 Widget pour afficher une information
  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStats() {
    return StreamBuilder<QuerySnapshot>(
      stream: ContractService.getPendingVehicles(_agenceId!),
      builder: (context, pendingSnapshot) {
        return StreamBuilder<QuerySnapshot>(
          stream: ContractService.getAgenceContracts(_agenceId!),
          builder: (context, contractsSnapshot) {
            final pendingCount = pendingSnapshot.data?.docs.length ?? 0;
            final contractsCount = contractsSnapshot.data?.docs.length ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Véhicules en attente',
                    '$pendingCount',
                    Icons.pending_actions,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard(
                    'Contrats créés',
                    '$contractsCount',
                    Icons.assignment_turned_in,
                    Colors.green,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Colors.grey.shade50],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.dashboard_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Actions Rapides',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.1,
            children: [
              _buildActionCard(
                'Mes Contrats',
                'Gérer vos contrats',
                Icons.assignment_rounded,
                const Color(0xFF10B981),
                () => _showMesContrats(),
              ),
              _buildActionCard(
                'Dossiers Affectés',
                'Traiter les véhicules',
                Icons.assignment_ind_rounded,
                const Color(0xFF3B82F6),
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PendingVehiclesManagementScreen(),
                  ),
                ),
              ),
              _buildActionCard(
                'Clients',
                'Gérer conducteurs',
                Icons.people_rounded,
                const Color(0xFFF59E0B),
                () => _showComingSoon('Gestion des clients'),
              ),
              _buildActionCard(
                'Rapports',
                'Statistiques & Analytics',
                Icons.analytics_rounded,
                const Color(0xFF8B5CF6),
                () => _showComingSoon('Rapports'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPendingVehiclesPreview() {
    print('🔍 [AGENT DASHBOARD] _agenceId = $_agenceId');
    print('🔍 [AGENT DASHBOARD] _agentInfo = $_agentInfo');

    // TOUJOURS afficher la section pour debug
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête de section
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange.shade600, Colors.orange.shade800],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.pending_actions,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Véhicules en attente',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'AgenceId: ${_agenceId ?? "NON DÉFINI"}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section véhicules en attente - TOUJOURS AFFICHÉE
          _buildVehiclesStreamWithDebug(),
        ],
      ),
    );
  }

  Widget _buildVehiclesStreamWithDebug() {
    // Toujours afficher la section véhicules, même si agenceId n'est pas défini
    return _buildVehiclesStream();
  }

  Widget _buildVehiclesStream() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Utilisateur non connecté',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('vehicules')
          .where('etatCompte', isEqualTo: 'Affecté à Agent')
          .where('agentAffecteId', isEqualTo: currentUser.uid)
          .snapshots(),
      builder: (context, snapshot) {
        print('🔍 [AGENT DASHBOARD] Stream state: ${snapshot.connectionState}');
        print('🔍 [AGENT DASHBOARD] Has error: ${snapshot.hasError}');
        print('🔍 [AGENT DASHBOARD] AgentId: ${currentUser.uid}');
        if (snapshot.hasError) {
          print('❌ [AGENT DASHBOARD] Erreur stream véhicules: ${snapshot.error}');
        }

        if (snapshot.hasError) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.red.shade200),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
                const SizedBox(height: 12),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.red.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
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
            ),
          );
        }

        final vehicules = snapshot.data?.docs ?? [];

        print('📊 [AGENT DASHBOARD] ${vehicules.length} véhicules affectés trouvés pour agent ${currentUser.uid}');

        // Debug: Afficher les détails des véhicules trouvés
        for (var doc in vehicules) {
          final data = doc.data() as Map<String, dynamic>;
          print('🚗 [AGENT DASHBOARD] Véhicule affecté: ${doc.id} - ${data['marque']} ${data['modele']} - agentId: ${data['agentAffecteId']} - etat: ${data['etatCompte']}');
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.orange.shade600, Colors.orange.shade800],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.pending_actions,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dossiers affectés',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${vehicules.length} dossier${vehicules.length > 1 ? 's' : ''} à traiter',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (vehicules.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${vehicules.length}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (vehicules.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.green.shade400,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Aucun dossier affecté',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Aucun dossier ne vous a été affecté pour le moment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Afficher les 3 premiers véhicules
                ...vehicules.take(3).map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade600,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        '${data['marque'] ?? 'N/A'} ${data['modele'] ?? 'N/A'}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Immatriculation: ${data['numeroImmatriculation'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          if (createdAt != null)
                            Text(
                              'Ajouté le ${_formatDate(createdAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                      trailing: Container(
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
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PendingVehiclesManagementScreen(),
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Bouton "Voir tout" si plus de 3 véhicules
                if (vehicules.length > 3) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PendingVehiclesManagementScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.list, size: 18),
                      label: Text('Voir tous les ${vehicules.length} véhicules'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ] else if (vehicules.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PendingVehiclesManagementScreen(),
                        ),
                      ),
                      icon: const Icon(Icons.manage_accounts, size: 18),
                      label: const Text('Gérer les véhicules'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.notifications_active,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Véhicules en attente de validation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Liste des véhicules en attente
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('vehicules')
                    .where('etatCompte', isEqualTo: 'En attente de validation')
                    .where('agenceId', isEqualTo: _agenceId)
                    .orderBy('dateCreation', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Erreur de chargement',
                            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final vehicules = snapshot.data?.docs ?? [];

                  if (vehicules.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 64, color: Colors.green.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune notification',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Tous les véhicules sont traités',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vehicules.length,
                    itemBuilder: (context, index) {
                      final vehicule = vehicules[index].data() as Map<String, dynamic>;
                      final dateCreation = (vehicule['dateCreation'] as Timestamp?)?.toDate();

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.directions_car,
                              color: Colors.orange.shade600,
                              size: 24,
                            ),
                          ),
                          title: Text(
                            '${vehicule['marque']} ${vehicule['modele']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Propriétaire: ${vehicule['prenomProprietaire']} ${vehicule['nomProprietaire']}'),
                              Text('Immatriculation: ${vehicule['numeroImmatriculation']}'),
                              if (dateCreation != null)
                                Text(
                                  'Soumis le: ${_formatDate(dateCreation)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                            ],
                          ),
                          trailing: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PendingVehiclesManagementScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Traiter', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_agentInfo!['prenom']} ${_agentInfo!['nom']}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          'Agent d\'Assurance',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu du profil
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProfileSection('Informations Personnelles', [
                      _buildProfileItem(Icons.email, 'Email', _agentInfo!['email'] ?? 'N/A'),
                      _buildProfileItem(Icons.phone, 'Téléphone', _agentInfo!['telephone'] ?? 'N/A'),
                      _buildProfileItem(Icons.badge, 'ID Agent', _agentInfo!['uid'] ?? 'N/A'),
                    ]),

                    const SizedBox(height: 24),

                    _buildProfileSection('Informations Professionnelles', [
                      _buildProfileItem(Icons.business, 'Compagnie', _agentInfo!['compagnieNom'] ?? 'N/A'),
                      _buildProfileItem(Icons.store, 'Agence', _agentInfo!['agenceNom'] ?? 'N/A'),
                      _buildProfileItem(Icons.access_time, 'Dernière Connexion', _formatDate(_agentInfo!['lastLoginAt']?.toDate())),
                    ]),

                    const SizedBox(height: 24),

                    // Statistiques en temps réel
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('contrats')
                          .where('agentId', isEqualTo: _agentId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        final contratsCount = snapshot.data?.docs.length ?? 0;
                        double totalPrimes = 0;

                        if (snapshot.hasData) {
                          for (var doc in snapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>;
                            totalPrimes += (data['primeAnnuelle'] as num?)?.toDouble() ?? 0;
                          }
                        }

                        return _buildProfileSection('Statistiques', [
                          _buildProfileItem(Icons.assignment, 'Contrats Créés', '$contratsCount'),
                          _buildProfileItem(Icons.euro, 'Total Primes', '${totalPrimes.toStringAsFixed(0)} DT'),
                          _buildProfileItem(Icons.trending_up, 'Dernière Activité', _formatDate(_agentInfo!['lastActivity']?.toDate())),
                        ]);
                      },
                    ),

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _showComingSoon('Modifier le profil');
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Modifier'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667EEA),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _logout();
                            },
                            icon: const Icon(Icons.logout),
                            label: const Text('Déconnexion'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 12),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF667EEA).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF667EEA), size: 20),
          ),
          const SizedBox(width: 12),
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
                const SizedBox(height: 2),
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
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Bientôt disponible !'),
        backgroundColor: Colors.blue.shade600,
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.of(context).pushNamedAndRemoveUntil(
                '/login',
                (route) => false,
              );
            },
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }

  /// 📋 Section des véhicules affectés à cet agent (SUPPRIMÉE)
  Widget _buildAssignedVehiclesSection_DELETED() {
    print('🔍 [AGENT DEBUG] ===== CONSTRUCTION SECTION VÉHICULES AFFECTÉS =====');
    print('🔍 [AGENT DEBUG] Agent ID: $_agentId');
    print('🔍 [AGENT DEBUG] Agent Info: $_agentInfo');
    print('🔍 [AGENT DEBUG] Current User: ${FirebaseAuth.instance.currentUser?.uid}');

    // Test rapide pour vérifier si on trouve le véhicule
    if (_agentId != null) {
      FirebaseFirestore.instance
          .collection('vehicules')
          .where('agentAffecteId', isEqualTo: _agentId)
          .get()
          .then((snapshot) {
        print('🔍 [AGENT DEBUG] Test rapide: ${snapshot.docs.length} véhicules trouvés pour $_agentId');
        for (final doc in snapshot.docs) {
          final data = doc.data();
          print('🔍 [AGENT DEBUG] Test véhicule: ${data['marque']} ${data['modele']} - ${data['etatCompte']}');
        }
      });
    }

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFF8FAFC)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Colors.blue.shade100,
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.assignment_ind,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Véhicules Affectés',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Dossiers qui vous sont assignés',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('vehicules')
                .where('etatCompte', isEqualTo: 'Affecté à Agent')
                .where('agentAffecteId', isEqualTo: _agentId)
                .snapshots(),
            builder: (context, snapshot) {
              print('🔍 [AGENT STREAM] StreamBuilder appelé - ConnectionState: ${snapshot.connectionState}');
              print('🔍 [AGENT STREAM] Agent ID recherché: $_agentId');
              print('🔍 [AGENT STREAM] HasError: ${snapshot.hasError}');
              print('🔍 [AGENT STREAM] HasData: ${snapshot.hasData}');
              if (snapshot.hasData) {
                print('🔍 [AGENT STREAM] Nombre de documents: ${snapshot.data!.docs.length}');
              }

              if (snapshot.hasError) {
                print('🔍 [AGENT STREAM] Erreur: ${snapshot.error}');
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Erreur de chargement',
                        style: TextStyle(color: Colors.red.shade700),
                      ),
                    ],
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('Chargement des véhicules affectés...'),
                    ],
                  ),
                );
              }

              final vehicules = snapshot.data?.docs ?? [];
              print('🔍 [AGENT STREAM] ${vehicules.length} véhicules affectés trouvés pour agent $_agentId');

              // Debug détaillé de chaque véhicule
              for (int i = 0; i < vehicules.length; i++) {
                final doc = vehicules[i];
                final data = doc.data() as Map<String, dynamic>;
                print('🔍 [AGENT STREAM] Véhicule $i: ${doc.id}');
                print('🔍 [AGENT STREAM] - Marque/Modèle: ${data['marque']} ${data['modele']}');
                print('🔍 [AGENT STREAM] - État: ${data['etatCompte']}');
                print('🔍 [AGENT STREAM] - Agent ID: ${data['agentAffecteId']}');
                print('🔍 [AGENT STREAM] - Agent Nom: ${data['agentAffecteNom']}');
              }

              if (vehicules.isEmpty) {
                print('🔍 [AGENT STREAM] Aucun véhicule trouvé - affichage message vide');
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: Colors.blue.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aucun véhicule affecté',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Les véhicules qui vous seront affectés apparaîtront ici',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              print('🔍 [AGENT STREAM] Affichage de ${vehicules.length} véhicules');

              return Column(
                children: [
                  ...vehicules.take(3).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    print('🔍 [AGENT STREAM] Construction carte pour: ${data['marque']} ${data['modele']}');
                    return _buildAssignedVehicleCard_DELETED(doc.id, data);
                  }),
                  if (vehicules.length > 3) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            '+${vehicules.length - 3} autres véhicules affectés',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  /// 🚗 Carte d'un véhicule affecté (SUPPRIMÉE)
  Widget _buildAssignedVehicleCard_DELETED(String vehicleId, Map<String, dynamic> data) {
    final assignedAt = (data['dateAffectation'] as Timestamp?)?.toDate();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec véhicule
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: Colors.blue.shade600,
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                    Text(
                      'Immatriculation: ${data['numeroImmatriculation'] ?? 'N/A'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Text(
                  'Affecté',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Informations propriétaire
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                    const SizedBox(width: 6),
                    Text(
                      'Propriétaire',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${data['prenomProprietaire'] ?? 'N/A'} ${data['nomProprietaire'] ?? 'N/A'}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (assignedAt != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: Colors.blue.shade600),
                      const SizedBox(width: 4),
                      Text(
                        'Affecté le ${assignedAt.day}/${assignedAt.month}/${assignedAt.year} à ${assignedAt.hour}:${assignedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blue.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Boutons d'action
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewVehicleDetails(vehicleId, data),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Voir Détails'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _processVehicle(vehicleId, data),
                  icon: const Icon(Icons.edit_document, size: 16),
                  label: const Text('Traiter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
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

  /// 👁️ Voir les détails d'un véhicule
  void _viewVehicleDetails(String vehicleId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.directions_car, color: Colors.blue.shade600),
            const SizedBox(width: 8),
            Text('${data['marque']} ${data['modele']}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Immatriculation', data['numeroImmatriculation']),
              _buildDetailRow('Propriétaire', '${data['prenomProprietaire']} ${data['nomProprietaire']}'),
              _buildDetailRow('Année', data['annee']?.toString()),
              _buildDetailRow('Couleur', data['couleur']),
              _buildDetailRow('Usage', data['usage']),
              _buildDetailRow('Compagnie', data['compagnieAssuranceNom']),
              _buildDetailRow('Agence', data['agenceAssuranceNom']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processVehicle(vehicleId, data);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Traiter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// 📝 Traiter un véhicule (créer contrat, etc.)
  void _processVehicle(String vehicleId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.edit_document, color: Colors.green.shade600),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Gestion du Contrat',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${data['marque']} ${data['modele']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Informations véhicule
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
                        const Text(
                          'Informations Véhicule',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('Propriétaire', '${data['prenomProprietaire']} ${data['nomProprietaire']}'),
                    _buildDetailRow('Immatriculation', data['numeroImmatriculation']),
                    _buildDetailRow('Année', data['annee']?.toString()),
                    _buildDetailRow('Usage', data['usage']),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Actions de gestion
              const Text(
                'Actions disponibles :',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Boutons d'action
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _createContract(vehicleId, data);
                      },
                      icon: const Icon(Icons.description, size: 20),
                      label: const Text('Créer Contrat d\'Assurance'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _requestDocuments(vehicleId, data);
                      },
                      icon: const Icon(Icons.folder_open, size: 20),
                      label: const Text('Demander Documents'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _markAsProcessed(vehicleId, data);
                      },
                      icon: const Icon(Icons.check_circle, size: 20),
                      label: const Text('Marquer comme Traité'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Bouton fermer
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Fermer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Ligne de détail pour le dialog
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'N/A',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }



  /// 📄 Créer un contrat d'assurance
  Future<void> _createContract(String vehicleId, Map<String, dynamic> data) async {
    final TextEditingController numeroContratController = TextEditingController();
    final TextEditingController primeController = TextEditingController();
    final TextEditingController franchiseController = TextEditingController();

    DateTime? dateDebut;
    DateTime? dateFin;
    bool isGeneratingNumber = false;

    // Générer automatiquement le numéro de contrat
    Future<void> generateContractNumber() async {
      try {
        isGeneratingNumber = true;
        final numero = await ContractNumberService.generateUniqueContractNumber(
          compagnieId: _agentInfo?['compagnieId'] ?? 'default_company',
          agenceId: _agenceId ?? 'default_agency',
          typeContrat: 'assurance_auto',
        );
        numeroContratController.text = numero;
        print('✅ [CONTRACT] Numéro généré: $numero');
      } catch (e) {
        print('❌ [CONTRACT] Erreur génération numéro: $e');
        // Fallback simple
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        numeroContratController.text = 'CTR_$timestamp';
      } finally {
        isGeneratingNumber = false;
      }
    }

    // Générer le numéro au début
    await generateContractNumber();

    final created = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.description, color: Colors.green),
              SizedBox(width: 8),
              Text('Créer Contrat d\'Assurance'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Numéro de contrat généré automatiquement
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.confirmation_number, color: Colors.blue.shade600, size: 20),
                          const SizedBox(width: 8),
                          const Text(
                            'Numéro de Contrat (Généré automatiquement)',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: numeroContratController,
                              readOnly: true,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatefulBuilder(
                            builder: (context, setButtonState) => IconButton(
                              onPressed: isGeneratingNumber ? null : () async {
                                setButtonState(() => isGeneratingNumber = true);
                                await generateContractNumber();
                                setButtonState(() => isGeneratingNumber = false);
                              },
                              icon: isGeneratingNumber
                                  ? SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.blue.shade600,
                                      ),
                                    )
                                  : Icon(Icons.refresh, color: Colors.blue.shade600),
                              tooltip: 'Générer un nouveau numéro',
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.blue.shade100,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: primeController,
                  decoration: const InputDecoration(
                    labelText: 'Prime annuelle (TND) *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.euro),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: franchiseController,
                  decoration: const InputDecoration(
                    labelText: 'Franchise (TND)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.money),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (date != null) {
                            setState(() {
                              dateDebut = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(dateDebut != null
                          ? 'Début: ${dateDebut!.day}/${dateDebut!.month}/${dateDebut!.year}'
                          : 'Date début *'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: dateDebut?.add(const Duration(days: 365)) ?? DateTime.now().add(const Duration(days: 365)),
                            firstDate: dateDebut ?? DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 730)),
                          );
                          if (date != null) {
                            setState(() {
                              dateFin = date;
                            });
                          }
                        },
                        icon: const Icon(Icons.calendar_today),
                        label: Text(dateFin != null
                          ? 'Fin: ${dateFin!.day}/${dateFin!.month}/${dateFin!.year}'
                          : 'Date fin *'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (numeroContratController.text.trim().isEmpty ||
                    primeController.text.trim().isEmpty ||
                    dateDebut == null ||
                    dateFin == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Veuillez remplir tous les champs obligatoires'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Créer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (created == true) {
      try {
        // Créer le contrat dans Firestore
        await FirebaseFirestore.instance.collection('contrats').add({
          'vehiculeId': vehicleId,
          'numeroContrat': numeroContratController.text.trim(),
          'primeAnnuelle': double.tryParse(primeController.text.trim()) ?? 0,
          'franchise': double.tryParse(franchiseController.text.trim()) ?? 0,
          'dateDebut': Timestamp.fromDate(dateDebut!),
          'dateFin': Timestamp.fromDate(dateFin!),
          'statut': 'Actif',
          'agentId': _agentId,
          'agentNom': '${_agentInfo!['prenom']} ${_agentInfo!['nom']}',
          'agenceId': _agenceId,
          'vehiculeInfo': {
            'marque': data['marque'],
            'modele': data['modele'],
            'immatriculation': data['numeroImmatriculation'],
            'proprietaire': '${data['prenomProprietaire']} ${data['nomProprietaire']}',
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour le statut du véhicule
        await FirebaseFirestore.instance
            .collection('vehicules')
            .doc(vehicleId)
            .update({
          'etatCompte': 'Contrat Créé',
          'numeroContrat': numeroContratController.text.trim(),
          'dateContrat': FieldValue.serverTimestamp(),
          'traitePar': _agentId,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Contrat ${numeroContratController.text.trim()} créé avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur lors de la création: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 📁 Demander des documents supplémentaires
  Future<void> _requestDocuments(String vehicleId, Map<String, dynamic> data) async {
    final TextEditingController messageController = TextEditingController();
    final List<String> documentsRequis = [];

    final sent = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.folder_open, color: Colors.orange),
              SizedBox(width: 8),
              Text('Demander Documents'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Véhicule: ${data['marque']} ${data['modele']}'),
                Text('Propriétaire: ${data['prenomProprietaire']} ${data['nomProprietaire']}'),
                const SizedBox(height: 16),
                const Text(
                  'Documents requis:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...['Carte grise', 'Permis de conduire', 'Carte d\'identité', 'Justificatif de domicile', 'Photos du véhicule']
                    .map((doc) => CheckboxListTile(
                      title: Text(doc),
                      value: documentsRequis.contains(doc),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            documentsRequis.add(doc);
                          } else {
                            documentsRequis.remove(doc);
                          }
                        });
                      },
                    )),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Message personnalisé',
                    border: OutlineInputBorder(),
                    hintText: 'Instructions supplémentaires...',
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: documentsRequis.isNotEmpty
                  ? () => Navigator.of(context).pop(true)
                  : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Envoyer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );

    if (sent == true) {
      try {
        // Créer une demande de documents
        await FirebaseFirestore.instance.collection('demandes_documents').add({
          'vehiculeId': vehicleId,
          'proprietaireNom': '${data['prenomProprietaire']} ${data['nomProprietaire']}',
          'documentsRequis': documentsRequis,
          'message': messageController.text.trim(),
          'statut': 'En attente',
          'agentId': _agentId,
          'agentNom': '${_agentInfo!['prenom']} ${_agentInfo!['nom']}',
          'agenceId': _agenceId,
          'vehiculeInfo': {
            'marque': data['marque'],
            'modele': data['modele'],
            'immatriculation': data['numeroImmatriculation'],
          },
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Mettre à jour le statut du véhicule
        await FirebaseFirestore.instance
            .collection('vehicules')
            .doc(vehicleId)
            .update({
          'etatCompte': 'Documents Demandés',
          'documentsRequis': documentsRequis,
          'messageDemande': messageController.text.trim(),
          'dateDemandeDocs': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Demande de ${documentsRequis.length} documents envoyée'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur lors de l\'envoi: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ✅ Marquer comme traité
  Future<void> _markAsProcessed(String vehicleId, Map<String, dynamic> data) async {
    final TextEditingController notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.blue),
            SizedBox(width: 8),
            Text('Marquer comme Traité'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous marquer ce véhicule comme traité ?'),
            const SizedBox(height: 8),
            Text(
              '${data['marque']} ${data['modele']} - ${data['prenomProprietaire']} ${data['nomProprietaire']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes de traitement',
                border: OutlineInputBorder(),
                hintText: 'Résumé du traitement effectué...',
              ),
              maxLines: 3,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Confirmer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('vehicules')
            .doc(vehicleId)
            .update({
          'etatCompte': 'Traité par Agent',
          'notesTraitement': notesController.text.trim(),
          'dateTraitement': FieldValue.serverTimestamp(),
          'traitePar': _agentId,
          'agentTraitementNom': '${_agentInfo!['prenom']} ${_agentInfo!['nom']}',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Véhicule marqué comme traité'),
              backgroundColor: Colors.blue,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// 📋 Afficher la liste des contrats de l'agent
  void _showMesContrats() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // En-tête
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade700],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.assignment,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mes Contrats',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Contrats créés par moi',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),

              // Liste des contrats
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _loadAgentContrats(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Chargement des contrats...'),
                          ],
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error, size: 64, color: Colors.red.shade400),
                            const SizedBox(height: 16),
                            Text('Erreur: ${snapshot.error}'),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showMesContrats(); // Recharger
                              },
                              child: const Text('Réessayer'),
                            ),
                          ],
                        ),
                      );
                    }

                    final contrats = snapshot.data ?? [];
                    print('📋 [CONTRATS] ${contrats.length} contrats trouvés pour agent');

                    if (contrats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_outlined,
                              size: 80,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucun contrat créé',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Les contrats que vous créez apparaîtront ici',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: contrats.length,
                      itemBuilder: (context, index) {
                        final contrat = contrats[index];
                        return _buildContratCard(contrat);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Charger les contrats de l'agent
  Future<List<Map<String, dynamic>>> _loadAgentContrats() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('❌ [CONTRATS] Utilisateur non connecté');
        return [];
      }

      print('📋 [CONTRATS] Chargement contrats pour agent: ${user.uid}');
      print('📋 [CONTRATS] Email agent: ${user.email}');

      // D'abord, testons avec une requête simple pour voir tous les contrats
      final allContratsQuery = await FirebaseFirestore.instance
          .collection('contrats')
          .get();

      print('📋 [CONTRATS] Total contrats dans la collection: ${allContratsQuery.docs.length}');

      // Affichons les agentId de tous les contrats pour debug
      for (final doc in allContratsQuery.docs) {
        final data = doc.data();
        print('📋 [CONTRATS] Contrat ${data['numeroContrat']} - agentId: ${data['agentId']}');
      }

      final contrats = <Map<String, dynamic>>[];

      try {
        // D'abord récupérer tous les contrats pour debug
        final allSnapshot = await FirebaseFirestore.instance
            .collection('contrats')
            .get();

        print('📋 [CONTRATS] Total contrats dans collection: ${allSnapshot.docs.length}');

        // Filtrer manuellement pour éviter les problèmes d'index
        for (final doc in allSnapshot.docs) {
          final contractData = doc.data();
          print('📋 [CONTRATS] Contrat ${contractData['numeroContrat']} - agentId: ${contractData['agentId']} - cherché: ${user.uid}');

          if (contractData['agentId'] == user.uid) {
            contractData['id'] = doc.id;
            contrats.add(contractData);
            print('✅ [CONTRATS] MATCH! Contrat ajouté: ${contractData['numeroContrat']}');
          }
        }

        print('📋 [CONTRATS] Total contrats trouvés pour cet agent: ${contrats.length}');
      } catch (e) {
        print('❌ [CONTRATS] Erreur récupération: $e');
      }

      // Trier par date de création (plus récent en premier) - en mémoire pour éviter l'index
      contrats.sort((a, b) {
        final aDate = a['createdAt'] as Timestamp?;
        final bDate = b['createdAt'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      print('📋 [CONTRATS] Total final: ${contrats.length} contrats');
      return contrats;
    } catch (e) {
      print('❌ [CONTRATS] Erreur chargement contrats agent: $e');
      return [];
    }
  }

  /// 📄 Carte de contrat
  Widget _buildContratCard(Map<String, dynamic> contrat) {
    final dateCreation = (contrat['createdAt'] as Timestamp?)?.toDate();
    final dateDebut = (contrat['dateDebut'] as Timestamp?)?.toDate();
    final dateFin = (contrat['dateFin'] as Timestamp?)?.toDate();
    final isActive = dateFin?.isAfter(DateTime.now()) ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.green.shade50, Colors.green.shade100]
              : [Colors.grey.shade50, Colors.grey.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête du contrat
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade600 : Colors.grey.shade600,
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
                    isActive ? Icons.verified : Icons.history,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contrat['numeroContrat'] ?? 'N/A',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isActive ? 'Contrat Actif' : 'Contrat Expiré',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contrat['typeContrat'] ?? 'RC',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Contenu du contrat
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Informations principales
                _buildContratInfoRow(
                  'Assuré',
                  '${contrat['conducteurInfo']?['nom'] ?? 'N/A'} ${contrat['conducteurInfo']?['prenom'] ?? 'N/A'}',
                  Icons.person,
                ),
                _buildContratInfoRow(
                  'Véhicule',
                  '${contrat['vehiculeInfo']?['marque'] ?? 'N/A'} ${contrat['vehiculeInfo']?['modele'] ?? 'N/A'}',
                  Icons.directions_car,
                ),
                _buildContratInfoRow(
                  'Immatriculation',
                  contrat['vehiculeInfo']?['immatriculation'] ?? 'N/A',
                  Icons.confirmation_number,
                ),
                _buildContratInfoRow(
                  'Prime',
                  '${contrat['primeAnnuelle'] ?? 0} DT',
                  Icons.payments,
                ),
                _buildContratInfoRow(
                  'Créé le',
                  _formatDate(dateCreation),
                  Icons.calendar_today,
                ),

                const SizedBox(height: 16),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showContratDetails(contrat),
                        icon: const Icon(Icons.visibility, size: 16),
                        label: const Text('Détails'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _exportContratPDF(contrat),
                        icon: const Icon(Icons.picture_as_pdf, size: 16),
                        label: const Text('PDF'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
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

  /// 📝 Ligne d'information du contrat
  Widget _buildContratInfoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.blue.shade700),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }



  /// 👁️ Afficher les détails du contrat
  void _showContratDetails(Map<String, dynamic> contrat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contrat ${contrat['numeroContrat']}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Type: ${contrat['typeContrat']}'),
              Text('Assuré: ${contrat['nomAssure']} ${contrat['prenomAssure']}'),
              Text('Prime: ${contrat['montantPrime']} DT'),
              Text('Statut: ${contrat['statutContrat']}'),
              if (contrat['observations'] != null && contrat['observations'].isNotEmpty)
                Text('Observations: ${contrat['observations']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  /// 📄 Exporter le contrat en PDF
  void _exportContratPDF(Map<String, dynamic> contrat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Aperçu PDF Contrat'),
          ],
        ),
        content: SingleChildScrollView(
          child: Container(
            width: double.maxFinite,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // En-tête simple
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONTRAT D\'ASSURANCE AUTOMOBILE',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Numero: ${contrat['numeroContrat']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Contenu texte simple
                Text(
                  'INFORMATIONS GENERALES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Type: ${contrat['typeContrat'] ?? 'N/A'}'),
                Text('Statut: ${contrat['statutContrat'] ?? 'N/A'}'),
                Text('Prime: ${contrat['primeAnnuelle'] ?? 0} DT'),
                Text('Franchise: ${contrat['franchise'] ?? 0} DT'),

                const SizedBox(height: 16),

                Text(
                  'ASSURE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Nom: ${contrat['conducteurInfo']?['nom'] ?? 'N/A'} ${contrat['conducteurInfo']?['prenom'] ?? 'N/A'}'),

                const SizedBox(height: 16),

                Text(
                  'VEHICULE',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Marque: ${contrat['vehiculeInfo']?['marque'] ?? 'N/A'}'),
                Text('Modele: ${contrat['vehiculeInfo']?['modele'] ?? 'N/A'}'),
                Text('Immatriculation: ${contrat['vehiculeInfo']?['immatriculation'] ?? 'N/A'}'),
                Text('Annee: ${contrat['vehiculeInfo']?['annee']?.toString() ?? 'N/A'}'),

                const SizedBox(height: 16),

                Text(
                  'GARANTIES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                ...((contrat['garanties'] as List<dynamic>?) ?? []).map((garantie) =>
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('- ${garantie.toString()}'),
                  ),
                ).toList(),

                const SizedBox(height: 16),

                // Note
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    'Le document sera sauvegarde dans le dossier Documents de votre telephone.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _generatePDFFile(contrat);
            },
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Telecharger PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }



  /// 📄 Générer le fichier PDF avec support Unicode
  Future<void> _generatePDFFile(Map<String, dynamic> contrat) async {
    try {
      // Afficher le loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Text('Génération PDF en cours...'),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          duration: const Duration(seconds: 2),
        ),
      );

      // Créer le document PDF
      final pdf = pw.Document();

      debugPrint('🔧 Début génération PDF pour contrat: ${contrat['numeroContrat']}');

      // Fonction pour nettoyer le texte (enlever les accents)
      String cleanText(String text) {
        return text
            .replaceAll('é', 'e')
            .replaceAll('è', 'e')
            .replaceAll('ê', 'e')
            .replaceAll('à', 'a')
            .replaceAll('ç', 'c')
            .replaceAll('ù', 'u')
            .replaceAll('û', 'u')
            .replaceAll('ô', 'o')
            .replaceAll('î', 'i')
            .replaceAll('â', 'a')
            .replaceAll('É', 'E')
            .replaceAll('È', 'E')
            .replaceAll('À', 'A')
            .replaceAll('Ç', 'C')
            .replaceAll('°', ' ')
            .replaceAll('•', '-');
      }

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  color: PdfColors.blue,
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cleanText('CONTRAT D\'ASSURANCE AUTOMOBILE'),
                        style: pw.TextStyle(
                          fontSize: 18,
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Numero: ${contrat['numeroContrat']}',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // Informations générales
                pw.Text(
                  cleanText('INFORMATIONS GENERALES'),
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.blue,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Type: ${cleanText(contrat['typeContrat'] ?? 'N/A')}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Statut: ${cleanText(contrat['statutContrat'] ?? 'N/A')}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Prime: ${contrat['primeAnnuelle'] ?? 0} DT',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Franchise: ${contrat['franchise'] ?? 0} DT',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 20),

                // Assuré
                pw.Text(
                  cleanText('ASSURE'),
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.blue,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Nom: ${cleanText('${contrat['conducteurInfo']?['nom'] ?? 'N/A'} ${contrat['conducteurInfo']?['prenom'] ?? 'N/A'}')}',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 20),

                // Véhicule
                pw.Text(
                  cleanText('VEHICULE'),
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.blue,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'Marque: ${cleanText(contrat['vehiculeInfo']?['marque'] ?? 'N/A')}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Modele: ${cleanText(contrat['vehiculeInfo']?['modele'] ?? 'N/A')}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Immatriculation: ${contrat['vehiculeInfo']?['immatriculation'] ?? 'N/A'}',
                  style: pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Annee: ${contrat['vehiculeInfo']?['annee']?.toString() ?? 'N/A'}',
                  style: pw.TextStyle(fontSize: 12),
                ),

                pw.SizedBox(height: 20),

                // Garanties
                pw.Text(
                  'GARANTIES',
                  style: pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.blue,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                ...((contrat['garanties'] as List<dynamic>?) ?? []).map((garantie) =>
                  pw.Text(
                    '- ${cleanText(garantie.toString())}',
                    style: pw.TextStyle(fontSize: 12),
                  ),
                ).toList(),

                pw.Spacer(),

                // Pied de page
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  color: PdfColors.grey200,
                  child: pw.Text(
                    'Document genere le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: pw.TextStyle(fontSize: 10),
                    textAlign: pw.TextAlign.center,
                  ),
                ),
              ],
            );
          },
        ),
      );

      debugPrint('✅ Page PDF créée avec succès');

      // Sauvegarder le fichier PDF dans le dossier de l'application
      debugPrint('📁 Sauvegarde du PDF dans le dossier de l\'application...');

      final fileName = 'contrat_${contrat['numeroContrat']}.pdf';
      final pdfBytes = await pdf.save();
      debugPrint('💾 PDF généré, taille: ${pdfBytes.length} bytes');

      // Utiliser le dossier de l'application (toujours accessible)
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfBytes);
      debugPrint('✅ Fichier sauvegardé: ${file.path}');

      // Afficher une boîte de dialogue avec les options
      _showPDFSuccessDialog(file, fileName, contrat, directory);

    } catch (e) {
      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Erreur PDF: $e'),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// 📄 Afficher la boîte de dialogue de succès PDF
  void _showPDFSuccessDialog(File file, String fileName, Map<String, dynamic> contrat, Directory directory) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('PDF Généré')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le contrat PDF a été généré avec succès !',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.folder, color: Colors.blue.shade600, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Dossier Documents de l\'application',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Taille: ${(file.lengthSync() / 1024).toStringAsFixed(1)} KB',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Utilisez "Partager" pour sauvegarder dans vos Téléchargements',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await Share.shareXFiles(
                  [XFile(file.path)],
                  text: 'Contrat d\'assurance ${contrat['numeroContrat']}',
                  subject: 'Contrat d\'assurance automobile',
                );
              } catch (e) {
                debugPrint('❌ Erreur partage: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur lors du partage: $e'),
                    backgroundColor: Colors.red.shade600,
                  ),
                );
              }
            },
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Partager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }




}
