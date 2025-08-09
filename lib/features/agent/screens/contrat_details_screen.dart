import 'package:flutter/material.dart';

/// 👁️ Écran de détails d'un contrat
class ContratDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> contratData;
  final Map<String, dynamic> agentData;

  const ContratDetailsScreen({
    Key? key,
    required this.contratData,
    required this.agentData,
  }) : super(key: key);

  @override
  State<ContratDetailsScreen> createState() => _ContratDetailsScreenState();
}

class _ContratDetailsScreenState extends State<ContratDetailsScreen> {
  late Map<String, dynamic> _contratData;

  @override
  void initState() {
    super.initState();
    _contratData = Map.from(widget.contratData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
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
                  child: _buildMainContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 📋 Header
  Widget _buildHeader() {
    final statut = _contratData['statut'] ?? 'actif';
    Color statutColor;
    
    switch (statut) {
      case 'actif':
        statutColor = Colors.green;
        break;
      case 'expire':
        statutColor = Colors.red;
        break;
      case 'suspendu':
        statutColor = Colors.orange;
        break;
      default:
        statutColor = Colors.grey;
    }
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _contratData['numeroContrat'] ?? 'Contrat',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${_contratData['prenomAssure']} ${_contratData['nomAssure']}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statutColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: statutColor),
            ),
            child: Text(
              statut.toUpperCase(),
              style: TextStyle(
                color: statutColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 📱 Contenu principal
  Widget _buildMainContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Informations du contrat
          _buildContratInfoCard(),
          const SizedBox(height: 24),
          
          // Informations de l'assuré
          _buildAssureInfoCard(),
          const SizedBox(height: 24),
          
          // Informations financières
          _buildFinancialInfoCard(),
          const SizedBox(height: 24),
          
          // Métadonnées
          _buildMetadataCard(),
        ],
      ),
    );
  }

  /// 📄 Carte informations du contrat
  Widget _buildContratInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                Icons.description_rounded,
                color: Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations du Contrat',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('Numéro de contrat', _contratData['numeroContrat']),
          _buildDetailRow('Type de contrat', _contratData['typeContrat']),
          _buildDetailRow('Statut', _contratData['statut']),
          _buildDetailRow('Date de début', _formatDate(_contratData['dateDebut'])),
          _buildDetailRow('Date de fin', _formatDate(_contratData['dateFin'])),
        ],
      ),
    );
  }

  /// 👤 Carte informations de l'assuré
  Widget _buildAssureInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                Icons.person_rounded,
                color: Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations de l\'Assuré',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('Nom complet', '${_contratData['prenomAssure']} ${_contratData['nomAssure']}'),
          if (_contratData['cinAssure'] != null && _contratData['cinAssure'].toString().isNotEmpty)
            _buildDetailRow('CIN', _contratData['cinAssure']),
          _buildDetailRow('Téléphone', _contratData['telephoneAssure']),
          _buildDetailRow('Email', _contratData['emailAssure']),
          if (_contratData['adresseAssure'] != null && _contratData['adresseAssure'].toString().isNotEmpty)
            _buildDetailRow('Adresse', _contratData['adresseAssure']),
        ],
      ),
    );
  }

  /// 💰 Carte informations financières
  Widget _buildFinancialInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                Icons.attach_money_rounded,
                color: Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Informations Financières',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          _buildDetailRow('Montant de la prime', '${_contratData['montantPrime'] ?? 0} DT'),
          
          // Calculer la durée du contrat
          if (_contratData['dateDebut'] != null && _contratData['dateFin'] != null) ...[
            _buildDetailRow('Durée du contrat', _calculateDuration()),
          ],
        ],
      ),
    );
  }

  /// 📊 Carte métadonnées
  Widget _buildMetadataCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
              Icon(
                Icons.info_rounded,
                color: Color(0xFF667EEA),
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Métadonnées',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          if (_contratData['createdAt'] != null)
            _buildDetailRow('Date de création', _formatDate(_contratData['createdAt'])),
          if (_contratData['updatedAt'] != null)
            _buildDetailRow('Dernière modification', _formatDate(_contratData['updatedAt'])),
          _buildDetailRow('Créé par', _contratData['createdBy'] ?? 'Non défini'),
          _buildDetailRow('Origine', _contratData['origin'] ?? 'Non définie'),
        ],
      ),
    );
  }

  /// 📝 Ligne de détail
  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Non défini',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
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

  /// ⏱️ Calculer la durée du contrat
  String _calculateDuration() {
    try {
      DateTime dateDebut;
      DateTime dateFin;
      
      if (_contratData['dateDebut'] is DateTime) {
        dateDebut = _contratData['dateDebut'];
      } else {
        dateDebut = _contratData['dateDebut'].toDate();
      }
      
      if (_contratData['dateFin'] is DateTime) {
        dateFin = _contratData['dateFin'];
      } else {
        dateFin = _contratData['dateFin'].toDate();
      }
      
      final difference = dateFin.difference(dateDebut);
      final days = difference.inDays;
      final months = (days / 30).round();
      final years = (days / 365).round();
      
      if (years > 0) {
        return '$years an${years > 1 ? 's' : ''}';
      } else if (months > 0) {
        return '$months mois';
      } else {
        return '$days jour${days > 1 ? 's' : ''}';
      }
    } catch (e) {
      return 'Calcul impossible';
    }
  }
}
