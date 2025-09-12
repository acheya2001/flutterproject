import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// 📊 États possibles d'un formulaire
enum FormStatus {
  enAttente,    // 🔴 Pas encore rempli
  enCours,      // 🟡 Commencé mais non fini
  termine,      // 🟢 Validé par le conducteur
}

/// 📋 Informations sur l'état d'un formulaire
class FormStatusInfo {
  final String etape;
  final FormStatus statut;
  final DateTime? dateModification;
  final double pourcentageCompletion;
  final String? sessionId;

  FormStatusInfo({
    required this.etape,
    required this.statut,
    this.dateModification,
    this.pourcentageCompletion = 0.0,
    this.sessionId,
  });

  /// 🎨 Couleur associée au statut
  static Color getCouleurStatut(FormStatus statut) {
    switch (statut) {
      case FormStatus.enAttente:
        return const Color(0xFFE53E3E); // 🔴 Rouge
      case FormStatus.enCours:
        return const Color(0xFFD69E2E); // 🟡 Orange/Jaune
      case FormStatus.termine:
        return const Color(0xFF38A169); // 🟢 Vert
    }
  }

  /// 📝 Texte associé au statut
  static String getTexteStatut(FormStatus statut) {
    switch (statut) {
      case FormStatus.enAttente:
        return 'En attente';
      case FormStatus.enCours:
        return 'En cours';
      case FormStatus.termine:
        return 'Terminé';
    }
  }

  /// 🎯 Icône associée au statut
  static IconData getIconeStatut(FormStatus statut) {
    switch (statut) {
      case FormStatus.enAttente:
        return Icons.pending_outlined;
      case FormStatus.enCours:
        return Icons.edit_outlined;
      case FormStatus.termine:
        return Icons.check_circle_outline;
    }
  }
}

/// 🛠️ Service de gestion des états des formulaires
class FormStatusService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 📊 Obtenir l'état de tous les formulaires d'une session
  static Future<List<FormStatusInfo>> obtenirEtatsFormulaires({
    required String sessionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return [];

      final List<FormStatusInfo> etatsFormulaires = [];

      // Récupérer tous les brouillons de cette session pour cet utilisateur
      final brouillonsQuery = await _firestore
          .collection('brouillons_session')
          .where('sessionId', isEqualTo: sessionId)
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      // Récupérer tous les formulaires finalisés de cette session pour cet utilisateur
      final finalisesQuery = await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('formulaires_finalises')
          .where('conducteurId', isEqualTo: user.uid)
          .get();

      // Créer un map des étapes trouvées
      final Map<String, FormStatusInfo> etapesMap = {};

      // Traiter les brouillons
      for (final doc in brouillonsQuery.docs) {
        final data = doc.data();
        final etape = data['etape'] as String;
        final dateModification = (data['dateModification'] as Timestamp?)?.toDate();

        // Calculer le pourcentage de completion
        final donnees = data['donnees'] as Map<String, dynamic>?;
        final pourcentage = donnees != null ? _calculerPourcentageCompletion(donnees) : 0.0;

        etapesMap[etape] = FormStatusInfo(
          etape: etape,
          statut: FormStatus.enCours,
          dateModification: dateModification,
          pourcentageCompletion: pourcentage,
          sessionId: sessionId,
        );
      }

      // Traiter les formulaires finalisés (ils remplacent les brouillons s'ils existent)
      for (final doc in finalisesQuery.docs) {
        final data = doc.data();
        final etape = data['etape'] as String;
        final dateModification = (data['dateModification'] as Timestamp?)?.toDate();

        etapesMap[etape] = FormStatusInfo(
          etape: etape,
          statut: FormStatus.termine,
          dateModification: dateModification,
          pourcentageCompletion: 100.0,
          sessionId: sessionId,
        );
      }

      // Convertir le map en liste
      etatsFormulaires.addAll(etapesMap.values);

      // Trier par ordre logique des étapes
      final ordreEtapes = [
        'formulaire_general',
        'circonstances',
        'croquis',
        'signatures',
      ];

      etatsFormulaires.sort((a, b) {
        final indexA = ordreEtapes.indexOf(a.etape);
        final indexB = ordreEtapes.indexOf(b.etape);
        return indexA.compareTo(indexB);
      });

      return etatsFormulaires;
    } catch (e) {
      print('❌ Erreur obtention états formulaires: $e');
      return [];
    }
  }

  /// 📈 Calculer le pourcentage de completion d'un formulaire
  static double _calculerPourcentageCompletion(Map<String, dynamic> donnees) {
    if (donnees.isEmpty) return 0.0;

    int champsRemplis = 0;
    int totalChamps = 0;

    donnees.forEach((key, value) {
      totalChamps++;
      if (value != null && value.toString().isNotEmpty) {
        if (value is List && value.isNotEmpty) {
          champsRemplis++;
        } else if (value is! List) {
          champsRemplis++;
        }
      }
    });

    return totalChamps > 0 ? (champsRemplis / totalChamps) * 100 : 0.0;
  }

  /// ✅ Marquer un formulaire comme terminé
  static Future<void> marquerCommeTermine({
    required String sessionId,
    required String etape,
    required Map<String, dynamic> donneesFinales,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Sauvegarder la version finalisée
      await _firestore
          .collection('sessions_collaboratives')
          .doc(sessionId)
          .collection('formulaires_finalises')
          .doc('${user.uid}_$etape')
          .set({
        'sessionId': sessionId,
        'conducteurId': user.uid,
        'etape': etape,
        'donnees': donneesFinales,
        'dateModification': DateTime.now().toIso8601String(),
        'statut': 'termine',
      });

      // Supprimer le brouillon
      await _firestore
          .collection('brouillons_session')
          .doc('${sessionId}_${user.uid}_$etape')
          .delete();

      print('✅ Formulaire marqué comme terminé: $etape');
    } catch (e) {
      print('❌ Erreur marquer comme terminé: $e');
    }
  }

  /// 📊 Obtenir les statistiques globales d'une session
  static Future<Map<String, dynamic>> obtenirStatistiquesSession({
    required String sessionId,
  }) async {
    try {
      final etats = await obtenirEtatsFormulaires(sessionId: sessionId);
      
      final int total = etats.length;
      final int termines = etats.where((e) => e.statut == FormStatus.termine).length;
      final int enCours = etats.where((e) => e.statut == FormStatus.enCours).length;
      final int enAttente = etats.where((e) => e.statut == FormStatus.enAttente).length;
      
      final double progressionGlobale = total > 0 ? (termines / total) * 100 : 0.0;

      return {
        'total': total,
        'termines': termines,
        'enCours': enCours,
        'enAttente': enAttente,
        'progressionGlobale': progressionGlobale,
        'etats': etats,
      };
    } catch (e) {
      print('❌ Erreur statistiques session: $e');
      return {};
    }
  }

  /// 🎨 Obtenir le nom d'affichage d'une étape
  static String getNomEtape(String etape) {
    switch (etape) {
      case 'formulaire_general':
        return 'Informations Générales';
      case 'circonstances':
        return 'Circonstances';
      case 'croquis':
        return 'Croquis';
      case 'signatures':
        return 'Signatures';
      default:
        return etape;
    }
  }
}


