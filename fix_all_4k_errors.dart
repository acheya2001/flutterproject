import 'dart:io';

/// 🔧 Correction complète et intelligente des 4K+ erreurs
void main() async {
  print('🔧 Correction des 4000+ erreurs...');
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  int totalErrors = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        int fileErrors = 0;
        
        // 1. CORRIGER LES ERREURS $1 CRITIQUES
        content = _fixDollarErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        // 2. CORRIGER LES ERREURS CONST
        content = _fixConstErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        // 3. CORRIGER LES ERREURS DE SYNTAXE
        content = _fixSyntaxErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        // 4. CORRIGER LES ERREURS DE CONSTRUCTEURS
        content = _fixConstructorErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        // 5. CORRIGER LES ERREURS D'IMPORTS
        content = _fixImportErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        // 6. CORRIGER LES ERREURS WITHOPACITY
        content = _fixWithOpacityErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        // 7. CORRIGER LES ERREURS SPÉCIFIQUES
        content = _fixSpecificErrors(content);
        if (content != originalContent) { fileErrors++; originalContent = content; }
        
        if (fileErrors > 0) {
          await file.writeAsString(content);
          filesFixed++;
          totalErrors += fileErrors;
          
          if (filesFixed % 25 == 0) {
            print('📝 $filesFixed fichiers corrigés (~$totalErrors erreurs)...');
          }
        }
        
      } catch (e) {
        print('⚠️ Erreur: ${file.path}');
      }
    }
  }
  
  print('✅ $filesFixed fichiers corrigés !');
  print('✅ ~$totalErrors erreurs corrigées !');
  print('🚀 Testez: flutter analyze');
}

/// Corriger les erreurs $1 créées par les scripts
String _fixDollarErrors(String content) {
  // Corriger les $1) basiques
  content = content.replaceAll('\$1)', '');
  content = content.replaceAll('\$1,', '');
  content = content.replaceAll('\$1;', ';');
  content = content.replaceAll('\$1', '');
  
  // Corriger les Text($1{...})
  content = content.replaceAll(RegExp(r'Text\(\$1\{([^}]+)\}\)'), r'Text("$1")');
  content = content.replaceAll(RegExp(r'\$1\{([^}]+)\}'), r'$1');
  
  // Corriger les erreurs de syntaxe communes
  content = content.replaceAll('Text("")', 'Text("Texte")');
  content = content.replaceAll('style: )', 'style: const TextStyle())');
  content = content.replaceAll('padding: )', 'padding: const EdgeInsets.all(8.0))');
  
  // Corriger les constructeurs cassés
  content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*\)'), r'const $1()');
  
  // Corriger les listes cassées
  content = content.replaceAll('this.createdData = );', 'this.createdData = const [];');
  content = content.replaceAll('this.collectionsUsed = );', 'this.collectionsUsed = const {};');
  
  return content;
}

/// Corriger les erreurs const
String _fixConstErrors(String content) {
  // Supprimer const des constructeurs non-const
  final nonConstConstructors = [
    'ElevatedButton', 'TextButton', 'IconButton', 'OutlinedButton',
    'FloatingActionButton', 'AppBar', 'Scaffold', 'MaterialApp',
    'TextField', 'TextFormField', 'DropdownButton', 'ListTile',
    'Card', 'Container', 'AlertDialog', 'Dialog', 'Drawer',
    'CircularProgressIndicator', 'LinearProgressIndicator',
    'BottomNavigationBar', 'TabBar', 'TabBarView', 'PageView',
    'ListView', 'GridView', 'SingleChildScrollView',
    'GestureDetector', 'InkWell', 'Hero', 'AnimatedContainer',
    'FadeTransition', 'SlideTransition', 'ScaleTransition'
  ];
  
  for (final constructor in nonConstConstructors) {
    content = content.replaceAll('const $constructor(', '$constructor(');
  }
  
  // Corriger les doubles const
  content = content.replaceAll(RegExp(r'const\s+const\s+'), 'const ');
  
  // Corriger const avec expressions non-const
  content = content.replaceAll(RegExp(r'const\s+([^(]*\$[^)]*)'), r'$1');
  content = content.replaceAll(RegExp(r'const\s+([^(]*\.shade[0-9]+[^)]*)'), r'$1');
  
  return content;
}

/// Corriger les erreurs de syntaxe
String _fixSyntaxErrors(String content) {
  // Corriger Selectableconst
  content = content.replaceAll('Selectableconst', 'SelectableText(');
  content = content.replaceAll('Selectable(const Text', 'SelectableText(');
  
  // Corriger les virgules manquantes
  content = content.replaceAll(RegExp(r'(\w+)\s+const\s+Text\('), r'$1, const Text(');
  
  // Corriger les parenthèses manquantes
  content = content.replaceAll('children: [', 'children: [');
  
  return content;
}

/// Corriger les erreurs de constructeurs
String _fixConstructorErrors(String content) {
  // Corriger les paramètres nommés incorrects
  content = content.replaceAll('adminData:', 'data:');
  
  // Corriger super.key
  content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*\{\s*super\.key'), r'const $1({Key? key');
  
  return content;
}

/// Corriger les erreurs d'imports
String _fixImportErrors(String content) {
  final unusedImports = [
    "import '../services/agent_management_service.dart';",
    "import 'package:firebase_auth/firebase_auth.dart';",
  ];
  
  for (final import in unusedImports) {
    content = content.replaceAll('$import\n', '');
  }
  
  return content;
}

/// Corriger les erreurs withOpacity
String _fixWithOpacityErrors(String content) {
  return content.replaceAll(RegExp(r'\.withOpacity\(([^)]+)\)'), '.withValues(alpha: \$1)');
}

/// Corriger les erreurs spécifiques
String _fixSpecificErrors(String content) {
  // Corriger les invalid constant values
  content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*[^)]*\$'), r'$1(');
  
  // Corriger les méthodes dans const
  content = content.replaceAll(RegExp(r'const\s+([^(]*\.[a-zA-Z]+\([^)]*\))'), r'$1');
  
  // Corriger les arguments non-const dans const
  content = content.replaceAll(RegExp(r'const\s+([^(]*\([^)]*[a-zA-Z]+\.[a-zA-Z]+[^)]*)'), r'$1');
  
  // Nettoyer les lignes vides multiples
  content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
  
  return content;
}
