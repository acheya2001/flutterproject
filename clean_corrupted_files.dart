import 'dart:io';

/// 🧹 Nettoyage radical des fichiers corrompus
void main() async {
  print('🧹 Nettoyage des fichiers corrompus...');
  
  final libDir = Directory('lib');
  int filesFixed = 0;
  
  await for (final file in libDir.list(recursive: true)) {
    if (file is File && file.path.endsWith('.dart')) {
      try {
        String content = await file.readAsString();
        String originalContent = content;
        
        // 1. SUPPRIMER LES CORRUPTIONS CRÉÉES PAR MES SCRIPTS
        content = content.replaceAll("'Texte'", "");
        content = content.replaceAll('"Texte"', '');
        content = content.replaceAll('Texte', '');
        
        // 2. CORRIGER LES ERREURS DE SYNTAXE CRÉÉES
        content = content.replaceAll("'sinistres')", "'sinistres');");
        content = content.replaceAll("'agents')", "'agents');");
        content = content.replaceAll("'experts')", "'experts');");
        content = content.replaceAll("'compagnies')", "'compagnies');");
        
        // 3. CORRIGER LES FINS DE FICHIERS CASSÉES
        if (!content.endsWith('\n')) {
          content += '\n';
        }
        
        // 4. CORRIGER LES ACCOLADES MANQUANTES
        if (content.contains('return _importGeneric(') && 
            !content.contains('  }\n}')) {
          content = content.replaceAll(
            RegExp(r'return _importGeneric\([^;]*;\s*$'),
            'return _importGeneric(headers, dataRows, \'data\');\n  }\n}'
          );
        }
        
        // 5. SUPPRIMER LES DOUBLONS DE TEXTE
        content = content.replaceAll('TexteTexte', '');
        content = content.replaceAll('""', '"Contenu"');
        content = content.replaceAll("''", "'Contenu'");
        
        // 6. CORRIGER LES ERREURS DE PARENTHÈSES
        content = content.replaceAll('();', '();');
        content = content.replaceAll(');)', ');');
        
        // 7. NETTOYER LES LIGNES VIDES MULTIPLES
        content = content.replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
        
        // 8. CORRIGER LES IMPORTS CASSÉS
        content = content.replaceAll("import '';", "");
        content = content.replaceAll('import "";', "");
        
        if (content != originalContent) {
          await file.writeAsString(content);
          filesFixed++;
          print('🧹 Nettoyé: ${file.path}');
        }
        
      } catch (e) {
        print('⚠️ Erreur: ${file.path}');
      }
    }
  }
  
  print('✅ $filesFixed fichiers nettoyés !');
  print('🚀 Testez: flutter analyze');
}
