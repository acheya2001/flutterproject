import 'package:flutter/material.dart';
import '../services/modern_pdf_agent_service.dart';
import '../models/collaborative_session_model.dart';

/// 📄 Exemple d'utilisation du service de génération PDF moderne
/// 
/// Ce fichier montre comment utiliser le service ModernPDFAgentService
/// pour générer et envoyer des PDFs élégants aux agents d'assurance.
class PDFGenerationExample {
  
  /// 🎯 Exemple 1: Génération simple d'un PDF
  /// 
  /// Utilisation basique pour générer un PDF à partir d'une session
  static Future<void> exempleGenerationSimple() async {
    try {
      // ID de la session collaborative
      const sessionId = 'session_123';
      
      // Informations de l'agent destinataire
      const agentEmail = 'agent@assurance.tn';
      const agencyName = 'Agence Tunis Centre';
      const companyName = 'STAR Assurances';
      
      // Générer et envoyer le PDF
      final pdfUrl = await ModernPDFAgentService.genererEtEnvoyerPDFAgent(
        sessionId: sessionId,
        agentEmail: agentEmail,
        agencyName: agencyName,
        companyName: companyName,
      );
      
      print('✅ PDF généré avec succès: $pdfUrl');
      
    } catch (e) {
      print('❌ Erreur génération PDF: $e');
    }
  }
  
  /// 🎯 Exemple 2: Génération avec gestion d'erreurs complète
  /// 
  /// Version plus robuste avec gestion d'erreurs et feedback utilisateur
  static Future<bool> exempleGenerationAvecGestionErreurs({
    required String sessionId,
    required String agentEmail,
    required String agencyName,
    required String companyName,
    VoidCallback? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      // Vérifier que la session existe
      print('🔍 Vérification de la session $sessionId...');
      
      // Générer le PDF
      print('📄 Génération du PDF en cours...');
      final pdfUrl = await ModernPDFAgentService.genererEtEnvoyerPDFAgent(
        sessionId: sessionId,
        agentEmail: agentEmail,
        agencyName: agencyName,
        companyName: companyName,
      );
      
      print('✅ PDF généré et notification créée');
      print('📧 Email sera envoyé à: $agentEmail');
      print('🔗 URL du PDF: $pdfUrl');
      
      onSuccess?.call();
      return true;
      
    } catch (e) {
      final errorMessage = 'Erreur lors de la génération du PDF: $e';
      print('❌ $errorMessage');
      onError?.call(errorMessage);
      return false;
    }
  }
  
  /// 🎯 Exemple 3: Génération pour plusieurs agents
  /// 
  /// Envoyer le même PDF à plusieurs agents d'assurance
  static Future<Map<String, bool>> exempleGenerationMultipleAgents({
    required String sessionId,
    required List<Map<String, String>> agents, // [{email, agencyName, companyName}]
    Function(int, int)? onProgress, // (success, total)
  }) async {
    final resultats = <String, bool>{};
    int successCount = 0;
    
    for (int i = 0; i < agents.length; i++) {
      final agent = agents[i];
      final email = agent['email']!;
      final agencyName = agent['agencyName']!;
      final companyName = agent['companyName']!;
      
      try {
        print('📧 Envoi PDF à $email (${i + 1}/${agents.length})...');
        
        await ModernPDFAgentService.genererEtEnvoyerPDFAgent(
          sessionId: sessionId,
          agentEmail: email,
          agencyName: agencyName,
          companyName: companyName,
        );
        
        resultats[email] = true;
        successCount++;
        print('✅ Succès pour $email');
        
      } catch (e) {
        resultats[email] = false;
        print('❌ Échec pour $email: $e');
      }
      
      // Callback de progression
      onProgress?.call(successCount, agents.length);
    }
    
    print('📊 Résumé: $successCount/${agents.length} envois réussis');
    return resultats;
  }
  
  /// 🎯 Exemple 4: Widget Flutter pour intégration UI
  /// 
  /// Exemple de widget Flutter qui utilise le service
  static Widget buildPDFGenerationButton({
    required String sessionId,
    required String agentEmail,
    required String agencyName,
    required String companyName,
    required BuildContext context,
  }) {
    return ElevatedButton.icon(
      onPressed: () async {
        // Afficher un indicateur de chargement
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Génération du PDF...'),
              ],
            ),
          ),
        );
        
        try {
          // Générer le PDF
          await ModernPDFAgentService.genererEtEnvoyerPDFAgent(
            sessionId: sessionId,
            agentEmail: agentEmail,
            agencyName: agencyName,
            companyName: companyName,
          );
          
          // Fermer le dialog de chargement
          Navigator.of(context).pop();
          
          // Afficher le succès
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF envoyé avec succès à $agentEmail'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
          
        } catch (e) {
          // Fermer le dialog de chargement
          Navigator.of(context).pop();
          
          // Afficher l'erreur
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
              action: SnackBarAction(
                label: 'Réessayer',
                textColor: Colors.white,
                onPressed: () {
                  // Relancer la génération
                },
              ),
            ),
          );
        }
      },
      icon: const Icon(Icons.picture_as_pdf),
      label: const Text('Envoyer PDF Agent'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
  
  /// 🎯 Exemple 5: Utilisation avec Stream pour suivi en temps réel
  /// 
  /// Suivre le statut d'envoi des emails en temps réel
  static Stream<Map<String, dynamic>> suivreStatutEnvoi(String sessionId) {
    return Stream.periodic(const Duration(seconds: 5), (count) async {
      // Simuler la vérification du statut
      // En réalité, vous pourriez interroger Firestore pour le statut des notifications
      return {
        'sessionId': sessionId,
        'timestamp': DateTime.now(),
        'status': count < 3 ? 'en_cours' : 'termine',
        'emailsEnvoyes': count * 2,
        'emailsTotal': 6,
      };
    }).asyncMap((future) => future);
  }
}

/// 📱 Exemple d'écran complet utilisant le service PDF
class ExemplePDFScreen extends StatefulWidget {
  final String sessionId;
  
  const ExemplePDFScreen({
    Key? key,
    required this.sessionId,
  }) : super(key: key);
  
  @override
  State<ExemplePDFScreen> createState() => _ExemplePDFScreenState();
}

class _ExemplePDFScreenState extends State<ExemplePDFScreen> {
  bool _isGenerating = false;
  String? _lastGeneratedPdfUrl;
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Génération PDF Agent'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Titre
            Text(
              'Générer PDF pour Agents',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              'Générez un rapport PDF moderne et professionnel pour les agents d\'assurance. '
              'Le PDF contient toutes les informations nécessaires au traitement du sinistre.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Bouton de génération
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isGenerating ? null : _genererPDF,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf),
                label: Text(_isGenerating ? 'Génération...' : 'Générer PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Résultat
            if (_lastGeneratedPdfUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green[600]),
                        const SizedBox(width: 8),
                        Text(
                          'PDF généré avec succès !',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Le PDF a été généré et les notifications d\'email ont été créées.',
                      style: TextStyle(color: Colors.green[700]),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Future<void> _genererPDF() async {
    setState(() {
      _isGenerating = true;
    });
    
    try {
      // Exemple avec des données fictives
      final pdfUrl = await ModernPDFAgentService.genererEtEnvoyerPDFAgent(
        sessionId: widget.sessionId,
        agentEmail: 'agent@example.com',
        agencyName: 'Agence Test',
        companyName: 'Compagnie Test',
      );
      
      setState(() {
        _lastGeneratedPdfUrl = pdfUrl;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isGenerating = false;
      });
    }
  }
}
