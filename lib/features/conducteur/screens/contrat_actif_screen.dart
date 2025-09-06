import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// 📄 Écran de contrat actif pour le conducteur
class ContratActifScreen extends StatefulWidget {
  final String? demandeId;

  const ContratActifScreen({Key? key, this.demandeId}) : super(key: key);

  @override
  State<ContratActifScreen> createState() => _ContratActifScreenState();
}

class _ContratActifScreenState extends State<ContratActifScreen> {
  String? _currentUserId;
  Map<String, dynamic>? _contratData;
  List<Map<String, dynamic>> _vehiculesAssures = [];
  List<Map<String, dynamic>> _historiquesPaiements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  Future<void> _getCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _currentUserId = user.uid);
      await _loadContratData();
    }
  }

  Future<void> _loadContratData() async {
    if (_currentUserId == null) return;

    try {
      // Charger le contrat actif
      Query query = FirebaseFirestore.instance
          .collection('demandes_contrats')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('statut', isEqualTo: 'contrat_actif');

      if (widget.demandeId != null) {
        query = FirebaseFirestore.instance
            .collection('demandes_contrats')
            .where('conducteurId', isEqualTo: _currentUserId);
      }

      final contratSnapshot = await query.limit(1).get();

      if (contratSnapshot.docs.isNotEmpty) {
        final doc = contratSnapshot.docs.first;
        setState(() {
          _contratData = {'id': doc.id, ...doc.data() as Map<String, dynamic>};
        });

        // Charger les véhicules assurés
        await _loadVehiculesAssures();
        
        // Charger l'historique des paiements
        await _loadHistoriquePaiements();
      }
    } catch (e) {
      print('❌ Erreur chargement contrat: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVehiculesAssures() async {
    if (_contratData == null) return;

    try {
      final vehiculesSnapshot = await FirebaseFirestore.instance
          .collection('vehicules_assures')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('contratId', isEqualTo: _contratData!['id'])
          .get();

      setState(() {
        _vehiculesAssures = vehiculesSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      print('❌ Erreur chargement véhicules: $e');
    }
  }

  Future<void> _loadHistoriquePaiements() async {
    if (_contratData == null) return;

    try {
      final paiementsSnapshot = await FirebaseFirestore.instance
          .collection('paiements')
          .where('conducteurId', isEqualTo: _currentUserId)
          .where('demandeId', isEqualTo: _contratData!['id'])
          .orderBy('dateCreation', descending: true)
          .get();

      setState(() {
        _historiquesPaiements = paiementsSnapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList();
      });
    } catch (e) {
      print('❌ Erreur chargement historique: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mon Contrat d\'Assurance',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2937),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showContractMenu(),
            icon: const Icon(Icons.more_vert),
            tooltip: 'Options du contrat',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _contratData == null
              ? _buildNoContractView()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Confirmation du contrat
                      _buildContractConfirmation(),
                      
                      const SizedBox(height: 24),
                      
                      // Véhicules assurés
                      _buildVehiculesSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Documents officiels
                      _buildDocumentsSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Historique des paiements
                      _buildHistoriqueSection(),
                      
                      const SizedBox(height: 24),
                      
                      // Services complémentaires
                      _buildServicesSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildNoContractView() {
    return Center(
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
            'Aucun contrat actif',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous n\'avez pas encore de contrat d\'assurance actif.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildContractConfirmation() {
    final numeroContrat = _contratData!['numeroContrat'] ?? _contratData!['id'];
    final dateDebut = _contratData!['dateDebutContrat'] != null
        ? (_contratData!['dateDebutContrat'] as Timestamp).toDate()
        : DateTime.now();
    final dateFin = _contratData!['dateFinContrat'] != null
        ? (_contratData!['dateFinContrat'] as Timestamp).toDate()
        : DateTime.now().add(const Duration(days: 365));
    final frequencePaiement = _contratData!['frequencePaiement'] ?? 'annuel';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Contrat Activé !',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          _buildInfoRow('Numéro de contrat', numeroContrat, Icons.numbers),
          const SizedBox(height: 12),
          _buildInfoRow('Date de début', DateFormat('dd/MM/yyyy').format(dateDebut), Icons.calendar_today),
          const SizedBox(height: 12),
          _buildInfoRow('Date de fin', DateFormat('dd/MM/yyyy').format(dateFin), Icons.event),
          const SizedBox(height: 12),
          _buildInfoRow('Type de paiement', _getFrequenceLabel(frequencePaiement), Icons.payment),
          const SizedBox(height: 12),
          _buildInfoRow('Statut', 'ACTIF', Icons.check_circle, isStatus: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isStatus = false}) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isStatus ? Colors.white : Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVehiculesSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Véhicules Assurés',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          if (_vehiculesAssures.isEmpty) ...[
            // Utiliser les données du contrat si pas de véhicules séparés
            _buildVehiculeCard({
              'marque': _contratData!['marque'] ?? 'N/A',
              'modele': _contratData!['modele'] ?? 'N/A',
              'immatriculation': _contratData!['immatriculation'] ?? 'N/A',
              'annee': _contratData!['annee'] ?? 'N/A',
              'statut': 'actif',
            }),
          ] else ...[
            ..._vehiculesAssures.map((vehicule) => _buildVehiculeCard(vehicule)).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildVehiculeCard(Map<String, dynamic> vehicule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[600],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${vehicule['marque']} ${vehicule['modele']}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'ACTIF',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildVehiculeInfo('Immatriculation', vehicule['immatriculation'] ?? 'N/A'),
              const SizedBox(width: 20),
              _buildVehiculeInfo('Année', vehicule['annee']?.toString() ?? 'N/A'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVehiculeInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentsSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: Colors.purple[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Documents Officiels',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildDocumentItem(
            'Attestation d\'Assurance',
            'Document officiel prouvant votre couverture',
            Icons.verified_user,
            Colors.green,
            () => _downloadDocument('attestation'),
          ),

          _buildDocumentItem(
            'Conditions Générales',
            'Termes et conditions de votre contrat',
            Icons.gavel,
            Colors.blue,
            () => _downloadDocument('conditions'),
          ),

          _buildDocumentItem(
            'Reçu de Paiement',
            'Justificatif de votre dernier paiement',
            Icons.receipt,
            Colors.orange,
            () => _downloadDocument('recu'),
          ),

          _buildDocumentItem(
            'Fiche des Garanties',
            'Détail de vos couvertures d\'assurance',
            Icons.security,
            Colors.purple,
            () => _downloadDocument('garanties'),
          ),

          if (_contratData!['frequencePaiement'] != 'annuel') ...[
            _buildDocumentItem(
              'Échéancier des Paiements',
              'Calendrier de vos prochains paiements',
              Icons.schedule,
              Colors.teal,
              () => _downloadDocument('echeancier'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDocumentItem(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.download, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoriqueSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, color: Colors.indigo[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Historique des Paiements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (_historiquesPaiements.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[500]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Aucun historique de paiement disponible',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            ..._historiquesPaiements.take(3).map((paiement) => _buildPaiementItem(paiement)).toList(),

            if (_historiquesPaiements.length > 3) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => _showFullHistorique(),
                  child: const Text('Voir tout l\'historique'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaiementItem(Map<String, dynamic> paiement) {
    final datePaiement = paiement['datePaiement'] != null
        ? (paiement['datePaiement'] as Timestamp).toDate()
        : null;
    final montant = paiement['montant']?.toDouble() ?? 0.0;
    final modePaiement = paiement['modePaiement'] ?? 'especes';
    final statut = paiement['statut'] ?? 'en_attente';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getStatutColor(statut),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getStatutIcon(statut),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${montant.toStringAsFixed(2)} DT',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  datePaiement != null
                      ? DateFormat('dd/MM/yyyy').format(datePaiement)
                      : 'En attente',
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
                _getModePaiementLabel(modePaiement),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatutColor(statut).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatutLabel(statut),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getStatutColor(statut),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.support_agent, color: Colors.red[600], size: 24),
              const SizedBox(width: 12),
              const Text(
                'Services Complémentaires',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _buildServiceItem(
            'Assistance 24h/24',
            'Numéro d\'urgence et support immédiat',
            Icons.phone,
            Colors.red,
            () => _callAssistance(),
          ),

          _buildServiceItem(
            'Historique des Demandes',
            'Consultez toutes vos demandes passées',
            Icons.history,
            Colors.blue,
            () => _showHistoriqueDemandes(),
          ),

          _buildServiceItem(
            'Renouveler le Contrat',
            'Prolongez votre assurance facilement',
            Icons.refresh,
            Colors.green,
            () => _renewContract(),
          ),

          _buildServiceItem(
            'Modifier le Contrat',
            'Changez vos options d\'assurance',
            Icons.edit,
            Colors.orange,
            () => _modifyContract(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceItem(String title, String description, IconData icon, Color color, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  // Méthodes utilitaires
  Color _getStatutColor(String statut) {
    switch (statut) {
      case 'paye':
        return Colors.green;
      case 'en_attente':
        return Colors.orange;
      case 'en_retard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatutIcon(String statut) {
    switch (statut) {
      case 'paye':
        return Icons.check_circle;
      case 'en_attente':
        return Icons.schedule;
      case 'en_retard':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }

  String _getStatutLabel(String statut) {
    switch (statut) {
      case 'paye':
        return 'PAYÉ';
      case 'en_attente':
        return 'EN ATTENTE';
      case 'en_retard':
        return 'EN RETARD';
      default:
        return statut.toUpperCase();
    }
  }

  String _getModePaiementLabel(String mode) {
    switch (mode) {
      case 'especes':
        return 'Espèces';
      case 'carte_bancaire':
        return 'Carte';
      case 'cheque':
        return 'Chèque';
      case 'virement':
        return 'Virement';
      default:
        return mode;
    }
  }

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

  // Actions
  Future<void> _downloadDocument(String type) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('📄 Téléchargement du document: $type'),
        backgroundColor: Colors.blue,
      ),
    );
    // TODO: Implémenter le téléchargement réel
  }

  Future<void> _callAssistance() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📞 Numéro d\'assistance: +216 71 234 567'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showHistoriqueDemandes() {
    // TODO: Naviguer vers l'historique des demandes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📋 Ouverture de l\'historique des demandes'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _renewContract() {
    // TODO: Naviguer vers le renouvellement
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🔄 Ouverture du renouvellement de contrat'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _modifyContract() {
    // TODO: Naviguer vers la modification
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✏️ Ouverture de la modification de contrat'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showFullHistorique() {
    // TODO: Afficher l'historique complet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📊 Affichage de l\'historique complet'),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  /// 📋 Afficher le menu des options du contrat
  void _showContractMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Options du Contrat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 20),
            _buildMenuOption(
              icon: Icons.share,
              title: 'Partager le contrat',
              subtitle: 'Envoyer par email ou SMS',
              onTap: () {
                Navigator.pop(context);
                _shareContract();
              },
            ),
            _buildMenuOption(
              icon: Icons.download,
              title: 'Télécharger PDF',
              subtitle: 'Sauvegarder sur l\'appareil',
              onTap: () {
                Navigator.pop(context);
                _downloadContractPDF();
              },
            ),
            _buildMenuOption(
              icon: Icons.print,
              title: 'Imprimer',
              subtitle: 'Imprimer le contrat',
              onTap: () {
                Navigator.pop(context);
                _printContract();
              },
            ),
            _buildMenuOption(
              icon: Icons.qr_code,
              title: 'QR Code',
              subtitle: 'Afficher le QR code du contrat',
              onTap: () {
                Navigator.pop(context);
                _showContractQR();
              },
            ),
            _buildMenuOption(
              icon: Icons.support_agent,
              title: 'Contacter l\'agent',
              subtitle: 'Assistance personnalisée',
              onTap: () {
                Navigator.pop(context);
                _contactAgent();
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  /// 📋 Option du menu
  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF8B5CF6)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
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
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  /// 📤 Partager le contrat
  void _shareContract() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📤 Partage du contrat en cours...'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// 📥 Télécharger le contrat en PDF
  void _downloadContractPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('📥 Téléchargement du PDF en cours...'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// 🖨️ Imprimer le contrat
  void _printContract() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🖨️ Impression en cours...'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// 📱 Afficher le QR code du contrat
  void _showContractQR() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('QR Code du Contrat'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.qr_code,
                size: 100,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Contrat N° ${_contratData?['numeroContrat'] ?? 'N/A'}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scannez ce code pour accéder rapidement aux détails du contrat',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _shareContract();
            },
            icon: const Icon(Icons.share),
            label: const Text('Partager'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📞 Contacter l'agent
  void _contactAgent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.support_agent, color: Colors.blue[600]),
            const SizedBox(width: 12),
            const Text('Contacter votre Agent'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Comment souhaitez-vous contacter votre agent ?'),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _callAssistance();
                    },
                    icon: const Icon(Icons.phone),
                    label: const Text('Appeler'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('💬 Ouverture du chat...'),
                          backgroundColor: Colors.blue,
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }
}
