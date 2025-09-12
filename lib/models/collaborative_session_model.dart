import 'package:cloud_firestore/cloud_firestore.dart';

/// 🎯 Modèle étendu pour sessions collaboratives multi-conducteurs
class CollaborativeSession {
  final String id;
  final String codeSession;
  final String qrCodeData;
  final String typeAccident;
  final int nombreVehicules;
  final SessionStatus statut;
  final String conducteurCreateur;
  final List<SessionParticipant> participants;
  final SessionProgress progression;
  final SessionSettings parametres;
  final DateTime dateCreation;
  final DateTime? dateModification;
  final DateTime? dateFinalisation;

  CollaborativeSession({
    required this.id,
    required this.codeSession,
    required this.qrCodeData,
    required this.typeAccident,
    required this.nombreVehicules,
    required this.statut,
    required this.conducteurCreateur,
    required this.participants,
    required this.progression,
    required this.parametres,
    required this.dateCreation,
    this.dateModification,
    this.dateFinalisation,
  });

  // Getter pour compatibilité
  String get code => codeSession;
  String? get createurId => conducteurCreateur;

  Map<String, dynamic> toMap() {
    return {
      'codeSession': codeSession,
      'qrCodeData': qrCodeData,
      'typeAccident': typeAccident,
      'nombreVehicules': nombreVehicules,
      'statut': statut.name,
      'conducteurCreateur': conducteurCreateur,
      'participants': participants.map((p) => p.toMap()).toList(),
      'progression': progression.toMap(),
      'parametres': parametres.toMap(),
      'dateCreation': Timestamp.fromDate(dateCreation),
      'dateModification': dateModification != null ? Timestamp.fromDate(dateModification!) : null,
      'dateFinalisation': dateFinalisation != null ? Timestamp.fromDate(dateFinalisation!) : null,
    };
  }

  factory CollaborativeSession.fromMap(Map<String, dynamic> map, String id) {
    return CollaborativeSession(
      id: id,
      codeSession: map['codeSession'] ?? '',
      qrCodeData: map['qrCodeData'] ?? '',
      typeAccident: map['typeAccident'] ?? '',
      nombreVehicules: map['nombreVehicules'] ?? 2,
      statut: SessionStatus.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => SessionStatus.creation,
      ),
      conducteurCreateur: map['conducteurCreateur'] ?? '',
      participants: (map['participants'] as List<dynamic>?)
          ?.map((p) => SessionParticipant.fromMap(p))
          .toList() ?? [],
      progression: SessionProgress.fromMap(map['progression'] ?? {}),
      parametres: SessionSettings.fromMap(map['parametres'] ?? {}),
      dateCreation: _parseDateTime(map['dateCreation']) ?? DateTime.now(),
      dateModification: _parseDateTime(map['dateModification']),
      dateFinalisation: _parseDateTime(map['dateFinalisation']),
    );
  }
}

/// 📊 Statuts de session
enum SessionStatus {
  creation,           // 🟡 Session créée, en attente de participants
  attente_participants, // 🟠 En attente que tous rejoignent
  en_cours,           // 🔵 Formulaires en cours de remplissage
  validation_croquis, // 🟣 Validation du croquis par tous
  pret_signature,     // 🟢 Prêt pour signatures
  signe,             // ✅ Toutes signatures effectuées
  finalise,          // 🏁 Constat finalisé et envoyé
  annule,            // ❌ Session annulée
}

/// 👤 Participant dans une session collaborative
class SessionParticipant {
  final String userId;
  final String nom;
  final String prenom;
  final String email;
  final String telephone;
  final String roleVehicule; // 'A', 'B', 'C', etc.
  final ParticipantType type;
  final ParticipantStatus statut;
  final FormulaireStatus formulaireStatus; // 🆕 État spécifique du formulaire
  final bool estCreateur;
  final DateTime? dateRejoint;
  final DateTime? dateFormulaireFini;
  final DateTime? dateSignature;
  final String? adresse;
  final String? cin;

  // Getter pour compatibilité
  String get id => userId;

  SessionParticipant({
    required this.userId,
    required this.nom,
    required this.prenom,
    required this.email,
    required this.telephone,
    required this.roleVehicule,
    required this.type,
    required this.statut,
    this.formulaireStatus = FormulaireStatus.en_attente, // 🆕 Par défaut en attente
    required this.estCreateur,
    this.dateRejoint,
    this.dateFormulaireFini,
    this.dateSignature,
    this.adresse,
    this.cin,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'telephone': telephone,
      'roleVehicule': roleVehicule,
      'type': type.name,
      'statut': statut.name,
      'formulaireStatus': formulaireStatus.name, // 🆕 État du formulaire
      'estCreateur': estCreateur,
      'dateRejoint': dateRejoint != null ? Timestamp.fromDate(dateRejoint!) : null,
      'dateFormulaireFini': dateFormulaireFini != null ? Timestamp.fromDate(dateFormulaireFini!) : null,
      'dateSignature': dateSignature != null ? Timestamp.fromDate(dateSignature!) : null,
      'adresse': adresse,
      'cin': cin,
    };
  }

  factory SessionParticipant.fromMap(Map<String, dynamic> map) {
    return SessionParticipant(
      userId: map['userId'] ?? '',
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      email: map['email'] ?? '',
      telephone: map['telephone'] ?? '',
      roleVehicule: map['roleVehicule'] ?? '',
      type: ParticipantType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => ParticipantType.inscrit,
      ),
      statut: ParticipantStatus.values.firstWhere(
        (s) => s.name == map['statut'],
        orElse: () => ParticipantStatus.en_attente,
      ),
      formulaireStatus: FormulaireStatus.values.firstWhere( // 🆕 État du formulaire
        (f) => f.name == map['formulaireStatus'],
        orElse: () => FormulaireStatus.en_attente,
      ),
      estCreateur: map['estCreateur'] ?? false,
      dateRejoint: _parseDateTime(map['dateRejoint']),
      dateFormulaireFini: _parseDateTime(map['dateFormulaireFini']),
      dateSignature: _parseDateTime(map['dateSignature']),
      adresse: map['adresse'],
      cin: map['cin'],
    );
  }
}

/// 🏷️ Types de participants
enum ParticipantType {
  inscrit,      // Conducteur déjà inscrit avec véhicule/contrat
  invite_guest, // Invité non-inscrit (formulaire complet)
}

/// 📈 Statuts des participants
enum ParticipantStatus {
  en_attente,        // 🔴 Pas encore rejoint
  rejoint,           // 🟡 A rejoint, formulaire en cours
  formulaire_fini,   // 🟢 Formulaire terminé
  croquis_valide,    // 🟣 Croquis validé
  signe,            // ✅ Signature effectuée
}

/// 📝 États spécifiques du formulaire
enum FormulaireStatus {
  en_attente,        // 🔴 Pas encore commencé
  en_cours,          // 🟡 Partiellement rempli
  termine,           // 🟢 Formulaire complété
}

/// 📊 Progression de la session
class SessionProgress {
  final int participantsRejoints;
  final int formulairesTermines;
  final int croquisValides;
  final int signaturesEffectuees;
  final bool croquisCree;
  final bool peutFinaliser;

  SessionProgress({
    required this.participantsRejoints,
    required this.formulairesTermines,
    required this.croquisValides,
    required this.signaturesEffectuees,
    required this.croquisCree,
    required this.peutFinaliser,
  });

  Map<String, dynamic> toMap() {
    return {
      'participantsRejoints': participantsRejoints,
      'formulairesTermines': formulairesTermines,
      'croquisValides': croquisValides,
      'signaturesEffectuees': signaturesEffectuees,
      'croquisCree': croquisCree,
      'peutFinaliser': peutFinaliser,
    };
  }

  factory SessionProgress.fromMap(Map<String, dynamic> map) {
    return SessionProgress(
      participantsRejoints: map['participantsRejoints'] ?? 0,
      formulairesTermines: map['formulairesTermines'] ?? 0,
      croquisValides: map['croquisValides'] ?? 0,
      signaturesEffectuees: map['signaturesEffectuees'] ?? 0,
      croquisCree: map['croquisCree'] ?? false,
      peutFinaliser: map['peutFinaliser'] ?? false,
    );
  }
}

/// ⚙️ Paramètres de session
class SessionSettings {
  final bool autoValidationCroquis;
  final int timeoutMinutes;
  final bool notificationsActives;
  final bool modeDebug;

  SessionSettings({
    this.autoValidationCroquis = false,
    this.timeoutMinutes = 60,
    this.notificationsActives = true,
    this.modeDebug = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'autoValidationCroquis': autoValidationCroquis,
      'timeoutMinutes': timeoutMinutes,
      'notificationsActives': notificationsActives,
      'modeDebug': modeDebug,
    };
  }

  factory SessionSettings.fromMap(Map<String, dynamic> map) {
    return SessionSettings(
      autoValidationCroquis: map['autoValidationCroquis'] ?? false,
      timeoutMinutes: map['timeoutMinutes'] ?? 60,
      notificationsActives: map['notificationsActives'] ?? true,
      modeDebug: map['modeDebug'] ?? false,
    );
  }
}

/// 🔧 Helper pour parser les dates (String ou Timestamp)
DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;

  if (value is Timestamp) {
    return value.toDate();
  } else if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (e) {
      print('❌ Erreur parsing date string: $value');
      return null;
    }
  }

  return null;
}
