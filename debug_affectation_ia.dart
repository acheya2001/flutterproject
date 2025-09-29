import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// 🔍 Script de debug pour vérifier l'affectation IA des demandes
void main() async {
  await Firebase.initializeApp();
  
  print('🔍 === DEBUG AFFECTATION IA ===');
  
  await debugDemandes();
  await debugAgents();
  await debugAffectations();
}

/// 📋 Debug des demandes de contrats
Future<void> debugDemandes() async {
  print('\n📋 === DEMANDES DE CONTRATS ===');
  
  try {
    final snapshot = await FirebaseFirestore.instance
        .collection('demandes_contrats')
        .get();
    
    print('📊 Total demandes: ${snapshot.docs.length}');
    
    for (final doc in snapshot.docs) {
      final data = doc.data();
      print('📄 Demande ${doc.id}:');
      print('  - Statut: ${data['statut']}');
      print('  - AgentId: ${data['agentId']}');
      print('  - AgentNom: ${data['agentNom']}');
      print('  - AgentEmail: ${data['agentEmail']}');
      print('  - Mode affectation: ${data['affectationMode']}');
      print('  - Date affectation: ${data['dateAffectation']}');
      print('  - Numéro: ${data['numero']}');
      print('  - Email conducteur: ${data['email']}');
      print('  ---');
    }
  } catch (e) {
    print('❌ Erreur debug demandes: $e');
  }
}

/// 👥 Debug des agents
Future<void> debugAgents() async {
  print('\n👥 === AGENTS ===');
  
  try {
    // Agents dans users
    final usersSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'agent')
        .get();
    
    print('📊 Agents dans users: ${usersSnapshot.docs.length}');
    
    for (final doc in usersSnapshot.docs) {
      final data = doc.data();
      print('👤 Agent ${doc.id}:');
      print('  - Nom: ${data['prenom']} ${data['nom']}');
      print('  - Email: ${data['email']}');
      print('  - AgenceId: ${data['agenceId']}');
      print('  - Statut: ${data['statut']}');
      print('  ---');
    }
    
    // Agents dans agents_assurance
    final agentsSnapshot = await FirebaseFirestore.instance
        .collection('agents_assurance')
        .get();
    
    print('📊 Agents dans agents_assurance: ${agentsSnapshot.docs.length}');
    
    for (final doc in agentsSnapshot.docs) {
      final data = doc.data();
      print('👤 Agent ${doc.id}:');
      print('  - Nom: ${data['prenom']} ${data['nom']}');
      print('  - Email: ${data['email']}');
      print('  - AgenceId: ${data['agenceId']}');
      print('  ---');
    }
  } catch (e) {
    print('❌ Erreur debug agents: $e');
  }
}

/// 🔗 Debug des affectations
Future<void> debugAffectations() async {
  print('\n🔗 === AFFECTATIONS ===');
  
  try {
    // Récupérer toutes les demandes affectées
    final demandesAffectees = await FirebaseFirestore.instance
        .collection('demandes_contrats')
        .where('statut', isEqualTo: 'affectee')
        .get();
    
    print('📊 Demandes affectées: ${demandesAffectees.docs.length}');
    
    for (final doc in demandesAffectees.docs) {
      final data = doc.data();
      final agentId = data['agentId'];
      
      if (agentId != null) {
        print('🔗 Demande ${doc.id} → Agent $agentId');
        
        // Vérifier si l'agent existe
        try {
          final agentDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(agentId)
              .get();
          
          if (agentDoc.exists) {
            final agentData = agentDoc.data()!;
            print('  ✅ Agent trouvé: ${agentData['prenom']} ${agentData['nom']} (${agentData['email']})');
          } else {
            print('  ❌ Agent non trouvé dans users');
            
            // Chercher dans agents_assurance
            final agentDoc2 = await FirebaseFirestore.instance
                .collection('agents_assurance')
                .doc(agentId)
                .get();
            
            if (agentDoc2.exists) {
              final agentData = agentDoc2.data()!;
              print('  ✅ Agent trouvé dans agents_assurance: ${agentData['prenom']} ${agentData['nom']}');
            } else {
              print('  ❌ Agent non trouvé nulle part');
            }
          }
        } catch (e) {
          print('  ❌ Erreur vérification agent: $e');
        }
      } else {
        print('🔗 Demande ${doc.id} → Pas d\'agentId');
      }
    }
  } catch (e) {
    print('❌ Erreur debug affectations: $e');
  }
}
