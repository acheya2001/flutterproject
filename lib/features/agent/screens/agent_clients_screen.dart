import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/document_delivery_options_widget.dart';

/// 👥 Écran de gestion des clients de l'agent
class AgentClientsScreen extends StatefulWidget {
  const AgentClientsScreen({Key? key}) : super(key: key);

  @override
  State<AgentClientsScreen> createState() => _AgentClientsScreenState();
}

class _AgentClientsScreenState extends State<AgentClientsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  String? _agentId;
  List<Map<String, dynamic>> _clients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _agentId = _auth.currentUser?.uid;
    _loadClients();
  }

  /// 📥 Charger les clients de l'agent
  Future<void> _loadClients() async {
    if (_agentId == null) return;

    try {
      setState(() => _isLoading = true);

      // Récupérer tous les véhicules traités par cet agent
      final vehiculesSnapshot = await _firestore
          .collection('vehicules')
          .where('agentAffecteId', isEqualTo: _agentId)
          .get();

      // Grouper par conducteur
      final Map<String, Map<String, dynamic>> clientsMap = {};

      for (final doc in vehiculesSnapshot.docs) {
        final vehiculeData = doc.data();
        final conducteurId = vehiculeData['conducteurId'];
        
        if (conducteurId != null) {
          if (!clientsMap.containsKey(conducteurId)) {
            // Récupérer les infos du conducteur
            final conducteurDoc = await _firestore.collection('users').doc(conducteurId).get();
            final conducteurData = conducteurDoc.data() ?? {};

            clientsMap[conducteurId] = {
              'id': conducteurId,
              'nom': conducteurData['nom'] ?? vehiculeData['nomProprietaire'] ?? '',
              'prenom': conducteurData['prenom'] ?? vehiculeData['prenomProprietaire'] ?? '',
              'email': conducteurData['email'] ?? '',
              'telephone': conducteurData['telephone'] ?? vehiculeData['telephoneProprietaire'] ?? '',
              'adresse': conducteurData['adresse'] ?? vehiculeData['adresseProprietaire'] ?? '',
              'vehicules': [],
              'contrats': [],
            };
          }

          // Ajouter le véhicule
          vehiculeData['id'] = doc.id;
          clientsMap[conducteurId]!['vehicules'].add(vehiculeData);

          // Récupérer les contrats pour ce véhicule
          final contratsSnapshot = await _firestore
              .collection('contrats')
              .where('vehiculeId', isEqualTo: doc.id)
              .where('agentId', isEqualTo: _agentId)
              .get();

          for (final contratDoc in contratsSnapshot.docs) {
            final contratData = contratDoc.data();
            contratData['id'] = contratDoc.id;
            clientsMap[conducteurId]!['contrats'].add(contratData);
          }
        }
      }

      setState(() {
        _clients = clientsMap.values.toList();
        _isLoading = false;
      });

    } catch (e) {
      print('❌ Erreur chargement clients: $e');
      setState(() => _isLoading = false);
    }
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadClients,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _clients.isEmpty
              ? _buildEmptyState()
              : _buildClientsList(),
    );
  }

  /// 📋 Liste des clients
  Widget _buildClientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clients.length,
      itemBuilder: (context, index) {
        final client = _clients[index];
        return _buildClientCard(client);
      },
    );
  }

  /// 👤 Carte de client
  Widget _buildClientCard(Map<String, dynamic> client) {
    final vehicules = client['vehicules'] as List<dynamic>;
    final contrats = client['contrats'] as List<dynamic>;
    final vehiculesAssures = vehicules.where((v) => v['etatCompte'] == 'assuré').length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            Colors.grey.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(20),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            '${client['prenom']?[0] ?? ''}${client['nom']?[0] ?? ''}',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          '${client['prenom']} ${client['nom']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (client['telephone'].isNotEmpty)
              Text('📞 ${client['telephone']}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.directions_car, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 4),
                Text('${vehicules.length} véhicule${vehicules.length > 1 ? 's' : ''}'),
                const SizedBox(width: 16),
                Icon(Icons.verified, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 4),
                Text('$vehiculesAssures assuré${vehiculesAssures > 1 ? 's' : ''}'),
              ],
            ),
          ],
        ),
        children: [
          // Liste des véhicules du client
          ...vehicules.map((vehicule) => _buildVehiculeItem(vehicule, contrats)).toList(),
        ],
      ),
    );
  }

  /// 🚗 Item de véhicule
  Widget _buildVehiculeItem(Map<String, dynamic> vehicule, List<dynamic> contrats) {
    final isAssured = vehicule['etatCompte'] == 'assuré';
    final vehiculeContrats = contrats.where((c) => c['vehiculeId'] == vehicule['id']).toList();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isAssured ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAssured ? Colors.green.shade200 : Colors.orange.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête véhicule
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isAssured ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.directions_car,
                  color: isAssured ? Colors.green.shade700 : Colors.orange.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${vehicule['marque']} ${vehicule['modele']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      vehicule['numeroImmatriculation'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAssured ? Colors.green.shade100 : Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isAssured ? '✅ Assuré' : '⏳ ${vehicule['etatCompte']}',
                  style: TextStyle(
                    color: isAssured ? Colors.green.shade700 : Colors.orange.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          // Contrats du véhicule
          if (vehiculeContrats.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...vehiculeContrats.map((contrat) => _buildContratItem(contrat)).toList(),
          ],
        ],
      ),
    );
  }

  /// 📄 Item de contrat
  Widget _buildContratItem(Map<String, dynamic> contrat) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.description, color: Colors.blue.shade600, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contrat N° ${contrat['numeroContrat']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${contrat['typeContratDisplay'] ?? contrat['typeContrat']} - ${contrat['primeAnnuelle']} DT',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _showDeliveryOptions(contrat),
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Envoyer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  /// 📤 Afficher les options de livraison
  void _showDeliveryOptions(Map<String, dynamic> contractData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDeliveryOptionsWidget(
        contractData: contractData,
        onDeliveryComplete: () {
          setState(() {});
        },
      ),
    );
  }

  /// 🚫 État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun client trouvé',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les clients avec des véhicules que vous gérez apparaîtront ici',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
