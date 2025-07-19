import 'dart:io';

/// 🔧 Correction des erreurs $1 créées par les scripts automatiques
void main() async {
  print('🔧 Correction des erreurs \$1...');
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        
        // 1. Corriger les erreurs $1) basiques
        content = content.replaceAll('\$1)', '');
        content = content.replaceAll('\$1,', '');
        content = content.replaceAll('\$1;', ';');
        
        // 2. Corriger les Text($1{...})
        content = content.replaceAll(RegExp(r'\$1\(\{([^}]+)\}\)'), r'Text(\$1)');
        content = content.replaceAll(RegExp(r'\$1\{([^}]+)\}'), r'\$1');
        
        // 3. Corriger les erreurs de syntaxe communes
        content = content.replaceAll('Text(\$1)', 'Text("")');
        content = content.replaceAll('style: \$1)', 'style: const TextStyle())');
        content = content.replaceAll('padding: \$1)', 'padding: const EdgeInsets.all(8.0))');
        
        // 4. Corriger les constructeurs cassés
        content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*\$1\)'), r'const \$1()');
        
        // 5. Corriger les listes cassées
        content = content.replaceAll('this.createdData = \$1);', 'this.createdData = const [],');
        content = content.replaceAll('this.collectionsUsed = \$1);', 'this.collectionsUsed = const {},');
        
        // 6. Corriger les EdgeInsets cassés
        content = content.replaceAll('EdgeInsets.\$1)', 'EdgeInsets.all(8.0))');
        
        // 7. Corriger les TextStyle cassés
        content = content.replaceAll('TextStyle(\$1)', 'TextStyle()');
        
        // 8. Corriger les erreurs de fermeture
        content = content.replaceAll(RegExp(r'\$1\)\s*,\s*\)'), ')');
        content = content.replaceAll(RegExp(r'\$1\)\s*\)'), ')');
        
        // 9. Corriger les erreurs spécifiques
        content = content.replaceAll('content: \$1),', 'content: const Text("Contenu"),');
        content = content.replaceAll('title: \$1),', 'title: const Text("Titre"),');
        
        // 10. Nettoyer les lignes vides multiples
        content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
        
        if (content != originalContent) {
          await file.writeAsString(content);
          filesFixed++;
          print('✅ Corrigé: ${file.path}');
        }
        
      } catch (e) {
        print('⚠️ Erreur avec ${file.path}: $e');
      }
    }
  }
  
  print('✅ $filesFixed fichiers corrigés !');
  print('🚀 Essayez: flutter run');
}
