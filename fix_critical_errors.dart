import 'dart:io';

/// 🔧 Script pour corriger les erreurs critiques de compilation
void main() async {
  print('🔧 Correction des erreurs critiques...');
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        
        // 1. Corriger les erreurs Selectableconst
        content = content.replaceAll('Selectableconst', 'Selectable(const');
        content = content.replaceAll('Selectable(const Text', 'Selectable.selectable(const Text');
        
        // 2. Corriger les erreurs de paramètres nommés
        content = content.replaceAll('adminData:', 'data:');
        
        // 3. Corriger les constructeurs const avec non-const
        content = content.replaceAll(RegExp(r'const\s+ElevatedButton\('), 'ElevatedButton(');
        content = content.replaceAll(RegExp(r'const\s+TextButton\('), 'TextButton(');
        content = content.replaceAll(RegExp(r'const\s+OutlinedButton\('), 'OutlinedButton(');
        content = content.replaceAll(RegExp(r'const\s+IconButton\('), 'IconButton(');
        content = content.replaceAll(RegExp(r'const\s+FloatingActionButton\('), 'FloatingActionButton(');
        content = content.replaceAll(RegExp(r'const\s+AppBar\('), 'AppBar(');
        content = content.replaceAll(RegExp(r'const\s+Scaffold\('), 'Scaffold(');
        content = content.replaceAll(RegExp(r'const\s+MaterialApp\('), 'MaterialApp(');
        content = content.replaceAll(RegExp(r'const\s+TextField\('), 'TextField(');
        content = content.replaceAll(RegExp(r'const\s+TextFormField\('), 'TextFormField(');
        content = content.replaceAll(RegExp(r'const\s+DropdownButton\('), 'DropdownButton(');
        content = content.replaceAll(RegExp(r'const\s+ListTile\('), 'ListTile(');
        content = content.replaceAll(RegExp(r'const\s+Card\('), 'Card(');
        content = content.replaceAll(RegExp(r'const\s+Container\('), 'Container(');
        content = content.replaceAll(RegExp(r'const\s+AlertDialog\('), 'AlertDialog(');
        content = content.replaceAll(RegExp(r'const\s+Dialog\('), 'Dialog(');
        content = content.replaceAll(RegExp(r'const\s+CircularProgressIndicator\('), 'CircularProgressIndicator(');
        content = content.replaceAll(RegExp(r'const\s+LinearProgressIndicator\('), 'LinearProgressIndicator(');
        
        // 4. Corriger les invalid constant values
        content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*[^)]*\$'), r'$1(');
        
        // 5. Corriger les Colors.shade dans const
        content = content.replaceAll(RegExp(r'const\s+([^(]*Colors\.[a-zA-Z]+\.shade[0-9]+[^)]*)'), r'$1');
        
        // 6. Corriger les méthodes dans const
        content = content.replaceAll(RegExp(r'const\s+([^(]*\.[a-zA-Z]+\([^)]*\)[^)]*)'), r'$1');
        
        // 7. Supprimer les imports inutilisés courants
        final unusedImports = [
          "import '../services/agent_management_service.dart';",
          "import 'package:firebase_auth/firebase_auth.dart';",
        ];
        
        for (final import in unusedImports) {
          content = content.replaceAll('$import\n', '');
        }
        
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
  print('🚀 Relancez: flutter run');
}
