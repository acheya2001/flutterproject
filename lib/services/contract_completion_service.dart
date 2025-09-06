import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'dart:convert';
import 'notification_service.dart';

/// 🎯 Service de finalisation de contrat après création par l'agent
class ContractCompletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📋 Traitement complet après création de contrat
  static Future<Map<String, dynamic>> completeContractProcess({
    required String contractId,
    required String vehicleId,
    required String conducteurId,
    required Map<String, dynamic> contractData,
  }) async {
    try {
      print('🎯 [CONTRACT_COMPLETION] Début finalisation contrat: $contractId');

      final results = <String, dynamic>{};

      // 1. Mettre à jour le statut du véhicule: en_attente → assuré
      await _updateVehicleToInsured(vehicleId, contractId, contractData);
      results['vehicleStatusUpdated'] = true;

      // 2. Générer les documents d'assurance
      final documents = await _generateInsuranceDocuments(contractData, vehicleId, conducteurId);
      results['documents'] = documents;

      // 3. Créer la carte verte numérique
      final carteVerte = await _generateCarteVerte(contractData);
      results['carteVerte'] = carteVerte;

      // 4. Générer la quittance de paiement
      final quittance = await _generateQuittancePaiement(contractData);
      results['quittance'] = quittance;

      // 5. Créer un certificat numérique avec QR Code
      final certificat = await _generateCertificatNumerique(contractData);
      results['certificat'] = certificat;

      // 6. Envoyer notification au conducteur
      await _notifyConducteurContractValidated(conducteurId, contractData, documents);
      results['notificationSent'] = true;

      // 7. Archiver dans la base de données pour audit
      await _archiveContractForAudit(contractId, contractData, documents);
      results['archived'] = true;

      print('✅ [CONTRACT_COMPLETION] Finalisation terminée pour contrat: $contractId');
      return results;

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur finalisation: $e');
      throw Exception('Erreur lors de la finalisation du contrat: $e');
    }
  }

  /// 🚗 Mettre à jour le statut du véhicule: en_attente → assuré
  static Future<void> _updateVehicleToInsured(
    String vehicleId, 
    String contractId, 
    Map<String, dynamic> contractData
  ) async {
    try {
      await _firestore.collection('vehicules').doc(vehicleId).update({
        'etatCompte': 'assuré',
        'statutAssurance': 'assuré',
        'contractId': contractId,
        'numeroContratAssurance': contractData['numeroContrat'],
        'dateAssurance': FieldValue.serverTimestamp(),
        'compagnieAssuranceId': contractData['compagnieId'],
        'agenceAssuranceId': contractData['agenceId'],
        'typeAssurance': contractData['typeContrat'],
        'primeAnnuelle': contractData['primeAnnuelle'],
        'dateDebutAssurance': contractData['dateDebut'],
        'dateFinAssurance': contractData['dateFin'],
        'isAssured': true,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ [CONTRACT_COMPLETION] Véhicule $vehicleId mis à jour: en_attente → assuré');
    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur mise à jour véhicule: $e');
      throw e;
    }
  }

  /// 📄 Générer tous les documents d'assurance
  static Future<Map<String, String>> _generateInsuranceDocuments(
    Map<String, dynamic> contractData,
    String vehicleId,
    String conducteurId,
  ) async {
    try {
      final documents = <String, String>{};

      // Récupérer les informations complètes
      final vehicleDoc = await _firestore.collection('vehicules').doc(vehicleId).get();
      final conducteurDoc = await _firestore.collection('users').doc(conducteurId).get();
      
      final vehicleInfo = vehicleDoc.data() ?? {};
      final conducteurInfo = conducteurDoc.data() ?? {};

      // 1. Contrat d'assurance complet (police d'assurance)
      final contratPdf = await _generateContratAssurance(contractData, vehicleInfo, conducteurInfo);
      documents['contrat_assurance'] = contratPdf;

      return documents;

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur génération documents: $e');
      throw e;
    }
  }

  /// 📋 Générer le contrat d'assurance (police d'assurance)
  static Future<String> _generateContratAssurance(
    Map<String, dynamic> contractData,
    Map<String, dynamic> vehicleInfo,
    Map<String, dynamic> conducteurInfo,
  ) async {
    try {
      final pdf = pw.Document();

      // Récupérer les informations de l'agence et compagnie
      final agenceDoc = await _firestore.collection('agences').doc(contractData['agenceId']).get();
      final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(contractData['compagnieId']).get();
      
      final agenceInfo = agenceDoc.data() ?? {};
      final compagnieInfo = compagnieDoc.data() ?? {};

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              // En-tête
              _buildContractHeader(compagnieInfo, agenceInfo),
              pw.SizedBox(height: 30),

              // Titre
              pw.Center(
                child: pw.Text(
                  'CONTRAT D\'ASSURANCE AUTOMOBILE',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // Informations du contrat
              _buildContractInfo(contractData),
              pw.SizedBox(height: 20),

              // Informations de l'assuré
              _buildAssuredInfo(conducteurInfo),
              pw.SizedBox(height: 20),

              // Informations du véhicule
              _buildVehicleInfo(vehicleInfo),
              pw.SizedBox(height: 20),

              // Garanties et conditions
              _buildGuarantiesInfo(contractData),
              pw.SizedBox(height: 20),

              // Informations financières
              _buildFinancialInfo(contractData),
              pw.SizedBox(height: 30),

              // Signatures
              _buildSignatures(agenceInfo),
            ];
          },
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/contrat_${contractData['numeroContrat']}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ [CONTRACT_COMPLETION] Contrat PDF généré: ${file.path}');
      return file.path;

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur génération contrat PDF: $e');
      throw e;
    }
  }

  /// 🏢 En-tête du contrat
  static pw.Widget _buildContractHeader(
    Map<String, dynamic> compagnieInfo,
    Map<String, dynamic> agenceInfo,
  ) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              compagnieInfo['nom'] ?? 'Compagnie d\'Assurance',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(compagnieInfo['adresse'] ?? ''),
            pw.Text('Tél: ${compagnieInfo['telephone'] ?? ''}'),
            pw.Text('Email: ${compagnieInfo['email'] ?? ''}'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Agence: ${agenceInfo['nom'] ?? ''}',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(agenceInfo['adresse'] ?? ''),
            pw.Text('Tél: ${agenceInfo['telephone'] ?? ''}'),
          ],
        ),
      ],
    );
  }

  /// 📋 Informations du contrat
  static pw.Widget _buildContractInfo(Map<String, dynamic> contractData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DU CONTRAT',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Numéro de contrat: ${contractData['numeroContrat'] ?? ''}'),
              pw.Text('Type: ${contractData['typeContratDisplay'] ?? contractData['typeContrat'] ?? ''}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Date de début: ${_formatDate(contractData['dateDebut'])}'),
              pw.Text('Date de fin: ${_formatDate(contractData['dateFin'])}'),
            ],
          ),
        ],
      ),
    );
  }

  /// 👤 Informations de l'assuré
  static pw.Widget _buildAssuredInfo(Map<String, dynamic> conducteurInfo) {
    final proprietaireInfo = conducteurInfo['proprietaireInfo'] as Map<String, dynamic>? ?? {};
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DE L\'ASSURÉ',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Nom: ${proprietaireInfo['nom'] ?? conducteurInfo['nom'] ?? ''}'),
          pw.Text('Prénom: ${proprietaireInfo['prenom'] ?? conducteurInfo['prenom'] ?? ''}'),
          pw.Text('Adresse: ${proprietaireInfo['adresse'] ?? conducteurInfo['adresse'] ?? ''}'),
          pw.Text('Téléphone: ${conducteurInfo['telephone'] ?? ''}'),
          pw.Text('Email: ${conducteurInfo['email'] ?? ''}'),
          pw.Text('N° Permis: ${proprietaireInfo['numeroPermis'] ?? conducteurInfo['numeroPermis'] ?? ''}'),
        ],
      ),
    );
  }

  /// 🚗 Informations du véhicule
  static pw.Widget _buildVehicleInfo(Map<String, dynamic> vehicleInfo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS DU VÉHICULE',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Marque: ${vehicleInfo['marque'] ?? ''}'),
              pw.Text('Modèle: ${vehicleInfo['modele'] ?? ''}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Immatriculation: ${vehicleInfo['numeroImmatriculation'] ?? ''}'),
              pw.Text('Année: ${vehicleInfo['annee'] ?? ''}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Puissance fiscale: ${vehicleInfo['puissanceFiscale'] ?? ''} CV'),
              pw.Text('Usage: ${vehicleInfo['usage'] ?? ''}'),
            ],
          ),
          if (vehicleInfo['numeroSerie'] != null)
            pw.Text('N° de série: ${vehicleInfo['numeroSerie']}'),
        ],
      ),
    );
  }

  /// 🛡️ Garanties et conditions
  static pw.Widget _buildGuarantiesInfo(Map<String, dynamic> contractData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GARANTIES ET CONDITIONS',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text('Type de couverture: ${contractData['typeContratDisplay'] ?? contractData['typeContrat'] ?? ''}'),
          pw.SizedBox(height: 5),
          pw.Text('Garanties incluses:'),
          pw.Bullet(text: 'Responsabilité civile obligatoire'),
          if (contractData['typeContrat'] == 'tous_risques') ...[
            pw.Bullet(text: 'Dommages tous accidents'),
            pw.Bullet(text: 'Vol et incendie'),
            pw.Bullet(text: 'Bris de glace'),
          ],
          if (contractData['typeContrat'] == 'tiers_complet') ...[
            pw.Bullet(text: 'Vol et incendie'),
            pw.Bullet(text: 'Bris de glace'),
          ],
        ],
      ),
    );
  }

  /// 💰 Informations financières
  static pw.Widget _buildFinancialInfo(Map<String, dynamic> contractData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'INFORMATIONS FINANCIÈRES',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Prime annuelle: ${contractData['primeAnnuelle'] ?? 0} DT'),
              pw.Text('Franchise: ${contractData['franchise'] ?? 'Non applicable'}'),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Text('Mode de paiement: Annuel'),
          pw.Text('Statut: ${contractData['statut'] ?? 'Actif'}'),
        ],
      ),
    );
  }

  /// ✍️ Signatures
  static pw.Widget _buildSignatures(Map<String, dynamic> agenceInfo) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('L\'Assuré'),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
            pw.Text('Signature'),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text('L\'Assureur'),
            pw.SizedBox(height: 40),
            pw.Container(
              width: 150,
              height: 1,
              color: PdfColors.black,
            ),
            pw.Text('${agenceInfo['nom'] ?? 'Agence'}'),
          ],
        ),
      ],
    );
  }

  /// 📅 Formater une date
  static String _formatDate(dynamic date) {
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

  /// 🟢 Générer la carte verte d'assurance
  static Future<String> _generateCarteVerte(Map<String, dynamic> contractData) async {
    try {
      final pdf = pw.Document();

      // Récupérer les informations de la compagnie
      final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(contractData['compagnieId']).get();
      final compagnieInfo = compagnieDoc.data() ?? {};

      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(85 * PdfPageFormat.mm, 54 * PdfPageFormat.mm), // Format carte de crédit
          margin: const pw.EdgeInsets.all(8),
          build: (pw.Context context) {
            return pw.Container(
              decoration: pw.BoxDecoration(
                color: PdfColors.green50,
                border: pw.Border.all(color: PdfColors.green, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // En-tête
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CARTE VERTE',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.green800,
                        ),
                      ),
                      pw.Text(
                        'TUNISIE',
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 4),

                  // Informations principales
                  pw.Text(
                    compagnieInfo['nom'] ?? 'Compagnie d\'Assurance',
                    style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.SizedBox(height: 2),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('N° Contrat:', style: const pw.TextStyle(fontSize: 7)),
                      pw.Text(
                        contractData['numeroContrat'] ?? '',
                        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Immatriculation:', style: const pw.TextStyle(fontSize: 7)),
                      pw.Text(
                        contractData['vehiculeInfo']?['immatriculation'] ?? '',
                        style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),

                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Validité:', style: const pw.TextStyle(fontSize: 7)),
                      pw.Text(
                        '${_formatDate(contractData['dateDebut'])} - ${_formatDate(contractData['dateFin'])}',
                        style: const pw.TextStyle(fontSize: 6),
                      ),
                    ],
                  ),

                  pw.Spacer(),

                  // Pied de page
                  pw.Center(
                    child: pw.Text(
                      'Attestation d\'assurance obligatoire',
                      style: const pw.TextStyle(fontSize: 6),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/carte_verte_${contractData['numeroContrat']}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ [CONTRACT_COMPLETION] Carte verte générée: ${file.path}');
      return file.path;

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur génération carte verte: $e');
      throw e;
    }
  }

  /// 🧾 Générer la quittance de paiement
  static Future<String> _generateQuittancePaiement(Map<String, dynamic> contractData) async {
    try {
      final pdf = pw.Document();

      // Récupérer les informations de l'agence et compagnie
      final agenceDoc = await _firestore.collection('agences').doc(contractData['agenceId']).get();
      final compagnieDoc = await _firestore.collection('compagnies_assurance').doc(contractData['compagnieId']).get();

      final agenceInfo = agenceDoc.data() ?? {};
      final compagnieInfo = compagnieDoc.data() ?? {};

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête similaire à l'exemple tunisien
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          compagnieInfo['nom'] ?? 'Compagnie d\'Assurance',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(compagnieInfo['adresse'] ?? ''),
                        pw.Text('Tél: ${compagnieInfo['telephone'] ?? ''}'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'QUITTANCE DE PRIME N°',
                          style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          contractData['numeroContrat'] ?? '',
                          style: pw.TextStyle(
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 30),

                // Informations du client (style tunisien)
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Nom, Prénom et Adresse',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text('${contractData['proprietaireInfo']?['prenom'] ?? ''} ${contractData['proprietaireInfo']?['nom'] ?? ''}'),
                      pw.Text(contractData['proprietaireInfo']?['adresse'] ?? ''),

                      pw.SizedBox(height: 10),

                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Type client:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('Personne physique'),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('Identification du véhicule', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                              pw.Text('Marque: ${contractData['vehiculeInfo']?['marque'] ?? ''}'),
                              pw.Text('Type: ${contractData['vehiculeInfo']?['modele'] ?? ''}'),
                              pw.Text('Immatriculation: ${contractData['vehiculeInfo']?['immatriculation'] ?? ''}'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Tableau des primes (style tunisien)
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.black),
                  children: [
                    // En-tête du tableau
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Code Agence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Contrat N°', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Prime nette', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Prime totale TTC', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    // Données
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(agenceInfo['code'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(contractData['numeroContrat'] ?? ''),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${contractData['primeAnnuelle'] ?? 0} DT'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${contractData['primeAnnuelle'] ?? 0} DT'),
                        ),
                      ],
                    ),
                  ],
                ),

                pw.SizedBox(height: 20),

                // Période de validité
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Période de validité du: ${_formatDate(contractData['dateDebut'])}'),
                      pw.Text('au: ${_formatDate(contractData['dateFin'])}'),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Signature et cachet
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Column(
                      children: [
                        pw.Text('Signature et cachet de l\'agence'),
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

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/quittance_${contractData['numeroContrat']}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ [CONTRACT_COMPLETION] Quittance générée: ${file.path}');
      return file.path;

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur génération quittance: $e');
      throw e;
    }
  }

  /// 📱 Générer un certificat numérique avec QR Code
  static Future<String> _generateCertificatNumerique(Map<String, dynamic> contractData) async {
    try {
      // Données pour le QR Code
      final qrData = {
        'numeroContrat': contractData['numeroContrat'],
        'immatriculation': contractData['vehiculeInfo']?['immatriculation'],
        'compagnie': contractData['compagnieId'],
        'validite': _formatDate(contractData['dateFin']),
        'type': 'certificat_assurance',
      };

      final qrString = jsonEncode(qrData);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  'CERTIFICAT NUMÉRIQUE D\'ASSURANCE',
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 30),

                pw.Text(
                  'Ce certificat atteste que le véhicule ci-dessous est assuré',
                  style: const pw.TextStyle(fontSize: 14),
                ),
                pw.SizedBox(height: 20),

                // Informations du véhicule
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'VÉHICULE ASSURÉ',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Text('Immatriculation: ${contractData['vehiculeInfo']?['immatriculation'] ?? ''}'),
                      pw.Text('Marque: ${contractData['vehiculeInfo']?['marque'] ?? ''}'),
                      pw.Text('Modèle: ${contractData['vehiculeInfo']?['modele'] ?? ''}'),
                      pw.Text('N° Contrat: ${contractData['numeroContrat'] ?? ''}'),
                      pw.Text('Validité: ${_formatDate(contractData['dateDebut'])} au ${_formatDate(contractData['dateFin'])}'),
                    ],
                  ),
                ),

                pw.SizedBox(height: 30),

                // QR Code (placeholder - nécessite une implémentation spécifique)
                pw.Container(
                  width: 150,
                  height: 150,
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black),
                  ),
                  child: pw.Center(
                    child: pw.Text(
                      'QR CODE\n\n${contractData['numeroContrat']}',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ),
                ),

                pw.SizedBox(height: 20),

                pw.Text(
                  'Scannez ce QR Code pour vérifier l\'authenticité',
                  style: const pw.TextStyle(fontSize: 12),
                ),

                pw.Spacer(),

                pw.Text(
                  'Document généré électroniquement le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder le PDF
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/certificat_${contractData['numeroContrat']}.pdf');
      await file.writeAsBytes(await pdf.save());

      print('✅ [CONTRACT_COMPLETION] Certificat numérique généré: ${file.path}');
      return file.path;

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur génération certificat: $e');
      throw e;
    }
  }

  /// 📧 Notifier le conducteur que son contrat est validé
  static Future<void> _notifyConducteurContractValidated(
    String conducteurId,
    Map<String, dynamic> contractData,
    Map<String, String> documents,
  ) async {
    try {
      // Utiliser le service de notification amélioré
      await NotificationService.notifyContractValidated(
        conducteurId: conducteurId,
        contractId: contractData['id'] ?? '',
        numeroContrat: contractData['numeroContrat'] ?? '',
        vehiculeImmatriculation: contractData['vehiculeInfo']?['immatriculation'] ?? '',
        typeAssurance: contractData['typeContratDisplay'] ?? contractData['typeContrat'] ?? '',
        documents: documents,
      );

      // Notifier aussi la disponibilité des documents
      await NotificationService.notifyDocumentsReady(
        conducteurId: conducteurId,
        numeroContrat: contractData['numeroContrat'] ?? '',
        documentTypes: documents.keys.toList(),
      );

      print('✅ [CONTRACT_COMPLETION] Notifications envoyées au conducteur: $conducteurId');

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur notification conducteur: $e');
      // Ne pas faire échouer le processus pour une erreur de notification
    }
  }

  /// 📚 Archiver le contrat pour audit et BI
  static Future<void> _archiveContractForAudit(
    String contractId,
    Map<String, dynamic> contractData,
    Map<String, String> documents,
  ) async {
    try {
      // Créer un enregistrement d'audit
      await _firestore.collection('audit_contrats').add({
        'contractId': contractId,
        'action': 'contrat_finalise',
        'contractData': contractData,
        'documents': documents,
        'processedAt': FieldValue.serverTimestamp(),
        'processedBy': _auth.currentUser?.uid,
        'agentId': contractData['agentId'],
        'agenceId': contractData['agenceId'],
        'compagnieId': contractData['compagnieId'],
        'vehiculeId': contractData['vehiculeId'],
        'conducteurId': contractData['conducteurId'],
        'status': 'completed',
      });

      // Mettre à jour les statistiques de l'agence
      await _updateAgenceStatistics(contractData['agenceId'], contractData);

      print('✅ [CONTRACT_COMPLETION] Contrat archivé pour audit: $contractId');

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur archivage: $e');
      // Ne pas faire échouer le processus pour une erreur d'archivage
    }
  }

  /// 📊 Mettre à jour les statistiques de l'agence
  static Future<void> _updateAgenceStatistics(String agenceId, Map<String, dynamic> contractData) async {
    try {
      final agenceRef = _firestore.collection('agences').doc(agenceId);

      await _firestore.runTransaction((transaction) async {
        final agenceDoc = await transaction.get(agenceRef);

        if (agenceDoc.exists) {
          final currentStats = agenceDoc.data()?['statistiques'] as Map<String, dynamic>? ?? {};

          // Incrémenter les compteurs
          final newStats = {
            ...currentStats,
            'contratsActifs': (currentStats['contratsActifs'] ?? 0) + 1,
            'primeTotal': (currentStats['primeTotal'] ?? 0.0) + (contractData['primeAnnuelle'] ?? 0.0),
            'dernierContrat': FieldValue.serverTimestamp(),
          };

          transaction.update(agenceRef, {
            'statistiques': newStats,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      print('✅ [CONTRACT_COMPLETION] Statistiques agence mises à jour: $agenceId');

    } catch (e) {
      print('❌ [CONTRACT_COMPLETION] Erreur mise à jour statistiques: $e');
    }
  }
}
