import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 📝 Service de gestion des brouillons pour les sessions collaboratives
class DraftService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 💾 Sauvegarder un brouillon de formulaire
  static Future<void> sauvegarderBrouillon({
    required String sessionId,
    required String etape,
    required Map<String, dynamic> donnees,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final brouillonData = {
        'sessionId': sessionId,
        'conducteurId': user.uid,
        'etape': etape,
        'donnees': donnees,
        'dateModification': FieldValue.serverTimestamp(),
        'statut': 'brouillon',
      };

      await _firestore
          .collection('brouillons_session')
          .doc('${sessionId}_${user.uid}_$etape')
          .set(brouillonData, SetOptions(merge: true));

      print('💾 Brouillon sauvegardé: $etape');
    } catch (e) {
      print('❌ Erreur sauvegarde brouillon: $e');
    }
  }

  /// 📖 Récupérer un brouillon
  static Future<Map<String, dynamic>?> recupererBrouillon({
    required String sessionId,
    required String etape,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return null;

      final doc = await _firestore
          .collection('brouillons_session')
          .doc('${sessionId}_${user.uid}_$etape')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        print('📖 Brouillon récupéré: $etape');
        return data['donnees'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      print('❌ Erreur récupération brouillon: $e');
      return null;
    }
  }

  /// 🗑️ Supprimer un brouillon (quand finalisé)
  static Future<void> supprimerBrouillon({
    required String sessionId,
    required String etape,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('brouillons_session')
          .doc('${sessionId}_${user.uid}_$etape')
          .delete();

      print('🗑️ Brouillon supprimé: $etape');
    } catch (e) {
      print('❌ Erreur suppression brouillon: $e');
    }
  }

  /// 📋 Lister tous les brouillons d'une session pour un conducteur
  static Future<List<Map<String, dynamic>>> listerBrouillons({
    required String sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final query = await _firestore
          .collection('brouillons_session')
          .where('sessionId', isEqualTo: sessionId)
          .where('conducteurId', isEqualTo: user.uid)
          .orderBy('dateModification', descending: true)
          .get();

      return query.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('❌ Erreur liste brouillons: $e');
      return [];
    }
  }

  /// 🔄 Vérifier si un brouillon existe
  static Future<bool> brouillonExiste({
    required String sessionId,
    required String etape,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final doc = await _firestore
          .collection('brouillons_session')
          .doc('${sessionId}_${user.uid}_$etape')
          .get();

      return doc.exists;
    } catch (e) {
      print('❌ Erreur vérification brouillon: $e');
      return false;
    }
  }

  /// 📊 Obtenir le statut de progression d'un conducteur
  static Future<Map<String, dynamic>> obtenirProgressionConducteur({
    required String sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final brouillons = await listerBrouillons(sessionId: sessionId);
      
      final progression = <String, dynamic>{};
      for (final brouillon in brouillons) {
        progression[brouillon['etape']] = {
          'statut': brouillon['statut'],
          'dateModification': brouillon['dateModification'],
          'pourcentage': _calculerPourcentageEtape(brouillon['donnees']),
        };
      }

      return progression;
    } catch (e) {
      print('❌ Erreur progression conducteur: $e');
      return {};
    }
  }

  /// 📈 Calculer le pourcentage de completion d'une étape
  static double _calculerPourcentageEtape(Map<String, dynamic> donnees) {
    if (donnees.isEmpty) return 0.0;

    int champsRemplis = 0;
    int totalChamps = 0;

    donnees.forEach((key, value) {
      totalChamps++;
      if (value != null && value.toString().isNotEmpty) {
        champsRemplis++;
      }
    });

    return totalChamps > 0 ? (champsRemplis / totalChamps) * 100 : 0.0;
  }

  /// 🎯 Sauvegarder automatiquement avec debounce
  static Timer? _debounceTimer;

  static void sauvegarderAvecDebounce({
    required String sessionId,
    required String etape,
    required Map<String, dynamic> donnees,
    Duration delai = const Duration(seconds: 2),
  }) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delai, () {
      sauvegarderBrouillon(
        sessionId: sessionId,
        etape: etape,
        donnees: donnees,
      );
    });
  }
}
