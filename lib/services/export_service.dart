import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      final fileName = 'statistiques_${agenceName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.html';
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

  /// 📊 Générer un PDF de statistiques (version HTML)
  static Future<Uint8List> _generateStatisticsPDF(Map<String, dynamic> statistics, String agenceName) async {
    try {
      debugPrint('[EXPORT_SERVICE] 🔍 Statistics data: $statistics');

      final contracts = statistics['contracts'] as Map<String, dynamic>? ?? {};
      final financial = statistics['financial'] as Map<String, dynamic>? ?? {};
      final agents = statistics['agents'] as Map<String, dynamic>? ?? {};
      final global = statistics['global'] as Map<String, dynamic>? ?? {};
      final agences = statistics['agences'] as List<dynamic>? ?? [];

      debugPrint('[EXPORT_SERVICE] 🔍 Contracts: $contracts');
      debugPrint('[EXPORT_SERVICE] 🔍 Financial: $financial');
      debugPrint('[EXPORT_SERVICE] 🔍 Agents: $agents');
      debugPrint('[EXPORT_SERVICE] 🔍 Global: $global');

      // Générer du contenu HTML pour un meilleur rendu
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Rapport Statistiques</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        .header { text-align: center; color: #2563eb; margin-bottom: 30px; }
        .section { margin-bottom: 25px; }
        .section-title { font-weight: bold; color: #1f2937; border-bottom: 2px solid #e5e7eb; padding-bottom: 5px; margin-bottom: 15px; }
        .metric-grid { display: grid; grid-template-columns: 1fr 1fr; gap: 15px; }
        .metric-item { background: #f9fafb; padding: 15px; border-radius: 8px; }
        .metric-label { font-weight: bold; color: #374151; }
        .metric-value { font-size: 24px; font-weight: bold; color: #2563eb; }
        .agence-item { background: #f3f4f6; padding: 10px; margin: 5px 0; border-radius: 6px; }
        .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #9ca3af; }
        table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        th, td { border: 1px solid #e5e7eb; padding: 8px; text-align: left; }
        th { background-color: #f3f4f6; font-weight: bold; }
    </style>
</head>
<body>
    <div class="header">
        <h1>RAPPORT STATISTIQUES</h1>
        <h2>${agenceName}</h2>
        <p>Généré le ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}</p>
    </div>

    <div class="section">
        <div class="section-title">RÉSUMÉ GLOBAL</div>
        <div class="metric-grid">
            <div class="metric-item">
                <div class="metric-label">Total Contrats</div>
                <div class="metric-value">${contracts['total'] ?? 0}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Contrats Actifs</div>
                <div class="metric-value">${contracts['active'] ?? 0}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">Total Agents</div>
                <div class="metric-value">${agents['totalAgents'] ?? 0}</div>
            </div>
            <div class="metric-item">
                <div class="metric-label">CA Total</div>
                <div class="metric-value">${(financial['totalPrimes'] ?? 0).toStringAsFixed(0)} DT</div>
            </div>
        </div>
    </div>

    <div class="section">
        <div class="section-title">PERFORMANCE FINANCIÈRE</div>
        <table>
            <tr>
                <th>Période</th>
                <th>Montant (DT)</th>
                <th>Évolution</th>
            </tr>
            <tr>
                <td>Ce mois</td>
                <td>${(financial['primesThisMonth'] ?? 0).toStringAsFixed(2)}</td>
                <td>${(financial['financialGrowthRate'] ?? 0) >= 0 ? '+' : ''}${(financial['financialGrowthRate'] ?? 0).toStringAsFixed(1)}%</td>
            </tr>
            <tr>
                <td>Mois dernier</td>
                <td>${(financial['primesLastMonth'] ?? 0).toStringAsFixed(2)}</td>
                <td>-</td>
            </tr>
            <tr>
                <td>Cette année</td>
                <td>${(financial['primesThisYear'] ?? financial['totalPrimes'] ?? 0).toStringAsFixed(2)}</td>
                <td>-</td>
            </tr>
        </table>
    </div>

    <div class="section">
        <div class="section-title">RÉPARTITION DES CONTRATS</div>
        <table>
            <tr>
                <th>Statut</th>
                <th>Nombre</th>
                <th>Pourcentage</th>
            </tr>
            <tr>
                <td>Actifs</td>
                <td>${contracts['active'] ?? 0}</td>
                <td>${_calculatePercentage(contracts['active'] ?? 0, contracts['total'] ?? 1)}%</td>
            </tr>
            <tr>
                <td>Expirés</td>
                <td>${contracts['expired'] ?? 0}</td>
                <td>${_calculatePercentage(contracts['expired'] ?? 0, contracts['total'] ?? 1)}%</td>
            </tr>
            <tr>
                <td>Suspendus</td>
                <td>${contracts['suspended'] ?? 0}</td>
                <td>${_calculatePercentage(contracts['suspended'] ?? 0, contracts['total'] ?? 1)}%</td>
            </tr>
        </table>
    </div>

    ${agences.isNotEmpty ? '''
    <div class="section">
        <div class="section-title">PERFORMANCE DES AGENCES</div>
        <table>
            <tr>
                <th>Agence</th>
                <th>Ville</th>
                <th>Contrats</th>
                <th>Agents</th>
                <th>CA (DT)</th>
                <th>Score</th>
            </tr>
            ${agences.take(10).map((agence) => '''
            <tr>
                <td>${agence['nom'] ?? 'N/A'}</td>
                <td>${agence['ville'] ?? 'N/A'}</td>
                <td>${agence['totalContrats'] ?? 0}</td>
                <td>${agence['totalAgents'] ?? 0}</td>
                <td>${(agence['totalPrimes'] ?? 0).toStringAsFixed(0)}</td>
                <td>${(agence['performanceScore'] ?? 0).toStringAsFixed(1)}</td>
            </tr>
            ''').join('')}
        </table>
    </div>
    ''' : ''}

    <div class="footer">
        <p>Rapport généré automatiquement par le système de gestion d'assurance</p>
        <p>Date et heure: ${DateTime.now()}</p>
    </div>
</body>
</html>
''';

      // Convertir HTML en bytes UTF-8
      return Uint8List.fromList(utf8.encode(htmlContent));

    } catch (e) {
      debugPrint('[EXPORT_SERVICE] ❌ Erreur génération PDF statistiques: $e');
      rethrow;
    }
  }

  /// 📊 Calculer un pourcentage
  static String _calculatePercentage(int value, int total) {
    if (total == 0) return '0';
    return ((value / total) * 100).toStringAsFixed(1);
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
