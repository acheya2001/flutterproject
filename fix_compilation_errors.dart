import 'dart:io';

/// 🔧 Script pour corriger automatiquement les erreurs de compilation
void main() async {
  print('🔧 Début de la correction des erreurs de compilation...');
  
  // 1. Corriger les withOpacity en withValues
  await fixWithOpacityErrors();
  
  // 2. Ajouter const aux constructeurs
  await addConstToConstructors();
  
  // 3. Supprimer les imports inutilisés
  await removeUnusedImports();
  
  print('✅ Correction terminée !');
  print('🚀 Vous pouvez maintenant lancer: flutter run');
}

/// Corriger les withOpacity en withValues
Future<void> fixWithOpacityErrors() async {
  print('📝 Correction des withOpacity...');
  
  final libDir = Directory('lib');
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        
        // Remplacer withOpacity par withValues
        content = content.replaceAll(
          RegExp(r'\.withOpacity\(([^)]+)\)'),
          '.withValues(alpha: \$1)',
        );
        
        await file.writeAsString(content);
      } catch (e) {
        print('⚠️ Erreur avec ${file.path}: $e');
      }
    }
  }
  
  print('✅ withOpacity corrigés');
}

/// Ajouter const aux constructeurs simples
Future<void> addConstToConstructors() async {
  print('📝 Ajout de const aux constructeurs...');
  
  final libDir = Directory('lib');
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        
        // Ajouter const aux constructeurs courants
        final replacements = {
          'Text(': 'const Text(',
          'Icon(': 'const Icon(',
          'SizedBox(': 'const SizedBox(',
          'EdgeInsets.': 'const EdgeInsets.',
          'Padding(': 'const Padding(',
          'Center(': 'const Center(',
        };
        
        for (final entry in replacements.entries) {
          // Éviter les doublons de const
          content = content.replaceAll(
            'const ${entry.value}',
            entry.value,
          );
          content = content.replaceAll(
            entry.key,
            entry.value,
          );
        }
        
        await file.writeAsString(content);
      } catch (e) {
        print('⚠️ Erreur avec ${file.path}: $e');
      }
    }
  }
  
  print('✅ const ajoutés');
}

/// Supprimer les imports inutilisés courants
Future<void> removeUnusedImports() async {
  print('📝 Suppression des imports inutilisés...');
  
  final commonUnusedImports = [
    "import 'package:provider/provider.dart';",
    "import 'dart:typed_data';",
    "import '../../../core/widgets/custom_app_bar.dart';",
    "import '../../../core/widgets/empty_state.dart';",
    "import '../../../core/widgets/loading_state.dart';",
    "import '../../../core/services/email_service.dart';",
  ];
  
  final libDir = Directory('lib');
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        
        for (final import in commonUnusedImports) {
          content = content.replaceAll('$import\n', '');
        }
        
        await file.writeAsString(content);
      } catch (e) {
        print('⚠️ Erreur avec ${file.path}: $e');
      }
    }
  }
  
  print('✅ Imports inutilisés supprimés');
}
