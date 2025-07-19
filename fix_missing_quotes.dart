import 'dart:io';

/// 🔧 Script pour corriger les apostrophes manquantes
/// 
/// Ce script identifie et corrige automatiquement les problèmes
/// d'apostrophes manquantes dans les imports et exports Dart.

void main() async {
  print('🔍 Recherche des fichiers avec apostrophes manquantes...');
  
  final libDir = Directory('lib');
  final dartFiles = await _findDartFiles(libDir);
  
  int fixedFiles = 0;
  int totalIssues = 0;
  
  for (final file in dartFiles) {
    final issues = await _fixMissingQuotes(file);
    if (issues > 0) {
      fixedFiles++;
      totalIssues += issues;
      print('✅ Corrigé ${issues} problème(s) dans: ${file.path}');
    }
  }
  
  print('\n🎉 Correction terminée !');
  print('📊 Fichiers corrigés: $fixedFiles');
  print('📊 Total problèmes résolus: $totalIssues');
}

/// Trouve tous les fichiers .dart dans un répertoire
Future<List<File>> _findDartFiles(Directory dir) async {
  final files = <File>[];
  
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      files.add(entity);
    }
  }
  
  return files;
}

/// Corrige les apostrophes manquantes dans un fichier
Future<int> _fixMissingQuotes(File file) async {
  try {
    final content = await file.readAsString();
    final lines = content.split('\n');
    bool modified = false;
    int issuesFixed = 0;
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      
      // Patterns à corriger
      final patterns = [
        // Import/export sans apostrophe fermante
        RegExp(r"^(import|export)\s+['\"]([^'\"]+)$"),
        // Import/export avec point-virgule manquant après apostrophe
        RegExp(r"^(import|export)\s+['\"]([^'\"]+)['\"]$"),
      ];
      
      for (final pattern in patterns) {
        final match = pattern.firstMatch(line);
        if (match != null) {
          final keyword = match.group(1)!;
          final path = match.group(2)!;
          
          // Corriger la ligne
          if (!line.endsWith("';") && !line.endsWith('";')) {
            lines[i] = "$keyword '$path';";
            modified = true;
            issuesFixed++;
          }
        }
      }
      
      // Corriger les chaînes non fermées dans le code
      if (line.contains("'") && !_isStringProperlyClosed(line)) {
        // Tentative de correction simple
        if (line.endsWith("'") == false && line.contains("'")) {
          final corrected = _attemptStringCorrection(line);
          if (corrected != line) {
            lines[i] = corrected;
            modified = true;
            issuesFixed++;
          }
        }
      }
    }
    
    if (modified) {
      await file.writeAsString(lines.join('\n'));
    }
    
    return issuesFixed;
  } catch (e) {
    print('❌ Erreur lors du traitement de ${file.path}: $e');
    return 0;
  }
}

/// Vérifie si une chaîne est correctement fermée
bool _isStringProperlyClosed(String line) {
  int singleQuotes = 0;
  int doubleQuotes = 0;
  bool inSingleQuote = false;
  bool inDoubleQuote = false;
  
  for (int i = 0; i < line.length; i++) {
    final char = line[i];
    
    if (char == "'" && !inDoubleQuote) {
      if (i == 0 || line[i - 1] != '\\') {
        inSingleQuote = !inSingleQuote;
        singleQuotes++;
      }
    } else if (char == '"' && !inSingleQuote) {
      if (i == 0 || line[i - 1] != '\\') {
        inDoubleQuote = !inDoubleQuote;
        doubleQuotes++;
      }
    }
  }
  
  return !inSingleQuote && !inDoubleQuote;
}

/// Tente de corriger une chaîne mal fermée
String _attemptStringCorrection(String line) {
  // Patterns courants à corriger
  final corrections = [
    // Chaîne simple non fermée à la fin
    RegExp(r"^(.+)'([^']*$)"),
    // Import/export mal formé
    RegExp(r"^(import|export)\s+['\"]([^'\"]+)$"),
  ];
  
  for (final pattern in corrections) {
    final match = pattern.firstMatch(line);
    if (match != null) {
      if (line.startsWith('import ') || line.startsWith('export ')) {
        return "${match.group(1)} '${match.group(2)}';";
      } else {
        return "${match.group(1)}'${match.group(2)}'";
      }
    }
  }
  
  return line;
}
