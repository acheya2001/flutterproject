import 'dart:io';

/// 🎯 Correction finale ultra-efficace
void main() async {
  print('🎯 Correction finale...');
  
  final criticalFixes = [
    // Erreurs critiques de syntaxe
    ['static ;', ''],
    ['static  ;', ''],
    ['static   ;', ''],
    ['\$1)', ''],
    ['\$1,', ''],
    ['\$1;', ';'],
    ['\$1', ''],
    
    // Erreurs const
    ['const ElevatedButton(', 'ElevatedButton('],
    ['const TextButton(', 'TextButton('],
    ['const IconButton(', 'IconButton('],
    ['const AppBar(', 'AppBar('],
    ['const Scaffold(', 'Scaffold('],
    ['const MaterialApp(', 'MaterialApp('],
    ['const TextField(', 'TextField('],
    ['const TextFormField(', 'TextFormField('],
    ['const Container(', 'Container('],
    ['const AlertDialog(', 'AlertDialog('],
    ['const Card(', 'Card('],
    ['const ListTile(', 'ListTile('],
    ['const FloatingActionButton(', 'FloatingActionButton('],
    ['const const ', 'const '],
    
    // Erreurs de syntaxe
    ['Selectableconst', 'SelectableText('],
    ['Selectable(const Text', 'SelectableText('],
    ['adminData:', 'data:'],
    
    // Erreurs withOpacity
    ['.withOpacity(', '.withValues(alpha: '],
    
    // Erreurs de constructeurs
    ['this.createdData = );', 'this.createdData = const [];'],
    ['this.collectionsUsed = );', 'this.collectionsUsed = const {};'],
    
    // Erreurs de texte
    ['Text("")', 'Text("Texte")'],
    ['Text()', 'Text("Texte")'],
    
    // Erreurs de style
    ['style: )', 'style: const TextStyle())'],
    ['padding: )', 'padding: const EdgeInsets.all(8.0))'],
    
    // Erreurs de parenthèses
    ['children: [', 'children: ['],
    [']),', '),'],
    
    // Nettoyer les lignes vides
    ['\n\n\n', '\n\n'],
    ['\n\n\n\n', '\n\n'],
  ];
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  int totalFixes = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        int fileFixes = 0;
        
        for (final fix in criticalFixes) {
          String before = content;
          content = content.replaceAll(fix[0], fix[1]);
          if (content != before) fileFixes++;
        }
        
        if (content != originalContent) {
          await file.writeAsString(content);
          filesFixed++;
          totalFixes += fileFixes;
          
          if (filesFixed % 20 == 0) {
            print('📝 $filesFixed fichiers corrigés...');
          }
        }
        
      } catch (e) {
        // Ignorer les erreurs de lecture
      }
    }
  }
  
  print('✅ $filesFixed fichiers corrigés !');
  print('✅ $totalFixes corrections appliquées !');
  print('🚀 Testez maintenant: flutter analyze');
}
