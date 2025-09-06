import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

class PDFService {
  /// 📄 Générer l'attestation d'assurance
  static Future<String> generateAttestation(Map<String, dynamic> contratData) async {
    final pdf = pw.Document();
    
    // Données du contrat
    final numeroContrat = contratData['numeroContrat'] ?? 'N/A';
    final vehicule = contratData['vehicule'] as Map<String, dynamic>? ?? {};
    final conducteur = contratData['conducteur'] as Map<String, dynamic>? ?? {};
    final compagnieNom = contratData['compagnieNom'] ?? 'Compagnie d\'Assurance';
    final agenceNom = contratData['agenceNom'] ?? 'Agence';
    final formuleLabel = contratData['formuleAssuranceLabel'] ?? 'Responsabilité Civile';
    final dateDebut = contratData['dateDebut']?.toDate() ?? DateTime.now();
    final dateFin = contratData['dateFin']?.toDate() ?? DateTime.now().add(const Duration(days: 365));

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
                  color: PdfColors.blue50,
                  border: pw.Border.all(color: PdfColors.blue200),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(
                      'ATTESTATION D\'ASSURANCE',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'République Tunisienne',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.Text(
                      'Ministère du Transport',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Informations de la compagnie
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COMPAGNIE D\'ASSURANCE',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Compagnie: $compagnieNom'),
                    pw.Text('Agence: $agenceNom'),
                    pw.Text('N° de Contrat: $numeroContrat'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Informations du véhicule
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'VÉHICULE ASSURÉ',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Marque: ${vehicule['marque'] ?? 'N/A'}'),
                    pw.Text('Modèle: ${vehicule['modele'] ?? 'N/A'}'),
                    pw.Text('Immatriculation: ${vehicule['immatriculation'] ?? 'N/A'}'),
                    pw.Text('Année: ${vehicule['annee'] ?? 'N/A'}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Informations de l'assurance
              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COUVERTURE D\'ASSURANCE',
                      style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text('Formule: $formuleLabel'),
                    pw.Text('Période de validité:'),
                    pw.Text('Du ${_formatDate(dateDebut)} au ${_formatDate(dateFin)}'),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Déclaration officielle
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green200),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'DÉCLARATION',
                      style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      'Nous certifions que le véhicule ci-dessus désigné est garanti par un contrat d\'assurance en cours de validité couvrant la responsabilité civile automobile conformément à la législation tunisienne.',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Pied de page
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Date d\'émission:'),
                      pw.Text(_formatDate(DateTime.now())),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Signature et cachet'),
                      pw.SizedBox(height: 30),
                      pw.Text('_________________'),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Sauvegarder le fichier
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/attestation_$numeroContrat.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  /// 💚 Générer la carte verte digitale
  static Future<String> generateCarteVerte(Map<String, dynamic> contratData) async {
    final pdf = pw.Document();
    
    // Données du contrat
    final numeroContrat = contratData['numeroContrat'] ?? 'N/A';
    final vehicule = contratData['vehicule'] as Map<String, dynamic>? ?? {};
    final compagnieNom = contratData['compagnieNom'] ?? 'Compagnie d\'Assurance';
    final dateDebut = contratData['dateDebut']?.toDate() ?? DateTime.now();
    final dateFin = contratData['dateFin']?.toDate() ?? DateTime.now().add(const Duration(days: 365));

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.green800, width: 3),
            ),
            child: pw.Column(
              children: [
                // En-tête vert
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  color: PdfColors.green800,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'CARTE VERTE INTERNATIONALE',
                        style: pw.TextStyle(
                          fontSize: 20,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'INTERNATIONAL MOTOR INSURANCE CARD',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.Text(
                        'TUNISIE - TUNISIA',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                pw.SizedBox(height: 20),

                // Informations du véhicule
                pw.Padding(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildCarteVerteRow('N° de la carte / Card number:', numeroContrat),
                      _buildCarteVerteRow('Immatriculation / Registration:', vehicule['immatriculation'] ?? 'N/A'),
                      _buildCarteVerteRow('Marque / Make:', vehicule['marque'] ?? 'N/A'),
                      _buildCarteVerteRow('Type / Type:', vehicule['modele'] ?? 'N/A'),
                      _buildCarteVerteRow('Assureur / Insurer:', compagnieNom),
                      _buildCarteVerteRow('Valable du / Valid from:', _formatDate(dateDebut)),
                      _buildCarteVerteRow('Au / To:', _formatDate(dateFin)),
                    ],
                  ),
                ),

                pw.Spacer(),

                // Pays couverts
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(15),
                  color: PdfColors.green100,
                  child: pw.Column(
                    children: [
                      pw.Text(
                        'PAYS COUVERTS / COUNTRIES COVERED',
                        style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 5),
                      pw.Text(
                        'Algérie, Maroc, Libye et autres pays membres du système carte verte',
                        style: const pw.TextStyle(fontSize: 10),
                        textAlign: pw.TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // Sauvegarder le fichier
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/carte_verte_$numeroContrat.pdf');
    await file.writeAsBytes(await pdf.save());

    return file.path;
  }

  static pw.Widget _buildCarteVerteRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 200,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// 📱 Ouvrir le fichier PDF généré
  static Future<void> openPDF(String filePath) async {
    await OpenFile.open(filePath);
  }
}
