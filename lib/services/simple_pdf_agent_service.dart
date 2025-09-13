import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/collaborative_session_model.dart';

/// 📄 Service simplifié de génération PDF pour agents d'assurance
class SimplePDFAgentService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // 🎨 Couleurs pour le PDF
  static const _primaryColor = PdfColor.fromInt(0xFF1565C0);
  static const _successColor = PdfColor.fromInt(0xFF2E7D32);
  static const _lightGray = PdfColor.fromInt(0xFFF5F5F5);
  
  /// 🎯 Méthode principale pour générer et envoyer un PDF
  static Future<String> genererEtEnvoyerPDFAgent({
    required String sessionId,
    required String agentEmail,
    required String agencyName,
    required String companyName,
  }) async {
    try {
      print('📄 Génération PDF pour session: $sessionId');
      
      // Charger la session collaborative
      final sessionDoc = await _firestore.collection('collaborative_sessions').doc(sessionId).get();
      if (!sessionDoc.exists) {
        throw Exception('Session non trouvée: $sessionId');
      }

      final session = CollaborativeSession.fromMap(sessionDoc.data()!, sessionDoc.id);

      // Générer le PDF
      final pdfBytes = await _genererPDFSimple(
        session: session,
        agentEmail: agentEmail,
        agencyName: agencyName,
        companyName: companyName,
      );

      // Sauvegarder dans Firebase Storage
      final fileName = 'constat_${session.codeSession}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final ref = _storage.ref().child('pdfs_agents').child(fileName);
      
      await ref.putData(pdfBytes);
      final downloadUrl = await ref.getDownloadURL();

      // Créer une notification pour l'agent
      await _creerNotificationAgent(
        agentEmail: agentEmail,
        sessionId: sessionId,
        pdfUrl: downloadUrl,
        agencyName: agencyName,
        companyName: companyName,
      );

      print('✅ PDF généré et notification créée: $downloadUrl');
      return downloadUrl;

    } catch (e) {
      print('❌ Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// 📄 Générer le PDF simple
  static Future<Uint8List> _genererPDFSimple({
    required CollaborativeSession session,
    required String agentEmail,
    required String agencyName,
    required String companyName,
  }) async {
    final pdf = pw.Document();

    // Page unique avec toutes les informations
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête
            _buildHeader(session, agentEmail, agencyName, companyName),
            
            pw.SizedBox(height: 30),
            
            // Informations de la session
            _buildSessionInfo(session),
            
            pw.SizedBox(height: 30),
            
            // Participants
            _buildParticipants(session),
            
            pw.SizedBox(height: 30),
            
            // Instructions pour l'agent
            _buildInstructions(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// 📋 En-tête du PDF
  static pw.Widget _buildHeader(
    CollaborativeSession session,
    String agentEmail,
    String agencyName,
    String companyName,
  ) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: _primaryColor,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RAPPORT DE CONSTAT AUTOMOBILE',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Session: ${session.codeSession}',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.white,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Destinataire: $agentEmail',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Agence: $agencyName',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
          pw.Text(
            'Compagnie: $companyName',
            style: pw.TextStyle(
              fontSize: 12,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Informations de la session
  static pw.Widget _buildSessionInfo(CollaborativeSession session) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS GÉNÉRALES',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Code Session: ${session.codeSession}'),
          pw.Text('Type d\'accident: ${session.typeAccident}'),
          pw.Text('Nombre de véhicules: ${session.nombreVehicules}'),
          pw.Text('Statut: ${_getStatutLabel(session.statut)}'),
          pw.Text('Date de création: ${_formatDate(session.dateCreation)}'),
          if (session.dateFinalisation != null)
            pw.Text('Date de finalisation: ${_formatDate(session.dateFinalisation!)}'),
        ],
      ),
    );
  }

  /// 👥 Liste des participants
  static pw.Widget _buildParticipants(CollaborativeSession session) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PARTICIPANTS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        pw.SizedBox(height: 10),
        ...session.participants.map((participant) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Véhicule ${participant.roleVehicule}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('Nom: ${participant.nom} ${participant.prenom}'),
              pw.Text('Email: ${participant.email}'),
              pw.Text('Téléphone: ${participant.telephone}'),
              pw.Text('Statut: ${participant.statut.toString().split('.').last}'),
            ],
          ),
        )),
      ],
    );
  }

  /// 📝 Instructions pour l'agent
  static pw.Widget _buildInstructions() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _successColor.shade(0.1),
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _successColor),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INSTRUCTIONS POUR L\'AGENT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: _successColor,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text('• Vérifier les informations des participants'),
          pw.Text('• Consulter l\'application pour les détails complets'),
          pw.Text('• Contacter les participants si nécessaire'),
          pw.Text('• Traiter le dossier selon les procédures'),
        ],
      ),
    );
  }

  /// 📧 Créer une notification pour l'agent
  static Future<void> _creerNotificationAgent({
    required String agentEmail,
    required String sessionId,
    required String pdfUrl,
    required String agencyName,
    required String companyName,
  }) async {
    await _firestore.collection('notifications_agents').add({
      'destinataire': agentEmail,
      'type': 'constat_simple',
      'sessionId': sessionId,
      'pdfUrl': pdfUrl,
      'agencyName': agencyName,
      'companyName': companyName,
      'dateCreation': FieldValue.serverTimestamp(),
      'statut': 'en_attente',
      'objet': 'Nouveau constat d\'accident - Session $sessionId',
      'message': 'Un nouveau constat d\'accident a été finalisé et nécessite votre attention.',
    });
  }

  /// 📅 Formater une date
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// 📊 Obtenir le libellé du statut
  static String _getStatutLabel(SessionStatus statut) {
    switch (statut) {
      case SessionStatus.creation:
        return 'Création';
      case SessionStatus.attente_participants:
        return 'En attente';
      case SessionStatus.en_cours:
        return 'En cours';
      case SessionStatus.validation_croquis:
        return 'Validation croquis';
      case SessionStatus.pret_signature:
        return 'Prêt signature';
      case SessionStatus.signe:
        return 'Signé';
      case SessionStatus.finalise:
        return 'Finalisé ✅';
      case SessionStatus.annule:
        return 'Annulé ❌';
      default:
        return 'Inconnu';
    }
  }
}
