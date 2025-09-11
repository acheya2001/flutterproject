import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:printing/printing.dart';

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
}
