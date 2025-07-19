import 'dart:io';

/// ⚡ Correction ultra-rapide des erreurs les plus critiques
void main() async {
  print('⚡ Correction ultra-rapide...');
  
  final fixes = [
    // Corrections critiques
    ['\$1)', ''],
    ['\$1,', ''],
    ['\$1;', ';'],
    ['\$1', ''],
    ['const ElevatedButton(', 'ElevatedButton('],
    ['const TextButton(', 'TextButton('],
    ['const IconButton(', 'IconButton('],
    ['const AppBar(', 'AppBar('],
    ['const Scaffold(', 'Scaffold('],
    ['const MaterialApp(', 'MaterialApp('],
    ['const TextField(', 'TextField('],
    ['const Container(', 'Container('],
    ['const AlertDialog(', 'AlertDialog('],
    ['const const ', 'const '],
    ['Selectableconst', 'SelectableText('],
    ['adminData:', 'data:'],
    ['.withOpacity(', '.withValues(alpha: '],
    ['this.createdData = );', 'this.createdData = const [];'],
    ['this.collectionsUsed = );', 'this.collectionsUsed = const {};'],
    ['Text("")', 'Text("Texte")'],
    ['style: )', 'style: const TextStyle())'],
    ['padding: )', 'padding: const EdgeInsets.all(8.0))'],
  ];
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        
        for (final fix in fixes) {
          content = content.replaceAll(fix[0], fix[1]);
        }
        
        if (content != originalContent) {
          await file.writeAsString(content);
          filesFixed++;
        }
        
      } catch (e) {
        // Ignorer les erreurs
      }
    }
  }
  
  print('✅ $filesFixed fichiers corrigés !');
  print('🚀 Testez: flutter run');
}
