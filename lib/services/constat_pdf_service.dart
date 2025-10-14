import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

/// 📄 Service de génération PDF pour constat d'accident complet
class ConstatPdfService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📄 Générer le PDF complet du constat
  static Future<File> genererPdfConstat({
    required String sessionId,
    required Map<String, dynamic> sessionData,
  }) async {
    try {
      print('📄 Génération PDF pour session: $sessionId');

      // Créer le document PDF
      final pdf = pw.Document();

      // Récupérer toutes les données nécessaires
      final participants = List<Map<String, dynamic>>.from(sessionData['participants'] ?? []);
      final infosGenerales = sessionData['infosGenerales'] as Map<String, dynamic>? ?? {};
      final croquisData = sessionData['croquisData'] as List<dynamic>? ?? [];

      // Page 1: En-tête et informations générales
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildEnTete(sessionData),
            pw.SizedBox(height: 20),
            _buildInfosGenerales(infosGenerales),
            pw.SizedBox(height: 20),
            _buildListeVehicules(participants),
          ],
        ),
      );

      // Page 2: Détails par véhicule
      for (int i = 0; i < participants.length; i++) {
        final participant = participants[i];
        pdf.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) => [
              _buildDetailVehicule(participant, i + 1),
            ],
          ),
        );
      }

      // Page 3: Croquis et signatures
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            _buildCroquisEtSignatures(croquisData, participants),
          ],
        ),
      );

      // Sauvegarder le fichier
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/constat_${sessionId}_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ PDF généré: ${file.path}');
      return file;

    } catch (e) {
      print('❌ Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// 📋 En-tête du document
  static pw.Widget _buildEnTete(Map<String, dynamic> sessionData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue, width: 2),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'CONSTAT AMIABLE D\'ACCIDENT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue,
                ),
              ),
              pw.Text(
                'N° ${sessionData['codeSession'] ?? 'N/A'}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Date: ${_formatDate(sessionData['dateCreation'])}',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.Text(
            'Statut: ${_getStatutLibelle(sessionData['statut'])}',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// 🌍 Informations générales de l'accident
  static pw.Widget _buildInfosGenerales(Map<String, dynamic> infos) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS GÉNÉRALES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildInfoRow('Date de l\'accident', infos['dateAccident'] ?? 'Non renseignée'),
          _buildInfoRow('Heure', infos['heureAccident'] ?? 'Non renseignée'),
          _buildInfoRow('Lieu', infos['lieuAccident'] ?? 'Non renseigné'),
          _buildInfoRow('Conditions météo', infos['conditionsMeteo'] ?? 'Non renseignées'),
          _buildInfoRow('Blessés', infos['blesses'] == true ? 'Oui' : 'Non'),
          _buildInfoRow('Dégâts matériels', infos['degatsMateriels'] == true ? 'Oui' : 'Non'),
        ],
      ),
    );
  }

  /// 🚗 Liste des véhicules impliqués
  static pw.Widget _buildListeVehicules(List<Map<String, dynamic>> participants) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'VÉHICULES IMPLIQUÉS (${participants.length})',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 8),
          ...participants.asMap().entries.map((entry) {
            final index = entry.key;
            final participant = entry.value;
            final vehicule = participant['vehicule'] as Map<String, dynamic>? ?? {};
            
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 8),
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 30,
                    height: 30,
                    decoration: pw.BoxDecoration(
                      color: _getVehiculeColor(index),
                      borderRadius: pw.BorderRadius.circular(15),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        String.fromCharCode(65 + index), // A, B, C...
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '${vehicule['marque'] ?? 'N/A'} ${vehicule['modele'] ?? ''}',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          'Immatriculation: ${vehicule['immatriculation'] ?? 'N/A'}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        pw.Text(
                          'Conducteur: ${participant['nom'] ?? 'N/A'} ${participant['prenom'] ?? ''}',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  /// 🚗 Détail d'un véhicule
  static pw.Widget _buildDetailVehicule(Map<String, dynamic> participant, int numero) {
    final vehicule = participant['vehicule'] as Map<String, dynamic>? ?? {};
    final conducteur = participant['conducteur'] as Map<String, dynamic>? ?? {};
    final assurance = participant['assurance'] as Map<String, dynamic>? ?? {};
    final circonstances = participant['circonstances'] as List<dynamic>? ?? [];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // En-tête véhicule
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            color: _getVehiculeColor(numero - 1),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            'VÉHICULE ${String.fromCharCode(64 + numero)} - DÉTAILS COMPLETS',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 16),

        // Informations véhicule
        _buildSection('VÉHICULE', [
          _buildInfoRow('Marque', vehicule['marque']),
          _buildInfoRow('Modèle', vehicule['modele']),
          _buildInfoRow('Immatriculation', vehicule['immatriculation']),
          _buildInfoRow('Couleur', vehicule['couleur']),
          _buildInfoRow('Année', vehicule['annee']?.toString()),
        ]),

        pw.SizedBox(height: 12),

        // Informations conducteur
        _buildSection('CONDUCTEUR', [
          _buildInfoRow('Nom', conducteur['nom']),
          _buildInfoRow('Prénom', conducteur['prenom']),
          _buildInfoRow('Date de naissance', conducteur['dateNaissance']),
          _buildInfoRow('Téléphone', conducteur['telephone']),
          _buildInfoRow('Adresse', conducteur['adresse']),
        ]),

        pw.SizedBox(height: 12),

        // Informations assurance
        _buildSection('ASSURANCE', [
          _buildInfoRow('Compagnie', assurance['compagnie']),
          _buildInfoRow('N° Police', assurance['numeroPolice']),
          _buildInfoRow('Agence', assurance['agence']),
          _buildInfoRow('Validité', assurance['validite']),
        ]),

        pw.SizedBox(height: 12),

        // Circonstances
        if (circonstances.isNotEmpty) ...[
          _buildSection('CIRCONSTANCES', [
            pw.Wrap(
              children: circonstances.map((c) => pw.Container(
                margin: const pw.EdgeInsets.only(right: 8, bottom: 4),
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue100,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Text(
                  c.toString(),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              )).toList(),
            ),
          ]),
        ],
      ],
    );
  }

  /// 🎨 Croquis et signatures
  static pw.Widget _buildCroquisEtSignatures(List<dynamic> croquisData, List<Map<String, dynamic>> participants) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CROQUIS ET SIGNATURES',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue,
          ),
        ),
        pw.SizedBox(height: 16),

        // Zone croquis
        pw.Container(
          width: double.infinity,
          height: 300,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: croquisData.isNotEmpty
                ? pw.Text('Croquis avec ${croquisData.length} éléments')
                : pw.Text('Aucun croquis disponible'),
          ),
        ),

        pw.SizedBox(height: 20),

        // Signatures
        pw.Text(
          'SIGNATURES',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),

        ...participants.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;
          final aSigne = participant['aSigne'] as bool? ?? false;

          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey),
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Row(
              children: [
                pw.Text(
                  'Véhicule ${String.fromCharCode(65 + index)}:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  '${participant['nom'] ?? 'N/A'} ${participant['prenom'] ?? ''}',
                ),
                pw.Spacer(),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: aSigne ? PdfColors.green : PdfColors.orange,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Text(
                    aSigne ? 'Signé' : 'En attente',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// 📋 Section avec titre
  static pw.Widget _buildSection(String titre, List<pw.Widget> contenu) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            titre,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue,
            ),
          ),
          pw.SizedBox(height: 8),
          ...contenu,
        ],
      ),
    );
  }

  /// 📝 Ligne d'information
  static pw.Widget _buildInfoRow(String label, String? value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value ?? 'Non renseigné',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  /// 🎨 Couleur par véhicule
  static PdfColor _getVehiculeColor(int index) {
    final colors = [
      PdfColors.blue,
      PdfColors.red,
      PdfColors.green,
      PdfColors.orange,
      PdfColors.purple,
    ];
    return colors[index % colors.length];
  }

  /// 📅 Formatage de date
  static String _formatDate(dynamic date) {
    if (date == null) return 'Non renseignée';
    
    try {
      DateTime dateTime;
      if (date is Timestamp) {
        dateTime = date.toDate();
      } else if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date is DateTime) {
        dateTime = date;
      } else {
        return 'Format invalide';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Erreur format';
    }
  }

  /// 📊 Libellé du statut
  static String _getStatutLibelle(String? statut) {
    switch (statut) {
      case 'creation': return 'En création';
      case 'en_cours': return 'En cours';
      case 'signe': return 'Signé';
      case 'finalise': return 'Finalisé';
      default: return statut ?? 'Inconnu';
    }
  }

  /// 📤 Partager le PDF
  static Future<void> partagerPdf(File pdfFile) async {
    try {
      await Share.shareXFiles(
        [XFile(pdfFile.path)],
        text: 'Constat d\'accident - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
      );
    } catch (e) {
      print('❌ Erreur partage PDF: $e');
      rethrow;
    }
  }

  /// 🖨️ Imprimer le PDF
  static Future<void> imprimerPdf(File pdfFile) async {
    try {
      final bytes = await pdfFile.readAsBytes();
      await Printing.layoutPdf(onLayout: (format) => bytes);
    } catch (e) {
      print('❌ Erreur impression PDF: $e');
      rethrow;
    }
  }

  // ========== NOUVELLES MÉTHODES POUR ENVOI À L'AGENT ==========

  /// 📤 Envoyer le PDF du constat à l'agent responsable
  static Future<Map<String, dynamic>> sendConstatPdfToAgent({
    required String sinistreId,
    required Uint8List pdfBytes,
    required String fileName,
    String? message,
  }) async {
    try {
      debugPrint('[CONSTAT_PDF] 📤 Envoi PDF constat pour sinistre: $sinistreId');

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non authentifié');
      }

      // 1. Récupérer les informations du sinistre
      final sinistreDoc = await _firestore.collection('sinistres').doc(sinistreId).get();
      if (!sinistreDoc.exists) {
        throw Exception('Sinistre non trouvé');
      }

      final sinistreData = sinistreDoc.data()!;
      final agenceId = sinistreData['agenceId'];
      final compagnieId = sinistreData['compagnieId'];
      final conducteurId = sinistreData['conducteurId'];

      if (conducteurId != user.uid) {
        throw Exception('Accès non autorisé à ce sinistre');
      }

      // 2. Trouver l'agent responsable
      final agentInfo = await _findResponsibleAgent(agenceId, compagnieId);
      if (agentInfo == null) {
        throw Exception('Aucun agent trouvé pour cette agence');
      }

      // 3. Uploader le PDF vers Firebase Storage
      final pdfUrl = await _uploadPdfToStorage(
        pdfBytes: pdfBytes,
        fileName: fileName,
        sinistreId: sinistreId,
        conducteurId: conducteurId,
      );

      // 4. Créer l'enregistrement d'envoi
      final envoi = await _createEnvoiRecord(
        sinistreId: sinistreId,
        agentId: agentInfo['id'],
        pdfUrl: pdfUrl,
        fileName: fileName,
        message: message,
        sinistreData: sinistreData,
        agentInfo: agentInfo,
      );

      // 5. Mettre à jour le statut du sinistre
      await _updateSinistreStatus(sinistreId, envoi['id']);

      // 6. Envoyer notification à l'agent
      await _notifyAgent(agentInfo, sinistreData, envoi);

      // 7. Envoyer notification au conducteur (confirmation)
      await _notifyConducteur(conducteurId, sinistreData, agentInfo);

      debugPrint('[CONSTAT_PDF] ✅ PDF envoyé avec succès à l\'agent ${agentInfo['prenom']} ${agentInfo['nom']}');

      return {
        'success': true,
        'envoiId': envoi['id'],
        'agentInfo': agentInfo,
        'pdfUrl': pdfUrl,
        'message': 'PDF envoyé avec succès à l\'agent responsable',
      };

    } catch (e) {
      debugPrint('[CONSTAT_PDF] ❌ Erreur envoi PDF: $e');
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// 🔍 Trouver l'agent responsable de l'agence
  static Future<Map<String, dynamic>?> _findResponsibleAgent(String agenceId, String compagnieId) async {
    try {
      // Chercher d'abord dans l'agence spécifique
      final agenceAgentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('agenceId', isEqualTo: agenceId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (agenceAgentsQuery.docs.isNotEmpty) {
        final agentDoc = agenceAgentsQuery.docs.first;
        return {
          'id': agentDoc.id,
          ...agentDoc.data(),
        };
      }

      // Si pas d'agent dans l'agence, chercher dans la compagnie
      final compagnieAgentsQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'agent')
          .where('compagnieId', isEqualTo: compagnieId)
          .where('isActive', isEqualTo: true)
          .limit(1)
          .get();

      if (compagnieAgentsQuery.docs.isNotEmpty) {
        final agentDoc = compagnieAgentsQuery.docs.first;
        return {
          'id': agentDoc.id,
          ...agentDoc.data(),
        };
      }

      return null;
    } catch (e) {
      debugPrint('[CONSTAT_PDF] ❌ Erreur recherche agent: $e');
      return null;
    }
  }

  /// ☁️ Uploader le PDF vers Firebase Storage
  static Future<String> _uploadPdfToStorage({
    required Uint8List pdfBytes,
    required String fileName,
    required String sinistreId,
    required String conducteurId,
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = 'constats_pdf/$conducteurId/$sinistreId/${timestamp}_$fileName';

      final ref = FirebaseStorage.instance.ref().child(path);
      final uploadTask = ref.putData(
        pdfBytes,
        SettableMetadata(
          contentType: 'application/pdf',
          customMetadata: {
            'sinistreId': sinistreId,
            'conducteurId': conducteurId,
            'uploadedAt': timestamp.toString(),
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('[CONSTAT_PDF] ☁️ PDF uploadé: $path');
      return downloadUrl;
    } catch (e) {
      debugPrint('[CONSTAT_PDF] ❌ Erreur upload PDF: $e');
      throw Exception('Erreur lors de l\'upload du PDF: $e');
    }
  }

  /// 📋 Créer l'enregistrement d'envoi
  static Future<Map<String, dynamic>> _createEnvoiRecord({
    required String sinistreId,
    required String agentId,
    required String pdfUrl,
    required String fileName,
    String? message,
    required Map<String, dynamic> sinistreData,
    required Map<String, dynamic> agentInfo,
  }) async {
    final envoiId = _firestore.collection('envois_constats').doc().id;

    final envoiData = {
      'id': envoiId,
      'sinistreId': sinistreId,
      'conducteurId': FirebaseAuth.instance.currentUser!.uid,
      'agentId': agentId,
      'pdfUrl': pdfUrl,
      'fileName': fileName,
      'message': message,
      'statut': 'envoye',
      'dateEnvoi': FieldValue.serverTimestamp(),
      'lu': false,
      'sinistreInfo': {
        'numeroSinistre': sinistreData['numeroSinistre'],
        'typeAccident': sinistreData['typeAccident'],
        'dateAccident': sinistreData['dateAccident'],
        'lieuAccident': sinistreData['lieuAccident'],
      },
      'agentInfo': {
        'nom': agentInfo['nom'],
        'prenom': agentInfo['prenom'],
        'email': agentInfo['email'],
        'agenceNom': agentInfo['agenceNom'],
      },
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _firestore.collection('envois_constats').doc(envoiId).set(envoiData);

    return {
      'id': envoiId,
      ...envoiData,
    };
  }

  /// 📊 Mettre à jour le statut du sinistre
  static Future<void> _updateSinistreStatus(String sinistreId, String envoiId) async {
    await _firestore.collection('sinistres').doc(sinistreId).update({
      'statutConstat': 'pdf_envoye',
      'envoiConstatId': envoiId,
      'dateEnvoiPdf': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔔 Notifier l'agent
  static Future<void> _notifyAgent(
    Map<String, dynamic> agentInfo,
    Map<String, dynamic> sinistreData,
    Map<String, dynamic> envoi,
  ) async {
    final notificationId = _firestore.collection('notifications').doc().id;

    await _firestore.collection('notifications').doc(notificationId).set({
      'id': notificationId,
      'userId': agentInfo['id'],
      'type': 'nouveau_constat_pdf',
      'titre': 'Nouveau PDF de constat reçu',
      'message': 'Constat PDF reçu pour le sinistre ${sinistreData['numeroSinistre']}',
      'data': {
        'sinistreId': envoi['sinistreId'],
        'envoiId': envoi['id'],
        'numeroSinistre': sinistreData['numeroSinistre'],
        'typeAccident': sinistreData['typeAccident'],
        'conducteurNom': '${sinistreData['conducteurPrenom'] ?? ''} ${sinistreData['conducteurNom'] ?? ''}',
      },
      'lu': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 🔔 Notifier le conducteur (confirmation)
  static Future<void> _notifyConducteur(
    String conducteurId,
    Map<String, dynamic> sinistreData,
    Map<String, dynamic> agentInfo,
  ) async {
    final notificationId = _firestore.collection('notifications').doc().id;

    await _firestore.collection('notifications').doc(notificationId).set({
      'id': notificationId,
      'userId': conducteurId,
      'type': 'constat_pdf_envoye',
      'titre': 'Constat PDF envoyé',
      'message': 'Votre constat PDF a été envoyé à l\'agent ${agentInfo['prenom']} ${agentInfo['nom']}',
      'data': {
        'sinistreId': sinistreData['id'],
        'numeroSinistre': sinistreData['numeroSinistre'],
        'agentNom': '${agentInfo['prenom']} ${agentInfo['nom']}',
        'agenceNom': agentInfo['agenceNom'],
      },
      'lu': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// 📋 Récupérer les envois de constat pour un agent
  static Future<List<Map<String, dynamic>>> getEnvoisForAgent(String agentId) async {
    try {
      final query = await _firestore
          .collection('envois_constats')
          .where('agentId', isEqualTo: agentId)
          .orderBy('dateEnvoi', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('[CONSTAT_PDF] ❌ Erreur récupération envois: $e');
      return [];
    }
  }

  /// 📋 Récupérer les envois de constat pour un conducteur
  static Future<List<Map<String, dynamic>>> getEnvoisForConducteur(String conducteurId) async {
    try {
      final query = await _firestore
          .collection('envois_constats')
          .where('conducteurId', isEqualTo: conducteurId)
          .orderBy('dateEnvoi', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      debugPrint('[CONSTAT_PDF] ❌ Erreur récupération envois: $e');
      return [];
    }
  }

  /// ✅ Marquer un envoi comme lu par l'agent
  static Future<void> markAsRead(String envoiId) async {
    try {
      await _firestore.collection('envois_constats').doc(envoiId).update({
        'lu': true,
        'dateLecture': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[CONSTAT_PDF] ❌ Erreur marquage lu: $e');
    }
  }
}
