import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'lib/services/modern_tunisian_pdf_service.dart';

/// 🧪 Test direct du service PDF moderne
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialiser Firebase
    await Firebase.initializeApp();
    print('✅ Firebase initialisé');
    
    // Tester avec la session réelle
    const sessionId = 'FJqpcwzC86m9EsXs1PcC';
    print('🇹🇳 [TEST] Début test PDF pour session: $sessionId');
    
    // Générer le PDF
    final pdfPath = await ModernTunisianPdfService.genererConstatModerne(
      sessionId: sessionId,
    );
    
    print('🎉 [TEST] PDF généré avec succès: $pdfPath');
    
  } catch (e, stackTrace) {
    print('❌ [TEST] Erreur: $e');
    print('📍 [TEST] Stack: $stackTrace');
  }
}
