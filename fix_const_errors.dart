import 'dart:io';

/// 🔧 Script pour corriger les erreurs const const
void main() async {
  print('🔧 Correction des erreurs const const...');
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        
        // Corriger les erreurs courantes
        content = content.replaceAll('const const ', 'const ');
        content = content.replaceAll('const const(', 'const (');
        content = content.replaceAll('const const Text', 'const Text');
        content = content.replaceAll('const const Icon', 'const Icon');
        content = content.replaceAll('const const SizedBox', 'const SizedBox');
        content = content.replaceAll('const const Padding', 'const Padding');
        content = content.replaceAll('const const Center', 'const Center');
        content = content.replaceAll('const const EdgeInsets', 'const EdgeInsets');
        
        // Corriger les erreurs de syntaxe avec const en tant qu'identifiant
        content = content.replaceAll(RegExp(r'const\s+const\s+'), 'const ');
        
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
  print('🚀 Vous pouvez maintenant lancer: flutter run');
}
