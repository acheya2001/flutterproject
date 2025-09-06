import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/collaborative_sketch_model.dart';

/// 🎨 Service de gestion du croquis collaboratif
class CollaborativeSketchService {
  static final CollaborativeSketchService _instance = CollaborativeSketchService._internal();
  factory CollaborativeSketchService() => _instance;
  CollaborativeSketchService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Couleurs assignées aux conducteurs
  static const List<String> _availableColors = [
    '#2196F3', // Bleu
    '#F44336', // Rouge
    '#4CAF50', // Vert
    '#FF9800', // Orange
    '#9C27B0', // Violet
    '#607D8B', // Bleu gris
    '#795548', // Marron
    '#E91E63', // Rose
  ];

  /// 🎨 Créer un nouveau croquis collaboratif
  Future<String> createCollaborativeSketch({
    required String sessionId,
    required String creatorId,
    required String creatorName,
    required SketchMode mode,
  }) async {
    try {
      // Utiliser le sessionId comme ID du document pour faciliter la recherche
      final sketch = CollaborativeSketch(
        id: sessionId,
        sessionId: sessionId,
        creatorId: creatorId,
        creatorName: creatorName,
        elements: [],
        signatures: {},
        isLocked: false,
        createdAt: DateTime.now(),
        mode: mode,
        conducteurColors: {creatorId: _availableColors[0]}, // Première couleur pour le créateur
      );

      await _firestore
          .collection('collaborative_sketches')
          .doc(sessionId)
          .set(sketch.toFirestore());

      // Créer la participation du créateur
      await _updateConducteurParticipation(
        sketchId: sessionId,
        conducteurId: creatorId,
        conducteurName: creatorName,
        isOnline: true,
        canEdit: true,
      );

      return sessionId;
    } catch (e) {
      throw Exception('Erreur lors de la création du croquis: $e');
    }
  }

  /// 🎨 Créer automatiquement un croquis pour une session d'accident
  Future<String> createSketchForAccidentSession({
    required String sessionCode,
    required String creatorId,
    required String creatorName,
  }) async {
    try {
      // Vérifier si un croquis existe déjà pour cette session
      final existingSketch = await getSketchBySession(sessionCode);
      if (existingSketch != null) {
        return existingSketch.id;
      }

      // Créer un nouveau croquis en mode collaboratif par défaut
      return await createCollaborativeSketch(
        sessionId: sessionCode,
        creatorId: creatorId,
        creatorName: creatorName,
        mode: SketchMode.collaborative,
      );
    } catch (e) {
      throw Exception('Erreur lors de la création du croquis pour la session: $e');
    }
  }

  /// 🎨 Rejoindre un croquis existant
  Future<bool> joinSketch({
    required String sketchId,
    required String conducteurId,
    required String conducteurName,
  }) async {
    try {
      final sketchDoc = await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .get();

      if (!sketchDoc.exists) {
        throw Exception('Croquis introuvable');
      }

      final sketch = CollaborativeSketch.fromFirestore(sketchDoc);
      
      if (sketch.isLocked) {
        throw Exception('Le croquis est verrouillé');
      }

      // Assigner une couleur si pas déjà assignée
      String assignedColor = sketch.conducteurColors[conducteurId] ?? 
          _getNextAvailableColor(sketch.conducteurColors.values.toList());

      // Mettre à jour les couleurs dans le croquis
      final updatedColors = Map<String, String>.from(sketch.conducteurColors);
      updatedColors[conducteurId] = assignedColor;

      await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .update({'conducteurColors': updatedColors});

      // Créer/mettre à jour la participation
      await _updateConducteurParticipation(
        sketchId: sketchId,
        conducteurId: conducteurId,
        conducteurName: conducteurName,
        isOnline: true,
        canEdit: sketch.mode == SketchMode.collaborative || conducteurId == sketch.creatorId,
      );

      return true;
    } catch (e) {
      throw Exception('Erreur lors de la connexion au croquis: $e');
    }
  }

  /// 🎨 Obtenir un croquis par session
  Future<CollaborativeSketch?> getSketchBySession(String sessionId) async {
    try {
      final doc = await _firestore
          .collection('collaborative_sketches')
          .doc(sessionId)
          .get();

      if (!doc.exists) {
        return null;
      }

      return CollaborativeSketch.fromFirestore(doc);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du croquis: $e');
    }
  }

  /// 🎨 Stream du croquis en temps réel
  Stream<CollaborativeSketch?> watchSketch(String sketchId) {
    return _firestore
        .collection('collaborative_sketches')
        .doc(sketchId)
        .snapshots()
        .map((doc) => doc.exists ? CollaborativeSketch.fromFirestore(doc) : null);
  }

  /// 🎨 Stream des participants en temps réel
  Stream<List<ConducteurParticipation>> watchParticipants(String sketchId) {
    return _firestore
        .collection('collaborative_sketches')
        .doc(sketchId)
        .collection('participants')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ConducteurParticipation.fromMap(doc.data()))
            .toList());
  }

  /// 🎨 Ajouter un élément au croquis
  Future<void> addElement({
    required String sketchId,
    required SketchElementData element,
  }) async {
    try {
      await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .update({
        'elements': FieldValue.arrayUnion([element.toMap()])
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'ajout de l\'élément: $e');
    }
  }

  /// 🎨 Supprimer un élément du croquis
  Future<void> removeElement({
    required String sketchId,
    required String elementId,
  }) async {
    try {
      final sketchDoc = await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .get();

      if (!sketchDoc.exists) return;

      final sketch = CollaborativeSketch.fromFirestore(sketchDoc);
      final updatedElements = sketch.elements
          .where((element) => element.id != elementId)
          .map((element) => element.toMap())
          .toList();

      await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .update({'elements': updatedElements});
    } catch (e) {
      throw Exception('Erreur lors de la suppression de l\'élément: $e');
    }
  }

  /// ✍️ Signer le croquis
  Future<void> signSketch({
    required String sketchId,
    required String conducteurId,
    required String conducteurName,
    required bool isAgreed,
    String? disagreementReason,
  }) async {
    try {
      final signature = ConducteurSignature(
        conducteurId: conducteurId,
        conducteurName: conducteurName,
        isAgreed: isAgreed,
        disagreementReason: disagreementReason,
        signedAt: DateTime.now(),
      );

      await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .update({
        'signatures.$conducteurId': signature.toMap(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la signature: $e');
    }
  }

  /// 🔒 Verrouiller le croquis
  Future<void> lockSketch(String sketchId) async {
    try {
      await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .update({
        'isLocked': true,
        'lockedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      throw Exception('Erreur lors du verrouillage: $e');
    }
  }

  /// 👥 Mettre à jour la participation d'un conducteur
  Future<void> _updateConducteurParticipation({
    required String sketchId,
    required String conducteurId,
    required String conducteurName,
    required bool isOnline,
    required bool canEdit,
  }) async {
    final participation = ConducteurParticipation(
      conducteurId: conducteurId,
      conducteurName: conducteurName,
      assignedColor: '#2196F3', // Sera mis à jour avec la vraie couleur
      isOnline: isOnline,
      lastSeen: DateTime.now(),
      canEdit: canEdit,
    );

    await _firestore
        .collection('collaborative_sketches')
        .doc(sketchId)
        .collection('participants')
        .doc(conducteurId)
        .set(participation.toMap());
  }

  /// 🎨 Obtenir la prochaine couleur disponible
  String _getNextAvailableColor(List<String> usedColors) {
    for (final color in _availableColors) {
      if (!usedColors.contains(color)) {
        return color;
      }
    }
    // Si toutes les couleurs sont utilisées, retourner une couleur aléatoire
    return _availableColors[usedColors.length % _availableColors.length];
  }

  /// 🚪 Quitter le croquis
  Future<void> leaveSketch({
    required String sketchId,
    required String conducteurId,
  }) async {
    try {
      await _firestore
          .collection('collaborative_sketches')
          .doc(sketchId)
          .collection('participants')
          .doc(conducteurId)
          .update({
        'isOnline': false,
        'lastSeen': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Ignorer les erreurs lors de la déconnexion
    }
  }
}
