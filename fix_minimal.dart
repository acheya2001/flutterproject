import 'dart:io';

/// 🔧 Correction minimale pour faire fonctionner l'app
void main() async {
  print('🔧 Correction minimale en cours...');
  
  // Fichiers critiques à corriger en priorité
  final criticalFiles = [
    'lib/main.dart',
    'lib/features/auth/presentation/screens/login_screen.dart',
    'lib/features/admin/presentation/screens/super_admin_dashboard.dart',
    'lib/admin/admin_compagnie_dashboard.dart',
    'lib/admin/widgets/agence_management_tab.dart',
    'lib/admin/widgets/agent_management_tab.dart',
    'lib/common/widgets/simple_credentials_dialog.dart',
  ];
  
  for (final filePath in criticalFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      try {
        String content = await file.readAsString();
        
        // Corrections essentielles
        content = _fixCriticalErrors(content);
        
        await file.writeAsString(content);
        print('✅ Corrigé: $filePath');
      } catch (e) {
        print('⚠️ Erreur: $filePath - $e');
      }
    }
  }
  
  print('✅ Correction minimale terminée !');
  print('🚀 Essayez: flutter run');
}

String _fixCriticalErrors(String content) {
  // 1. Supprimer les const problématiques
  content = content.replaceAll('const ElevatedButton(', 'ElevatedButton(');
  content = content.replaceAll('const TextButton(', 'TextButton(');
  content = content.replaceAll('const IconButton(', 'IconButton(');
  content = content.replaceAll('const AppBar(', 'AppBar(');
  content = content.replaceAll('const Scaffold(', 'Scaffold(');
  content = content.replaceAll('const MaterialApp(', 'MaterialApp(');
  content = content.replaceAll('const TextField(', 'TextField(');
  content = content.replaceAll('const Container(', 'Container(');
  content = content.replaceAll('const AlertDialog(', 'AlertDialog(');
  
  // 2. Corriger withOpacity
  content = content.replaceAll(RegExp(r'\.withOpacity\(([^)]+)\)'), '.withValues(alpha: \$1)');
  
  // 3. Corriger les doubles const
  content = content.replaceAll('const const ', 'const ');
  
  // 4. Corriger les erreurs spécifiques
  content = content.replaceAll('Selectableconst', 'Selectable(const');
  content = content.replaceAll('adminData:', 'data:');
  
  return content;
}
