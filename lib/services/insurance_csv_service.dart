import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// 📊 Service CSV spécialisé pour les données d'assurance
class InsuranceCsvService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 📥 Importer des données CSV d'assurance
  static Future<ImportResult> importInsuranceData(String csvContent) async {
    try {
      debugPrint('[INSURANCE_CSV] 🚀 Début importation CSV');

      final lines = csvContent.trim().split('\n');
      if (lines.isEmpty) {
        return ImportResult(
          success: false,
          totalRows: 0,
          successfulRows: 0,
          errors: ['Fichier CSV vide'],
          dataType: 'unknown',
        );
      }

      final headers = lines[0].split(',');
      final dataRows = lines.skip(1).map((line) => line.split(',')).toList();

      debugPrint('[INSURANCE_CSV] 📊 Headers détectés: $headers');
      debugPrint('[INSURANCE_CSV] 📊 ${dataRows.length} lignes de données');

      final dataType = _detectDataType(headers);
      debugPrint('[INSURANCE_CSV] 🔍 Type détecté: $dataType');

      switch (dataType) {
        case 'compagnies':
          return await _importCompagnies(headers, dataRows);
        case 'agences':
          return await _importAgences(headers, dataRows);
        case 'agents':
          return await _importAgents(headers, dataRows);
        case 'vehicules':
          return await _importVehicules(headers, dataRows);
        case 'contrats':
          return await _importContrats(headers, dataRows);
        case 'sinistres':
          return await _importSinistres(headers, dataRows);
        default:
          return await _importGeneric(headers, dataRows, dataType);
      }
    } catch (e) {
      debugPrint('[INSURANCE_CSV] ❌ Erreur importation: ${e.toString()}');
      return ImportResult(
        success: false,
        totalRows: 0,
        successfulRows: 0,
        errors: ['Erreur générale: $e'],
        dataType: 'unknown',
      );
    }
  }

  /// 🔍 Détecter le type de données basé sur les headers
  static String _detectDataType(List<String> headers) {
    final headerStr = headers.join(' ').toLowerCase();

    // Compagnies d'assurance
    if (headerStr.contains('compagnie') ||
        headerStr.contains('assurance') ||
        (headerStr.contains('nom') && headerStr.contains('code'))) {
      return 'compagnies';
    }

    // Agences
    if (headerStr.contains('agence') ||
        (headerStr.contains('nom') && headerStr.contains('ville'))) {
      return 'agences';
    }

    // Agents
    if (headerStr.contains('agent') ||
        (headerStr.contains('prenom') && headerStr.contains('nom'))) {
      return 'agents';
    }

    // Véhicules
    if (headerStr.contains('vehicule') ||
        headerStr.contains('immatriculation') ||
        headerStr.contains('marque') ||
        headerStr.contains('modele')) {
      return 'vehicules';
    }

    // Contrats
    if (headerStr.contains('contrat') ||
        headerStr.contains('police') ||
        headerStr.contains('prime')) {
      return 'contrats';
    }

    // Sinistres
    if (headerStr.contains('sinistre') ||
        headerStr.contains('accident') ||
        headerStr.contains('constat')) {
      return 'sinistres';
    }

    return 'generic';
  }

  /// 🏢 Importer les compagnies d'assurance
  static Future<ImportResult> _importCompagnies(
      List<String> headers, List<List<dynamic>> dataRows) async {
    final List<String> errors = [];
    final List<Map<String, dynamic>> createdData = [];

    for (int i = 0; i < dataRows.length; i++) {
      try {
        final row = dataRows[i];
        final data = _mapRowToData(headers, row);

        // Validation
        if (!data.containsKey('nom') || data['nom'].toString().isEmpty) {
          errors.add('Ligne ${i + 2}: Nom de compagnie manquant');
          continue;
        }

        // Générer un code si manquant
        if (!data.containsKey('code') || data['code'].toString().isEmpty) {
          data['code'] = data['nom'].toString().toUpperCase().replaceAll(' ', '').substring(0, 4);
        }

        final compagnieId = data['code'].toString().toUpperCase();
        final compagnieData = {
          'id': compagnieId,
          'nom': data['nom'],
          'code': compagnieId,
          'adresse': data['adresse'] ?? '',
          'telephone': data['telephone'] ?? data['tel'] ?? '',
          'email': data['email'] ?? '',
          'ville': data['ville'] ?? '',
          'pays': 'Tunisie',
          'status': 'actif',
          'created_at': FieldValue.serverTimestamp(),
          'imported_from': 'csv',
          'import_date': DateTime.now().toIso8601String(),
        };

        bool saved = await _saveToMultipleCollections(['companies', 'compagnies'], compagnieData);
        if (saved) {
          createdData.add(compagnieData);
          debugPrint('[INSURANCE_CSV] ✅ Compagnie créée: ${compagnieData['nom']}');
        } else {
          errors.add('Ligne ${i + 2}: Impossible de sauvegarder ${data['nom']}');
        }
      } catch (e) {
        errors.add('Ligne ${i + 2}: Erreur - ${e.toString()}');
      }
    }

    return ImportResult(
      success: errors.isEmpty,
      totalRows: dataRows.length,
      successfulRows: createdData.length,
      errors: errors,
      dataType: 'compagnies',
      createdData: createdData,
    );
  }

  /// 🏢 Importer les agences
  static Future<ImportResult> _importAgences(
      List<String> headers, List<List<dynamic>> dataRows) async {
    final List<String> errors = [];
    final List<Map<String, dynamic>> createdData = [];

    for (int i = 0; i < dataRows.length; i++) {
      try {
        final row = dataRows[i];
        final data = _mapRowToData(headers, row);

        // Validation
        if (!data.containsKey('nom') || data['nom'].toString().isEmpty) {
          errors.add('Ligne ${i + 2}: Nom d\'agence manquant');
          continue;
        }

        final agenceId = 'agence_${DateTime.now().millisecondsSinceEpoch}_$i';
        final agenceData = {
          'id': agenceId,
          'nom': data['nom'],
          'compagnieId': data['compagnie'] ?? data['compagnieid'] ?? 'UNKNOWN',
          'adresse': data['adresse'] ?? '',
          'ville': data['ville'] ?? '',
          'telephone': data['telephone'] ?? data['tel'] ?? '',
          'responsable': data['responsable'] ?? '',
          'status': 'actif',
          'created_at': FieldValue.serverTimestamp(),
          'imported_from': 'csv',
          'import_date': DateTime.now().toIso8601String(),
        };

        bool saved = await _saveToMultipleCollections(['agencies', 'agences'], agenceData);
        if (saved) {
          createdData.add(agenceData);
          debugPrint('[INSURANCE_CSV] ✅ Agence créée: ${agenceData['nom']}');
        } else {
          errors.add('Ligne ${i + 2}: Impossible de sauvegarder ${data['nom']}');
        }
      } catch (e) {
        errors.add('Ligne ${i + 2}: Erreur - ${e.toString()}');
      }
    }

    return ImportResult(
      success: errors.isEmpty,
      totalRows: dataRows.length,
      successfulRows: createdData.length,
      errors: errors,
      dataType: 'agences',
      createdData: createdData,
    );
  }

  /// 👤 Importer les agents
  static Future<ImportResult> _importAgents(
      List<String> headers, List<List<dynamic>> dataRows) async {
    // TODO: Implémenter l'importation d'agents
    return _importGeneric(headers, dataRows, 'agents');
  }

  /// 🚗 Importer les véhicules
  static Future<ImportResult> _importVehicules(
      List<String> headers, List<List<dynamic>> dataRows) async {
    // TODO: Implémenter l'importation de véhicules
    return _importGeneric(headers, dataRows, 'vehicules');
  }

  /// 📄 Importer les contrats
  static Future<ImportResult> _importContrats(
      List<String> headers, List<List<dynamic>> dataRows) async {
    // TODO: Implémenter l'importation de contrats
    return _importGeneric(headers, dataRows, 'contrats');
  }

  /// 🚨 Importer les sinistres
  static Future<ImportResult> _importSinistres(
      List<String> headers, List<List<dynamic>> dataRows) async {
    // TODO: Implémenter l'importation de sinistres
    return _importGeneric(headers, dataRows, 'sinistres');
  }

  /// 📊 Importation générique
  static Future<ImportResult> _importGeneric(
      List<String> headers, List<List<dynamic>> dataRows, String dataType) async {
    final List<String> errors = [];
    final List<Map<String, dynamic>> createdData = [];

    for (int i = 0; i < dataRows.length; i++) {
      try {
        final row = dataRows[i];
        final data = _mapRowToData(headers, row);

        final docId = '${dataType}_${DateTime.now().millisecondsSinceEpoch}_$i';
        final docData = {
          'id': docId,
          'data_type': dataType,
          ...data,
          'created_at': FieldValue.serverTimestamp(),
          'imported_from': 'csv',
          'import_date': DateTime.now().toIso8601String(),
        };

        bool saved = await _saveToMultipleCollections(['csv_imports', dataType], docData);
        if (saved) {
          createdData.add(docData);
        } else {
          errors.add('Ligne ${i + 2}: Impossible de sauvegarder');
        }
      } catch (e) {
        errors.add('Ligne ${i + 2}: Erreur - ${e.toString()}');
      }
    }

    return ImportResult(
      success: errors.isEmpty,
      totalRows: dataRows.length,
      successfulRows: createdData.length,
      errors: errors,
      dataType: dataType,
      createdData: createdData,
    );
  }

  /// 🗂️ Mapper une ligne vers un objet de données
  static Map<String, dynamic> _mapRowToData(List<String> headers, List<dynamic> row) {
    final Map<String, dynamic> data = {};
    for (int i = 0; i < headers.length && i < row.length; i++) {
      final key = headers[i].toLowerCase().trim();
      final value = row[i]?.toString().trim() ?? '';
      if (value.isNotEmpty) {
        data[key] = value;
      }
    }
    return data;
  }

  /// 💾 Sauvegarder dans plusieurs collections
  static Future<bool> _saveToMultipleCollections(
      List<String> collections, Map<String, dynamic> data) async {
    try {
      for (final collection in collections) {
        await _firestore
            .collection(collection)
            .doc(data['id'])
            .set(data)
            .timeout(const Duration(seconds: 10));
        debugPrint('[INSURANCE_CSV] ✅ Sauvegarde dans collection: $collection');
      }
      return true;
    } catch (e) {
      debugPrint('[INSURANCE_CSV] ❌ Échec collection: ${e.toString()}');
      return false;
    }
  }
}

/// 📊 Résultat d'importation CSV
class ImportResult {
  final bool success;
  final int totalRows;
  final int successfulRows;
  final List<String> errors;
  final String dataType;
  final List<Map<String, dynamic>>? createdData;

  ImportResult({
    required this.success,
    required this.totalRows,
    required this.successfulRows,
    required this.errors,
    required this.dataType,
    this.createdData,
  });

  /// Taux de succès en pourcentage
  double get successRate => totalRows > 0 ? (successfulRows / totalRows) * 100 : 0;

  /// Nombre d'erreurs
  int get errorCount => errors.length;

  /// Résumé textuel
  String get summary =>
      'Importation $dataType: $successfulRows/$totalRows réussies (${successRate.toStringAsFixed(1)}%)';

  @override
  String toString() {
    return 'ImportResult{success: $success, totalRows: $totalRows, '
           'successfulRows: $successfulRows, errors: ${errors.length}, dataType: $dataType}';
  }
}