import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

/// 📄 Widget pour afficher et télécharger les documents de contrat
class ContractDocumentsWidget extends StatefulWidget {
  final String contractId;
  final Map<String, dynamic> contractData;

  const ContractDocumentsWidget({
    Key? key,
    required this.contractId,
    required this.contractData,
  }) : super(key: key);

  @override
  State<ContractDocumentsWidget> createState() => _ContractDocumentsWidgetState();
}

class _ContractDocumentsWidgetState extends State<ContractDocumentsWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.green.shade700,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎉 Contrat Validé !',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    Text(
                      'Votre véhicule est maintenant assuré',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Informations du contrat
          _buildContractInfo(),
          
          const SizedBox(height: 20),
          
          // Documents disponibles
          Text(
            '📄 Documents Disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Liste des documents
          _buildDocumentsList(),
          
          const SizedBox(height: 20),
          
          // Actions
          _buildActionButtons(),
        ],
      ),
    );
  }

  /// 📋 Informations du contrat
  Widget _buildContractInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'N° Contrat',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                widget.contractData['numeroContrat'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Véhicule',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                widget.contractData['vehiculeInfo']?['immatriculation'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Type d\'assurance',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                widget.contractData['typeContratDisplay'] ?? widget.contractData['typeContrat'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 📄 Liste des documents
  Widget _buildDocumentsList() {
    final documents = [
      {
        'title': 'Carte Verte d\'Assurance',
        'subtitle': 'Attestation obligatoire pour le pare-brise',
        'icon': Icons.credit_card_rounded,
        'color': Colors.green,
        'type': 'carte_verte',
      },
      {
        'title': 'Quittance de Paiement',
        'subtitle': 'Reçu de paiement de la prime',
        'icon': Icons.receipt_rounded,
        'color': Colors.blue,
        'type': 'quittance',
      },
      {
        'title': 'Contrat d\'Assurance',
        'subtitle': 'Police d\'assurance complète',
        'icon': Icons.description_rounded,
        'color': Colors.orange,
        'type': 'contrat',
      },
      {
        'title': 'Certificat Numérique',
        'subtitle': 'Certificat avec QR Code pour contrôles',
        'icon': Icons.qr_code_rounded,
        'color': Colors.purple,
        'type': 'certificat',
      },
    ];

    return Column(
      children: documents.map((doc) => _buildDocumentCard(doc)).toList(),
    );
  }

  /// 📄 Carte de document
  Widget _buildDocumentCard(Map<String, dynamic> document) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: () => _downloadDocument(document['type']),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (document['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    document['icon'],
                    color: document['color'],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document['title'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        document['subtitle'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.download_rounded,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🎯 Boutons d'action
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : _downloadAllDocuments,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded),
            label: Text(_isLoading ? 'Téléchargement...' : 'Tout Télécharger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareContractInfo,
            icon: const Icon(Icons.share_rounded),
            label: const Text('Partager'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.green.shade600,
              side: BorderSide(color: Colors.green.shade600),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 📥 Télécharger un document spécifique
  Future<void> _downloadDocument(String documentType) async {
    try {
      setState(() => _isLoading = true);

      // Ici, vous pouvez implémenter la logique de téléchargement
      // En récupérant les chemins des documents depuis Firestore
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📄 Téléchargement de ${_getDocumentName(documentType)} en cours...'),
          backgroundColor: Colors.green,
        ),
      );

      // Simuler le téléchargement
      await Future.delayed(const Duration(seconds: 2));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_getDocumentName(documentType)} téléchargé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📥 Télécharger tous les documents
  Future<void> _downloadAllDocuments() async {
    try {
      setState(() => _isLoading = true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📄 Téléchargement de tous les documents en cours...'),
          backgroundColor: Colors.green,
        ),
      );

      // Simuler le téléchargement de tous les documents
      await Future.delayed(const Duration(seconds: 3));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Tous les documents ont été téléchargés avec succès'),
          backgroundColor: Colors.green,
        ),
      );

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Erreur lors du téléchargement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// 📤 Partager les informations du contrat
  Future<void> _shareContractInfo() async {
    final contractInfo = '''
🎉 Mon véhicule est maintenant assuré !

📋 Contrat N°: ${widget.contractData['numeroContrat']}
🚗 Véhicule: ${widget.contractData['vehiculeInfo']?['immatriculation']}
🛡️ Type: ${widget.contractData['typeContratDisplay'] ?? widget.contractData['typeContrat']}
📅 Validité: ${_formatDate(widget.contractData['dateDebut'])} - ${_formatDate(widget.contractData['dateFin'])}

Généré par l'application Constat Tunisie
''';

    await Share.share(contractInfo);
  }

  /// 📄 Obtenir le nom du document
  String _getDocumentName(String type) {
    switch (type) {
      case 'carte_verte':
        return 'Carte Verte';
      case 'quittance':
        return 'Quittance de Paiement';
      case 'contrat':
        return 'Contrat d\'Assurance';
      case 'certificat':
        return 'Certificat Numérique';
      default:
        return 'Document';
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = date.toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return date.toString();
    }
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }
}
