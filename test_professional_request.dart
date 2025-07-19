import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// 🧪 Script de test pour vérifier les demandes professionnelles
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Test de lecture des demandes
  await testReadRequests();
}

/// 📋 Test de lecture des demandes depuis Firestore
Future<void> testReadRequests() async {
  try {
    print('🔍 Test de lecture des demandes professionnelles...');
    
    final firestore = FirebaseFirestore.instance;
    
    // Lire toutes les demandes
    final snapshot = await firestore.collection('demandes_professionnels').get();
    
    print('📊 Nombre de demandes trouvées: ${snapshot.docs.length}');
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      print('📝 Demande ID: ${doc.id}');
      print('   - Nom: ${data['nom_complet']}');
      print('   - Email: ${data['email']}');
      print('   - Rôle: ${data['role_demande']}');
      print('   - Status: ${data['status']}');
      print('   - Envoyé le: ${data['envoye_le']}');
      print('   ---');
    }
    
    // Compter les demandes en attente
    final pendingSnapshot = await firestore
        .collection('demandes_professionnels')
        .where('status', isEqualTo: 'en_attente')
        .get();
    
    print('⏳ Demandes en attente: ${pendingSnapshot.docs.length}');
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}
