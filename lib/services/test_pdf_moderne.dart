import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'modern_tunisian_pdf_service.dart';

/// 🧪 Service de test pour le PDF moderne avec vérification des données
class TestPdfModerne {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🔍 Vérifier les données d'une session avant génération PDF
  static Future<Map<String, dynamic>> verifierDonneesSession(String sessionId) async {
    try {
      print('🔍 [TEST] Vérification des données pour session: $sessionId');
      
      final resultats = <String, dynamic>{
        'sessionId': sessionId,
        'sessionExiste': false,
        'participants': [],
        'signatures': [],
        'croquis': null,
        'erreurs': [],
      };

      // 1. Vérifier session principale
      final sessionDoc = await _firestore.collection('sessions_collaboratives').doc(sessionId).get();
      if (sessionDoc.exists) {
        resultats['sessionExiste'] = true;
        resultats['sessionData'] = sessionDoc.data();
        print('✅ [TEST] Session trouvée');
      } else {
        resultats['erreurs'].add('Session non trouvée');
        print('❌ [TEST] Session non trouvée');
        return resultats;
      }

      // 2. Vérifier participants
      final participantsSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('participants_data')
          .get();
      
      resultats['participants'] = participantsSnapshot.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();
      print('📊 [TEST] ${participantsSnapshot.docs.length} participants trouvés');

      // 3. Vérifier signatures
      final signaturesSnapshot = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('signatures')
          .get();
      
      resultats['signatures'] = signaturesSnapshot.docs.map((doc) => {
        'id': doc.id,
        'data': doc.data(),
      }).toList();
      print('✍️ [TEST] ${signaturesSnapshot.docs.length} signatures trouvées');

      // 4. Vérifier croquis
      try {
        final croquisDoc = await _firestore
            .collection('sessions_collaboratives')
            .doc(sessionId)
            .collection('croquis')
            .doc('principal')
            .get();
        
        if (croquisDoc.exists) {
          resultats['croquis'] = croquisDoc.data();
          print('🎨 [TEST] Croquis trouvé');
        } else {
          print('⚠️ [TEST] Aucun croquis trouvé');
        }
      } catch (e) {
        print('⚠️ [TEST] Erreur croquis: $e');
      }

      return resultats;
    } catch (e) {
      print('❌ [TEST] Erreur vérification: $e');
      return {
        'sessionId': sessionId,
        'erreurs': ['Erreur vérification: $e'],
      };
    }
  }

  /// 🧪 Tester la génération PDF avec vérification préalable
  static Future<void> testerGenerationPdfAvecVerification(BuildContext context, String sessionId) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Vérification des données...'),
            ],
          ),
        ),
      );

      // 1. Vérifier les données
      final verification = await verifierDonneesSession(sessionId);
      
      // Fermer l'indicateur de vérification
      Navigator.of(context).pop();

      // 2. Afficher les résultats de vérification
      if (verification['erreurs'].isNotEmpty) {
        _afficherErreurs(context, verification);
        return;
      }

      // 3. Afficher les données trouvées
      await _afficherDonneesTrouvees(context, verification);

      // 4. Demander confirmation pour générer le PDF
      final confirmer = await _demanderConfirmationGeneration(context);
      if (!confirmer) return;

      // 5. Générer le PDF
      await _genererPdfAvecIndicateur(context, sessionId);

    } catch (e) {
      Navigator.of(context).pop(); // Fermer l'indicateur si ouvert
      _afficherErreur(context, 'Erreur test: $e');
    }
  }

  /// 📊 Afficher les données trouvées
  static Future<void> _afficherDonneesTrouvees(BuildContext context, Map<String, dynamic> verification) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📊 Données trouvées'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Session: ${verification['sessionExiste'] ? '✅' : '❌'}'),
              Text('Participants: ${verification['participants'].length}'),
              Text('Signatures: ${verification['signatures'].length}'),
              Text('Croquis: ${verification['croquis'] != null ? '✅' : '❌'}'),
              const SizedBox(height: 10),
              const Text('Détails participants:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...verification['participants'].map<Widget>((p) => Text('• ${p['id']}')).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ❓ Demander confirmation pour génération
  static Future<bool> _demanderConfirmationGeneration(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🇹🇳 Générer PDF Tunisien'),
        content: const Text('Voulez-vous générer le PDF avec ces données ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Générer'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// 📄 Générer le PDF avec indicateur
  static Future<void> _genererPdfAvecIndicateur(BuildContext context, String sessionId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Text('Génération PDF en cours...'),
          ],
        ),
      ),
    );

    try {
      final pdfPath = await ModernTunisianPdfService.genererConstatModerne(
        sessionId: sessionId,
      );
      
      Navigator.of(context).pop(); // Fermer l'indicateur
      
      // Afficher le succès
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🎉 PDF Généré !'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Le PDF a été généré avec succès !'),
              const SizedBox(height: 10),
              SelectableText(pdfPath, style: const TextStyle(fontSize: 12)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Fermer l'indicateur
      _afficherErreur(context, 'Erreur génération PDF: $e');
    }
  }

  /// ❌ Afficher les erreurs
  static void _afficherErreurs(BuildContext context, Map<String, dynamic> verification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Erreurs trouvées'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: verification['erreurs'].map<Widget>((e) => Text('• $e')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// ❌ Afficher une erreur simple
  static void _afficherErreur(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('❌ Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
