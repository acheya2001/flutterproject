import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/agent_service.dart';

/// 🚨 Écran de gestion des sinistres
class SinistresScreen extends StatefulWidget {
  final Map<String, dynamic> agentData;
  final Map<String, dynamic> userData;

  const SinistresScreen({
    Key? key,
    required this.agentData,
    required this.userData,
  }) : super(key: key);

  @override
  State<SinistresScreen> createState() => _SinistresScreenState();
}

class _SinistresScreenState extends State<SinistresScreen> with TickerProviderStateMixin {
  List<Map<String, dynamic>> _sinistres = [];
  List<Map<String, dynamic>> _constatsFinalises = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Utiliser safeInit pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSinistres();
      _loadConstatsFinalises();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// 🚨 Charger les sinistres
  Future<void> _loadSinistres() async {
    setState(() => _isLoading = true);

    try {
      final sinistres = await AgentService.getAgentSinistres(widget.agentData['id']);
      setState(() => _sinistres = sinistres);
    } catch (e) {
      debugPrint('[SINISTRES] ❌ Erreur chargement sinistres: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📄 Charger les constats finalisés pour cet agent
  Future<void> _loadConstatsFinalises() async {
    try {
      final agentId = widget.agentData['id'];

      // Récupérer les notifications de constats finalisés pour cet agent
      final notificationsQuery = await FirebaseFirestore.instance
          .collection('notifications_agents')
          .where('destinataire', isEqualTo: widget.agentData['email'])
          .where('type', isEqualTo: 'constat_finalise')
          .orderBy('dateCreation', descending: true)
          .get();

      final constats = <Map<String, dynamic>>[];

      for (final doc in notificationsQuery.docs) {
        final notification = doc.data();
        final sessionId = notification['sessionId'] as String?;
        final contratId = notification['contratId'] as String?;

        if (sessionId != null && contratId != null) {
          // Récupérer les détails du contrat
          final contratDoc = await FirebaseFirestore.instance
              .collection('contrats')
              .doc(contratId)
              .get();

          if (contratDoc.exists) {
            final contratData = contratDoc.data()!;

            constats.add({
              'id': doc.id,
              'sessionId': sessionId,
              'contratId': contratId,
              'dateCreation': notification['dateCreation'],
              'statut': notification['statut'],
              'pdfUrl': notification['pdfUrl'],
              'contratData': contratData,
              'participantData': notification['participantData'],
            });
          }
        }
      }

      setState(() => _constatsFinalises = constats);

    } catch (e) {
      debugPrint('[CONSTATS] ❌ Erreur chargement constats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Contenu principal
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
                  child: _isLoading ? _buildLoadingContent() : _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _declarerSinistre,
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.report_problem_rounded),
        label: const Text('Déclarer Sinistre'),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.warning_rounded,
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
                  'Gestion des Sinistres',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_sinistres.length} sinistre(s) traité(s)',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🔄 Contenu de chargement
  Widget _buildLoadingContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFFEF4444)),
          SizedBox(height: 20),
          Text(
            'Chargement des sinistres...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal avec onglets
  Widget _buildMainContent() {
    return Column(
      children: [
        // TabBar
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(25),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(25),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Colors.grey[600],
            labelStyle: const TextStyle(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Sinistres Déclarés'),
              Tab(text: 'Constats Reçus'),
            ],
          ),
        ),

        // TabBarView
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSinistresTab(),
              _buildConstatsTab(),
            ],
          ),
        ),
      ],
    );
  }

  /// 🚨 Onglet des sinistres déclarés
  Widget _buildSinistresTab() {
    if (_sinistres.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _sinistres.length,
      itemBuilder: (context, index) {
        final sinistre = _sinistres[index];
        return _buildSinistreCard(sinistre);
      },
    );
  }

  /// 📄 Onglet des constats finalisés reçus
  Widget _buildConstatsTab() {
    if (_constatsFinalises.isEmpty) {
      return _buildEmptyConstatsState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _constatsFinalises.length,
      itemBuilder: (context, index) {
        return _buildConstatCard(_constatsFinalises[index]);
      },
    );
  }

  /// 🚨 Carte de sinistre
  Widget _buildSinistreCard(Map<String, dynamic> sinistre) {
    final statut = sinistre['statut'] ?? 'ouvert';
    Color statutColor;
    
    switch (statut) {
      case 'ouvert':
        statutColor = Colors.orange;
        break;
      case 'en_cours':
        statutColor = Colors.blue;
        break;
      case 'clos':
        statutColor = Colors.green;
        break;
      case 'rejete':
        statutColor = Colors.red;
        break;
      default:
        statutColor = Colors.grey;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_rounded,
                    color: statutColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sinistre['numeroSinistre'] ?? 'N° non défini',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        sinistre['typeSinistre'] ?? 'Type non défini',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statut.toUpperCase(),
                    style: TextStyle(
                      color: statutColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSinistreInfo('Date', _formatDate(sinistre['dateSinistre'])),
                ),
                Expanded(
                  child: _buildSinistreInfo('Lieu', sinistre['lieuSinistre'] ?? 'N/A'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📝 Information du sinistre
  Widget _buildSinistreInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  /// 📭 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun sinistre déclaré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Heureusement, aucun sinistre n\'a été déclaré',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),
          ElevatedButton.icon(
            onPressed: _declarerSinistre,
            icon: const Icon(Icons.report_problem_rounded),
            label: const Text('Déclarer un Sinistre'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 🚨 Déclarer un sinistre
  void _declarerSinistre() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Déclaration de sinistre - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return 'Non défini';
    
    try {
      DateTime dateTime;
      if (date is DateTime) {
        dateTime = date;
      } else {
        dateTime = date.toDate();
      }
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Format invalide';
    }
  }

  /// 📄 État vide pour les constats
  Widget _buildEmptyConstatsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.description_outlined,
              size: 60,
              color: Colors.blue.shade300,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucun constat reçu',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les constats finalisés pour vos contrats\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Carte de constat finalisé
  Widget _buildConstatCard(Map<String, dynamic> constat) {
    final contratData = constat['contratData'] as Map<String, dynamic>;
    final participantData = constat['participantData'] as Map<String, dynamic>? ?? {};
    final donneesFormulaire = participantData['donneesFormulaire'] as Map<String, dynamic>? ?? {};
    final donneesPersonnelles = donneesFormulaire['donneesPersonnelles'] as Map<String, dynamic>? ?? {};
    final donneesVehicule = donneesFormulaire['donneesVehicule'] as Map<String, dynamic>? ?? {};

    final conducteurNom = '${donneesPersonnelles['prenom'] ?? ''} ${donneesPersonnelles['nom'] ?? ''}'.trim();
    final vehiculeInfo = '${donneesVehicule['marque'] ?? ''} ${donneesVehicule['modele'] ?? ''}'.trim();
    final immatriculation = donneesVehicule['immatriculation'] ?? '';
    final numeroPolice = contratData['numeroPolice'] ?? '';

    final statut = constat['statut'] ?? 'en_attente';
    Color statutColor;
    String statutText;

    switch (statut) {
      case 'en_attente':
        statutColor = Colors.orange;
        statutText = 'En attente';
        break;
      case 'envoye':
        statutColor = Colors.green;
        statutText = 'Traité';
        break;
      case 'erreur':
        statutColor = Colors.red;
        statutText = 'Erreur';
        break;
      default:
        statutColor = Colors.grey;
        statutText = 'Inconnu';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec statut
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statutText,
                    style: TextStyle(
                      color: statutColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(constat['dateCreation']),
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Informations du contrat
            Row(
              children: [
                Icon(Icons.assignment, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contrat: $numeroPolice',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Informations du véhicule
            Row(
              children: [
                Icon(Icons.directions_car, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$vehiculeInfo ($immatriculation)',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Conducteur
            if (conducteurNom.isNotEmpty) ...[
              Row(
                children: [
                  Icon(Icons.person, color: Colors.orange.shade600, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Conducteur: $conducteurNom',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Actions
            Row(
              children: [
                if (constat['pdfUrl'] != null) ...[
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _ouvrirPDF(constat['pdfUrl']),
                      icon: const Icon(Icons.picture_as_pdf, size: 16),
                      label: const Text('Voir PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _voirDetailsConstat(constat),
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('Détails'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 📄 Ouvrir le PDF du constat
  void _ouvrirPDF(String pdfUrl) {
    // TODO: Implémenter l'ouverture du PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ouverture du PDF: $pdfUrl'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 👁️ Voir les détails du constat
  void _voirDetailsConstat(Map<String, dynamic> constat) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Détails du Constat'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Session: ${constat['sessionId']}'),
              const SizedBox(height: 8),
              Text('Contrat: ${constat['contratId']}'),
              const SizedBox(height: 8),
              Text('Statut: ${constat['statut']}'),
              const SizedBox(height: 8),
              Text('Date: ${_formatDate(constat['dateCreation'])}'),
              if (constat['pdfUrl'] != null) ...[
                const SizedBox(height: 8),
                Text('PDF disponible: Oui'),
              ],
            ],
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
  }
}

