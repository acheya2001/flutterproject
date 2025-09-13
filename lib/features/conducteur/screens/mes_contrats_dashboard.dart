import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MesContratsDashboard extends StatefulWidget {
  final String? contractId; // Pour redirection depuis notification
  
  const MesContratsDashboard({
    Key? key,
    this.contractId,
  }) : super(key: key);

  @override
  State<MesContratsDashboard> createState() => _MesContratsDashboardState();
}

class _MesContratsDashboardState extends State<MesContratsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String? _currentUserId;
  bool _isLoading = true;
  List<Map<String, dynamic>> _contrats = [];
  Map<String, dynamic>? _selectedContract;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _getCurrentUser();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
      await _loadContrats();
    }
  }

  Future<void> _loadContrats() async {
    if (_currentUserId == null) return;

    try {
      setState(() => _isLoading = true);

      // Charger tous les contrats du conducteur (sans orderBy pour éviter l'erreur d'index)
      final contratsQuery = await FirebaseFirestore.instance
          .collection('contrats')
          .where('conducteurId', isEqualTo: _currentUserId)
          .get();

      final contrats = contratsQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Trier localement par date de création (plus récent en premier)
      contrats.sort((a, b) {
        final dateA = a['dateCreation'] as Timestamp?;
        final dateB = b['dateCreation'] as Timestamp?;

        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;

        return dateB.compareTo(dateA);
      });

      setState(() {
        _contrats = contrats;

        // Si aucun contrat trouvé, créer des données de démonstration
        if (contrats.isEmpty) {
          _contrats = _createDemoContracts();
        }

        // Si on a un contractId spécifique (depuis notification), le sélectionner
        if (widget.contractId != null) {
          _selectedContract = _contrats.firstWhere(
            (c) => c['id'] == widget.contractId,
            orElse: () => _contrats.isNotEmpty ? _contrats.first : {},
          );
        } else if (_contrats.isNotEmpty) {
          _selectedContract = _contrats.first;
        }

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _createDemoContracts() {
    return [
      {
        'id': 'demo_contract_1',
        'numeroContrat': 'ASS-2024-001',
        'statut': 'Actif',
        'dateDebut': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'dateFin': Timestamp.fromDate(DateTime.now().add(const Duration(days: 335))),
        'dateCreation': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 30))),
        'frequencePaiement': 'mensuel',
        'primeAnnuelle': 960,
        'conducteurId': _currentUserId,
        'vehicule': {
          'marque': 'Peugeot',
          'modele': '208',
          'annee': 2022,
          'immatriculation': '123 TUN 456',
          'couleur': 'Blanc',
          'puissance': '90 CV',
          'carburant': 'Essence',
        },
        'garanties': {
          'responsabiliteCivile': true,
          'collision': true,
          'vol': true,
          'incendie': true,
          'brisDeGlace': true,
          'assistanceDepannage': true,
        },
      },
      {
        'id': 'demo_contract_2',
        'numeroContrat': 'ASS-2024-002',
        'statut': 'Actif',
        'dateDebut': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'dateFin': Timestamp.fromDate(DateTime.now().add(const Duration(days: 305))),
        'dateCreation': Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 60))),
        'frequencePaiement': 'trimestriel',
        'primeAnnuelle': 1200,
        'conducteurId': _currentUserId,
        'vehicule': {
          'marque': 'Renault',
          'modele': 'Clio',
          'annee': 2021,
          'immatriculation': '789 TUN 012',
          'couleur': 'Rouge',
          'puissance': '75 CV',
          'carburant': 'Diesel',
        },
        'garanties': {
          'responsabiliteCivile': true,
          'collision': true,
          'vol': false,
          'incendie': true,
          'brisDeGlace': false,
          'assistanceDepannage': true,
        },
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildModernAppBar(),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_contrats.isEmpty)
            _buildEmptyState()
          else
            SliverFillRemaining(
              child: Column(
                children: [
                  _buildContractSelector(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildDocumentsTab(),
                        _buildPaiementsTab(),
                        _buildDetailsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.transparent,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF667EEA),
                Color(0xFF764BA2),
                Color(0xFF667EEA),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.description,
                          color: Colors.white,
                          size: 28,
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
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Documents et paiements',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_selectedContract != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Contrat N° ${_selectedContract!['numeroContrat'] ?? 'N/A'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Container(
          color: Colors.white,
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF667EEA),
            unselectedLabelColor: Colors.grey[600],
            indicatorColor: const Color(0xFF667EEA),
            tabs: const [
              Tab(text: 'Documents'),
              Tab(text: 'Paiements'),
              Tab(text: 'Détails'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.description_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun contrat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos contrats d\'assurance apparaîtront ici',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractSelector() {
    if (_contrats.length <= 1) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<Map<String, dynamic>>(
          value: _selectedContract,
          isExpanded: true,
          hint: const Text('Sélectionner un contrat'),
          items: _contrats.map((contrat) {
            return DropdownMenuItem<Map<String, dynamic>>(
              value: contrat,
              child: Text(
                'Contrat ${contrat['numeroContrat']} - ${contrat['vehicule']?['marque']} ${contrat['vehicule']?['modele']}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (contrat) {
            setState(() {
              _selectedContract = contrat;
            });
          },
        ),
      ),
    );
  }

  Widget _buildDocumentsTab() {
    if (_selectedContract == null) {
      return const Center(child: Text('Aucun contrat sélectionné'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDocumentCard(
            'Attestation d\'Assurance',
            'Document officiel prouvant votre couverture',
            Icons.verified_user,
            Colors.green,
            () => _downloadDocument('attestation'),
          ),
          const SizedBox(height: 12),
          _buildDocumentCard(
            'Conditions Générales',
            'Termes et conditions de votre contrat',
            Icons.gavel,
            Colors.blue,
            () => _downloadDocument('conditions'),
          ),
          const SizedBox(height: 12),
          _buildDocumentCard(
            'Reçu de Paiement',
            'Justificatif de votre dernier paiement',
            Icons.receipt,
            Colors.orange,
            () => _downloadDocument('recu'),
          ),
          const SizedBox(height: 12),
          _buildDocumentCard(
            'Fiche des Garanties',
            'Détail de vos couvertures d\'assurance',
            Icons.security,
            Colors.purple,
            () => _downloadDocument('garanties'),
          ),
          const SizedBox(height: 12),
          if (_selectedContract!['frequencePaiement'] != 'annuel')
            _buildDocumentCard(
              'Échéancier des Paiements',
              'Calendrier de vos prochains paiements',
              Icons.schedule,
              Colors.teal,
              () => _downloadDocument('echeancier'),
            ),
        ],
      ),
    );
  }

  Widget _buildPaiementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHistoriquePaiements(),
          const SizedBox(height: 24),
          _buildProchainsPaiements(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    if (_selectedContract == null) {
      return const Center(child: Text('Aucun contrat sélectionné'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildContractDetails(),
          const SizedBox(height: 24),
          _buildVehicleDetails(),
          const SizedBox(height: 24),
          _buildCoverageDetails(),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    // Simuler des dates et statuts pour les documents
    final Map<String, Map<String, String>> documentInfo = {
      'Attestation d\'Assurance': {'date': '15/12/2024', 'status': 'Disponible', 'size': '245 KB'},
      'Conditions Générales': {'date': '10/12/2024', 'status': 'Disponible', 'size': '1.2 MB'},
      'Reçu de Paiement': {'date': '12/12/2024', 'status': 'Disponible', 'size': '156 KB'},
      'Fiche des Garanties': {'date': '10/12/2024', 'status': 'Disponible', 'size': '320 KB'},
      'Échéancier des Paiements': {'date': '10/12/2024', 'status': 'Disponible', 'size': '180 KB'},
    };

    final info = documentInfo[title] ?? {'date': 'N/A', 'status': 'Indisponible', 'size': 'N/A'};
    final isAvailable = info['status'] == 'Disponible';

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: isAvailable ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                Colors.white,
                color.withValues(alpha: 0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.1),
                        color.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isAvailable ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              info['status']!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isAvailable ? Colors.green[700] : Colors.orange[700],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${info['date']} • ${info['size']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isAvailable ? color.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isAvailable ? Icons.download : Icons.schedule,
                    color: isAvailable ? color : Colors.grey[400],
                    size: 22,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoriquePaiements() {
    // Simuler un historique de paiements plus complet
    final paiements = [
      {
        'type': 'Paiement initial',
        'montant': '850 DT',
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'status': 'Validé',
        'methode': 'Carte bancaire',
        'reference': 'PAY-2024-001',
      },
      {
        'type': 'Frais de dossier',
        'montant': '50 DT',
        'date': DateTime.now().subtract(const Duration(days: 30)),
        'status': 'Validé',
        'methode': 'Carte bancaire',
        'reference': 'PAY-2024-002',
      },
      if (_selectedContract?['frequencePaiement'] == 'mensuel') ...[
        {
          'type': 'Paiement mensuel',
          'montant': '80 DT',
          'date': DateTime.now().subtract(const Duration(days: 60)),
          'status': 'Validé',
          'methode': 'Prélèvement automatique',
          'reference': 'PAY-2024-003',
        },
        {
          'type': 'Paiement mensuel',
          'montant': '80 DT',
          'date': DateTime.now().subtract(const Duration(days: 90)),
          'status': 'Validé',
          'methode': 'Prélèvement automatique',
          'reference': 'PAY-2024-004',
        },
      ],
      if (_selectedContract?['frequencePaiement'] == 'trimestriel') ...[
        {
          'type': 'Paiement trimestriel',
          'montant': '230 DT',
          'date': DateTime.now().subtract(const Duration(days: 90)),
          'status': 'Validé',
          'methode': 'Virement bancaire',
          'reference': 'PAY-2024-003',
        },
      ],
    ];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              Colors.blue.withValues(alpha: 0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withValues(alpha: 0.1),
                          Colors.blue.withValues(alpha: 0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.history, color: Colors.blue[600], size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Historique des Paiements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${paiements.length} paiements',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ...paiements.map((paiement) => _buildPaiementItemEnhanced(
                paiement['type'] as String,
                paiement['montant'] as String,
                paiement['date'] as DateTime,
                paiement['status'] as String,
                paiement['methode'] as String,
                paiement['reference'] as String,
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProchainsPaiements() {
    if (_selectedContract?['frequencePaiement'] == 'annuel') {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.orange[600], size: 24),
                  const SizedBox(width: 12),
                  const Text(
                    'Prochains Paiements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Paiement annuel - Prochain renouvellement dans 11 mois',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.schedule, color: Colors.orange[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Prochains Paiements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPaiementItem(
              _selectedContract?['frequencePaiement'] == 'mensuel'
                  ? 'Paiement mensuel'
                  : 'Paiement trimestriel',
              _selectedContract?['frequencePaiement'] == 'mensuel'
                  ? '80 DT'
                  : '230 DT',
              DateTime.now().add(Duration(
                days: _selectedContract?['frequencePaiement'] == 'mensuel' ? 30 : 90
              )),
              'À venir',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaiementItemEnhanced(String titre, String montant, DateTime date, String statut, String methode, String reference) {
    final isValidated = statut == 'Validé';
    final statusColor = isValidated ? Colors.green : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isValidated ? Icons.check_circle : Icons.schedule,
                    color: statusColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titre,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('dd MMMM yyyy', 'fr_FR').format(date),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      montant,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statut,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.payment, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Méthode: $methode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Réf: $reference',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontFamily: 'monospace',
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

  Widget _buildPaiementItem(String titre, String montant, DateTime date, String statut, Color couleur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy').format(date),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                montant,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: couleur,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: couleur,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statut,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContractDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: Colors.blue[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Informations du Contrat',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Numéro de contrat', _selectedContract?['numeroContrat'] ?? 'N/A'),
            _buildDetailRow('Statut', _selectedContract?['statut'] ?? 'N/A'),
            _buildDetailRow('Date de début', _formatDate(_selectedContract?['dateDebut'])),
            _buildDetailRow('Date de fin', _formatDate(_selectedContract?['dateFin'])),
            _buildDetailRow('Fréquence de paiement', _getFrequenceLabel(_selectedContract?['frequencePaiement'])),
            _buildDetailRow('Prime annuelle', '${_selectedContract?['primeAnnuelle'] ?? 'N/A'} DT'),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleDetails() {
    final vehicule = _selectedContract?['vehicule'] as Map<String, dynamic>?;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.green[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Véhicule Assuré',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Marque', vehicule?['marque'] ?? 'N/A'),
            _buildDetailRow('Modèle', vehicule?['modele'] ?? 'N/A'),
            _buildDetailRow('Année', vehicule?['annee']?.toString() ?? 'N/A'),
            _buildDetailRow('Immatriculation', vehicule?['immatriculation'] ?? 'N/A'),
            _buildDetailRow('Numéro de série', vehicule?['numeroSerie'] ?? 'N/A'),
            _buildDetailRow('Puissance fiscale', '${vehicule?['puissanceFiscale'] ?? 'N/A'} CV'),
          ],
        ),
      ),
    );
  }

  Widget _buildCoverageDetails() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: Colors.purple[600], size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Garanties et Couvertures',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildGarantieItem('Responsabilité Civile', 'Obligatoire', Colors.green),
            _buildGarantieItem('Dommages Collision', 'Incluse', Colors.blue),
            _buildGarantieItem('Vol et Incendie', 'Incluse', Colors.orange),
            _buildGarantieItem('Bris de Glace', 'Incluse', Colors.purple),
            _buildGarantieItem('Assistance 24h/24', 'Incluse', Colors.teal),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGarantieItem(String nom, String statut, Color couleur) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: couleur, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              nom,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              statut,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    if (date is Timestamp) {
      return DateFormat('dd/MM/yyyy').format(date.toDate());
    } else if (date is DateTime) {
      return DateFormat('dd/MM/yyyy').format(date);
    } else if (date is String) {
      try {
        final parsedDate = DateTime.parse(date);
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        return date;
      }
    }

    return 'N/A';
  }

  String _getFrequenceLabel(String? frequence) {
    switch (frequence) {
      case 'annuel':
        return 'Paiement Annuel';
      case 'trimestriel':
        return 'Paiement Trimestriel';
      case 'mensuel':
        return 'Paiement Mensuel';
      default:
        return 'N/A';
    }
  }

  Future<void> _downloadDocument(String type) async {
    // Afficher un dialog de confirmation avec plus d'informations
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(_getDocumentIcon(type), color: _getDocumentColor(type)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Télécharger le document',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Document: ${_getDocumentTitle(type)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Taille: ${_getDocumentSize(type)}',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Format: PDF',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Le document sera téléchargé dans votre dossier de téléchargements.',
                      style: TextStyle(fontSize: 12, color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.download),
            label: const Text('Télécharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getDocumentColor(type),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Afficher un indicateur de progression
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Génération du document en cours...'),
              const SizedBox(height: 8),
              Text(
                _getDocumentTitle(type),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );

      // Simuler la génération du document
      await Future.delayed(const Duration(seconds: 3));

      // Fermer le dialog de progression
      Navigator.pop(context);

      // Afficher le succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Document téléchargé avec succès',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _getDocumentTitle(type),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Ouvrir',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Ouvrir le document téléchargé
            },
          ),
        ),
      );
    } catch (e) {
      // Fermer le dialog de progression si ouvert
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'attestation': return Icons.verified_user;
      case 'conditions': return Icons.gavel;
      case 'recu': return Icons.receipt;
      case 'garanties': return Icons.security;
      case 'echeancier': return Icons.schedule;
      default: return Icons.description;
    }
  }

  Color _getDocumentColor(String type) {
    switch (type) {
      case 'attestation': return Colors.green;
      case 'conditions': return Colors.blue;
      case 'recu': return Colors.orange;
      case 'garanties': return Colors.purple;
      case 'echeancier': return Colors.teal;
      default: return Colors.grey;
    }
  }

  String _getDocumentTitle(String type) {
    switch (type) {
      case 'attestation': return 'Attestation d\'Assurance';
      case 'conditions': return 'Conditions Générales';
      case 'recu': return 'Reçu de Paiement';
      case 'garanties': return 'Fiche des Garanties';
      case 'echeancier': return 'Échéancier des Paiements';
      default: return 'Document';
    }
  }

  String _getDocumentSize(String type) {
    switch (type) {
      case 'attestation': return '245 KB';
      case 'conditions': return '1.2 MB';
      case 'recu': return '156 KB';
      case 'garanties': return '320 KB';
      case 'echeancier': return '180 KB';
      default: return 'N/A';
    }
  }
}
