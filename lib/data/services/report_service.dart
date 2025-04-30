// lib/data/services/report_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/report_model.dart';
import '../models/accident_report_model.dart';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final Logger _logger = Logger();
  final Uuid _uuid = Uuid();

  // Collection reference
  CollectionReference get _constatsCollection => _firestore.collection('constats');

  // Générer un numéro de constat unique
  Future<String> _generateReportNumber() async {
    final now = DateTime.now();
    final year = now.year.toString();
    final month = now.month.toString().padLeft(2, '0');
    
    // Compter le nombre de constats pour ce mois
    final snapshot = await _constatsCollection
        .where('numero', isGreaterThanOrEqualTo: '$year$month')
        .where('numero', isLessThan: '$year${(now.month + 1).toString().padLeft(2, '0')}')
        .get();
    
    final count = snapshot.docs.length + 1;
    return '$year$month${count.toString().padLeft(4, '0')}';
  }

  // Créer un nouveau constat
  Future<String> createReport(AccidentReport report) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Générer un numéro de constat unique
      final reportNumber = await _generateReportNumber();
      
      // Créer le document du constat
      final docRef = await _constatsCollection.add({
        ...report.toFirestore(),
        'numero': reportNumber,
        'createdBy': user.uid,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });
      
      return docRef.id;
    } catch (e) {
      _logger.e('Erreur lors de la création du constat: $e');
      rethrow;
    }
  }

  // Obtenir un constat par son ID
  Future<AccidentReport?> getReportById(String reportId) async {
    try {
      final doc = await _constatsCollection.doc(reportId).get();
      if (doc.exists) {
        return AccidentReport.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du constat: $e');
      rethrow;
    }
  }

  // Obtenir les constats d'un conducteur
  Future<List<AccidentReport>> getUserReports(String userId) async {
    try {
      // Constats où l'utilisateur est impliqué dans la partie A
      final snapshotA = await _constatsCollection
          .where('partyA.userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      
      // Constats où l'utilisateur est impliqué dans la partie B
      final snapshotB = await _constatsCollection
          .where('partyB.userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      
      // Combiner les résultats (en évitant les doublons)
      final Set<String> uniqueIds = {};
      final List<AccidentReport> result = [];
      
      for (var doc in [...snapshotA.docs, ...snapshotB.docs]) {
        if (!uniqueIds.contains(doc.id)) {
          uniqueIds.add(doc.id);
          result.add(AccidentReport.fromFirestore(doc));
        }
      }
      
      // Trier par date (plus récent en premier)
      result.sort((a, b) => b.date.compareTo(a.date));
      
      return result;
    } catch (e) {
      _logger.e('Erreur lors de la récupération des constats: $e');
      rethrow;
    }
  }

  // Mettre à jour un constat
  Future<void> updateReport(String reportId, AccidentReport report) async {
    try {
      await _constatsCollection.doc(reportId).update({
        ...report.toFirestore(),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du constat: $e');
      rethrow;
    }
  }

  // Mettre à jour partiellement un constat
  Future<void> updateReportFields(String reportId, Map<String, dynamic> data) async {
    try {
      await _constatsCollection.doc(reportId).update({
        ...data,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la mise à jour du constat: $e');
      rethrow;
    }
  }

  // Uploader une image (signature, croquis, photo de dommage)
  Future<String> uploadImage(File imageFile, String reportId, String type) async {
    try {
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('reports/$reportId/$type/$fileName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _logger.e('Erreur lors de l\'upload de l\'image: $e');
      rethrow;
    }
  }

  // Télécharger une photo de dommage
  Future<String> uploadDamagePhoto(String reportId, String party, File photo) async {
    try {
      final downloadUrl = await uploadImage(photo, reportId, 'damages');
      
      // Mettre à jour le document du constat avec la nouvelle photo
      await _constatsCollection.doc(reportId).update({
        'party$party.damagePhotoUrls': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': Timestamp.now(),
      });
      
      return downloadUrl;
    } catch (e) {
      _logger.e('Erreur lors du téléchargement de la photo de dommage: $e');
      rethrow;
    }
  }

  // Télécharger une signature
  Future<String> uploadSignature(String reportId, String party, File signature) async {
    try {
      final downloadUrl = await uploadImage(signature, reportId, 'signatures');
      
      // Mettre à jour le document du constat avec la nouvelle signature
      final field = party == 'A' ? 'signatureAUrl' : 'signatureBUrl';
      await _constatsCollection.doc(reportId).update({
        field: downloadUrl,
        'updatedAt': Timestamp.now(),
      });
      
      return downloadUrl;
    } catch (e) {
      _logger.e('Erreur lors du téléchargement de la signature: $e');
      rethrow;
    }
  }

  // Télécharger un croquis
  Future<String> uploadSketch(String reportId, File sketch, Map<String, dynamic> sketchData) async {
    try {
      final downloadUrl = await uploadImage(sketch, reportId, 'sketches');
      
      // Mettre à jour le document du constat avec le nouveau croquis
      await _constatsCollection.doc(reportId).update({
        'sketchImageUrl': downloadUrl,
        'sketchData': sketchData,
        'updatedAt': Timestamp.now(),
      });
      
      return downloadUrl;
    } catch (e) {
      _logger.e('Erreur lors du téléchargement du croquis: $e');
      rethrow;
    }
  }

  // Générer un code d'invitation
  String generateInvitationCode() {
    return _uuid.v4().substring(0, 8).toUpperCase();
  }
  
  // Obtenir un constat par code d'invitation
  Future<AccidentReport?> getReportByInvitationCode(String code) async {
    try {
      final snapshot = await _constatsCollection
          .where('invitationCode', isEqualTo: code)
          .limit(1)
          .get();
      
      if (snapshot.docs.isNotEmpty) {
        return AccidentReport.fromFirestore(snapshot.docs.first);
      }
      return null;
    } catch (e) {
      _logger.e('Erreur lors de la récupération du constat par code: $e');
      rethrow;
    }
  }

  // Rejoindre un constat existant (partie B)
  Future<void> joinReport(String reportId, PartyInformation partyB) async {
    try {
      await _constatsCollection.doc(reportId).update({
        'partyB': partyB.toMap(),
        'status': ReportStatus.completed.index,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors de la jonction au constat: $e');
      rethrow;
    }
  }

  // Changer le statut d'un constat
  Future<void> changeReportStatus(String reportId, ReportStatus status, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }
      
      // Créer l'objet d'historique
      final historyEntry = {
        'status': status.index,
        'timestamp': Timestamp.now(),
        'comment': comment,
        'userId': user.uid,
      };
      
      // Mettre à jour le document du constat
      await _constatsCollection.doc(reportId).update({
        'status': status.index,
        'statusHistory': FieldValue.arrayUnion([historyEntry]),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      _logger.e('Erreur lors du changement de statut du constat: $e');
      rethrow;
    }
  }

  // Soumettre le constat à l'assurance
  Future<void> submitToInsurance(String reportId) async {
    try {
      await changeReportStatus(
        reportId, 
        ReportStatus.submittedToInsurance, 
        'Constat soumis à l\'assurance'
      );
    } catch (e) {
      _logger.e('Erreur lors de la soumission à l\'assurance: $e');
      rethrow;
    }
  }

  // Assigner un expert à un constat
  Future<void> assignExpert(String reportId, String expertId, String expertName) async {
    try {
      await _constatsCollection.doc(reportId).update({
        'expertId': expertId,
        'expertName': expertName,
        'status': ReportStatus.processingByInsurance.index,
        'updatedAt': Timestamp.now(),
      });
      
      await changeReportStatus(
        reportId, 
        ReportStatus.processingByInsurance, 
        'Expert assigné: $expertName'
      );
    } catch (e) {
      _logger.e('Erreur lors de l\'assignation de l\'expert: $e');
      rethrow;
    }
  }

  // Ajouter un rapport d'expertise
  Future<void> addExpertReport(String reportId, Map<String, dynamic> expertReport) async {
    try {
      await _constatsCollection.doc(reportId).update({
        'expertReport': expertReport,
        'updatedAt': Timestamp.now(),
      });
      
      await changeReportStatus(
        reportId, 
        ReportStatus.closed, 
        'Rapport d\'expertise ajouté'
      );
    } catch (e) {
      _logger.e('Erreur lors de l\'ajout du rapport d\'expertise: $e');
      rethrow;
    }
  }

  // Supprimer un constat (réservé aux administrateurs)
  Future<void> deleteReport(String reportId) async {
    try {
      // Supprimer les fichiers associés dans Storage
      final storageRef = _storage.ref().child('reports/$reportId');
      try {
        final listResult = await storageRef.listAll();
        for (var item in listResult.items) {
          await item.delete();
        }
        for (var prefix in listResult.prefixes) {
          final subList = await prefix.listAll();
          for (var item in subList.items) {
            await item.delete();
          }
        }
      } catch (e) {
        _logger.w('Erreur lors de la suppression des fichiers: $e');
        // Continuer malgré l'erreur
      }
      
      // Supprimer le document Firestore
      await _constatsCollection.doc(reportId).delete();
    } catch (e) {
      _logger.e('Erreur lors de la suppression du constat: $e');
      rethrow;
    }
  }
  
  // Obtenir les statistiques des constats pour un utilisateur
  Future<Map<String, dynamic>> getUserReportStats(String userId) async {
    try {
      final reports = await getUserReports(userId);
      
      // Initialiser les compteurs
      int total = reports.length;
      int pending = 0;
      int completed = 0;
      int processing = 0;
      int closed = 0;
      
      // Compter par statut
      for (var report in reports) {
        switch (report.status) {
          case ReportStatus.draft:
          case ReportStatus.pendingPartyB:
            pending++;
            break;
          case ReportStatus.completed:
            completed++;
            break;
          case ReportStatus.submittedToInsurance:
          case ReportStatus.processingByInsurance:
            processing++;
            break;
          case ReportStatus.closed:
            closed++;
            break;
        }
      }
      
      return {
        'total': total,
        'pending': pending,
        'completed': completed,
        'processing': processing,
        'closed': closed,
      };
    } catch (e) {
      _logger.e('Erreur lors de la récupération des statistiques: $e');
      rethrow;
    }
  }
}