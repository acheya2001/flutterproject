import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../core/models/contract_models.dart';
import '../core/services/logging_service.dart';
import '../core/exceptions/app_exceptions.dart';
import '../services/cloudinary_storage_service.dart';

/// 📄 Service de gestion des contrats hybrides (digital + migration papier)
class HybridContractService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🆕 Créer un contrat numérique (nouveau conducteur)
  static Future<String> createDigitalContract({
    required Map<String, dynamic> vehicleData,
    required Map<String, dynamic> conducteurData,
    required String agentId,
    required String typeContrat,
    required double primeAnnuelle,
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    try {
      LoggingService.info('CONTRACT', 'Création contrat digital pour véhicule: ${vehicleData['numeroImmatriculation']}');

      // 1. Générer le numéro de contrat unique
      final numeroContrat = await _generateContractNumber();

      // 2. Récupérer les informations de l'agent
      final agentInfo = await _getAgentInfo(agentId);

      // 3. Créer le document de contrat
      final contractId = _firestore.collection('contrats').doc().id;
      final contractData = {
        'id': contractId,
        'numeroContrat': numeroContrat,
        'typeContrat': typeContrat,
        'primeAnnuelle': primeAnnuelle,
        'dateDebut': Timestamp.fromDate(dateDebut),
        'dateFin': Timestamp.fromDate(dateFin),
        'status': ContractStatus.contractProposed.value,
        
        // Informations conducteur
        'conducteurInfo': {
          'conducteurId': conducteurData['uid'],
          'nom': conducteurData['nom'],
          'prenom': conducteurData['prenom'],
          'cin': conducteurData['cin'],
          'telephone': conducteurData['telephone'],
          'email': conducteurData['email'],
          'adresse': conducteurData['adresse'],
        },
        
        // Informations véhicule
        'vehiculeInfo': {
          'vehiculeId': vehicleData['id'],
          'numeroImmatriculation': vehicleData['numeroImmatriculation'],
          'marque': vehicleData['marque'],
          'modele': vehicleData['modele'],
          'annee': vehicleData['annee'],
          'puissanceFiscale': vehicleData['puissanceFiscale'],
          'typeVehicule': vehicleData['typeVehicule'],
        },
        
        // Informations agent/agence
        'agentId': agentId,
        'agentNom': agentInfo['nom'],
        'agenceId': agentInfo['agenceId'],
        'agenceNom': agentInfo['agenceNom'],
        'compagnieId': agentInfo['compagnieId'],
        'compagnieNom': agentInfo['compagnieNom'],
        
        // Métadonnées
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'createdBy': agentId,
        'contractMethod': 'digital',
      };

      await _firestore.collection('contrats').doc(contractId).set(contractData);

      // 4. Mettre à jour le statut du véhicule
      await _firestore.collection('vehicules').doc(vehicleData['id']).update({
        'etatCompte': 'Contrat Proposé',
        'contractId': contractId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      LoggingService.info('CONTRACT', 'Contrat digital créé: $contractId ($numeroContrat)');
      return contractId;

    } catch (e, stackTrace) {
      LoggingService.error('CONTRACT', 'Erreur création contrat digital', e, stackTrace);
      throw BusinessException(
        'Erreur lors de la création du contrat',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 📄 Migrer un contrat depuis papier
  static Future<String> migrateFromPaper({
    required PaperContract paperContract,
    required String agentId,
  }) async {
    try {
      LoggingService.info('CONTRACT', 'Migration contrat papier: ${paperContract.contractNumber}');

      // 1. Vérifier que le contrat n'existe pas déjà
      final existingContract = await _firestore
          .collection('contrats')
          .where('numeroContrat', isEqualTo: paperContract.contractNumber)
          .get();

      if (existingContract.docs.isNotEmpty) {
        throw BusinessException('Ce contrat existe déjà dans le système');
      }

      // 2. Créer le contrat migré
      final contractId = _firestore.collection('contrats').doc().id;
      final contractData = paperContract.toMap();
      contractData['id'] = contractId;
      contractData['migratedBy'] = agentId;

      await _firestore.collection('contrats').doc(contractId).set(contractData);

      LoggingService.info('CONTRACT', 'Contrat papier migré: $contractId');
      return contractId;

    } catch (e, stackTrace) {
      LoggingService.error('CONTRACT', 'Erreur migration contrat papier', e, stackTrace);
      throw BusinessException(
        'Erreur lors de la migration du contrat',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 📋 Générer les documents numériques
  static Future<Map<String, String>> generateDigitalDocuments(String contractId) async {
    try {
      LoggingService.info('DOCUMENTS', 'Génération documents pour contrat: $contractId');

      // 1. Récupérer les données du contrat
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      if (!contractDoc.exists) {
        throw BusinessException('Contrat non trouvé');
      }

      final contractData = contractDoc.data()!;

      // 2. Générer le contrat PDF
      final contractPdfUrl = await _generateContractPDF(contractData);

      // 3. Générer la carte verte digitale
      final carteVertePdfUrl = await _generateCarteVertePDF(contractData);

      // 4. Générer la quittance
      final quittancePdfUrl = await _generateQuittancePDF(contractData);

      // 5. Sauvegarder les URLs dans le contrat
      await _firestore.collection('contrats').doc(contractId).update({
        'documents': {
          'contractPdf': contractPdfUrl,
          'carteVerte': carteVertePdfUrl,
          'quittance': quittancePdfUrl,
          'generatedAt': FieldValue.serverTimestamp(),
        },
        'documentsGenerated': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      LoggingService.info('DOCUMENTS', 'Documents générés avec succès pour: $contractId');

      return {
        'contractPdf': contractPdfUrl,
        'carteVerte': carteVertePdfUrl,
        'quittance': quittancePdfUrl,
      };

    } catch (e, stackTrace) {
      LoggingService.error('DOCUMENTS', 'Erreur génération documents', e, stackTrace);
      throw BusinessException(
        'Erreur lors de la génération des documents',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// ✅ Activer un contrat après paiement
  static Future<void> activateContract({
    required String contractId,
    required String agentId,
    required Map<String, dynamic> paymentInfo,
  }) async {
    try {
      LoggingService.info('CONTRACT', 'Activation contrat: $contractId');

      // 1. Mettre à jour le statut du contrat
      await _firestore.collection('contrats').doc(contractId).update({
        'status': ContractStatus.active.value,
        'activatedAt': FieldValue.serverTimestamp(),
        'activatedBy': agentId,
        'paymentInfo': paymentInfo,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Récupérer les infos du contrat pour mettre à jour le véhicule
      final contractDoc = await _firestore.collection('contrats').doc(contractId).get();
      final contractData = contractDoc.data()!;

      // 3. Mettre à jour le statut du véhicule
      final vehiculeId = contractData['vehiculeInfo']['vehiculeId'];
      await _firestore.collection('vehicules').doc(vehiculeId).update({
        'etatCompte': 'Assuré',
        'contractId': contractId,
        'activatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 4. Générer les documents si pas encore fait
      if (contractData['documentsGenerated'] != true) {
        await generateDigitalDocuments(contractId);
      }

      // 5. Envoyer notification au conducteur
      await _notifyConducteurContractActive(contractData['conducteurInfo']['conducteurId'], contractId);

      LoggingService.info('CONTRACT', 'Contrat activé avec succès: $contractId');

    } catch (e, stackTrace) {
      LoggingService.error('CONTRACT', 'Erreur activation contrat', e, stackTrace);
      throw BusinessException(
        'Erreur lors de l\'activation du contrat',
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// 📊 Obtenir les statistiques des contrats
  static Future<Map<String, dynamic>> getContractStats({String? agentId}) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      Query query = _firestore.collection('contrats');
      
      if (agentId != null) {
        query = query.where('agentId', isEqualTo: agentId);
      }

      // Contrats ce mois
      final thisMonthQuery = await query
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .get();

      // Contrats actifs
      final activeQuery = await query
          .where('status', isEqualTo: ContractStatus.active.value)
          .get();

      // Contrats en attente de paiement
      final awaitingPaymentQuery = await query
          .where('status', isEqualTo: ContractStatus.awaitingPayment.value)
          .get();

      return {
        'totalThisMonth': thisMonthQuery.docs.length,
        'totalActive': activeQuery.docs.length,
        'awaitingPayment': awaitingPaymentQuery.docs.length,
        'conversionRate': thisMonthQuery.docs.isNotEmpty 
            ? (activeQuery.docs.length / thisMonthQuery.docs.length * 100).round()
            : 0,
      };

    } catch (e) {
      LoggingService.error('CONTRACT', 'Erreur récupération statistiques contrats', e);
      return {
        'totalThisMonth': 0,
        'totalActive': 0,
        'awaitingPayment': 0,
        'conversionRate': 0,
      };
    }
  }

  // ========== MÉTHODES PRIVÉES ==========

  /// 🔢 Générer un numéro de contrat unique
  static Future<String> _generateContractNumber() async {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'CTR-$year-$timestamp';
  }

  /// 👨‍💼 Récupérer les informations de l'agent
  static Future<Map<String, dynamic>> _getAgentInfo(String agentId) async {
    final agentDoc = await _firestore.collection('users').doc(agentId).get();
    
    if (!agentDoc.exists) {
      throw BusinessException('Agent non trouvé');
    }

    return agentDoc.data()!;
  }

  /// 📄 Générer le PDF du contrat
  static Future<String> _generateContractPDF(Map<String, dynamic> contractData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'CONTRAT D\'ASSURANCE AUTOMOBILE',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'N° ${contractData['numeroContrat']}',
                      style: pw.TextStyle(
                        fontSize: 16,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Informations compagnie
              _buildPdfSection('COMPAGNIE D\'ASSURANCE', [
                'Compagnie: ${contractData['compagnieNom']}',
                'Agence: ${contractData['agenceNom']}',
                'Agent: ${contractData['agentNom']}',
              ]),
              
              pw.SizedBox(height: 20),
              
              // Informations assuré
              _buildPdfSection('ASSURÉ', [
                'Nom: ${contractData['conducteurInfo']['prenom']} ${contractData['conducteurInfo']['nom']}',
                'CIN: ${contractData['conducteurInfo']['cin']}',
                'Téléphone: ${contractData['conducteurInfo']['telephone']}',
                'Email: ${contractData['conducteurInfo']['email']}',
              ]),
              
              pw.SizedBox(height: 20),
              
              // Informations véhicule
              _buildPdfSection('VÉHICULE ASSURÉ', [
                'Immatriculation: ${contractData['vehiculeInfo']['numeroImmatriculation']}',
                'Marque: ${contractData['vehiculeInfo']['marque']}',
                'Modèle: ${contractData['vehiculeInfo']['modele']}',
                'Année: ${contractData['vehiculeInfo']['annee']}',
                'Puissance: ${contractData['vehiculeInfo']['puissanceFiscale']} CV',
              ]),
              
              pw.SizedBox(height: 20),
              
              // Informations contrat
              _buildPdfSection('DÉTAILS DU CONTRAT', [
                'Type: ${contractData['typeContrat']}',
                'Prime annuelle: ${contractData['primeAnnuelle']} DT',
                'Date début: ${_formatDate(contractData['dateDebut'])}',
                'Date fin: ${_formatDate(contractData['dateFin'])}',
              ]),
              
              pw.Spacer(),
              
              // Signature
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Text('Signature de l\'Assuré'),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Text('Cachet et Signature de l\'Assureur'),
                      pw.SizedBox(height: 40),
                      pw.Container(
                        width: 150,
                        height: 1,
                        color: PdfColors.black,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Convertir en bytes et uploader
    final pdfBytes = await pdf.save();
    return await _uploadPdfToCloudinary(pdfBytes, 'contrat_${contractData['numeroContrat']}.pdf');
  }

  /// 🟢 Générer le PDF de la carte verte
  static Future<String> _generateCarteVertePDF(Map<String, dynamic> contractData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green, width: 3),
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête carte verte
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'CARTE VERTE D\'ASSURANCE',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Informations principales
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildCarteVerteField('Police N°:', contractData['numeroContrat']),
                          _buildCarteVerteField('Compagnie:', contractData['compagnieNom']),
                          _buildCarteVerteField('Agence:', contractData['agenceNom']),
                          
                          pw.SizedBox(height: 15),
                          pw.Text('VÉHICULE ASSURÉ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          _buildCarteVerteField('Immatriculation:', contractData['vehiculeInfo']['numeroImmatriculation']),
                          _buildCarteVerteField('Marque:', contractData['vehiculeInfo']['marque']),
                          _buildCarteVerteField('Modèle:', contractData['vehiculeInfo']['modele']),
                        ],
                      ),
                    ),
                    
                    pw.SizedBox(width: 20),
                    
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('VALIDITÉ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          _buildCarteVerteField('Du:', _formatDate(contractData['dateDebut'])),
                          _buildCarteVerteField('Au:', _formatDate(contractData['dateFin'])),
                          
                          pw.SizedBox(height: 15),
                          pw.Text('ASSURÉ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          _buildCarteVerteField('Nom:', '${contractData['conducteurInfo']['prenom']} ${contractData['conducteurInfo']['nom']}'),
                          _buildCarteVerteField('CIN:', contractData['conducteurInfo']['cin']),
                        ],
                      ),
                    ),
                  ],
                ),
                
                pw.Spacer(),
                
                // QR Code placeholder et signature
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Container(
                      width: 80,
                      height: 80,
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(),
                      ),
                      child: pw.Center(
                        child: pw.Text('QR CODE', style: pw.TextStyle(fontSize: 10)),
                      ),
                    ),
                    pw.Column(
                      children: [
                        pw.Text('Cachet et Signature'),
                        pw.SizedBox(height: 30),
                        pw.Container(width: 100, height: 1, color: PdfColors.black),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    return await _uploadPdfToCloudinary(pdfBytes, 'carte_verte_${contractData['numeroContrat']}.pdf');
  }

  /// 🧾 Générer le PDF de la quittance
  static Future<String> _generateQuittancePDF(Map<String, dynamic> contractData) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête quittance
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Center(
                  child: pw.Text(
                    'QUITTANCE DE PRIME D\'ASSURANCE',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ),
              
              pw.SizedBox(height: 30),
              
              // Détails de la quittance
              _buildPdfSection('DÉTAILS DE LA QUITTANCE', [
                'N° Contrat: ${contractData['numeroContrat']}',
                'Période: ${_formatDate(contractData['dateDebut'])} au ${_formatDate(contractData['dateFin'])}',
                'Prime annuelle: ${contractData['primeAnnuelle']} DT',
                'Date d\'émission: ${_formatDate(Timestamp.now())}',
              ]),
              
              pw.SizedBox(height: 20),
              
              // Informations assuré
              _buildPdfSection('ASSURÉ', [
                'Nom: ${contractData['conducteurInfo']['prenom']} ${contractData['conducteurInfo']['nom']}',
                'CIN: ${contractData['conducteurInfo']['cin']}',
                'Véhicule: ${contractData['vehiculeInfo']['marque']} ${contractData['vehiculeInfo']['modele']}',
                'Immatriculation: ${contractData['vehiculeInfo']['numeroImmatriculation']}',
              ]),
              
              pw.Spacer(),
              
              // Total et signature
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL À PAYER: ${contractData['primeAnnuelle']} DT',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.Text('Cachet et Signature'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    return await _uploadPdfToCloudinary(pdfBytes, 'quittance_${contractData['numeroContrat']}.pdf');
  }

  /// 📤 Uploader un PDF vers Cloudinary
  static Future<String> _uploadPdfToCloudinary(Uint8List pdfBytes, String fileName) async {
    try {
      // TODO: Implémenter l'upload PDF vers Cloudinary
      // Pour l'instant, on simule avec une URL
      LoggingService.info('PDF', 'Upload PDF simulé: $fileName');
      return 'https://cloudinary.com/pdf/$fileName';
    } catch (e) {
      LoggingService.error('PDF', 'Erreur upload PDF', e);
      throw StorageException('Erreur lors de l\'upload du document PDF');
    }
  }

  /// 🔔 Notifier le conducteur de l'activation du contrat
  static Future<void> _notifyConducteurContractActive(String conducteurId, String contractId) async {
    // TODO: Implémenter les notifications push
    LoggingService.info('NOTIFICATION', 'Contrat activé pour conducteur: $conducteurId');
  }

  // ========== UTILITAIRES PDF ==========

  static pw.Widget _buildPdfSection(String title, List<String> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue900,
          ),
        ),
        pw.SizedBox(height: 10),
        ...items.map((item) => pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Text(item, style: const pw.TextStyle(fontSize: 12)),
        )),
      ],
    );
  }

  static pw.Widget _buildCarteVerteField(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static String _formatDate(dynamic date) {
    if (date is Timestamp) {
      final dateTime = date.toDate();
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    }
    return 'N/A';
  }
}
