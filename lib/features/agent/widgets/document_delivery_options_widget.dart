import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/contract_completion_service.dart';

/// 📤 Widget des options de livraison de documents
class DocumentDeliveryOptionsWidget extends StatefulWidget {
  final Map<String, dynamic> contractData;
  final VoidCallback? onDeliveryComplete;

  const DocumentDeliveryOptionsWidget({
    Key? key,
    required this.contractData,
    this.onDeliveryComplete,
  }) : super(key: key);

  @override
  State<DocumentDeliveryOptionsWidget> createState() => _DocumentDeliveryOptionsWidgetState();
}

class _DocumentDeliveryOptionsWidgetState extends State<DocumentDeliveryOptionsWidget> {
  bool _isLoading = false;
  String _selectedMethod = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.send_rounded,
                  color: Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Envoyer les Documents',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Contrat N° ${widget.contractData['numeroContrat']}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Options de livraison
          const Text(
            'Choisissez la méthode de livraison :',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Option 1: Notification App + Email
          _buildDeliveryOption(
            'app_email',
            'Notification App + Email',
            'Le conducteur recevra une notification dans l\'app et un email avec les documents',
            Icons.notifications_active_rounded,
            Colors.green,
            isRecommended: true,
          ),
          
          // Option 2: WhatsApp
          _buildDeliveryOption(
            'whatsapp',
            'Envoyer via WhatsApp',
            'Partager les documents directement sur WhatsApp du conducteur',
            Icons.chat_rounded,
            Colors.green.shade600,
          ),
          
          // Option 3: SMS avec lien
          _buildDeliveryOption(
            'sms',
            'SMS avec lien de téléchargement',
            'Envoyer un SMS avec un lien sécurisé pour télécharger les documents',
            Icons.sms_rounded,
            Colors.blue,
          ),
          
          // Option 4: Impression pour remise en main propre
          _buildDeliveryOption(
            'print',
            'Imprimer pour remise en main propre',
            'Générer les documents PDF pour impression et remise physique',
            Icons.print_rounded,
            Colors.orange,
          ),
          
          const SizedBox(height: 24),
          
          // Bouton d'action
          if (_selectedMethod.isNotEmpty) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _executeDelivery,
                icon: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_isLoading ? 'Envoi en cours...' : 'Envoyer les Documents'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 📋 Option de livraison
  Widget _buildDeliveryOption(
    String method,
    String title,
    String description,
    IconData icon,
    Color color, {
    bool isRecommended = false,
  }) {
    final isSelected = _selectedMethod == method;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedMethod = method),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? color.withOpacity(0.05) : Colors.grey.shade50,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isSelected ? color : Colors.black87,
                            ),
                          ),
                          if (isRecommended) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Recommandé',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: color, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🚀 Exécuter la livraison
  Future<void> _executeDelivery() async {
    setState(() => _isLoading = true);

    try {
      switch (_selectedMethod) {
        case 'app_email':
          await _sendViaAppAndEmail();
          break;
        case 'whatsapp':
          await _sendViaWhatsApp();
          break;
        case 'sms':
          await _sendViaSMS();
          break;
        case 'print':
          await _generateForPrint();
          break;
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onDeliveryComplete?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Documents envoyés avec succès via ${_getMethodName()}'),
            backgroundColor: Colors.green,
          ),
        );
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

  /// 📱 Envoyer via App + Email
  Future<void> _sendViaAppAndEmail() async {
    // Utiliser le service de finalisation complet
    await ContractCompletionService.completeContractProcess(
      contractId: widget.contractData['id'],
      vehicleId: widget.contractData['vehiculeId'],
      conducteurId: widget.contractData['conducteurId'],
      contractData: widget.contractData,
    );
  }

  /// 💬 Envoyer via WhatsApp
  Future<void> _sendViaWhatsApp() async {
    // Générer les documents d'abord
    await ContractCompletionService.completeContractProcess(
      contractId: widget.contractData['id'],
      vehicleId: widget.contractData['vehiculeId'],
      conducteurId: widget.contractData['conducteurId'],
      contractData: widget.contractData,
    );

    // Créer le message WhatsApp
    final message = '''
🎉 Félicitations ! Votre contrat d'assurance est validé !

📋 Contrat N° ${widget.contractData['numeroContrat']}
🚗 Véhicule: ${widget.contractData['vehiculeInfo']?['immatriculation']}
📅 Validité: ${_formatDate(widget.contractData['dateFin'])}

📄 Vos documents d'assurance sont disponibles dans l'application Constat Tunisie.

Téléchargez l'app pour accéder à:
• Carte verte d'assurance
• Quittance de paiement  
• Certificat numérique

Merci de votre confiance ! 🙏
''';

    // Ouvrir WhatsApp
    final phone = widget.contractData['conducteurPhone'] ?? '';
    final whatsappUrl = 'https://wa.me/$phone?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl));
    }
  }

  /// 📱 Envoyer via SMS
  Future<void> _sendViaSMS() async {
    // Générer les documents d'abord
    await ContractCompletionService.completeContractProcess(
      contractId: widget.contractData['id'],
      vehicleId: widget.contractData['vehiculeId'],
      conducteurId: widget.contractData['conducteurId'],
      contractData: widget.contractData,
    );

    // Créer le SMS
    final message = '''
🎉 Contrat d'assurance validé !
N° ${widget.contractData['numeroContrat']}

Téléchargez vos documents sur l'app Constat Tunisie ou via ce lien: [LIEN_SECURISE]

Merci !
''';

    final phone = widget.contractData['conducteurPhone'] ?? '';
    final smsUrl = 'sms:$phone?body=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(smsUrl))) {
      await launchUrl(Uri.parse(smsUrl));
    }
  }

  /// 🖨️ Générer pour impression
  Future<void> _generateForPrint() async {
    // Générer les documents
    final results = await ContractCompletionService.completeContractProcess(
      contractId: widget.contractData['id'],
      vehicleId: widget.contractData['vehiculeId'],
      conducteurId: widget.contractData['conducteurId'],
      contractData: widget.contractData,
    );

    // Partager les fichiers PDF pour impression
    final documents = results['documents'] as Map<String, String>? ?? {};
    if (documents.isNotEmpty) {
      await Share.shareXFiles(
        documents.values.map((path) => XFile(path)).toList(),
        text: 'Documents d\'assurance à imprimer - Contrat ${widget.contractData['numeroContrat']}',
      );
    }
  }

  /// 📅 Formater une date
  String _formatDate(dynamic date) {
    if (date == null) return '';
    
    DateTime dateTime;
    if (date is Timestamp) {
      dateTime = (date as Timestamp).toDate();
    } else if (date is DateTime) {
      dateTime = date;
    } else {
      return date.toString();
    }
    
    return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
  }

  /// 📝 Nom de la méthode
  String _getMethodName() {
    switch (_selectedMethod) {
      case 'app_email':
        return 'notification app + email';
      case 'whatsapp':
        return 'WhatsApp';
      case 'sms':
        return 'SMS';
      case 'print':
        return 'génération pour impression';
      default:
        return 'méthode sélectionnée';
    }
  }
}
