import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/config/app_routes.dart';
import 'contrat_actif_screen.dart';
import 'mes_vehicules_screen.dart';
import '../../services/document_download_service.dart';
import '../../../conducteur/screens/accident_declaration_screen.dart';
import '../../sinistre/screens/sinistre_choix_rapide_screen.dart';

/// 🏠 Dashboard principal du conducteur
class ConducteurDashboardScreen extends ConsumerStatefulWidget {
  const ConducteurDashboardScreen({super.key});

  @override
  ConsumerState<ConducteurDashboardScreen> createState() => _ConducteurDashboardScreenState();
}

class _ConducteurDashboardScreenState extends ConsumerState<ConducteurDashboardScreen> {
  String? _conducteurNom;
  String? _conducteurPrenom;

  @override
  void initState() {
    super.initState();
    _loadConducteurInfo();
  }

  Future<void> _loadConducteurInfo() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            _conducteurNom = data['nom'];
            _conducteurPrenom = data['prenom'];
          });
        }
      } catch (e) {
        print('Erreur lors du chargement des infos conducteur: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Dashboard Conducteur',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {
              // TODO: Profil
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadConducteurInfo,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildMyContracts(),
              const SizedBox(height: 24),
              _buildUpcomingPayments(),
              const SizedBox(height: 24),
              _buildMyVehicles(),
              const SizedBox(height: 24),
              _buildMyRequests(),
              const SizedBox(height: 24),
              _buildRecentActivity(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bonjour,',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                Text(
                  _conducteurPrenom != null && _conducteurNom != null
                      ? '$_conducteurPrenom $_conducteurNom'
                      : 'Conducteur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gérez vos assurances en toute simplicité',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Actions rapides',
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
                title: 'Mon Contrat',
                subtitle: 'Voir mon assurance active',
                icon: Icons.verified_user,
                color: const Color(0xFF8B5CF6),
                onTap: () => _openContratActif(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Nouvelle Demande',
                subtitle: 'Assurer un nouveau véhicule',
                icon: Icons.add_circle,
                color: const Color(0xFF10B981),
                onTap: () => _openNewInsuranceRequest(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Mes Véhicules',
                subtitle: 'Gérer mes véhicules',
                icon: Icons.directions_car,
                color: const Color(0xFF3B82F6),
                onTap: () => _openMesVehicules(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                title: 'Agence Proche',
                subtitle: 'Trouver une agence',
                icon: Icons.location_on,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  // TODO: Géolocalisation
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Géolocalisation - À implémenter')),
                  );
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionCard(
                title: 'Déclarer Sinistre',
                subtitle: 'Nouveau sinistre',
                icon: Icons.report_problem,
                color: const Color(0xFFEF4444),
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
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
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
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 📄 Section Mes Contrats
  Widget _buildMyContracts() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mes Contrats d\'Assurance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              TextButton.icon(
                onPressed: () => _openContratActif(),
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                label: const Text('Voir tout'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildContractsContent(),
        ],
      ),
    );
  }

  /// 📄 Contenu des contrats
  Widget _buildContractsContent() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return _buildNoContractsCard();
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            height: 100,
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Erreur: ${snapshot.error}'),
                ),
              ],
            ),
          );
        }

        final allDocs = snapshot.data?.docs ?? [];
        final contrats = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final statut = data['statut'] ?? '';
          return ['contrat_actif', 'en_attente_paiement', 'frequence_choisie', 'documents_completes'].contains(statut);
        }).take(3).toList();

        if (contrats.isEmpty) {
          return _buildNoContractsCard();
        }

        return Column(
          children: contrats.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return _buildContractCard(doc.id, data);
          }).toList(),
        );
      },
    );
  }



  /// 📄 Carte de contrat
  Widget _buildContractCard(String contractId, Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final numeroContrat = data['numeroContrat'] ?? contractId;
    final marque = data['marque'] ?? 'N/A';
    final modele = data['modele'] ?? 'N/A';
    final immatriculation = data['immatriculation'] ?? 'N/A';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (statut) {
      case 'contrat_actif':
        statusColor = const Color(0xFF10B981);
        statusText = 'ACTIF';
        statusIcon = Icons.verified;
        break;
      case 'en_attente_paiement':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'EN ATTENTE PAIEMENT';
        statusIcon = Icons.payment;
        break;
      case 'frequence_choisie':
        statusColor = const Color(0xFF8B5CF6);
        statusText = 'PRÊT POUR PAIEMENT';
        statusIcon = Icons.schedule;
        break;
      default:
        statusColor = Colors.grey;
        statusText = statut.toUpperCase();
        statusIcon = Icons.help_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openContratActif(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Contrat N° $numeroContrat',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$marque $modele',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.directions_car, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    immatriculation,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                ],
              ),

              // Boutons de téléchargement pour les contrats actifs
              if (statut == 'contrat_actif') ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadAttestation(contractId, data),
                        icon: const Icon(Icons.file_download, size: 16),
                        label: const Text('Attestation'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF3B82F6),
                          side: const BorderSide(color: Color(0xFF3B82F6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _downloadEcheancier(contractId, data),
                        icon: const Icon(Icons.schedule, size: 16),
                        label: const Text('Échéancier'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                          side: const BorderSide(color: Color(0xFF8B5CF6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 📄 Carte quand il n'y a pas de contrats
  Widget _buildNoContractsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.description_outlined,
              size: 32,
              color: const Color(0xFF8B5CF6),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun Contrat Actif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de contrat d\'assurance. Commencez par faire une demande.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openNewInsuranceRequest(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Demande'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 💰 Section Prochaines Échéances
  Widget _buildUpcomingPayments() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prochaines Échéances',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('paiements')
              .where('conducteurId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[600]),
                    const SizedBox(width: 12),
                    const Text('Erreur lors du chargement des échéances'),
                  ],
                ),
              );
            }

            final allPaiements = snapshot.data?.docs ?? [];

            // Filtrer les paiements en attente côté client
            final paiements = allPaiements.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final statut = data['statut'] ?? '';
              return statut == 'en_attente';
            }).take(3).toList();

            if (paiements.isEmpty) {
              return _buildNoPaymentsCard();
            }

            return Column(
              children: paiements.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildPaymentCard(doc.id, data);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  /// 💰 Carte de paiement
  Widget _buildPaymentCard(String paymentId, Map<String, dynamic> data) {
    final dateEcheance = (data['dateEcheance'] as Timestamp?)?.toDate();
    final montant = data['montant']?.toDouble() ?? 0.0;
    final frequence = data['frequencePaiement'] ?? 'annuel';
    final numeroContrat = data['numeroContrat'] ?? 'N/A';

    if (dateEcheance == null) return const SizedBox.shrink();

    final maintenant = DateTime.now();
    final difference = dateEcheance.difference(maintenant).inDays;

    Color urgencyColor;
    String urgencyText;
    IconData urgencyIcon;

    if (difference < 0) {
      urgencyColor = Colors.red;
      urgencyText = 'EN RETARD';
      urgencyIcon = Icons.warning;
    } else if (difference <= 3) {
      urgencyColor = Colors.orange;
      urgencyText = 'URGENT';
      urgencyIcon = Icons.schedule;
    } else if (difference <= 15) {
      urgencyColor = Colors.blue;
      urgencyText = 'BIENTÔT';
      urgencyIcon = Icons.info;
    } else {
      urgencyColor = Colors.green;
      urgencyText = 'À VENIR';
      urgencyIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _openContratActif(),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: urgencyColor.withOpacity(0.3)),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${montant.toStringAsFixed(2)} DT',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contrat N° $numeroContrat',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgencyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(urgencyIcon, size: 14, color: urgencyColor),
                        const SizedBox(width: 4),
                        Text(
                          urgencyText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: urgencyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Text(
                    'Échéance: ${_formatDate(dateEcheance)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.repeat, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    _getFrequenceLabel(frequence),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              if (difference <= 3) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: urgencyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.payment, size: 16, color: urgencyColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          difference < 0
                              ? 'Paiement en retard de ${difference.abs()} jour(s)'
                              : 'Paiement dû dans $difference jour(s)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: urgencyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// 💰 Carte quand il n'y a pas de paiements en attente
  Widget _buildNoPaymentsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
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
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 32,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucun Paiement en Attente',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tous vos paiements sont à jour. Vous recevrez une notification avant la prochaine échéance.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference == 0) {
      return 'Aujourd\'hui';
    } else if (difference == 1) {
      return 'Demain';
    } else if (difference == -1) {
      return 'Hier';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// 🔄 Obtenir le label de fréquence
  String _getFrequenceLabel(String frequence) {
    switch (frequence) {
      case 'annuel':
        return 'Annuel';
      case 'trimestriel':
        return 'Trimestriel';
      case 'mensuel':
        return 'Mensuel';
      default:
        return frequence;
    }
  }

  Widget _buildMyVehicles() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Mes véhicules',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/conducteur/vehicules');
              },
              child: const Text('Voir tout'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('demandes_contrats')
              .where('conducteurId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('statut', isEqualTo: 'contrat_actif')
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyVehicles();
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildVehicleCard(data);
              }).toList(),
            );
          },
        ),
        ],
      ),
    );
  }

  Widget _buildEmptyVehicles() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun véhicule assuré',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez par faire une demande d\'assurance',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openNewInsuranceRequest(),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle demande'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.directions_car,
              color: Color(0xFF3B82F6),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data['marque'] ?? 'N/A'} ${data['modele'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  data['immatriculation'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  'Contrat: ${data['numeroContrat'] ?? 'N/A'}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Actif',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRequests() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mes demandes en cours',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('insurance_requests')
              .where('conducteurId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
              .where('statut', whereIn: ['en_attente', 'affectee', 'en_cours'])
              .orderBy('dateCreation', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _buildEmptyRequests();
            }

            return Column(
              children: snapshot.data!.docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _buildRequestCard(data);
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyRequests() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 32,
            color: Colors.grey[400],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aucune demande en cours',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                Text(
                  'Toutes vos demandes ont été traitées',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> data) {
    final vehicule = data['vehicule'] ?? {};
    final statut = data['statut'] ?? 'en_attente';

    Color statusColor;
    String statusText;

    switch (statut) {
      case 'en_attente':
        statusColor = const Color(0xFFF59E0B);
        statusText = 'En attente';
        break;
      case 'affectee':
        statusColor = const Color(0xFF3B82F6);
        statusText = 'Affectée';
        break;
      case 'en_cours':
        statusColor = const Color(0xFF8B5CF6);
        statusText = 'En cours';
        break;
      default:
        statusColor = Colors.grey;
        statusText = statut;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.assignment,
              color: statusColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${vehicule['marque'] ?? 'N/A'} ${vehicule['modele'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  vehicule['immatriculation'] ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activité récente',
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
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Icon(
                Icons.history,
                size: 32,
                color: Colors.grey[400],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Aucune activité récente',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    Text(
                      'Vos dernières actions apparaîtront ici',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _openNewInsuranceRequest() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Nouvelle Demande')),
          body: const Center(child: Text('Fonctionnalité en cours de développement')),
        ),
      ),
    );

    if (result == true) {
      // Rafraîchir les données si la demande a été soumise avec succès
      setState(() {});
    }
  }

  /// 📄 Ouvrir l'écran de contrat actif
  void _openContratActif() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Vous devez être connecté'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Vérifier s'il y a un contrat actif
      final contratSnapshot = await FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: user.uid)
          .where('statut', isEqualTo: 'contrat_actif')
          .limit(1)
          .get();

      if (contratSnapshot.docs.isEmpty) {
        // Pas de contrat actif, proposer de faire une demande
        _showNoContractDialog();
        return;
      }

      // Naviguer vers l'écran de contrat actif
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ContratActifScreen(),
        ),
      );

      if (result == true) {
        // Rafraîchir les données si nécessaire
        setState(() {});
      }
    } catch (e) {
      print('❌ Erreur ouverture contrat actif: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 💬 Afficher le dialogue quand il n'y a pas de contrat actif
  void _showNoContractDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[600]),
            const SizedBox(width: 12),
            const Text('Aucun Contrat Actif'),
          ],
        ),
        content: const Text(
          'Vous n\'avez pas encore de contrat d\'assurance actif. Souhaitez-vous faire une nouvelle demande ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _openNewInsuranceRequest();
            },
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle Demande'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openContratActif() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ContratActifScreen(),
      ),
    );
  }

  void _openNewInsuranceRequest() {
    // TODO: Implémenter la navigation vers la nouvelle demande
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nouvelle demande - À implémenter')),
    );
  }

  void _openMesVehicules() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const MesVehiculesScreen(),
      ),
    );
  }

  /// 📄 Télécharger l'attestation d'assurance
  Future<void> _downloadAttestation(String contractId, Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Génération de l\'attestation...'),
          backgroundColor: Colors.blue,
        ),
      );

      final filePath = await DocumentDownloadService.generateAttestationAssurance(
        contratId: contractId,
        contratData: data,
      );

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Attestation téléchargée: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ouvrir',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Ouvrir le fichier avec l'application par défaut
              },
            ),
          ),
        );
      } else {
        throw Exception('Erreur lors de la génération');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 📅 Télécharger l'échéancier des paiements
  Future<void> _downloadEcheancier(String contractId, Map<String, dynamic> data) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📅 Génération de l\'échéancier...'),
          backgroundColor: Colors.purple,
        ),
      );

      final filePath = await DocumentDownloadService.generateEcheancier(
        contratId: contractId,
        contratData: data,
      );

      if (filePath != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Échéancier téléchargé: ${filePath.split('/').last}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Ouvrir',
              textColor: Colors.white,
              onPressed: () {
                // TODO: Ouvrir le fichier avec l'application par défaut
              },
            ),
          ),
        );
      } else {
        throw Exception('Erreur lors de la génération');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
