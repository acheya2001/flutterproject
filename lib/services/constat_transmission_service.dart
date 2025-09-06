import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/accident_session.dart';
import '../models/vehicule_model.dart';
import 'email_notification_service.dart';
import 'pdf_generation_service.dart';

/// 📤 Service de transmission automatique des constats aux compagnies d'assurance
class ConstatTransmissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// 🚀 Transmission automatique après finalisation du constat
  static Future<void> transmettreConstatFinalise(AccidentSession session) async {
    try {
      print('🚀 Début transmission constat ${session.codePublic}');

      // 1. Générer le PDF complet
      final pdfBytes = await PDFGenerationService.genererConstatComplet(session);
      
      // 2. Sauvegarder le PDF dans Firebase Storage
      final pdfUrl = await _sauvegarderPDF(session.id, pdfBytes);
      
      // 3. Identifier toutes les compagnies impliquées
      final compagniesImpliquees = await _identifierCompagnies(session);
      
      // 4. Transmettre à chaque compagnie
      for (final compagnie in compagniesImpliquees) {
        await _transmettreACompagnie(session, compagnie, pdfUrl);
      }
      
      // 5. Envoyer copies aux conducteurs
      await _envoyerCopiesAuxConducteurs(session, pdfUrl);
      
      // 6. Marquer comme transmis
      await _marquerCommeTransmis(session.id);
      
      print('✅ Transmission terminée avec succès');

    } catch (e) {
      print('❌ Erreur transmission: $e');
      await _enregistrerErreurTransmission(session.id, e.toString());
      rethrow;
    }
  }

  /// 💾 Sauvegarder le PDF dans Firebase Storage
  static Future<String> _sauvegarderPDF(String sessionId, List<int> pdfBytes) async {
    final ref = _storage.ref().child('constats/$sessionId/constat_final.pdf');
    await ref.putData(Uint8List.fromList(pdfBytes));
    return await ref.getDownloadURL();
  }

  /// 🏢 Identifier toutes les compagnies d'assurance impliquées
  static Future<List<Map<String, dynamic>>> _identifierCompagnies(AccidentSession session) async {
    final compagnies = <Map<String, dynamic>>[];
    
    for (final entry in session.identitesVehicules.entries) {
      final role = entry.key;
      final identite = entry.value;
      
      // Récupérer les infos de la compagnie depuis Firestore
      final compagnieDoc = await _firestore
          .collection('compagnies_assurance')
          .where('nom', isEqualTo: identite.compagnieAssurance)
          .limit(1)
          .get();
      
      if (compagnieDoc.docs.isNotEmpty) {
        final compagnieData = compagnieDoc.docs.first.data();
        compagnies.add({
          'id': compagnieDoc.docs.first.id,
          'nom': compagnieData['nom'],
          'email': compagnieData['email'],
          'agenceId': compagnieData['agenceId'],
          'vehiculeRole': role,
          'numeroPolice': identite.numeroPolice,
        });
      }
    }
    
    return compagnies;
  }

  /// 📧 Transmettre le constat à une compagnie spécifique
  static Future<void> _transmettreACompagnie(
    AccidentSession session,
    Map<String, dynamic> compagnie,
    String pdfUrl,
  ) async {
    // 1. Créer l'entrée dans la collection des constats reçus
    await _firestore.collection('constats_recus').add({
      'sessionId': session.id,
      'codePublic': session.codePublic,
      'compagnieId': compagnie['id'],
      'agenceId': compagnie['agenceId'],
      'vehiculeRole': compagnie['vehiculeRole'],
      'numeroPolice': compagnie['numeroPolice'],
      'dateAccident': Timestamp.fromDate(session.dateAccident!),
      'dateReception': Timestamp.now(),
      'statut': 'nouveau',
      'pdfUrl': pdfUrl,
      'priorite': _calculerPriorite(session),
      'montantEstime': null,
      'expertAssigne': null,
      'observations': '',
      'documentsComplementaires': [],
      'historique': [
        {
          'action': 'reception_automatique',
          'date': Timestamp.now(),
          'details': 'Constat reçu automatiquement depuis l\'application mobile',
        }
      ],
    });

    // 2. Envoyer notification email à la compagnie
    await EmailNotificationService.envoyerNotificationConstat(
      destinataire: compagnie['email'],
      codeConstat: session.codePublic,
      vehiculeRole: compagnie['vehiculeRole'],
      numeroPolice: compagnie['numeroPolice'],
      pdfUrl: pdfUrl,
    );

    // 3. Notification push aux admins de l'agence (si connectés)
    await _envoyerNotificationPushAgence(compagnie['agenceId'], session);
  }

  /// 📱 Envoyer notification push aux admins d'agence
  static Future<void> _envoyerNotificationPushAgence(String agenceId, AccidentSession session) async {
    // Récupérer les tokens FCM des admins de cette agence
    final adminsQuery = await _firestore
        .collection('users')
        .where('role', isEqualTo: 'admin_agence')
        .where('agenceId', isEqualTo: agenceId)
        .where('fcmToken', isNotEqualTo: null)
        .get();

    for (final adminDoc in adminsQuery.docs) {
      final fcmToken = adminDoc.data()['fcmToken'];
      if (fcmToken != null) {
        // TODO: Implémenter l'envoi FCM
        print('📱 Notification push envoyée à admin agence: $fcmToken');
      }
    }
  }

  /// 📧 Envoyer copies aux conducteurs
  static Future<void> _envoyerCopiesAuxConducteurs(AccidentSession session, String pdfUrl) async {
    for (final entry in session.identitesVehicules.entries) {
      final role = entry.key;
      final identite = entry.value;
      
      if (identite.emailConducteur.isNotEmpty) {
        await EmailNotificationService.envoyerCopieConstat(
          destinataire: identite.emailConducteur,
          nomConducteur: '${identite.prenomConducteur} ${identite.nomConducteur}',
          codeConstat: session.codePublic,
          vehiculeRole: role,
          pdfUrl: pdfUrl,
        );
      }
    }
  }

  /// ✅ Marquer le constat comme transmis
  static Future<void> _marquerCommeTransmis(String sessionId) async {
    await _firestore.collection('accident_sessions').doc(sessionId).update({
      'statut': AccidentSession.STATUT_TRANSMIS,
      'dateTransmission': Timestamp.now(),
      'transmissionReussie': true,
    });
  }

  /// ❌ Enregistrer une erreur de transmission
  static Future<void> _enregistrerErreurTransmission(String sessionId, String erreur) async {
    await _firestore.collection('accident_sessions').doc(sessionId).update({
      'erreurTransmission': erreur,
      'dateErreurTransmission': Timestamp.now(),
      'transmissionReussie': false,
    });

    // Log dans une collection séparée pour monitoring
    await _firestore.collection('erreurs_transmission').add({
      'sessionId': sessionId,
      'erreur': erreur,
      'date': Timestamp.now(),
      'resolu': false,
    });
  }

  /// 🎯 Calculer la priorité du constat
  static String _calculerPriorite(AccidentSession session) {
    // Haute priorité si blessés
    if (session.blesses) return 'haute';
    
    // Moyenne priorité si dégâts importants
    if (session.degatsAutres) return 'moyenne';
    
    // Normale par défaut
    return 'normale';
  }

  /// 📊 Obtenir le statut de transmission d'un constat
  static Future<Map<String, dynamic>> obtenirStatutTransmission(String sessionId) async {
    final doc = await _firestore.collection('accident_sessions').doc(sessionId).get();
    
    if (!doc.exists) {
      throw Exception('Session introuvable');
    }

    final data = doc.data()!;
    return {
      'transmis': data['transmissionReussie'] ?? false,
      'dateTransmission': data['dateTransmission'],
      'erreur': data['erreurTransmission'],
      'statut': data['statut'],
    };
  }

  /// 🔄 Retenter la transmission en cas d'échec
  static Future<void> retenterTransmission(String sessionId) async {
    final sessionDoc = await _firestore.collection('accident_sessions').doc(sessionId).get();
    
    if (!sessionDoc.exists) {
      throw Exception('Session introuvable');
    }

    final session = AccidentSession.fromFirestore(sessionDoc);
    await transmettreConstatFinalise(session);
  }

  /// 📈 Statistiques de transmission
  static Future<Map<String, int>> obtenirStatistiquesTransmission() async {
    final stats = <String, int>{};
    
    // Constats transmis avec succès
    final transmisQuery = await _firestore
        .collection('accident_sessions')
        .where('transmissionReussie', isEqualTo: true)
        .count()
        .get();
    stats['transmis'] = transmisQuery.count;
    
    // Constats en erreur
    final erreurQuery = await _firestore
        .collection('accident_sessions')
        .where('transmissionReussie', isEqualTo: false)
        .count()
        .get();
    stats['erreurs'] = erreurQuery.count;
    
    // Constats en attente
    final attenteQuery = await _firestore
        .collection('accident_sessions')
        .where('statut', isEqualTo: AccidentSession.STATUT_SIGNE_VALIDE)
        .where('transmissionReussie', isEqualTo: null)
        .count()
        .get();
    stats['en_attente'] = attenteQuery.count;
    
    return stats;
  }
}
