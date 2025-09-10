import 'dart:io';

/// Script pour nettoyer le fichier dashboard en supprimant le code orphelin
void main() async {
  final file = File('lib/features/conducteur/screens/conducteur_dashboard_complete.dart');
  
  if (!await file.exists()) {
    print('❌ Fichier non trouvé');
    return;
  }
  
  final lines = await file.readAsLines();
  print('📄 Fichier original: ${lines.length} lignes');
  
  // Trouver la fin de la classe principale
  int classEndIndex = -1;
  int braceCount = 0;
  bool inClass = false;
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i].trim();
    
    // Détecter le début de la classe
    if (line.contains('class _ConducteurDashboardCompleteState extends StatefulWidget')) {
      inClass = true;
      print('🎯 Début de classe trouvé à la ligne ${i + 1}');
    }
    
    if (inClass) {
      // Compter les accolades
      braceCount += '{'.allMatches(line).length;
      braceCount -= '}'.allMatches(line).length;
      
      // Si on revient à 0, c'est la fin de la classe
      if (braceCount == 0 && line == '}') {
        classEndIndex = i;
        print('🎯 Fin de classe trouvée à la ligne ${i + 1}');
        break;
      }
    }
  }
  
  if (classEndIndex == -1) {
    print('❌ Impossible de trouver la fin de la classe');
    return;
  }
  
  // Garder seulement les lignes jusqu'à la fin de la classe
  final cleanLines = lines.sublist(0, classEndIndex + 1);
  
  // Créer une sauvegarde
  final backupFile = File('lib/features/conducteur/screens/conducteur_dashboard_complete.dart.backup');
  await backupFile.writeAsString(lines.join('\n'));
  print('💾 Sauvegarde créée: ${backupFile.path}');
  
  // Écrire le fichier nettoyé
  await file.writeAsString(cleanLines.join('\n'));
  
  print('✅ Fichier nettoyé: ${cleanLines.length} lignes (supprimé ${lines.length - cleanLines.length} lignes)');
  print('🎉 Nettoyage terminé !');
}
