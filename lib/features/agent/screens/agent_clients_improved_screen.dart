import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

/// 👥 Écran amélioré des clients de l'agent
class AgentClientsImprovedScreen extends StatefulWidget {
  const AgentClientsImprovedScreen({Key? key}) : super(key: key);

  @override
  State<AgentClientsImprovedScreen> createState() => _AgentClientsImprovedScreenState();
}

class _AgentClientsImprovedScreenState extends State<AgentClientsImprovedScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _agentId;
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
          'Mes Clients',
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
                _buildSearchSection(),
                Expanded(child: _buildClientsList()),
              ],
            ),
    );
  }

  /// 🔍 Section de recherche
  Widget _buildSearchSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1E293B),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: TextField(
        controller: _rechercheController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Rechercher par nom, email, téléphone...',
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
    );
  }

  /// 👥 Liste des clients
  Widget _buildClientsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('demandes_contrats')
          .where('agentId', isEqualTo: _agentId)
          .snapshots(),
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
        final clientsUniques = _extraireClientsUniques(contrats);
        final clientsFiltres = _filtrerClients(clientsUniques);

        if (clientsFiltres.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people, color: Colors.grey[400], size: 64),
                const SizedBox(height: 16),
                Text(
                  _rechercheText.isNotEmpty 
                      ? 'Aucun client trouvé pour "$_rechercheText"'
                      : 'Aucun client trouvé',
                  style: TextStyle(color: Colors.grey[400], fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: clientsFiltres.length,
          itemBuilder: (context, index) {
            final client = clientsFiltres[index];
            return _buildClientCard(client);
          },
        );
      },
    );
  }

  /// 👤 Extraire les clients uniques
  Map<String, Map<String, dynamic>> _extraireClientsUniques(List<QueryDocumentSnapshot> contrats) {
    // Trier les contrats par dateCreation (plus récent en premier)
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

    final Map<String, Map<String, dynamic>> clients = {};

    for (final contrat in contrats) {
      final data = contrat.data() as Map<String, dynamic>;
      final conducteurId = data['conducteurId'];
      final email = data['email'];
      
      // Utiliser conducteurId ou email comme clé unique
      final cleClient = conducteurId ?? email ?? contrat.id;
      
      if (!clients.containsKey(cleClient)) {
        // Compter les contrats de ce client
        final contratsClient = contrats.where((c) {
          final cData = c.data() as Map<String, dynamic>;
          final cConducteurId = cData['conducteurId'];
          final cEmail = cData['email'];
          final cCleClient = cConducteurId ?? cEmail ?? c.id;
          return cCleClient == cleClient;
        }).toList();

        final contratsActifs = contratsClient.where((c) {
          final cData = c.data() as Map<String, dynamic>;
          return cData['statut'] == 'contrat_actif';
        }).length;

        clients[cleClient] = {
          ...data,
          'clientId': cleClient,
          'nombreContrats': contratsClient.length,
          'contratsActifs': contratsActifs,
          'dernierContrat': contrat.id,
        };
      }
    }

    return clients;
  }

  /// 🔍 Filtrer les clients selon la recherche
  List<Map<String, dynamic>> _filtrerClients(Map<String, Map<String, dynamic>> clients) {
    final clientsList = clients.values.toList();
    
    if (_rechercheText.isEmpty) return clientsList;

    return clientsList.where((client) {
      final searchableText = [
        client['nom']?.toString() ?? '',
        client['prenom']?.toString() ?? '',
        client['email']?.toString() ?? '',
        client['telephone']?.toString() ?? '',
        client['cin']?.toString() ?? '',
      ].join(' ').toLowerCase();

      return searchableText.contains(_rechercheText);
    }).toList();
  }

  /// 👤 Carte de client
  Widget _buildClientCard(Map<String, dynamic> client) {
    final nombreContrats = client['nombreContrats'] ?? 0;
    final contratsActifs = client['contratsActifs'] ?? 0;
    final nom = '${client['prenom']} ${client['nom']}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        children: [
          // En-tête avec informations principales
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF334155),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF10B981),
                  child: Text(
                    nom.isNotEmpty ? nom[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nom,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '$contratsActifs/$nombreContrats contrats actifs',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: contratsActifs > 0 ? Colors.green[600] : Colors.grey[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    contratsActifs > 0 ? 'ACTIF' : 'INACTIF',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Informations détaillées
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('📧 Email', client['email'] ?? 'N/A'),
                _buildInfoRow('📞 Téléphone', client['telephone'] ?? 'N/A'),
                _buildInfoRow('🆔 CIN', client['cin'] ?? 'N/A'),
                _buildInfoRow('📍 Adresse', client['adresse'] ?? 'N/A'),
              ],
            ),
          ),
          
          // Actions
          _buildActionsSection(client),
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
            width: 100,
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
  Widget _buildActionsSection(Map<String, dynamic> client) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF334155),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Row(
        children: [
          // Bouton Contacter
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _contacterClient(client),
              icon: const Icon(Icons.phone, size: 16),
              label: const Text('Contacter'),
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

          // Bouton Voir contrats
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => _voirContratsClient(client),
              icon: const Icon(Icons.assignment, size: 16),
              label: const Text('Contrats'),
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
        ],
      ),
    );
  }

  /// 📞 Contacter le client
  void _contacterClient(Map<String, dynamic> client) {
    final email = client['email'] ?? '';
    final telephone = client['telephone'] ?? '';
    final nom = '${client['prenom']} ${client['nom']}';

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

  /// 📋 Voir les contrats du client
  void _voirContratsClient(Map<String, dynamic> client) {
    final clientId = client['clientId'];
    final nom = '${client['prenom']} ${client['nom']}';

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
                        'Contrats de $nom',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
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
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('demandes_contrats')
                      .where('agentId', isEqualTo: _agentId)
                      .where('conducteurId', isEqualTo: clientId)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erreur: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFF10B981)),
                      );
                    }

                    final contrats = snapshot.data?.docs ?? [];

                    if (contrats.isEmpty) {
                      return const Center(
                        child: Text(
                          'Aucun contrat trouvé',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: contrats.length,
                      itemBuilder: (context, index) {
                        final contrat = contrats[index];
                        final data = contrat.data() as Map<String, dynamic>;
                        return _buildContratResume(contrat.id, data);
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

  /// 📄 Résumé de contrat
  Widget _buildContratResume(String contratId, Map<String, dynamic> data) {
    final statut = data['statut'] ?? '';
    final couleurStatut = _getCouleurStatut(statut);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: couleurStatut.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '🚗 ${data['marque']} ${data['modele']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: couleurStatut,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatutLabel(statut),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '📋 ${data['numeroContrat'] ?? data['numero'] ?? contratId}',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 🎨 Obtenir la couleur selon le statut
  Color _getCouleurStatut(String statut) {
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

  /// 📝 Obtenir le label du statut
  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'contrat_actif':
        return 'ACTIF';
      case 'en_attente_paiement':
        return 'ATTENTE';
      case 'frequence_choisie':
        return 'PAIEMENT';
      case 'expire':
        return 'EXPIRÉ';
      default:
        return statut.toUpperCase();
    }
  }
}
