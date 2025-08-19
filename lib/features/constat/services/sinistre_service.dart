import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/sinistre_model.dart';
import '../models/participant_model.dart';

/// 🚨 Service de gestion des sinistres collaboratifs
class SinistreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static const Uuid _uuid = Uuid();

  /// Créer un nouveau sinistre
  static Future<String> createSinistre({
    required SinistreLocation location,
    required DateTime dateAccident,
    required List<SinistreVehicleRef> vehicles,
    String? description,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final sinistreId = _uuid.v4();
    final now = DateTime.now();

    // Détecter automatiquement les contrats et agences
    final contracts = await _detectContracts(vehicles);
    final agencyId = contracts.isNotEmpty ? contracts.first.agencyId : null;
    final companyId = contracts.isNotEmpty ? contracts.first.companyId : null;

    final sinistre = SinistreModel(
      id: sinistreId,
      createdBy: user.uid,
      createdAt: now,
      status: SinistreStatus.draft,
      location: location,
      dateAccident: dateAccident,
      mode: 'collaboratif',
      ownerConducteurUid: user.uid,
      vehicles: vehicles,
      contracts: contracts,
      agencyId: agencyId,
      companyId: companyId,
      witnesses: [],
      attachments: [],
      invites: [],
      lastUpdatedBy: user.uid,
      lastUpdatedAt: now,
      description: description,
    );

    // Sauvegarder le sinistre
    await _firestore.collection('sinistres').doc(sinistreId).set(sinistre.toMap());

    // Créer le participant principal (initiateur)
    await _createMainParticipant(sinistreId, user.uid, vehicles.first);

    // Log d'audit
    await _logAudit(
      action: 'sinistre_created',
      actorUid: user.uid,
      targetId: sinistreId,
      data: {'location': location.address, 'vehiclesCount': vehicles.length},
    );

    return sinistreId;
  }

  /// Ajouter un participant par invitation
  static Future<String> addParticipant({
    required String sinistreId,
    required String emailOrPhone,
    required RoleInAccident role,
    SinistreVehicleRef? vehicleRef,
    bool isOwner = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    // Générer token d'invitation
    final inviteToken = _generateInviteToken();
    final inviteId = _uuid.v4();
    final participantId = _uuid.v4();
    final expiresAt = DateTime.now().add(const Duration(hours: 72));

    // Créer l'invitation
    final invite = SinistreInvite(
      inviteId: inviteId,
      emailOrPhone: emailOrPhone,
      token: inviteToken,
      expiresAt: expiresAt,
      status: 'pending',
    );

    // Créer le participant
    final participant = ParticipantModel(
      participantId: participantId,
      uid: null, // Sera rempli quand l'utilisateur accepte
      name: '', // Sera rempli par l'invité
      email: emailOrPhone.contains('@') ? emailOrPhone : '',
      phone: !emailOrPhone.contains('@') ? emailOrPhone : '',
      roleInAccident: role,
      vehicleRef: vehicleRef != null ? ParticipantVehicleRef.fromMap(vehicleRef.toMap()) : null,
      isOwner: isOwner,
      status: ParticipantStatus.notStarted,
      filledFields: {},
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      lastUpdatedBy: user.uid,
    );

    // Batch write pour atomicité
    final batch = _firestore.batch();

    // Ajouter l'invitation au sinistre
    final sinistreRef = _firestore.collection('sinistres').doc(sinistreId);
    batch.update(sinistreRef, {
      'invites': FieldValue.arrayUnion([invite.toMap()]),
      'lastUpdatedBy': user.uid,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Créer le participant
    final participantRef = _firestore
        .collection('sinistres')
        .doc(sinistreId)
        .collection('participants')
        .doc(participantId);
    batch.set(participantRef, participant.toMap());

    await batch.commit();

    // Envoyer l'invitation (email/SMS)
    await _sendInvitation(sinistreId, inviteToken, emailOrPhone);

    // Log d'audit
    await _logAudit(
      action: 'participant_invited',
      actorUid: user.uid,
      targetId: sinistreId,
      data: {'participantId': participantId, 'emailOrPhone': emailOrPhone, 'role': role.value},
    );

    return participantId;
  }

  /// Accepter une invitation
  static Future<void> acceptInvitation({
    required String sinistreId,
    required String inviteToken,
    required String name,
    String? cin,
  }) async {
    final user = _auth.currentUser;

    // Vérifier le token
    final sinistreDoc = await _firestore.collection('sinistres').doc(sinistreId).get();
    if (!sinistreDoc.exists) throw Exception('Sinistre introuvable');

    final sinistre = SinistreModel.fromMap(sinistreDoc.data()!);
    final invite = sinistre.invites.firstWhere(
      (inv) => inv.token == inviteToken && inv.status == 'pending',
      orElse: () => throw Exception('Invitation invalide ou expirée'),
    );

    if (invite.expiresAt.isBefore(DateTime.now())) {
      throw Exception('Invitation expirée');
    }

    // Trouver le participant correspondant
    final participantsQuery = await _firestore
        .collection('sinistres')
        .doc(sinistreId)
        .collection('participants')
        .where('email', isEqualTo: invite.emailOrPhone)
        .get();

    if (participantsQuery.docs.isEmpty) {
      throw Exception('Participant introuvable');
    }

    final participantDoc = participantsQuery.docs.first;
    final participant = ParticipantModel.fromMap(participantDoc.data());

    // Mettre à jour le participant
    final updatedParticipant = participant.copyWith(
      uid: user?.uid,
      name: name,
      cin: cin,
      status: ParticipantStatus.inProgress,
      lastUpdatedAt: DateTime.now(),
      lastUpdatedBy: user?.uid ?? 'anonymous',
    );

    // Mettre à jour l'invitation
    final updatedInvites = sinistre.invites.map((inv) {
      if (inv.inviteId == invite.inviteId) {
        return SinistreInvite(
          inviteId: inv.inviteId,
          emailOrPhone: inv.emailOrPhone,
          token: inv.token,
          expiresAt: inv.expiresAt,
          status: 'accepted',
        );
      }
      return inv;
    }).toList();

    // Batch update
    final batch = _firestore.batch();

    batch.update(_firestore.collection('sinistres').doc(sinistreId), {
      'invites': updatedInvites.map((inv) => inv.toMap()).toList(),
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    batch.update(participantDoc.reference, updatedParticipant.toMap());

    await batch.commit();

    // Log d'audit
    await _logAudit(
      action: 'invitation_accepted',
      actorUid: user?.uid ?? 'anonymous',
      targetId: sinistreId,
      data: {'participantId': participant.participantId, 'name': name},
    );
  }

  /// Uploader une pièce jointe
  static Future<String> uploadAttachment({
    required String sinistreId,
    required File file,
    required String type, // image, video, document
    String? participantId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');

    final fileId = _uuid.v4();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final extension = file.path.split('.').last;
    final filename = '${timestamp}_${user.uid}_${fileId}.$extension';

    // Déterminer le path de stockage
    final sinistre = await getSinistre(sinistreId);
    final companyId = sinistre.companyId ?? 'unknown';
    final agencyId = sinistre.agencyId ?? 'unknown';

    final storagePath = 'companies/$companyId/agencies/$agencyId/sinistres/$sinistreId/attachments/$filename';

    // Upload vers Firebase Storage
    final ref = _storage.ref().child(storagePath);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Créer l'objet attachment
    final attachment = SinistreAttachment(
      id: fileId,
      storagePath: storagePath,
      type: type,
      uploadedBy: user.uid,
      uploadedAt: DateTime.now(),
      thumbUrl: type == 'image' ? downloadUrl : null, // TODO: Générer thumbnail
      filename: file.path.split('/').last,
      size: await file.length(),
      mimeType: _getMimeType(extension),
    );

    // Ajouter à la liste des attachments du sinistre
    await _firestore.collection('sinistres').doc(sinistreId).update({
      'attachments': FieldValue.arrayUnion([attachment.toMap()]),
      'lastUpdatedBy': user.uid,
      'lastUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Log d'audit
    await _logAudit(
      action: 'attachment_uploaded',
      actorUid: user.uid,
      targetId: sinistreId,
      data: {'attachmentId': fileId, 'type': type, 'filename': attachment.filename},
    );

    return fileId;
  }

  /// Récupérer un sinistre
  static Future<SinistreModel> getSinistre(String sinistreId) async {
    final doc = await _firestore.collection('sinistres').doc(sinistreId).get();
    if (!doc.exists) throw Exception('Sinistre introuvable');
    return SinistreModel.fromMap(doc.data()!);
  }

  /// Stream des participants d'un sinistre (temps réel)
  static Stream<List<ParticipantModel>> getParticipantsStream(String sinistreId) {
    return _firestore
        .collection('sinistres')
        .doc(sinistreId)
        .collection('participants')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ParticipantModel.fromMap(doc.data()))
            .toList());
  }

  /// Méthodes privées
  static Future<List<SinistreContractRef>> _detectContracts(List<SinistreVehicleRef> vehicles) async {
    // TODO: Implémenter la détection automatique des contrats
    // Pour l'instant, retourner une liste vide
    return [];
  }

  static Future<void> _createMainParticipant(String sinistreId, String uid, SinistreVehicleRef vehicle) async {
    final user = _auth.currentUser!;
    final participantId = _uuid.v4();

    final participant = ParticipantModel(
      participantId: participantId,
      uid: uid,
      name: user.displayName ?? '',
      email: user.email ?? '',
      phone: '', // TODO: Récupérer depuis le profil utilisateur
      roleInAccident: RoleInAccident.conducteur,
      vehicleRef: ParticipantVehicleRef.fromMap(vehicle.toMap()),
      isOwner: vehicle.isOwnerBoolean,
      status: ParticipantStatus.inProgress,
      filledFields: {},
      createdAt: DateTime.now(),
      lastUpdatedAt: DateTime.now(),
      lastUpdatedBy: uid,
    );

    await _firestore
        .collection('sinistres')
        .doc(sinistreId)
        .collection('participants')
        .doc(participantId)
        .set(participant.toMap());
  }

  static String _generateInviteToken() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        8, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  static Future<void> _sendInvitation(String sinistreId, String token, String emailOrPhone) async {
    // TODO: Implémenter l'envoi d'email/SMS via Cloud Functions
    print('Invitation envoyée à $emailOrPhone avec token: $token');
    print('Lien: https://app/constat/$sinistreId?invite=$token');
  }

  static String _getMimeType(String extension) {
    switch (extension.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<void> _logAudit({
    required String action,
    required String actorUid,
    required String targetId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore.collection('audit_logs').add({
      'action': action,
      'actorUid': actorUid,
      'targetId': targetId,
      'data': data,
      'timestamp': FieldValue.serverTimestamp(),
      'ip': null, // TODO: Récupérer l'IP si nécessaire
    });
  }
}
