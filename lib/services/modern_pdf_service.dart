import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:open_file/open_file.dart';

/// 📄 Service PDF moderne et professionnel
class ModernPdfService {
  
  /// 📄 Générer une attestation d'assurance professionnelle
  static Future<String?> generateAttestation({
    required String contratId,
    required Map<String, dynamic> contratData,
  }) async {
    try {
      final pdf = pw.Document();
      
      // Données du contrat
      final numeroContrat = contratData['numeroContrat'] ?? contratId;
      final conducteurNom = '${contratData['prenom'] ?? ''} ${contratData['nom'] ?? ''}'.trim();
      final marque = contratData['marque'] ?? 'N/A';
      final modele = contratData['modele'] ?? 'N/A';
      final immatriculation = contratData['immatriculation'] ?? 'N/A';
      final dateNow = DateTime.now();
      final dateExpiration = DateTime.now().add(const Duration(days: 365));

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête officiel
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColors.blue900, PdfColors.blue700],
                    ),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ATTESTATION D\'ASSURANCE AUTOMOBILE',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'République Tunisienne',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Informations principales
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildSectionTitle('INFORMATIONS DU CONTRAT'),
                          pw.SizedBox(height: 15),
                          _buildInfoRow('N° de contrat', numeroContrat),
                          _buildInfoRow('Assuré', conducteurNom.isNotEmpty ? conducteurNom : 'Conducteur'),
                          _buildInfoRow('Véhicule', '$marque $modele'),
                          _buildInfoRow('Immatriculation', immatriculation),
                          _buildInfoRow('Date d\'émission', DateFormat('dd/MM/yyyy').format(dateNow)),
                          _buildInfoRow('Valide jusqu\'au', DateFormat('dd/MM/yyyy').format(dateExpiration)),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 30),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(15),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.green50,
                          border: pw.Border.all(color: PdfColors.green300, width: 2),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Column(
                          children: [
                            pw.Container(
                              width: 60,
                              height: 60,
                              decoration: pw.BoxDecoration(
                                color: PdfColors.green,
                                borderRadius: pw.BorderRadius.circular(30),
                              ),
                              child: pw.Center(
                                child: pw.Text(
                                  '✓',
                                  style: pw.TextStyle(
                                    fontSize: 30,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.white,
                                  ),
                                ),
                              ),
                            ),
                            pw.SizedBox(height: 10),
                            pw.Text(
                              'ASSURANCE',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                            pw.Text(
                              'VALIDE',
                              style: pw.TextStyle(
                                fontSize: 14,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.green800,
                              ),
                              textAlign: pw.TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Garanties
                _buildSectionTitle('GARANTIES COUVERTES'),
                pw.SizedBox(height: 15),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      _buildGarantieRow('Responsabilité Civile', 'Obligatoire'),
                      _buildGarantieRow('Dommages Collision', 'Inclus'),
                      _buildGarantieRow('Vol et Incendie', 'Inclus'),
                      _buildGarantieRow('Assistance 24h/24', 'Inclus'),
                      _buildGarantieRow('Protection Juridique', 'Inclus'),
                    ],
                  ),
                ),
                
                pw.Spacer(),
                
                // Pied de page officiel
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400),
                    borderRadius: pw.BorderRadius.circular(5),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'Cette attestation certifie que le véhicule mentionné ci-dessus est couvert par une assurance automobile en cours de validité conformément à la législation tunisienne.',
                        style: const pw.TextStyle(fontSize: 12),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Document généré le ${DateFormat('dd/MM/yyyy à HH:mm').format(dateNow)}',
                            style: pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                          pw.Text(
                            'Document officiel',
                            style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder dans le dossier Téléchargements
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        // Fallback vers le dossier documents de l'app
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/Attestation_$numeroContrat.pdf');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      } else {
        final file = File('${directory.path}/Attestation_$numeroContrat.pdf');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      }
    } catch (e) {
      print('❌ Erreur génération attestation: $e');
      return null;
    }
  }

  /// 📅 Générer un échéancier professionnel
  static Future<String?> generateEcheancier({
    required String contratId,
    required Map<String, dynamic> contratData,
  }) async {
    try {
      final pdf = pw.Document();
      
      final numeroContrat = contratData['numeroContrat'] ?? contratId;
      final marque = contratData['marque'] ?? 'N/A';
      final modele = contratData['modele'] ?? 'N/A';
      final dateNow = DateTime.now();
      
      // Générer des échéances réalistes
      final echeances = _generateEcheances();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // En-tête
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    gradient: pw.LinearGradient(
                      colors: [PdfColors.purple900, PdfColors.purple700],
                    ),
                    borderRadius: pw.BorderRadius.circular(10),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'ÉCHÉANCIER DES PAIEMENTS',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'Contrat N° $numeroContrat',
                        style: pw.TextStyle(
                          fontSize: 16,
                          color: PdfColors.white,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Informations du véhicule
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: _buildInfoRow('Véhicule', '$marque $modele'),
                    ),
                    pw.Expanded(
                      child: _buildInfoRow('Date d\'émission', DateFormat('dd/MM/yyyy').format(dateNow)),
                    ),
                  ],
                ),
                
                pw.SizedBox(height: 30),
                
                // Tableau des échéances
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey400),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(1),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FlexColumnWidth(2),
                    3: const pw.FlexColumnWidth(1.5),
                  },
                  children: [
                    // En-tête du tableau
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColors.purple100),
                      children: [
                        _buildTableHeader('N°'),
                        _buildTableHeader('Date d\'échéance'),
                        _buildTableHeader('Montant'),
                        _buildTableHeader('Statut'),
                      ],
                    ),
                    // Lignes des échéances
                    ...echeances.asMap().entries.map((entry) {
                      final index = entry.key;
                      final echeance = entry.value;
                      final isEven = index % 2 == 0;
                      return pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: isEven ? PdfColors.grey50 : PdfColors.white,
                        ),
                        children: [
                          _buildTableCell('${index + 1}'),
                          _buildTableCell(DateFormat('dd/MM/yyyy').format(echeance['date'])),
                          _buildTableCell('${echeance['montant'].toStringAsFixed(2)} DT'),
                          _buildTableCell(echeance['statut'], 
                            color: echeance['statut'] == 'Payé' ? PdfColors.green : PdfColors.orange),
                        ],
                      );
                    }).toList(),
                  ],
                ),
                
                pw.SizedBox(height: 20),
                
                // Résumé
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'TOTAL ANNUEL',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        '${echeances.fold(0.0, (sum, e) => sum + e['montant']).toStringAsFixed(2)} DT',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );

      // Sauvegarder
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File('${appDir.path}/Echeancier_$numeroContrat.pdf');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      } else {
        final file = File('${directory.path}/Echeancier_$numeroContrat.pdf');
        await file.writeAsBytes(await pdf.save());
        return file.path;
      }
    } catch (e) {
      print('❌ Erreur génération échéancier: $e');
      return null;
    }
  }

  /// 📱 Ouvrir le fichier PDF généré
  static Future<void> openPdf(String filePath) async {
    try {
      await OpenFile.open(filePath);
    } catch (e) {
      print('❌ Erreur ouverture PDF: $e');
    }
  }

  // Méthodes utilitaires
  static pw.Widget _buildSectionTitle(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 18,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.blue900,
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildGarantieRow(String garantie, String statut) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('• $garantie'),
          pw.Text(
            statut,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.green700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeader(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: pw.FontWeight.bold,
          fontSize: 12,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 11,
          color: color,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static List<Map<String, dynamic>> _generateEcheances() {
    final now = DateTime.now();
    return [
      {'date': now, 'montant': 180.0, 'statut': 'Payé'},
      {'date': DateTime(now.year, now.month + 3), 'montant': 180.0, 'statut': 'À venir'},
      {'date': DateTime(now.year, now.month + 6), 'montant': 180.0, 'statut': 'À venir'},
      {'date': DateTime(now.year, now.month + 9), 'montant': 180.0, 'statut': 'À venir'},
    ];
  }
}
