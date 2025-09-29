import 'dart:io';
import 'lib/services/complete_elegant_pdf_service.dart';

void main() async {
  print('🧪 Test de génération PDF...');
  
  // ID de session de test (remplacez par un vrai ID de votre Firestore)
  const sessionId = 'test_session_id';
  
  try {
    final pdfBytes = await CompleteElegantPdfService.genererPdfComplet(sessionId);
    
    if (pdfBytes != null) {
      // Sauvegarder le PDF
      final file = File('test_constat.pdf');
      await file.writeAsBytes(pdfBytes);
      print('✅ PDF généré avec succès: ${file.path}');
      print('📄 Taille: ${pdfBytes.length} bytes');
    } else {
      print('❌ Échec de la génération PDF');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
