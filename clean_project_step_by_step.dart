import 'dart:io';

/// 🧹 NETTOYAGE ÉTAPE PAR ÉTAPE DU PROJET PFE
void main() async {
  print('🧹 NETTOYAGE COMPLET DU PROJET PFE');
  print('=' * 60);
  
  // ÉTAPE 1: Identifier les fichiers corrompus
  print('📋 ÉTAPE 1: Identification des fichiers corrompus...');
  final corruptedFiles = await _identifyCorruptedFiles();
  print('   ❌ ${corruptedFiles.length} fichiers corrompus trouvés');
  
  // ÉTAPE 2: Nettoyer les fichiers corrompus
  print('🔧 ÉTAPE 2: Nettoyage des fichiers corrompus...');
  int cleanedFiles = 0;
  for (final file in corruptedFiles) {
    try {
      final cleaned = await _cleanFile(file);
      if (cleaned) {
        cleanedFiles++;
        if (cleanedFiles % 10 == 0) {
          print('   ✅ $cleanedFiles fichiers nettoyés...');
        }
      }
    } catch (e) {
      print('   ⚠️ Erreur: ${file.path} - $e');
    }
  }
  
  // ÉTAPE 3: Supprimer les fichiers irrécupérables
  print('🗑️ ÉTAPE 3: Suppression des fichiers irrécupérables...');
  final deletedFiles = await _deleteIrrecoverableFiles();
  print('   🗑️ $deletedFiles fichiers supprimés');
  
  // ÉTAPE 4: Créer les fichiers essentiels manquants
  print('📝 ÉTAPE 4: Création des fichiers essentiels...');
  await _createEssentialFiles();
  print('   ✅ Fichiers essentiels créés');
  
  print('');
  print('🎉 NETTOYAGE TERMINÉ !');
  print('✅ $cleanedFiles fichiers nettoyés');
  print('🗑️ $deletedFiles fichiers supprimés');
  print('📝 Fichiers essentiels recréés');
  print('');
  print('🚀 Vous pouvez maintenant lancer: flutter run');
}

/// Identifier les fichiers corrompus
Future<List<File>> _identifyCorruptedFiles() async {
  final corruptedFiles = <File>[];
  final libDir = Directory('lib');
  
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        
        // Vérifier les signes de corruption
        if (_isCorrupted(content)) {
          corruptedFiles.add(entity);
        }
      } catch (e) {
        corruptedFiles.add(entity);
      }
    }
  }
  
  return corruptedFiles;
}

/// Vérifier si un fichier est corrompu
bool _isCorrupted(String content) {
  // Signes de corruption simples
  if (content.contains('Contenu\'') ||
      content.contains('Contenu"') ||
      content.contains('import.*Contenu') ||
      content.contains('class.*Contenu')) {
    return true;
  }

  // Vérifier les patterns avec RegExp
  final patterns = [
    r'\w+\s*\(\s*\)\s*\)\s*:',
    r';\s*;',
    r',\s*,',
    r'\)\s*\)',
    r'\}\s*\}',
  ];

  for (final pattern in patterns) {
    if (RegExp(pattern).hasMatch(content)) {
      return true;
    }
  }

  return false;
}

/// Nettoyer un fichier corrompu
Future<bool> _cleanFile(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;
    
    // Nettoyage systématique
    content = _performCleaning(content);
    
    // Si le contenu a changé, sauvegarder
    if (content != originalContent && content.trim().isNotEmpty) {
      await file.writeAsString(content);
      return true;
    }
    
    return false;
  } catch (e) {
    return false;
  }
}

/// Effectuer le nettoyage du contenu
String _performCleaning(String content) {
  // 1. Nettoyer les chaînes corrompues
  content = content.replaceAll('Contenu\'', '');
  content = content.replaceAll('Contenu"', '');
  content = content.replaceAll('Contenu', '');

  // 2. Nettoyer les imports corrompus (simple)
  final lines = content.split('\n');
  final cleanLines = <String>[];

  for (final line in lines) {
    if (line.contains('import') && (line.contains('Contenu') || !line.contains(';'))) {
      // Ignorer les imports corrompus
      continue;
    }
    cleanLines.add(line);
  }

  content = cleanLines.join('\n');

  // 3. Nettoyer les doublons simples
  content = content.replaceAll(';;', ';');
  content = content.replaceAll(',,', ',');
  content = content.replaceAll('))', ')');
  content = content.replaceAll('}}', '}');

  // 4. Nettoyer les lignes vides multiples
  content = content.replaceAll('\n\n\n', '\n\n');

  // 5. Ajouter import Flutter si nécessaire
  if (content.contains('StatefulWidget') && !content.contains("import 'package:flutter/material.dart'")) {
    content = "import 'package:flutter/material.dart';\n\n$content";
  }

  return content;
}

/// Supprimer les fichiers irrécupérables
Future<int> _deleteIrrecoverableFiles() async {
  int deletedCount = 0;
  final libDir = Directory('lib');
  
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      try {
        final content = await entity.readAsString();
        
        // Si le fichier est trop corrompu (moins de 50 caractères utiles)
        final cleanContent = content.replaceAll(RegExp(r'\s+'), ' ').trim();
        if (cleanContent.length < 50 || 
            !cleanContent.contains('import') && !cleanContent.contains('class')) {
          await entity.delete();
          deletedCount++;
        }
      } catch (e) {
        // Fichier illisible, le supprimer
        try {
          await entity.delete();
          deletedCount++;
        } catch (_) {}
      }
    }
  }
  
  return deletedCount;
}

/// Créer les fichiers essentiels manquants
Future<void> _createEssentialFiles() async {
  // Créer app_theme.dart si manquant
  final themeFile = File('lib/core/theme/app_theme.dart');
  if (!await themeFile.exists()) {
    await themeFile.create(recursive: true);
    await themeFile.writeAsString(_getAppThemeContent());
  }
  
  // Créer app_constants.dart si manquant
  final constantsFile = File('lib/core/constants/app_constants.dart');
  if (!await constantsFile.exists()) {
    await constantsFile.create(recursive: true);
    await constantsFile.writeAsString(_getAppConstantsContent());
  }
  
  // Créer validators.dart si manquant
  final validatorsFile = File('lib/core/utils/validators.dart');
  if (!await validatorsFile.exists()) {
    await validatorsFile.create(recursive: true);
    await validatorsFile.writeAsString(_getValidatorsContent());
  }
}

String _getAppThemeContent() {
  return '''import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Colors.blue;
  static const Color secondaryColor = Colors.green;
  static const Color accentColor = Colors.orange;
  
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      primarySwatch: Colors.blue,
      brightness: Brightness.dark,
      useMaterial3: true,
    );
  }
}
''';
}

String _getAppConstantsContent() {
  return '''class AppConstants {
  static const String appName = 'Constat Tunisie';
  static const String appVersion = '1.0.0';
  
  // Collections Firestore
  static const String usersCollection = 'users';
  static const String compagniesCollection = 'compagnies_assurance';
  static const String agencesCollection = 'agences';
  static const String agentsCollection = 'agents_assurance';
  static const String expertsCollection = 'experts';
  static const String contratsCollection = 'contrats';
  static const String sinistresCollection = 'sinistres';
  static const String vehiculesCollection = 'vehicules_assures';
  static const String constatsCollection = 'constats';
}
''';
}

String _getValidatorsContent() {
  return '''class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email requis';
    }
    if (!value.contains('@')) {
      return 'Email invalide';
    }
    return null;
  }
  
  static String? required(String? value, [String? message]) {
    if (value == null || value.isEmpty) {
      return message ?? 'Champ requis';
    }
    return null;
  }
  
  static String? phone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Téléphone requis';
    }
    if (value.length < 8) {
      return 'Téléphone invalide';
    }
    return null;
  }
}
''';
}
