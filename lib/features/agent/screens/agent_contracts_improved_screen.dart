import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'sinistres_contrat_screen.dart';

/// 📋 Écran amélioré des contrats de l'agent avec filtrage et renouvellement
class AgentContractsImprovedScreen extends StatefulWidget {
  const AgentContractsImprovedScreen({Key? key}) : super(key: key);

  @override
  State<AgentContractsImprovedScreen> createState() => _AgentContractsImprovedScreenState();
}

class _AgentContractsImprovedScreenState extends State<AgentContractsImprovedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _agentId;
  String _filtreStatut = 'tous';
  String _rechercheText = '';
  final TextEditingController _rechercheController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _agentId = _auth.currentUser?.uid;
  }

  @override
  void dispose() {
    _rechercheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        title: const Text(
          'Mes Contrats',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _agentId == null
          ? const Center(
              child: Text(
                'Erreur: Agent non connecté',
                style: TextStyle(color: Colors.white),
              ),
            )
          : Column(
              children: [
                _buildFiltersSection(),
                Expanded(child: _buildContractsList()),
              ],
            ),
    );
  }

  /// 🔍 Section des filtres
  Widget _buildFiltersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Barre de recherche
          TextField(
            controller: _rechercheController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Rechercher par nom, véhicule, contrat...',
              hintStyle: TextStyle(color: Colors.grey[400]),
              prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
              suffixIcon: _rechercheText.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey[400]),
                      onPressed: () {
                        _rechercheController.clear();
                        setState(() => _rechercheText = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: const Color(0xFF334155),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (value) => setState(() => _rechercheText = value.toLowerCase()),
          ),
          
          const SizedBox(height: 16),
          
          // Filtres par statut
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('tous', 'Tous', Icons.list),
                _buildFilterChip('contrat_actif', 'Actifs', Icons.check_circle),
                _buildFilterChip('en_attente_paiement', 'En attente', Icons.schedule),
                _buildFilterChip('expire', 'Expirés', Icons.error),
                _buildFilterChip('frequence_choisie', 'Paiement choisi', Icons.payment),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷️ Chip de filtre
  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filtreStatut == value;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.grey[400]),
            const SizedBox(width: 4),
            Text(label),
          ],
        ),
        onSelected: (selected) => setState(() => _filtreStatut = value),
        selectedColor: const Color(0xFF10B981),
        backgroundColor: const Color(0xFF334155),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.grey[300],
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? const Color(0xFF10B981) : Colors.grey[600]!,
        ),
      ),
    );
  }

  /// 📋 Liste des contrats
  Widget _buildContractsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildContractsQuery(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error, color: Colors.red[400], size: 64),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF10B981)),
          );
        }

        final contrats = snapshot.data?.docs ?? [];
        final contratsFiltres = _filtrerContrats(contrats);

        if (contratsFiltres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment, color: Colors.grey[400], size: 64),
                const SizedBox(height: 16),
                Text(
                  _rechercheText.isNotEmpty 
                      ? 'Aucun contrat trouvé pour "$_rechercheText"'
                      : 'Aucun contrat ${_filtreStatut == "tous" ? "" : _getStatutLabel(_filtreStatut)}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: contratsFiltres.length,
          itemBuilder: (context, index) {
            final contrat = contratsFiltres[index];
            final data = contrat.data() as Map<String, dynamic>;
            return _buildContractCard(contrat.id, data);
          },
        );
      },
    );
  }

  /// 🔍 Construire la requête selon le filtre
  Stream<QuerySnapshot> _buildContractsQuery() {
    Query query = _firestore
        .collection('demandes_contrats')
        .where('agentId', isEqualTo: _agentId);

    // Filtrer par statut si nécessaire
    if (_filtreStatut != 'tous') {
      query = query.where('statut', isEqualTo: _filtreStatut);
    }

    // Éviter orderBy pour éviter les problèmes d'index composite
    return query.snapshots();
  }

  /// 🔍 Filtrer les contrats selon la recherche
  List<QueryDocumentSnapshot> _filtrerContrats(List<QueryDocumentSnapshot> contrats) {
    // D'abord trier par dateCreation (plus récent en premier)
    contrats.sort((a, b) {
      final dataA = a.data() as Map<String, dynamic>;
      final dataB = b.data() as Map<String, dynamic>;
      final dateA = dataA['dateCreation'] as Timestamp?;
      final dateB = dataB['dateCreation'] as Timestamp?;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA); // Plus récent en premier
    });

    if (_rechercheText.isEmpty) return contrats;

    return contrats.where((contrat) {
      final data = contrat.data() as Map<String, dynamic>;
      final searchableText = [
        data['nom']?.toString() ?? '',
        data['prenom']?.toString() ?? '',
        data['marque']?.toString() ?? '',
        data['modele']?.toString() ?? '',
        data['immatriculation']?.toString() ?? '',
        data['numeroContrat']?.toString() ?? '',
        data['numero']?.toString() ?? '',
      ].join(' ').toLowerCase();

      return searchableText.contains(_rechercheText);
    }).toList();
  }

  /// 📄 Carte de contrat
  Widget _buildContractCard(String contratId, Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final isExpire = _isContratExpire(data);
    final couleurStatut = _getCouleurStatut(statut, isExpire);
    final iconeStatut = _getIconeStatut(statut, isExpire);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleurStatut.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          // En-tête avec statut
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: couleurStatut.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Icon(iconeStatut, color: couleurStatut, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data['prenom']} ${data['nom']}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        _getStatutLabel(statut) + (isExpire ? ' (Expiré)' : ''),
                        style: TextStyle(
                          color: couleurStatut,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isExpire)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'EXPIRÉ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('🚗 Véhicule', '${data['marque']} ${data['modele']} (${data['immatriculation']})'),
                _buildInfoRow('📋 N° Contrat', data['numeroContrat'] ?? data['numero'] ?? contratId),
                _buildInfoRow('📧 Email', data['email'] ?? 'N/A'),
                _buildInfoRow('📞 Téléphone', data['telephone'] ?? 'N/A'),
                if (data['dateCreation'] != null)
                  _buildInfoRow('📅 Créé le', _formatDate(data['dateCreation'])),
                if (data['dateFinContrat'] != null)
                  _buildInfoRow('⏰ Expire le', _formatDate(data['dateFinContrat'])),
              ],
            ),
          ),
          
          // Actions
          _buildActionsSection(contratId, data, statut, isExpire),
        ],
      ),
    );
  }

  /// 📊 Ligne d'information
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ⚡ Section des actions
  Widget _buildActionsSection(String contratId, Map<String, dynamic> data, String statut, bool isExpire) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF334155),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Bouton Voir détails
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _voirDetailsContrat(contratId, data),
              icon: const Icon(Icons.visibility, size: 16),
              label: const Text('Voir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Bouton Sinistres
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _voirSinistresContrat(contratId, data),
              icon: const Icon(Icons.warning, size: 16),
              label: const Text('Sinistres'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton Contacter
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _contacterClient(data),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Contact'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Bouton Renouveler (si expiré)
          if (isExpire)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _renouvelerContrat(contratId, data),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Renouveler'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
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
    );
  }

  /// 🎨 Obtenir la couleur selon le statut
  Color _getCouleurStatut(String statut, bool isExpire) {
    if (isExpire) return Colors.red[600]!;

    switch (statut) {
      case 'contrat_actif':
        return Colors.green[600]!;
      case 'en_attente_paiement':
      case 'frequence_choisie':
        return Colors.orange[600]!;
      case 'expire':
        return Colors.red[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  /// 🎯 Obtenir l'icône selon le statut
  IconData _getIconeStatut(String statut, bool isExpire) {
    if (isExpire) return Icons.error;

    switch (statut) {
      case 'contrat_actif':
        return Icons.check_circle;
      case 'en_attente_paiement':
      case 'frequence_choisie':
        return Icons.schedule;
      case 'expire':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  /// 📝 Obtenir le label du statut
  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'contrat_actif':
        return 'Contrat Actif';
      case 'en_attente_paiement':
        return 'En attente paiement';
      case 'frequence_choisie':
        return 'Paiement choisi';
      case 'expire':
        return 'Expiré';
      case 'en_attente':
        return 'En attente';
      case 'affectee':
        return 'Affectée';
      case 'documents_manquants':
        return 'Documents manquants';
      default:
        return statut.replaceAll('_', ' ').toUpperCase();
    }
  }

  /// ⏰ Vérifier si le contrat est expiré
  bool _isContratExpire(Map<String, dynamic> data) {
    final dateFinContrat = data['dateFinContrat'];
    if (dateFinContrat == null) return false;

    try {
      DateTime dateFin;
      if (dateFinContrat is Timestamp) {
        dateFin = dateFinContrat.toDate();
      } else if (dateFinContrat is DateTime) {
        dateFin = dateFinContrat;
      } else {
        return false;
      }

      return dateFin.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'N/A';
      }
      return DateFormat('dd/MM/yyyy').format(dateTime);
    } catch (e) {
      return 'N/A';
    }
  }

  /// 👁️ Voir les détails du contrat
  void _voirDetailsContrat(String contratId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E293B),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.assignment, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Détails du Contrat',
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

              // Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailSection('👤 Informations Client', [
                        _buildDetailRow('Nom complet', '${data['prenom']} ${data['nom']}'),
                        _buildDetailRow('Email', data['email'] ?? 'N/A'),
                        _buildDetailRow('Téléphone', data['telephone'] ?? 'N/A'),
                        _buildDetailRow('CIN', data['cin'] ?? 'N/A'),
                        _buildDetailRow('Adresse', data['adresse'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('🚗 Informations Véhicule', [
                        _buildDetailRow('Marque', data['marque'] ?? 'N/A'),
                        _buildDetailRow('Modèle', data['modele'] ?? 'N/A'),
                        _buildDetailRow('Immatriculation', data['immatriculation'] ?? 'N/A'),
                        _buildDetailRow('Année', data['annee']?.toString() ?? 'N/A'),
                        _buildDetailRow('Couleur', data['couleur'] ?? 'N/A'),
                      ]),

                      const SizedBox(height: 20),

                      _buildDetailSection('📋 Informations Contrat', [
                        _buildDetailRow('N° Contrat', data['numeroContrat'] ?? data['numero'] ?? contratId),
                        _buildDetailRow('Statut', _getStatutLabel(data['statut'] ?? '')),
                        _buildDetailRow('Formule', data['formuleAssuranceLabel'] ?? data['formuleAssurance'] ?? 'N/A'),
                        if (data['dateCreation'] != null)
                          _buildDetailRow('Date création', _formatDate(data['dateCreation'])),
                        if (data['dateDebutContrat'] != null)
                          _buildDetailRow('Date début', _formatDate(data['dateDebutContrat'])),
                        if (data['dateFinContrat'] != null)
                          _buildDetailRow('Date fin', _formatDate(data['dateFinContrat'])),
                      ]),

                      if (data['primeAnnuelle'] != null || data['franchise'] != null)
                        Column(
                          children: [
                            const SizedBox(height: 20),
                            _buildDetailSection('💰 Informations Financières', [
                              if (data['primeAnnuelle'] != null)
                                _buildDetailRow('Prime annuelle', '${data['primeAnnuelle']} DT'),
                              if (data['franchise'] != null)
                                _buildDetailRow('Franchise', '${data['franchise']} DT'),
                              if (data['montantAPayer'] != null)
                                _buildDetailRow('Montant à payer', '${data['montantAPayer']} DT'),
                              if (data['frequencePaiement'] != null)
                                _buildDetailRow('Fréquence paiement', data['frequencePaiement']),
                            ]),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Section de détails
  Widget _buildDetailSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  /// 📊 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📞 Contacter le client
  void _contacterClient(Map<String, dynamic> data) {
    final email = data['email'] ?? '';
    final telephone = data['telephone'] ?? '';
    final nom = '${data['prenom']} ${data['nom']}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Color(0xFF1E293B),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Contacter $nom',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            if (telephone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Color(0xFF10B981)),
                title: const Text('Appeler', style: TextStyle(color: Colors.white)),
                subtitle: Text(telephone, style: TextStyle(color: Colors.grey[400])),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('tel:$telephone');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),

            if (email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email, color: Color(0xFF3B82F6)),
                title: const Text('Envoyer un email', style: TextStyle(color: Colors.white)),
                subtitle: Text(email, style: TextStyle(color: Colors.grey[400])),
                onTap: () async {
                  Navigator.pop(context);
                  final uri = Uri.parse('mailto:$email');
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),

            const SizedBox(height: 10),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔄 Renouveler le contrat
  void _renouvelerContrat(String contratId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Row(
          children: [
            Icon(Icons.refresh, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Renouveler le Contrat', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Voulez-vous renouveler le contrat de ${data['prenom']} ${data['nom']} ?',
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🚗 ${data['marque']} ${data['modele']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '📋 ${data['numeroContrat'] ?? data['numero'] ?? contratId}',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  Text(
                    '📅 Expiré le: ${_formatDate(data['dateFinContrat'])}',
                    style: TextStyle(color: Colors.red[400]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () => _confirmerRenouvellement(contratId, data),
            icon: const Icon(Icons.refresh),
            label: const Text('Renouveler'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Confirmer le renouvellement
  Future<void> _confirmerRenouvellement(String contratId, Map<String, dynamic> data) async {
    Navigator.pop(context); // Fermer le dialogue

    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          backgroundColor: Color(0xFF1E293B),
          content: Row(
            children: [
              CircularProgressIndicator(color: Color(0xFFF59E0B)),
              SizedBox(width: 16),
              Text('Renouvellement en cours...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      );

      // Calculer les nouvelles dates (1 an à partir d'aujourd'hui)
      final maintenant = DateTime.now();
      final nouvelleFinContrat = DateTime(maintenant.year + 1, maintenant.month, maintenant.day);

      // Créer un nouveau contrat basé sur l'ancien
      final nouveauContrat = Map<String, dynamic>.from(data);
      nouveauContrat.addAll({
        'statut': 'contrat_actif',
        'dateCreation': FieldValue.serverTimestamp(),
        'dateDebutContrat': Timestamp.fromDate(maintenant),
        'dateFinContrat': Timestamp.fromDate(nouvelleFinContrat),
        'numeroContrat': 'REN-${DateTime.now().millisecondsSinceEpoch}',
        'contratPrecedent': contratId,
        'typeRenouvellement': 'renouvellement_agent',
        'agentRenouvellement': _agentId,
        'dateRenouvellement': FieldValue.serverTimestamp(),
      });

      // Ajouter le nouveau contrat
      await _firestore.collection('demandes_contrats').add(nouveauContrat);

      // Marquer l'ancien contrat comme renouvelé
      await _firestore.collection('demandes_contrats').doc(contratId).update({
        'statut': 'renouvele',
        'dateRenouvellement': FieldValue.serverTimestamp(),
        'agentRenouvellement': _agentId,
      });

      Navigator.pop(context); // Fermer l'indicateur de chargement

      // Afficher le succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Contrat renouvelé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      Navigator.pop(context); // Fermer l'indicateur de chargement

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du renouvellement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// 🚨 Voir les sinistres d'un contrat
  void _voirSinistresContrat(String contratId, Map<String, dynamic> data) {
    // Naviguer vers l'écran des sinistres avec filtrage par contrat
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SinistresContratScreen(
          contratId: contratId,
          numeroContrat: data['numeroContrat'] ?? data['numero'] ?? contratId,
          nomAssure: '${data['prenom'] ?? ''} ${data['nom'] ?? ''}'.trim(),
          vehicule: '${data['marque'] ?? ''} ${data['modele'] ?? ''} (${data['immatriculation'] ?? ''})',
        ),
      ),
    );
  }
}
