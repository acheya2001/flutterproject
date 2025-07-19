import 'dart:io';

/// 🔧 Correction massive et intelligente de toutes les erreurs
void main() async {
  print('🔧 Correction massive de 4147 erreurs...');
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  int errorsFixed = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        int fileErrors = 0;
        
        // 1. CORRIGER LES ERREURS CONST CRITIQUES
        content = _fixConstErrors(content);
        if (content != originalContent) fileErrors++;
        
        // 2. CORRIGER LES ERREURS WITHOPACITY
        content = _fixWithOpacityErrors(content);
        if (content != originalContent) fileErrors++;
        
        // 3. CORRIGER LES ERREURS DE CONSTRUCTEURS
        content = _fixConstructorErrors(content);
        if (content != originalContent) fileErrors++;
        
        // 4. CORRIGER LES ERREURS DE SYNTAXE
        content = _fixSyntaxErrors(content);
        if (content != originalContent) fileErrors++;
        
        // 5. CORRIGER LES ERREURS D'IMPORTS
        content = _fixImportErrors(content);
        if (content != originalContent) fileErrors++;
        
        // 6. CORRIGER LES ERREURS SPÉCIFIQUES
        content = _fixSpecificErrors(content);
        if (content != originalContent) fileErrors++;
        
        if (content != originalContent) {
          await file.writeAsString(content);
          filesFixed++;
          errorsFixed += fileErrors;
          if (filesFixed % 50 == 0) {
            print('📝 $filesFixed fichiers corrigés...');
          }
        }
        
      } catch (e) {
        print('⚠️ Erreur: ${file.path}');
      }
    }
  }
  
  print('✅ $filesFixed fichiers corrigés !');
  print('✅ ~$errorsFixed erreurs corrigées !');
  print('🚀 Lancez: flutter run');
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
    'ListView', 'GridView', 'SingleChildScrollView', 'Column',
    'Row', 'Stack', 'Positioned', 'Expanded', 'Flexible',
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
  content = content.replaceAll(RegExp(r'const\s+([^(]*\.[a-zA-Z]+\([^)]*\)[^)]*)'), r'$1');
  
  return content;
}

/// Corriger les erreurs withOpacity
String _fixWithOpacityErrors(String content) {
  return content.replaceAll(RegExp(r'\.withOpacity\(([^)]+)\)'), '.withValues(alpha: \$1)');
}

/// Corriger les erreurs de constructeurs
String _fixConstructorErrors(String content) {
  // Corriger super.key en Key? key
  content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*\{\s*super\.key'), r'const $1({Key? key');
  content = content.replaceAll('}) : super(key: key);', '}) : super(key: key);');
  
  // Corriger les paramètres nommés incorrects
  content = content.replaceAll('adminData:', 'data:');
  
  return content;
}

/// Corriger les erreurs de syntaxe
String _fixSyntaxErrors(String content) {
  // Corriger Selectableconst
  content = content.replaceAll('Selectableconst', 'Selectable(const');
  content = content.replaceAll('Selectable(const Text', 'SelectableText(');
  
  // Corriger les virgules manquantes
  content = content.replaceAll(RegExp(r'(\w+)\s+const\s+Text\('), r'$1, const Text(');
  
  return content;
}

/// Corriger les erreurs d'imports
String _fixImportErrors(String content) {
  final unusedImports = [
    "import '../services/agent_management_service.dart';",
    "import 'package:firebase_auth/firebase_auth.dart';",
    "import 'package:provider/provider.dart';",
    "import 'dart:typed_data';",
  ];
  
  for (final import in unusedImports) {
    content = content.replaceAll('$import\n', '');
  }
  
  return content;
}

/// Corriger les erreurs spécifiques
String _fixSpecificErrors(String content) {
  // Corriger les invalid constant values
  content = content.replaceAll(RegExp(r'const\s+([A-Z][a-zA-Z]*)\s*\(\s*[^)]*\$'), r'$1(');
  
  // Corriger les méthodes dans const
  content = content.replaceAll(RegExp(r'const\s+([^(]*\.[a-zA-Z]+\([^)]*\))'), r'$1');
  
  // Corriger les arguments non-const dans const
  content = content.replaceAll(RegExp(r'const\s+([^(]*\([^)]*[a-zA-Z]+\.[a-zA-Z]+[^)]*)'), r'$1');
  
  return content;
}
