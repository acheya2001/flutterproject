import 'package:flutter/material.dart';
import '../../../services/admin_agence_contract_service.dart';

/// 📄 Écran de détails d'un contrat pour Admin Agence
class ContractDetailsScreen extends StatefulWidget {
  final String contractId;
  final Map<String, dynamic> contractData;

  const ContractDetailsScreen({
    Key? key,
    required this.contractId,
    required this.contractData,
  }) : super(key: key);

  @override
  State<ContractDetailsScreen> createState() => _ContractDetailsScreenState();
}

class _ContractDetailsScreenState extends State<ContractDetailsScreen> {
  Map<String, dynamic>? _fullContractData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContractDetails();
  }

  /// 📄 Charger les détails complets du contrat
  Future<void> _loadContractDetails() async {
    try {
      final details = await AdminAgenceContractService.getContractDetails(widget.contractId);
      setState(() {
        _fullContractData = details;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('[CONTRACT_DETAILS] ❌ Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  /// 📱 AppBar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1A1A1A),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Détails du Contrat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            widget.contractData['numeroContrat'] ?? 'N/A',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _downloadContractPDF,
          icon: const Icon(Icons.picture_as_pdf_rounded),
          tooltip: 'Télécharger PDF',
        ),
        IconButton(
          onPressed: _shareContract,
          icon: const Icon(Icons.share_rounded),
          tooltip: 'Partager',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Modifier'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'suspend',
              child: Row(
                children: [
                  Icon(Icons.pause_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Suspendre'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'renew',
              child: Row(
                children: [
                  Icon(Icons.refresh_rounded, size: 20),
                  SizedBox(width: 8),
                  Text('Renouveler'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// ⏳ État de chargement
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Chargement des détails...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// 📄 Contenu principal
  Widget _buildContent() {
    if (_fullContractData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger les détails du contrat.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadContractDetails,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Statut et informations principales
          _buildStatusCard(),
          const SizedBox(height: 20),

          // Informations du conducteur
          _buildConducteurCard(),
          const SizedBox(height: 20),

          // Informations du véhicule
          _buildVehiculeCard(),
          const SizedBox(height: 20),

          // Détails du contrat
          _buildContractDetailsCard(),
          const SizedBox(height: 20),

          // Informations financières
          _buildFinancialCard(),
          const SizedBox(height: 20),

          // Agent responsable
          _buildAgentCard(),
          const SizedBox(height: 20),

          // Historique
          _buildHistoryCard(),
        ],
      ),
    );
  }

  /// 📊 Carte de statut
  Widget _buildStatusCard() {
    final statut = _fullContractData!['statut'] ?? _fullContractData!['statutContrat'] ?? 'Inconnu';
    final statusColor = _getStatusColor(statut);
    final dateDebut = _fullContractData!['dateDebut'];
    final dateFin = _fullContractData!['dateFin'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statut,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                _fullContractData!['numeroContrat'] ?? 'N/A',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Date de début',
                  dateDebut != null ? _formatDate(dateDebut) : 'N/A',
                  Icons.calendar_today_rounded,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  'Date de fin',
                  dateFin != null ? _formatDate(dateFin) : 'N/A',
                  Icons.event_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 👤 Carte conducteur
  Widget _buildConducteurCard() {
    final conducteurData = _fullContractData!['conducteurData'] as Map<String, dynamic>?;
    
    return _buildInfoCard(
      'Conducteur Assuré',
      Icons.person_rounded,
      [
        _buildDetailRow('Nom complet', conducteurData != null 
            ? '${conducteurData['prenom']} ${conducteurData['nom']}'
            : 'Non défini'),
        _buildDetailRow('Email', conducteurData?['email'] ?? 'Non défini'),
        _buildDetailRow('Téléphone', conducteurData?['telephone'] ?? 'Non défini'),
        _buildDetailRow('Date de naissance', conducteurData?['dateNaissance'] != null 
            ? _formatDate(conducteurData!['dateNaissance'])
            : 'Non défini'),
        _buildDetailRow('Adresse', conducteurData?['adresse'] ?? 'Non défini'),
      ],
    );
  }

  /// 🚗 Carte véhicule
  Widget _buildVehiculeCard() {
    final vehiculeData = _fullContractData!['vehiculeData'] as Map<String, dynamic>?;
    
    return _buildInfoCard(
      'Véhicule Assuré',
      Icons.directions_car_rounded,
      [
        _buildDetailRow('Marque et modèle', vehiculeData != null 
            ? '${vehiculeData['marque']} ${vehiculeData['modele']}'
            : 'Non défini'),
        _buildDetailRow('Immatriculation', vehiculeData?['numeroImmatriculation'] ?? 'Non défini'),
        _buildDetailRow('Type', vehiculeData?['typeVehicule'] ?? 'Non défini'),
        _buildDetailRow('Année', vehiculeData?['annee']?.toString() ?? 'Non défini'),
        _buildDetailRow('Couleur', vehiculeData?['couleur'] ?? 'Non défini'),
        _buildDetailRow('Puissance', vehiculeData?['puissance']?.toString() ?? 'Non défini'),
      ],
    );
  }

  /// 📋 Carte détails du contrat
  Widget _buildContractDetailsCard() {
    return _buildInfoCard(
      'Détails du Contrat',
      Icons.description_rounded,
      [
        _buildDetailRow('Type de couverture', _fullContractData!['typeCouverture'] ?? 'Non défini'),
        _buildDetailRow('Franchise', '${_fullContractData!['franchise'] ?? 0} DT'),
        _buildDetailRow('Durée', _fullContractData!['dureeContrat'] ?? 'Non défini'),
        _buildDetailRow('Date de création', _fullContractData!['createdAt'] != null 
            ? _formatDate(_fullContractData!['createdAt'])
            : 'Non défini'),
        _buildDetailRow('Conditions particulières', _fullContractData!['conditionsParticulieres'] ?? 'Aucune'),
      ],
    );
  }

  /// 💰 Carte financière
  Widget _buildFinancialCard() {
    final prime = _fullContractData!['primeAnnuelle'] ?? _fullContractData!['primeAssurance'] ?? 0;
    final franchise = _fullContractData!['franchise'] ?? 0;
    final taxes = _fullContractData!['taxes'] ?? 0;
    final total = prime + taxes;
    
    return _buildInfoCard(
      'Informations Financières',
      Icons.monetization_on_rounded,
      [
        _buildDetailRow('Prime annuelle', '$prime DT'),
        _buildDetailRow('Franchise', '$franchise DT'),
        _buildDetailRow('Taxes', '$taxes DT'),
        _buildDetailRow('Montant total', '$total DT'),
        _buildDetailRow('Mode de paiement', _fullContractData!['modePaiement'] ?? 'Non défini'),
        _buildDetailRow('Fréquence', _fullContractData!['frequencePaiement'] ?? 'Annuel'),
      ],
    );
  }

  /// 👨‍💼 Carte agent
  Widget _buildAgentCard() {
    final agentData = _fullContractData!['agentData'] as Map<String, dynamic>?;
    
    return _buildInfoCard(
      'Agent Responsable',
      Icons.support_agent_rounded,
      [
        _buildDetailRow('Nom', agentData != null 
            ? '${agentData['prenom']} ${agentData['nom']}'
            : 'Non défini'),
        _buildDetailRow('Email', agentData?['email'] ?? 'Non défini'),
        _buildDetailRow('Téléphone', agentData?['telephone'] ?? 'Non défini'),
        _buildDetailRow('Code agent', agentData?['codeAgent'] ?? 'Non défini'),
      ],
    );
  }

  /// 📜 Carte historique
  Widget _buildHistoryCard() {
    final history = _fullContractData!['history'] as List<dynamic>? ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_rounded, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              const Text(
                'Historique',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (history.isEmpty)
            Center(
              child: Text(
                'Aucun historique disponible',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                ),
              ),
            )
          else
            ...history.map((item) => _buildHistoryItem(item)).toList(),
        ],
      ),
    );
  }

  /// 📋 Carte d'information générique
  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📝 Item d'information
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  /// 📜 Item d'historique
  Widget _buildHistoryItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF667EEA),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['action'] ?? 'Action',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item['description'] != null)
                  Text(
                    item['description'],
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            item['timestamp'] != null ? _formatDate(item['timestamp']) : '',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur du statut
  Color _getStatusColor(String statut) {
    switch (statut.toLowerCase()) {
      case 'actif':
        return const Color(0xFF10B981);
      case 'expiré':
      case 'expire':
        return const Color(0xFFEF4444);
      case 'suspendu':
        return const Color(0xFFF59E0B);
      case 'proposé':
      case 'propose':
        return const Color(0xFF3B82F6);
      default:
        return Colors.grey;
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    try {
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date.runtimeType.toString().contains('Timestamp')) {
        dateTime = date.toDate();
      } else {
        return 'Date invalide';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Date invalide';
    }
  }

  /// 📄 Télécharger le contrat en PDF
  void _downloadContractPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Téléchargement PDF du contrat ${_fullContractData!['numeroContrat']}'),
        backgroundColor: Colors.green,
        action: SnackBarAction(
          label: 'Voir',
          onPressed: () {
            // TODO: Ouvrir le PDF téléchargé
          },
        ),
      ),
    );
  }

  /// 📤 Partager le contrat
  void _shareContract() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partage du contrat ${_fullContractData!['numeroContrat']}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// ⚙️ Gérer les actions du menu
  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _editContract();
        break;
      case 'suspend':
        _suspendContract();
        break;
      case 'renew':
        _renewContract();
        break;
    }
  }

  /// ✏️ Modifier le contrat
  void _editContract() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Modification du contrat - À implémenter'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  /// ⏸️ Suspendre le contrat
  void _suspendContract() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Suspendre le contrat'),
        content: const Text('Êtes-vous sûr de vouloir suspendre ce contrat ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contrat suspendu avec succès'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Suspendre'),
          ),
        ],
      ),
    );
  }

  /// 🔄 Renouveler le contrat
  void _renewContract() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Renouvellement du contrat - À implémenter'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
