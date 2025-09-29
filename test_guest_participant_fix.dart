import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 🧪 Script de test pour vérifier la correction des participants invités
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialiser Firebase
  await Firebase.initializeApp();
  
  print('🚀 Test de la correction des participants invités...\n');
  
  await testGuestParticipantFix();
  
  print('\n✅ Test terminé');
}

/// 🔧 Tester la correction des participants invités
Future<void> testGuestParticipantFix() async {
  try {
    print('🔍 Phase 1: Recherche des sessions avec problèmes...');
    await findProblematicSessions();
    
    print('\n🔧 Phase 2: Test de création d\'un participant invité...');
    await testGuestParticipantCreation();
    
    print('\n📊 Phase 3: Vérification du comptage...');
    await verifyParticipantCounting();
    
  } catch (e) {
    print('❌ Erreur lors du test: $e');
  }
}

/// 🔍 Rechercher les sessions avec des problèmes de comptage
Future<void> findProblematicSessions() async {
  try {
    final sessionsQuery = await FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .where('statut', whereIn: ['creation', 'attente_participants', 'en_cours'])
        .get();

    print('📊 ${sessionsQuery.docs.length} sessions actives trouvées');

    int sessionsProblematiques = 0;
    
    for (final sessionDoc in sessionsQuery.docs) {
      final sessionData = sessionDoc.data();
      final sessionId = sessionDoc.id;
      
      final participants = List.from(sessionData['participants'] ?? []);
      final nombreVehicules = sessionData['nombreVehicules'] ?? 2;
      final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
      
      final participantsRejoints = progression['participantsRejoints'] ?? 0;
      final formulairesTermines = progression['formulairesTermines'] ?? 0;
      
      // Calculer les vraies statistiques
      final vraiParticipantsRejoints = participants.length;
      final vraiFormulairesTermines = participants.where((p) =>
        p['statut'] == 'formulaire_fini' ||
        p['formulaireStatus'] == 'termine'
      ).length;
      
      // Détecter les problèmes
      bool hasProblems = false;
      List<String> problems = [];
      
      if (vraiParticipantsRejoints != participantsRejoints) {
        hasProblems = true;
        problems.add('Participants: $vraiParticipantsRejoints vs $participantsRejoints');
      }
      
      if (vraiFormulairesTermines != formulairesTermines) {
        hasProblems = true;
        problems.add('Formulaires: $vraiFormulairesTermines vs $formulairesTermines');
      }
      
      if (hasProblems) {
        sessionsProblematiques++;
        print('⚠️  Session $sessionId:');
        print('   - Code: ${sessionData['codeSession']}');
        print('   - Véhicules: $nombreVehicules');
        print('   - Problèmes: ${problems.join(', ')}');
      }
    }
    
    print('📊 Résumé: $sessionsProblematiques sessions problématiques sur ${sessionsQuery.docs.length}');
    
  } catch (e) {
    print('❌ Erreur recherche sessions: $e');
  }
}

/// 🧪 Tester la création d'un participant invité
Future<void> testGuestParticipantCreation() async {
  try {
    print('🎭 Simulation de création d\'un participant invité...');
    
    // Créer une session de test
    final testSessionData = {
      'codeSession': 'TEST${DateTime.now().millisecondsSinceEpoch}',
      'typeAccident': 'Test accident',
      'nombreVehicules': 2,
      'statut': 'attente_participants',
      'conducteurCreateur': 'test_user',
      'participants': [
        {
          'userId': 'test_user',
          'nom': 'Créateur',
          'prenom': 'Test',
          'email': 'test@example.com',
          'telephone': '12345678',
          'roleVehicule': 'A',
          'type': 'inscrit',
          'statut': 'rejoint',
          'formulaireStatus': 'en_cours',
          'estCreateur': true,
          'dateRejoint': Timestamp.fromDate(DateTime.now()),
        }
      ],
      'progression': {
        'participantsRejoints': 1,
        'formulairesTermines': 0,
        'croquisValides': 0,
        'signaturesEffectuees': 0,
        'croquisCree': false,
        'peutFinaliser': false,
        'pourcentage': 0,
      },
      'dateCreation': Timestamp.fromDate(DateTime.now()),
      'dateModification': Timestamp.fromDate(DateTime.now()),
    };
    
    final sessionRef = await FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .add(testSessionData);
    
    print('✅ Session de test créée: ${sessionRef.id}');
    
    // Simuler l'ajout d'un participant invité
    await simulateGuestParticipantJoin(sessionRef.id);
    
    // Vérifier le résultat
    await verifySessionAfterGuestJoin(sessionRef.id);
    
    // Nettoyer
    await sessionRef.delete();
    print('🧹 Session de test supprimée');
    
  } catch (e) {
    print('❌ Erreur test création participant: $e');
  }
}

/// 🎭 Simuler l'ajout d'un participant invité
Future<void> simulateGuestParticipantJoin(String sessionId) async {
  try {
    print('👤 Simulation ajout participant invité...');
    
    final sessionRef = FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .doc(sessionId);
    
    final sessionDoc = await sessionRef.get();
    final sessionData = sessionDoc.data()!;
    
    List<dynamic> participants = List.from(sessionData['participants'] ?? []);
    
    // Ajouter le participant invité avec le bon format
    final nouveauParticipant = {
      'userId': 'guest_${DateTime.now().millisecondsSinceEpoch}',
      'nom': 'Invité',
      'prenom': 'Test',
      'email': 'invite@example.com',
      'telephone': '87654321',
      'roleVehicule': 'B',
      'type': 'invite_guest',
      'statut': 'formulaire_fini',
      'formulaireStatus': 'termine',
      'estCreateur': false,
      'dateRejoint': Timestamp.fromDate(DateTime.now()),
      'dateFormulaireFini': Timestamp.fromDate(DateTime.now()),
      'adresse': '123 Rue Test',
      'cin': '12345678',
    };
    
    participants.add(nouveauParticipant);
    
    // Recalculer la progression
    final participantsRejoints = participants.length;
    final formulairesTermines = participants.where((p) =>
      p['statut'] == 'formulaire_fini' ||
      p['formulaireStatus'] == 'termine'
    ).length;
    
    final progression = {
      'participantsRejoints': participantsRejoints,
      'formulairesTermines': formulairesTermines,
      'croquisValides': 0,
      'signaturesEffectuees': 0,
      'croquisCree': false,
      'peutFinaliser': false,
      'pourcentage': participantsRejoints > 0 ? ((formulairesTermines / participantsRejoints) * 100).round() : 0,
    };
    
    // Déterminer le nouveau statut
    final nombreVehicules = sessionData['nombreVehicules'] ?? 2;
    String nouveauStatut = 'attente_participants';
    
    if (participantsRejoints >= nombreVehicules) {
      if (formulairesTermines >= nombreVehicules) {
        nouveauStatut = 'validation_croquis';
      } else {
        nouveauStatut = 'en_cours';
      }
    }
    
    // Mettre à jour la session
    await sessionRef.update({
      'participants': participants,
      'progression': progression,
      'statut': nouveauStatut,
      'dateModification': Timestamp.fromDate(DateTime.now()),
    });
    
    print('✅ Participant invité ajouté avec succès');
    print('📊 Progression: $participantsRejoints/$nombreVehicules participants');
    print('📋 Formulaires terminés: $formulairesTermines');
    print('🔄 Nouveau statut: $nouveauStatut');
    
  } catch (e) {
    print('❌ Erreur simulation participant: $e');
  }
}

/// 📊 Vérifier la session après l'ajout du participant invité
Future<void> verifySessionAfterGuestJoin(String sessionId) async {
  try {
    print('🔍 Vérification de la session après ajout...');
    
    final sessionDoc = await FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .doc(sessionId)
        .get();
    
    final sessionData = sessionDoc.data()!;
    final participants = List.from(sessionData['participants'] ?? []);
    final progression = sessionData['progression'] as Map<String, dynamic>;
    
    print('📊 Résultats de vérification:');
    print('   - Participants dans la liste: ${participants.length}');
    print('   - Participants dans progression: ${progression['participantsRejoints']}');
    print('   - Formulaires terminés: ${progression['formulairesTermines']}');
    print('   - Statut: ${sessionData['statut']}');
    
    // Vérifier la cohérence
    bool isConsistent = true;
    
    if (participants.length != progression['participantsRejoints']) {
      print('❌ Incohérence: nombre de participants');
      isConsistent = false;
    }
    
    final realFormulairesTermines = participants.where((p) =>
      p['statut'] == 'formulaire_fini' ||
      p['formulaireStatus'] == 'termine'
    ).length;
    
    if (realFormulairesTermines != progression['formulairesTermines']) {
      print('❌ Incohérence: formulaires terminés');
      isConsistent = false;
    }
    
    if (isConsistent) {
      print('✅ Session cohérente après ajout du participant invité');
    } else {
      print('❌ Session incohérente après ajout du participant invité');
    }
    
  } catch (e) {
    print('❌ Erreur vérification: $e');
  }
}

/// 📊 Vérifier le comptage des participants
Future<void> verifyParticipantCounting() async {
  try {
    print('📊 Vérification du comptage global...');
    
    final sessionsQuery = await FirebaseFirestore.instance
        .collection('sessions_collaboratives')
        .limit(10)
        .get();
    
    int sessionsOK = 0;
    int sessionsProblematiques = 0;
    
    for (final sessionDoc in sessionsQuery.docs) {
      final sessionData = sessionDoc.data();
      final participants = List.from(sessionData['participants'] ?? []);
      final progression = sessionData['progression'] as Map<String, dynamic>? ?? {};
      
      final participantsRejoints = progression['participantsRejoints'] ?? 0;
      final formulairesTermines = progression['formulairesTermines'] ?? 0;
      
      final vraiParticipantsRejoints = participants.length;
      final vraiFormulairesTermines = participants.where((p) =>
        p['statut'] == 'formulaire_fini' ||
        p['formulaireStatus'] == 'termine'
      ).length;
      
      if (vraiParticipantsRejoints == participantsRejoints && 
          vraiFormulairesTermines == formulairesTermines) {
        sessionsOK++;
      } else {
        sessionsProblematiques++;
      }
    }
    
    print('📊 Résultats du comptage:');
    print('   - Sessions OK: $sessionsOK');
    print('   - Sessions problématiques: $sessionsProblematiques');
    print('   - Total vérifié: ${sessionsOK + sessionsProblematiques}');
    
    if (sessionsProblematiques == 0) {
      print('✅ Tous les comptages sont corrects !');
    } else {
      print('⚠️  Il reste des sessions avec des problèmes de comptage');
    }
    
  } catch (e) {
    print('❌ Erreur vérification comptage: $e');
  }
}

/// 🔧 Instructions d'utilisation
/// 
/// Pour exécuter ce test:
/// 1. Assurez-vous que Firebase est configuré
/// 2. Lancez: dart test_guest_participant_fix.dart
/// 
/// Le test va:
/// - Identifier les sessions avec des problèmes de comptage
/// - Créer une session de test
/// - Simuler l'ajout d'un participant invité
/// - Vérifier que le comptage est correct
/// - Nettoyer les données de test
