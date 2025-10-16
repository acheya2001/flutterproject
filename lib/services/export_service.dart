import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// 📄 Service d'export pour PDF et Excel
class ExportService {
  
  /// 📄 Générer et télécharger un PDF de contrat
  static Future<void> downloadContractPDF(Map<String, dynamic> contractData) async {
    try {
      debugPrint('[EXPORT_SERVICE] 📄 Génération PDF contrat: ${contractData['numeroContrat']}');

      // Générer le contenu PDF
      final pdfBytes = await _generateContractPDF(contractData);

      // Sauvegarder le fichier
      final fileName = 'contrat_${contractData['numeroContrat']}_${DateTime.now().millisecondsSinceEpoch}.html';
      final file = await _saveFile(pdfBytes, fileName);

      debugPrint('[EXPORT_SERVICE] ✅ PDF généré: ${file.path}');

      // Partager le fichier
      await Share.shareXFiles([XFile(file.path)], text: 'Contrat ${contractData['numeroContrat']}');

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur génération PDF: $e');
      rethrow;
    }
  }

  /// 📊 Exporter les contrats en Excel
  static Future<void> exportContractsToExcel(List<Map<String, dynamic>> contracts, String agenceName) async {
    try {
      debugPrint('[EXPORT_SERVICE] 📊 Export Excel: ${contracts.length} contrats');

      // Debug: Afficher la structure de tous les contrats
      for (int i = 0; i < contracts.length; i++) {
        debugPrint('[EXPORT_SERVICE] 🔍 Contrat $i keys: ${contracts[i].keys.toList()}');
        debugPrint('[EXPORT_SERVICE] 🔍 Contrat $i data: ${contracts[i]}');
        debugPrint('[EXPORT_SERVICE] 🔍 Contrat $i conducteurData: ${contracts[i]['conducteurData']}');
        debugPrint('[EXPORT_SERVICE] 🔍 Contrat $i agentData: ${contracts[i]['agentData']}');
        debugPrint('[EXPORT_SERVICE] 🔍 Contrat $i vehiculeData: ${contracts[i]['vehiculeData']}');
      }

      // Générer le contenu Excel (CSV pour simplicité)
      final csvContent = _generateContractsCSV(contracts);
      final csvBytes = Uint8List.fromList(utf8.encode(csvContent));

      // Sauvegarder le fichier
      final fileName = 'contrats_${agenceName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = await _saveFile(csvBytes, fileName);

      debugPrint('[EXPORT_SERVICE] ✅ Excel généré: ${file.path}');

      // Partager le fichier
      await Share.shareXFiles([XFile(file.path)], text: 'Export contrats $agenceName');

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur export Excel: $e');
      rethrow;
    }
  }

  /// 📊 Exporter les statistiques en PDF
  static Future<void> exportStatisticsPDF(Map<String, dynamic> statistics, String agenceName) async {
    try {
      debugPrint('[EXPORT_SERVICE] 📊 Export statistiques PDF: $agenceName');

      // Générer le contenu PDF
      final pdfBytes = await _generateStatisticsPDF(statistics, agenceName);

      // Sauvegarder le fichier
      final fileName = 'statistiques_${agenceName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = await _saveFile(pdfBytes, fileName);

      debugPrint('[EXPORT_SERVICE] ✅ Statistiques PDF générées: ${file.path}');

      // Partager le fichier
      await Share.shareXFiles([XFile(file.path)], text: 'Statistiques $agenceName');

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur export statistiques: $e');
      rethrow;
    }
  }

  /// 🔐 Demander la permission de stockage
  static Future<bool> _requestStoragePermission() async {
    try {
      if (Platform.isAndroid) {
        // Pour Android 13+ (API 33+), on n'a plus besoin de permissions spéciales
        // pour écrire dans le dossier Documents de l'app
        final androidInfo = await _getAndroidVersion();

        if (androidInfo >= 33) {
          // Android 13+: Utiliser le dossier Documents de l'app (pas de permission requise)
          debugPrint('[EXPORT_SERVICE] 📱 Android 13+: Utilisation du dossier Documents de l\'app');
          return true;
        } else {
          // Android < 13: Demander les permissions classiques
          final status = await Permission.storage.request();
          return status.isGranted;
        }
      }

      // Sur iOS, pas besoin de permission spéciale pour Documents
      return true;
    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur permission: $e');
      // En cas d'erreur, on continue quand même (utiliser le dossier Documents de l'app)
      return true;
    }
  }

  /// 📱 Obtenir la version Android
  static Future<int> _getAndroidVersion() async {
    try {
      if (Platform.isAndroid) {
        // Simuler la récupération de la version Android
        // Dans une vraie app, on utiliserait device_info_plus
        return 33; // Supposer Android 13+ pour la simplicité
      }
      return 0;
    } catch (e) {
      return 33; // Par défaut, supposer Android 13+
    }
  }

  /// 💾 Sauvegarder un fichier
  static Future<File> _saveFile(Uint8List bytes, String fileName) async {
    try {
      Directory directory;

      if (Platform.isAndroid) {
        // Toujours utiliser le dossier Documents de l'app (pas de permission requise)
        directory = await getApplicationDocumentsDirectory();
        debugPrint('[EXPORT_SERVICE] 📁 Sauvegarde dans: ${directory.path}');
      } else {
        // Utiliser Documents sur iOS
        directory = await getApplicationDocumentsDirectory();
      }

      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(bytes);

      debugPrint('[EXPORT_SERVICE] ✅ Fichier sauvegardé: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// 📄 Générer un PDF de contrat (version HTML vers PDF)
  static Future<Uint8List> _generateContractPDF(Map<String, dynamic> contractData) async {
    try {
      // Extraire les données avec fallbacks
      final conducteurNom = contractData['conducteurNom'] ??
                           contractData['conducteurData']?['nom'] ??
                           '${contractData['conducteurData']?['prenom'] ?? ''} ${contractData['conducteurData']?['nom'] ?? ''}'.trim();

      final typeCouverture = contractData['typeCouverture'] ??
                            contractData['typeAssurance'] ??
                            'Non défini';

      final statut = contractData['statut'] ??
                    contractData['statutContrat'] ??
                    'Non défini';

      // Générer du contenu HTML pour un meilleur rendu
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Contrat d'Assurance</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; color: #2563eb; margin-bottom: 30px; }
        .section { margin-bottom: 20px; }
        .section-title { font-weight: bold; color: #1f2937; border-bottom: 2px solid #e5e7eb; padding-bottom: 5px; }
        .info-row { margin: 8px 0; }
        .label { font-weight: bold; color: #374151; }
        .value { color: #6b7280; }
        .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #9ca3af; }
    </style>
</head>
<body>
    <div class="header">
        <h1>CONTRAT D'ASSURANCE</h1>
        <h2>N° ${contractData['numeroContrat'] ?? 'N/A'}</h2>
    </div>

    <div class="section">
        <div class="section-title">INFORMATIONS GÉNÉRALES</div>
        <div class="info-row"><span class="label">Numéro de contrat:</span> <span class="value">${contractData['numeroContrat'] ?? 'N/A'}</span></div>
        <div class="info-row"><span class="label">Statut:</span> <span class="value">${statut}</span></div>
        <div class="info-row"><span class="label">Type de couverture:</span> <span class="value">${typeCouverture}</span></div>
    </div>

    <div class="section">
        <div class="section-title">CONDUCTEUR</div>
        <div class="info-row"><span class="label">Nom:</span> <span class="value">${conducteurNom.isEmpty ? 'Non défini' : conducteurNom}</span></div>
        <div class="info-row"><span class="label">Email:</span> <span class="value">${contractData['conducteurEmail'] ?? contractData['conducteurData']?['email'] ?? 'Non défini'}</span></div>
        <div class="info-row"><span class="label">Téléphone:</span> <span class="value">${contractData['conducteurTelephone'] ?? contractData['conducteurData']?['telephone'] ?? 'Non défini'}</span></div>
    </div>

    <div class="section">
        <div class="section-title">VÉHICULE</div>
        <div class="info-row"><span class="label">Immatriculation:</span> <span class="value">${contractData['vehiculeImmatriculation'] ?? contractData['vehiculeData']?['immatriculation'] ?? 'Non défini'}</span></div>
        <div class="info-row"><span class="label">Marque:</span> <span class="value">${contractData['vehiculeMarque'] ?? contractData['vehiculeData']?['marque'] ?? 'Non défini'}</span></div>
        <div class="info-row"><span class="label">Modèle:</span> <span class="value">${contractData['vehiculeModele'] ?? contractData['vehiculeData']?['modele'] ?? 'Non défini'}</span></div>
        <div class="info-row"><span class="label">Année:</span> <span class="value">${contractData['vehiculeAnnee'] ?? contractData['vehiculeData']?['annee'] ?? 'Non défini'}</span></div>
    </div>

    <div class="section">
        <div class="section-title">INFORMATIONS FINANCIÈRES</div>
        <div class="info-row"><span class="label">Prime annuelle:</span> <span class="value">${contractData['primeAnnuelle'] ?? contractData['primeAssurance'] ?? 0} DT</span></div>
        <div class="info-row"><span class="label">Franchise:</span> <span class="value">${contractData['franchise'] ?? 0} DT</span></div>
    </div>

    <div class="section">
        <div class="section-title">DATES</div>
        <div class="info-row"><span class="label">Date de début:</span> <span class="value">${_formatDateForPDF(contractData['dateDebut'])}</span></div>
        <div class="info-row"><span class="label">Date de fin:</span> <span class="value">${_formatDateForPDF(contractData['dateFin'])}</span></div>
    </div>

    <div class="footer">
        <p>Document généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}</p>
        <p>Compagnie d'Assurance - Système de Gestion des Contrats</p>
    </div>
</body>
</html>
''';

      // Convertir HTML en bytes UTF-8
      return Uint8List.fromList(utf8.encode(htmlContent));

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur génération PDF contrat: $e');
      rethrow;
    }
  }

  /// 📅 Formater une date pour PDF
  static String _formatDateForPDF(dynamic date) {
    try {
      if (date == null) return 'Non défini';

      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date.runtimeType.toString().contains('Timestamp')) {
        dateTime = date.toDate();
      } else {
        return 'Non défini';
      }

      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return 'Non défini';
    }
  }

  /// 📊 Générer un CSV des contrats
  static String _generateContractsCSV(List<Map<String, dynamic>> contracts) {
    try {
      final buffer = StringBuffer();

      // En-têtes avec BOM UTF-8 pour Excel
      buffer.write('\uFEFF'); // BOM UTF-8
      buffer.writeln('Numéro Contrat,Conducteur,Type Couverture,Prime Annuelle,Statut,Date Début,Date Fin,Agent,Agence');

      // Données
      for (final contract in contracts) {
        debugPrint('[EXPORT_SERVICE] 📊 Processing contract: ${contract['id']}');
        debugPrint('[EXPORT_SERVICE] 📊 Contract data keys: ${contract.keys.toList()}');

        // Utiliser les nouvelles fonctions d'extraction robustes
        final numeroContrat = _extractContractNumber(contract);
        final conducteur = _extractConducteurName(contract);
        final typeCouverture = _extractTypeCouverture(contract);
        final primeAnnuelle = _extractPrimeAnnuelle(contract);
        final statut = _extractStatut(contract);
        final dateDebut = _extractDateDebut(contract);
        final dateFin = _extractDateFin(contract);
        final agent = _extractAgentName(contract);
        final agence = _extractAgenceName(contract);

        debugPrint('[EXPORT_SERVICE] 📋 Extracted: $numeroContrat, $conducteur, $typeCouverture, $primeAnnuelle, $statut, $dateDebut, $dateFin, $agent, $agence');

        final row = [
          _escapeCsvValue(numeroContrat),
          _escapeCsvValue(conducteur),
          _escapeCsvValue(typeCouverture),
          _escapeCsvValue(primeAnnuelle),
          _escapeCsvValue(statut),
          _escapeCsvValue(dateDebut),
          _escapeCsvValue(dateFin),
          _escapeCsvValue(agent),
          _escapeCsvValue(agence),
        ];
        buffer.writeln(row.join(','));
      }

      return buffer.toString();

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur génération CSV: $e');
      rethrow;
    }
  }

  /// 📊 Générer un PDF de statistiques (version PDF native)
  static Future<Uint8List> _generateStatisticsPDF(Map<String, dynamic> statistics, String agenceName) async {
    try {
      debugPrint('[EXPORT_SERVICE] 🔍 Statistics data keys: ${statistics.keys.toList()}');

      final contracts = statistics['contracts'] as Map<String, dynamic>? ?? {};
      final financial = statistics['financial'] as Map<String, dynamic>? ?? {};
      final agents = statistics['agents'] as Map<String, dynamic>? ?? {};
      final overview = statistics['overview'] as Map<String, dynamic>? ?? {};
      final agences = statistics['agences'] as List<dynamic>? ?? [];

      debugPrint('[EXPORT_SERVICE] 🔍 Contracts keys: ${contracts.keys.toList()}');
      debugPrint('[EXPORT_SERVICE] 🔍 Contracts values: $contracts');
      debugPrint('[EXPORT_SERVICE] 🔍 Contracts actifs: ${contracts['actifs']} (type: ${contracts['actifs'].runtimeType})');
      debugPrint('[EXPORT_SERVICE] 🔍 Contracts active: ${contracts['active']} (type: ${contracts['active'].runtimeType})');
      debugPrint('[EXPORT_SERVICE] 🔍 Contracts total: ${contracts['total']} (type: ${contracts['total'].runtimeType})');

      // Test des valeurs utilisées dans le template
      final actifsValue = contracts['actifs'] ?? contracts['active'] ?? 0;
      final totalValue = contracts['total'] ?? 1;
      debugPrint('[EXPORT_SERVICE] 🔍 Template actifs value: $actifsValue (type: ${actifsValue.runtimeType})');
      debugPrint('[EXPORT_SERVICE] 🔍 Template total value: $totalValue (type: ${totalValue.runtimeType})');
      debugPrint('[EXPORT_SERVICE] 🔍 Percentage calculation: ${_calculatePercentage(actifsValue, totalValue)}%');

      // Créer le document PDF
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (context) => [
            // En-tête avec design original
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue800, width: 2),
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'RAPPORT STATISTIQUES',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue800,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    agenceName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue600,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                    style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 25),

            // Résumé global avec métriques
            _buildMetricsGrid(contracts, financial, agents, overview),
            pw.SizedBox(height: 25),

            // Performance financière
            _buildFinancialTable(financial),
            pw.SizedBox(height: 25),

            // Répartition des contrats
            _buildContractsTable(contracts),
            pw.SizedBox(height: 25),

            // Performance des agences (version complète)
            if (agences.isNotEmpty) _buildAgencesPerformanceTable(agences),

            pw.Spacer(),

            // Pied de page
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(15),
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey100,
              ),
              child: pw.Column(
                children: [
                  pw.Text(
                    'Rapport généré automatiquement par le système de gestion d\'assurance',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                  pw.Text(
                    'Date et heure: ${DateTime.now()}',
                    style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      debugPrint('[EXPORT_SERVICE] ✅ PDF généré avec succès');
      return pdf.save();
    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur génération PDF statistiques: $e');
      rethrow;
    }
  }

  /// 📊 Construire la grille de métriques (design original)
  static pw.Widget _buildMetricsGrid(Map<String, dynamic> contracts, Map<String, dynamic> financial, Map<String, dynamic> agents, Map<String, dynamic> overview) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RÉSUMÉ GLOBAL',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard('Total Contrats', '${contracts['total'] ?? 0}', PdfColors.blue),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: _buildMetricCard('Contrats Actifs', '${contracts['actifs'] ?? 0}', PdfColors.green),
            ),
          ],
        ),
        pw.SizedBox(height: 15),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildMetricCard('Total Agents', '${agents['totalAgents'] ?? 0}', PdfColors.orange),
            ),
            pw.SizedBox(width: 15),
            pw.Expanded(
              child: _buildMetricCard('CA Total', '${(financial['totalPrimes'] ?? 0).toStringAsFixed(0)} DT', PdfColors.purple),
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Construire une carte de métrique
  static pw.Widget _buildMetricCard(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: color, width: 2),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 📊 Construire le tableau de performance financière
  static pw.Widget _buildFinancialTable(Map<String, dynamic> financial) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PERFORMANCE FINANCIÈRE',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Période', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Montant (DT)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Évolution', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Ce mois'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${(financial['primesThisMonth'] ?? 0).toStringAsFixed(2)}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${(financial['financialGrowthRate'] ?? 0) >= 0 ? '+' : ''}${(financial['financialGrowthRate'] ?? 0).toStringAsFixed(1)}%'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Mois dernier'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${(financial['primesLastMonth'] ?? 0).toStringAsFixed(2)}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('-'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Cette année'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${(financial['primesThisYear'] ?? financial['totalPrimes'] ?? 0).toStringAsFixed(2)}'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('-'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Construire le tableau des contrats
  static pw.Widget _buildContractsTable(Map<String, dynamic> contracts) {
    final actifsValue = contracts['actifs'] ?? contracts['active'] ?? 0;
    final expiresValue = contracts['expires'] ?? contracts['expired'] ?? 0;
    final suspendusValue = contracts['suspendus'] ?? contracts['suspended'] ?? 0;
    final totalValue = contracts['total'] ?? 1;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'RÉPARTITION DES CONTRATS',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Statut', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Nombre', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Pourcentage', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Actifs'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('$actifsValue'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${_calculatePercentage(actifsValue, totalValue)}%'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Expirés'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('$expiresValue'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${_calculatePercentage(expiresValue, totalValue)}%'),
                ),
              ],
            ),
            pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Suspendus'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('$suspendusValue'),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${_calculatePercentage(suspendusValue, totalValue)}%'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// 📊 Construire le tableau de performance des agences (version complète)
  static pw.Widget _buildAgencesPerformanceTable(List<dynamic> agences) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PERFORMANCE DES AGENCES',
          style: pw.TextStyle(
            fontSize: 16,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue800,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.5),
            5: const pw.FlexColumnWidth(1),
          },
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Agence', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Ville', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Contrats', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Agents', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('CA (DT)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('Score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                ),
              ],
            ),
            ...agences.take(10).map((agence) => pw.TableRow(
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(agence['nom'] ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text(agence['ville'] ?? 'N/A', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${agence['totalContrats'] ?? 0}', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${agence['totalAgents'] ?? 0}', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${(agence['totalPrimes'] ?? 0).toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 9)),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(8),
                  child: pw.Text('${(agence['performanceScore'] ?? 0).toStringAsFixed(1)}', style: const pw.TextStyle(fontSize: 9)),
                ),
              ],
            )),
          ],
        ),
      ],
    );

  }



  /// 📊 Calculer un pourcentage
  static String _calculatePercentage(dynamic value, dynamic total) {
    final numValue = (value is num) ? value.toDouble() : 0.0;
    final numTotal = (total is num) ? total.toDouble() : 1.0;

    if (numTotal == 0) return '0';
    return ((numValue / numTotal) * 100).toStringAsFixed(1);
  }

  /// 🔧 Échapper les valeurs CSV
  static String _escapeCsvValue(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  // ========== FONCTIONS D'EXTRACTION ROBUSTES ==========

  /// 📋 Extraire le numéro de contrat
  static String _extractContractNumber(Map<String, dynamic> contract) {
    return contract['numeroContrat']?.toString() ??
           contract['numero']?.toString() ??
           contract['id']?.toString() ??
           'N/A';
  }

  /// 👤 Extraire le nom du conducteur
  static String _extractConducteurName(Map<String, dynamic> contract) {
    // Essayer d'abord les données enrichies
    if (contract['conducteurData'] != null) {
      final conducteurData = contract['conducteurData'] as Map<String, dynamic>;
      final prenom = conducteurData['prenom']?.toString() ?? '';
      final nom = conducteurData['nom']?.toString() ?? '';
      final fullName = '$prenom $nom'.trim();
      if (fullName.isNotEmpty) return fullName;
    }

    // Fallback sur les champs directs
    return contract['conducteurNom']?.toString() ??
           contract['nomConducteur']?.toString() ??
           'Conducteur inconnu';
  }

  /// 🛡️ Extraire le type de couverture
  static String _extractTypeCouverture(Map<String, dynamic> contract) {
    return contract['typeCouverture']?.toString() ??
           contract['typeAssurance']?.toString() ??
           contract['couverture']?.toString() ??
           contract['type']?.toString() ??
           'Non défini';
  }

  /// 💰 Extraire la prime annuelle
  static String _extractPrimeAnnuelle(Map<String, dynamic> contract) {
    final prime = contract['primeAnnuelle'] ??
                  contract['primeAssurance'] ??
                  contract['montantPrime'] ??
                  contract['prime'] ??
                  0;
    return prime.toString();
  }

  /// 📊 Extraire le statut
  static String _extractStatut(Map<String, dynamic> contract) {
    return contract['statut']?.toString() ??
           contract['statutContrat']?.toString() ??
           contract['status']?.toString() ??
           'Non défini';
  }

  /// 📅 Extraire la date de début
  static String _extractDateDebut(Map<String, dynamic> contract) {
    return _formatDateForCSV(contract['dateDebut']) ??
           _formatDateForCSV(contract['dateEffet']) ??
           _formatDateForCSV(contract['createdAt']) ??
           'N/A';
  }

  /// 📅 Extraire la date de fin
  static String _extractDateFin(Map<String, dynamic> contract) {
    return _formatDateForCSV(contract['dateFin']) ??
           _formatDateForCSV(contract['dateExpiration']) ??
           _formatDateForCSV(contract['dateEcheance']) ??
           'N/A';
  }

  /// 👨‍💼 Extraire le nom de l'agent
  static String _extractAgentName(Map<String, dynamic> contract) {
    // Essayer d'abord les données enrichies
    if (contract['agentData'] != null) {
      final agentData = contract['agentData'] as Map<String, dynamic>;
      final prenom = agentData['prenom']?.toString() ?? '';
      final nom = agentData['nom']?.toString() ?? '';
      final fullName = '$prenom $nom'.trim();
      if (fullName.isNotEmpty) return fullName;
    }

    // Fallback sur les champs directs
    return contract['agentNom']?.toString() ??
           contract['nomAgent']?.toString() ??
           'Agent inconnu';
  }

  /// 🏢 Extraire le nom de l'agence
  static String _extractAgenceName(Map<String, dynamic> contract) {
    return contract['agenceNom']?.toString() ??
           contract['agenceName']?.toString() ??
           contract['nomAgence']?.toString() ??
           'Agence inconnue';
  }

  // ========== FONCTIONS DE TEST ==========

  /// 🧪 Générer des données de test pour les exports
  static List<Map<String, dynamic>> generateTestContracts() {
    return [
      {
        'id': 'test1',
        'numeroContrat': 'AG23_TES_2025_08_173842',
        'conducteurData': {
          'prenom': 'Ahmed',
          'nom': 'Ben Ali',
          'email': 'ahmed.benali@email.com',
          'telephone': '+216 98 123 456'
        },
        'vehiculeData': {
          'immatriculation': '123 TUN 456',
          'marque': 'Toyota',
          'modele': 'Corolla',
          'annee': 2020
        },
        'agentData': {
          'prenom': 'Fatma',
          'nom': 'Trabelsi',
          'email': 'fatma.trabelsi@agence.com'
        },
        'typeCouverture': 'Tous Risques',
        'primeAnnuelle': 1200,
        'statut': 'actif',
        'dateDebut': Timestamp.fromDate(DateTime(2025, 1, 1)),
        'dateFin': Timestamp.fromDate(DateTime(2025, 12, 31)),
        'agenceNom': 'test agence final',
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'test2',
        'numeroContrat': 'AG23_TES_2025_08_591942',
        'conducteurData': {
          'prenom': 'Salma',
          'nom': 'Khediri',
          'email': 'salma.khediri@email.com',
          'telephone': '+216 97 654 321'
        },
        'vehiculeData': {
          'immatriculation': '789 TUN 012',
          'marque': 'Peugeot',
          'modele': '208',
          'annee': 2019
        },
        'agentData': {
          'prenom': 'Mohamed',
          'nom': 'Sassi',
          'email': 'mohamed.sassi@agence.com'
        },
        'typeCouverture': 'Responsabilité Civile',
        'primeAnnuelle': 640,
        'statut': 'actif',
        'dateDebut': Timestamp.fromDate(DateTime(2025, 2, 15)),
        'dateFin': Timestamp.fromDate(DateTime(2026, 2, 14)),
        'agenceNom': 'test agence final',
        'createdAt': Timestamp.now(),
      },
      {
        'id': 'test3',
        'numeroContrat': 'AG23_TES_2025_08_923645',
        'conducteurData': {
          'prenom': 'Karim',
          'nom': 'Bouazizi',
          'email': 'karim.bouazizi@email.com',
          'telephone': '+216 99 876 543'
        },
        'vehiculeData': {
          'immatriculation': '345 TUN 678',
          'marque': 'Renault',
          'modele': 'Clio',
          'annee': 2021
        },
        'agentData': {
          'prenom': 'Leila',
          'nom': 'Hamdi',
          'email': 'leila.hamdi@agence.com'
        },
        'typeCouverture': 'Tous Risques',
        'primeAnnuelle': 1248,
        'statut': 'actif',
        'dateDebut': Timestamp.fromDate(DateTime(2025, 3, 1)),
        'dateFin': Timestamp.fromDate(DateTime(2026, 2, 28)),
        'agenceNom': 'test agence final',
        'createdAt': Timestamp.now(),
      },
    ];
  }

  /// 🧪 Générer des statistiques de test
  static Map<String, dynamic> generateTestStatistics() {
    return {
      'contracts': {
        'total': 3,
        'active': 3,
        'expired': 0,
        'suspended': 0,
        'expiringThisMonth': 0,
        'growthRate': 15.5,
        'activePercentage': 100.0,
      },
      'financial': {
        'totalPrimes': 3088.0,
        'primesThisMonth': 2528.0,
        'primesLastMonth': 1200.0,
        'financialGrowthRate': 110.7,
        'averagePrime': 1029.3,
      },
      'agents': {
        'totalAgents': 3,
        'activeAgents': 3,
        'topPerformers': [
          {'nom': 'Fatma Trabelsi', 'contractsCount': 1},
          {'nom': 'Mohamed Sassi', 'contractsCount': 1},
          {'nom': 'Leila Hamdi', 'contractsCount': 1},
        ],
      },
      'vehicles': {
        'totalVehicules': 3,
        'activeVehicules': 3,
        'pendingVehicules': 0,
      },
      'recentActivity': [],
      'lastUpdated': DateTime.now().toIso8601String(),
    };
  }

  /// 📅 Formater une date pour CSV
  static String _formatDateForCSV(dynamic date) {
    try {
      if (date == null) return '';
      
      DateTime dateTime;
      if (date is String) {
        dateTime = DateTime.parse(date);
      } else if (date.runtimeType.toString().contains('Timestamp')) {
        dateTime = date.toDate();
      } else {
        return '';
      }
      
      return '${dateTime.day.toString().padLeft(2, '0')}/${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }

  /// 📱 Partager un fichier simple
  static Future<void> shareFile(String filePath, String text) async {
    try {
      await Share.shareXFiles([XFile(filePath)], text: text);
    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur partage: $e');
      rethrow;
    }
  }

  /// 📄 Obtenir le répertoire de téléchargement
  static Future<String> getDownloadDirectory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      return directory.path;
    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur répertoire: $e');
      return '/tmp'; // Fallback
    }
  }

  /// 📤 Partager du contenu directement (sans sauvegarde de fichier)
  static Future<void> shareContent(String content, String fileName, String mimeType) async {
    try {
      // Créer un fichier temporaire
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(content);

      // Partager le fichier
      await Share.shareXFiles([XFile(file.path)], text: fileName);

      // Supprimer le fichier temporaire après un délai
      Future.delayed(const Duration(seconds: 5), () {
        try {
          if (file.existsSync()) {
            file.deleteSync();
          }
        } catch (e) {
          debugPrint('[EXPORT_SERVICE] ⚠️ Impossible de supprimer le fichier temporaire: $e');
        }
      });

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur partage contenu: $e');
      rethrow;
    }
  }
}
