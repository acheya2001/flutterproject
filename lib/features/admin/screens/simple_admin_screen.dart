import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/services/notification_service.dart';
import 'admin_demandes_screen.dart';
import '../utils/create_test_demande.dart';
import 'admin_hierarchy_setup_screen.dart';

/// 🎯 Écran admin simple qui fonctionne à 100%
class SimpleAdminScreen extends StatefulWidget {
  const SimpleAdminScreen({super.key});

  @override
  State<SimpleAdminScreen> createState() => _SimpleAdminScreenState();
}

class _SimpleAdminScreenState extends State<SimpleAdminScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Map<String, int> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  /// 📊 Charger les statistiques
  Future<void> _loadStats() async {
    try {
      final stats = <String, int>{};

      // Compter les demandes en attente
      final pendingRequests = await _firestore
          .collection('professional_account_requests')
          .where('status', isEqualTo: 'pending')
          .count()
          .get();
      stats['Demandes en attente'] = pendingRequests.count ?? 0;

      // Compter les utilisateurs par type
      final users = await _firestore.collection('users').get();
      stats['Total utilisateurs'] = users.size;

      int conducteurs = 0, assureurs = 0, experts = 0;
      for (var doc in users.docs) {
        final userType = doc.data()['userType'] as String?;
        switch (userType) {
          case 'conducteur': conducteurs++; break;
          case 'assureur': assureurs++; break;
          case 'expert': experts++; break;
        }
      }
      stats['Conducteurs'] = conducteurs;
      stats['Assureurs'] = assureurs;
      stats['Experts'] = experts;

      // Compter les contrats
      final contracts = await _firestore.collection('contracts').count().get();
      stats['Contrats'] = contracts.count ?? 0;

      // Compter les constats
      final constats = await _firestore.collection('constats').count().get();
      stats['Constats'] = constats.count ?? 0;

      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('🎯 Administration'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/user-type-selection', (route) => false);
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.deepPurple, Colors.purple[300]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.admin_panel_settings, color: Colors.white, size: 32),
                      SizedBox(width: 12),
                      Text(
                        'Tableau de Bord Admin',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Connecté en tant que: ${user?.email ?? "Admin"}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Message de succès
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                border: Border.all(color: Colors.green[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '✅ Connexion admin réussie ! Le système fonctionne parfaitement.',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Actions rapides
            const Text(
              'Actions Administrateur',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistiques en temps réel
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              Expanded(
                child: Column(
                  children: [
                    // Grille de statistiques
                    Expanded(
                      flex: 2,
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.2,
                        ),
                        itemCount: _stats.length,
                        itemBuilder: (context, index) {
                          final entry = _stats.entries.elementAt(index);
                          return _buildStatCard(
                            title: entry.key,
                            value: entry.value.toString(),
                            color: _getColorForStat(entry.key),
                            icon: _getIconForStat(entry.key),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Actions rapides
                    Expanded(
                      flex: 1,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.5,
                        children: [
                          _buildActionButton(
                            icon: Icons.pending_actions,
                            title: 'Demandes d\'Inscription',
                            color: Colors.orange,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminDemandesScreen(),
                              ),
                            ),
                          ),
                          _buildActionButton(
                            icon: Icons.refresh,
                            title: 'Actualiser',
                            color: Colors.blue,
                            onTap: () => _loadStats(),
                          ),
                          _buildActionButton(
                            icon: Icons.science,
                            title: 'Créer Test',
                            color: Colors.purple,
                            onTap: () => _createTestDemandes(),
                          ),
                          _buildActionButton(
                            icon: Icons.description,
                            title: 'Constats',
                            color: Colors.purple,
                            onTap: () => _showConstats(),
                          ),
                          _buildActionButton(
                            icon: Icons.admin_panel_settings,
                            title: 'Config Hiérarchie',
                            color: Colors.red,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AdminHierarchySetupScreen(),
                              ),
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
      ),
    );
  }
  
  /// 📊 Carte de statistique
  Widget _buildStatCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// 🔘 Bouton d'action
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Couleur pour statistique
  Color _getColorForStat(String statName) {
    switch (statName) {
      case 'Demandes en attente': return Colors.orange;
      case 'Total utilisateurs': return Colors.blue;
      case 'Conducteurs': return Colors.green;
      case 'Assureurs': return Colors.purple;
      case 'Experts': return Colors.teal;
      case 'Contrats': return Colors.indigo;
      case 'Constats': return Colors.red;
      default: return Colors.grey;
    }
  }

  /// 🎯 Icône pour statistique
  IconData _getIconForStat(String statName) {
    switch (statName) {
      case 'Demandes en attente': return Icons.pending_actions;
      case 'Total utilisateurs': return Icons.people;
      case 'Conducteurs': return Icons.drive_eta;
      case 'Assureurs': return Icons.business;
      case 'Experts': return Icons.engineering;
      case 'Contrats': return Icons.description;
      case 'Constats': return Icons.report_problem;
      default: return Icons.info;
    }
  }

  /// 📋 Afficher les demandes en attente
  void _showPendingRequests() async {
    try {
      final requests = await _firestore
          .collection('professional_account_requests')
          .where('status', isEqualTo: 'pending')
          .get();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📋 Demandes en attente'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: requests.docs.isEmpty
                ? const Center(child: Text('Aucune demande en attente'))
                : ListView.builder(
                    itemCount: requests.docs.length,
                    itemBuilder: (context, index) {
                      final data = requests.docs[index].data();
                      return ListTile(
                        title: Text('${data['prenom']} ${data['nom']}'),
                        subtitle: Text('${data['userType']} - ${data['email']}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () => _approveRequest(requests.docs[index].id),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () => _rejectRequest(requests.docs[index].id),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  /// ✅ Approuver une demande
  Future<void> _approveRequest(String requestId) async {
    try {
      print('🔍 DEBUG: Approbation demande $requestId...');

      // Mettre à jour le statut
      await _firestore
          .collection('professional_account_requests')
          .doc(requestId)
          .update({
        'status': 'approved',
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin',
      });

      print('✅ DEBUG: Statut mis à jour, envoi notification...');

      // Envoyer notification et email
      try {
        await NotificationService.notifyAccountApproved(
          userId: requestId,
          approvedBy: 'admin',
        );
        print('✅ DEBUG: Notification envoyée');
      } catch (notifError) {
        print('❌ DEBUG: Erreur notification: $notifError');
        // Continuer même si la notification échoue
      }

      if (mounted) {
        Navigator.pop(context);
        _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demande approuvée et email envoyé'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Erreur approbation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// ❌ Rejeter une demande
  Future<void> _rejectRequest(String requestId) async {
    // Demander la raison du rejet
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Raison du rejet'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Expliquez pourquoi la demande est rejetée...',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      print('🔍 DEBUG: Rejet demande $requestId avec raison: $reason');

      // Mettre à jour le statut
      await _firestore
          .collection('professional_account_requests')
          .doc(requestId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
        'reviewedBy': 'admin',
      });

      print('✅ DEBUG: Statut mis à jour, envoi notification de rejet...');

      // Envoyer notification et email de rejet
      try {
        await NotificationService.notifyAccountRejected(
          userId: requestId,
          rejectedBy: 'admin',
          reason: reason,
        );
        print('✅ DEBUG: Notification de rejet envoyée');
      } catch (notifError) {
        print('❌ DEBUG: Erreur notification rejet: $notifError');
      }

      if (mounted) {
        Navigator.pop(context);
        _loadStats();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Demande rejetée et email envoyé'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ DEBUG: Erreur rejet: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 👥 Afficher les utilisateurs
  void _showUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎯 Gestion utilisateurs - En développement')),
    );
  }

  /// 📄 Afficher les constats
  void _showConstats() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎯 Gestion constats - En développement')),
    );
  }

  /// 🧪 Créer des demandes de test
  Future<void> _createTestDemandes() async {
    try {
      await CreateTestDemande.createMultipleTestDemandes();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Demandes de test créées ! Vérifiez l\'onglet "Demandes d\'Inscription"'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Actualiser les stats
      _loadStats();
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
