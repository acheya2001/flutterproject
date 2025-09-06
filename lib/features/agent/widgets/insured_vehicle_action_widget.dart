import 'package:flutter/material.dart';
import '../../../services/contract_completion_service.dart';
import 'document_delivery_options_widget.dart';

/// 🚗 Widget d'action pour véhicule assuré
class InsuredVehicleActionWidget extends StatefulWidget {
  final Map<String, dynamic> vehicleData;
  final VoidCallback? onDocumentsSent;

  const InsuredVehicleActionWidget({
    Key? key,
    required this.vehicleData,
    this.onDocumentsSent,
  }) : super(key: key);

  @override
  State<InsuredVehicleActionWidget> createState() => _InsuredVehicleActionWidgetState();
}

class _InsuredVehicleActionWidgetState extends State<InsuredVehicleActionWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isInsured = widget.vehicleData['etatCompte'] == 'assuré' || 
                     widget.vehicleData['statutAssurance'] == 'assuré';

    if (!isInsured) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green.shade50,
            Colors.blue.shade50,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec statut
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: Colors.green.shade700,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Véhicule Assuré',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      widget.vehicleData['numeroImmatriculation'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Informations du contrat
          if (widget.vehicleData['numeroContratAssurance'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.description_rounded,
                        color: Colors.blue.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'N° Contrat: ${widget.vehicleData['numeroContratAssurance']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (widget.vehicleData['compagnieAssuranceNom'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.business_rounded,
                          color: Colors.grey.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.vehicleData['compagnieAssuranceNom'],
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 16),
          ],
          
          // Bouton d'action
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _showDeliveryOptions,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(_isLoading ? 'Envoi en cours...' : 'Envoyer Documents d\'Assurance'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Texte d'aide
          Text(
            '📄 Carte verte, quittance de paiement et certificat numérique',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// 📤 Afficher les options de livraison
  void _showDeliveryOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DocumentDeliveryOptionsWidget(
        contractData: {
          'id': widget.vehicleData['contractId'] ?? '',
          'numeroContrat': widget.vehicleData['numeroContratAssurance'] ?? '',
          'vehiculeId': widget.vehicleData['id'] ?? '',
          'conducteurId': widget.vehicleData['conducteurId'] ?? '',
          'agenceId': widget.vehicleData['agenceAssuranceId'] ?? '',
          'compagnieId': widget.vehicleData['compagnieAssuranceId'] ?? '',
          'typeContrat': widget.vehicleData['typeAssurance'] ?? 'responsabilite_civile',
          'primeAnnuelle': widget.vehicleData['primeAnnuelle'] ?? 0,
          'dateDebut': widget.vehicleData['dateDebutAssurance'],
          'dateFin': widget.vehicleData['dateFinAssurance'],
          'statut': 'actif',
          'vehiculeInfo': {
            'immatriculation': widget.vehicleData['numeroImmatriculation'],
            'marque': widget.vehicleData['marque'],
            'modele': widget.vehicleData['modele'],
          },
          'proprietaireInfo': {
            'nom': widget.vehicleData['nomProprietaire'],
            'prenom': widget.vehicleData['prenomProprietaire'],
            'adresse': widget.vehicleData['adresseProprietaire'],
          },
          'conducteurPhone': widget.vehicleData['telephoneProprietaire'] ?? '',
        },
        onDeliveryComplete: () {
          widget.onDocumentsSent?.call();
        },
      ),
    );
  }

  /// 📤 Envoyer les documents d'assurance (méthode simple)
  Future<void> _sendInsuranceDocuments() async {
    try {
      setState(() => _isLoading = true);

      // Préparer les données du contrat
      final contractData = {
        'id': widget.vehicleData['contractId'] ?? '',
        'numeroContrat': widget.vehicleData['numeroContratAssurance'] ?? '',
        'vehiculeId': widget.vehicleData['id'] ?? '',
        'conducteurId': widget.vehicleData['conducteurId'] ?? '',
        'agenceId': widget.vehicleData['agenceAssuranceId'] ?? '',
        'compagnieId': widget.vehicleData['compagnieAssuranceId'] ?? '',
        'typeContrat': widget.vehicleData['typeAssurance'] ?? 'responsabilite_civile',
        'primeAnnuelle': widget.vehicleData['primeAnnuelle'] ?? 0,
        'dateDebut': widget.vehicleData['dateDebutAssurance'],
        'dateFin': widget.vehicleData['dateFinAssurance'],
        'statut': 'actif',
        'vehiculeInfo': {
          'immatriculation': widget.vehicleData['numeroImmatriculation'],
          'marque': widget.vehicleData['marque'],
          'modele': widget.vehicleData['modele'],
        },
        'proprietaireInfo': {
          'nom': widget.vehicleData['nomProprietaire'],
          'prenom': widget.vehicleData['prenomProprietaire'],
          'adresse': widget.vehicleData['adresseProprietaire'],
        },
      };

      // Utiliser le service de finalisation de contrat
      final results = await ContractCompletionService.completeContractProcess(
        contractId: contractData['id'],
        vehicleId: contractData['vehiculeId'],
        conducteurId: contractData['conducteurId'],
        contractData: contractData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✅ Documents envoyés avec succès !'),
                      Text(
                        'Le conducteur a reçu ses documents d\'assurance',
                        style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );

        // Callback optionnel
        widget.onDocumentsSent?.call();
      }

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
