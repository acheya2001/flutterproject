# 🎯 **SCÉNARIO COMPLET : SESSION COLLABORATIVE**

## **📱 FLUX UTILISATEUR DÉTAILLÉ**

### **ÉTAPE 1 : CRÉATION DE SESSION (Conducteur A)**
1. **Conducteur A** déclare un accident
2. **Choisit** "Constat collaboratif"
3. **Saisit** le nombre de véhicules (2-6)
4. **Entre** les emails des autres conducteurs
5. **Système** génère un code unique (ex: `SESS_ABC123`)
6. **Emails** envoyés automatiquement via Gmail API

### **ÉTAPE 2 : RÉCEPTION EMAIL (Conducteur B)**
1. **Reçoit** l'email avec template HTML professionnel
2. **Voit** le code de session mis en évidence
3. **Lit** les instructions étape par étape
4. **Clique** sur "Rejoindre la Session" (optionnel)

### **ÉTAPE 3 : REJOINDRE LA SESSION (Conducteur B)**
1. **Ouvre** l'application Constat Tunisie
2. **Appuie** sur "Rejoindre une session"
3. **Saisit** le code `SESS_ABC123`
4. **Système** valide le code et trouve la session
5. **Attribution** automatique de position (B, C, D...)
6. **Redirection** vers formulaire de constat

### **ÉTAPE 4 : REMPLISSAGE COLLABORATIF**
1. **Formulaire adapté** à sa position de conducteur
2. **Sections** : Infos personnelles, véhicule, assurance, circonstances
3. **Sauvegarde automatique** dans Firestore
4. **Synchronisation** en temps réel avec autres conducteurs
5. **Photos** et documents uploadés

### **ÉTAPE 5 : VALIDATION ET FINALISATION**
1. **Chaque conducteur** valide ses informations
2. **Système** vérifie que toutes les parties sont complètes
3. **Génération** du constat final PDF
4. **Envoi** par email à tous les participants

---

## **🗄️ STRUCTURE FIRESTORE**

### **Collection : `sessions_collaboratives`**
```
sessions_collaboratives/
├── {sessionId}/
│   ├── sessionCode: "SESS_ABC123"
│   ├── dateAccident: Timestamp
│   ├── lieuAccident: "Avenue Habib Bourguiba, Tunis"
│   ├── coordonnees: GeoPoint
│   ├── nombreConducteurs: 2
│   ├── createdBy: "userId_conducteurA"
│   ├── createdAt: Timestamp
│   ├── updatedAt: Timestamp
│   ├── status: "draft" | "in_progress" | "completed"
│   ├── invitationsSent: ["email1@test.com", "email2@test.com"]
│   ├── validationStatus: {"A": true, "B": false}
│   └── conducteurs/
│       ├── A/
│       │   ├── userId: "userId_conducteurA"
│       │   ├── email: "conducteurA@email.com"
│       │   ├── position: "A"
│       │   ├── isInvited: false
│       │   ├── hasJoined: true
│       │   ├── joinedAt: Timestamp
│       │   ├── isCompleted: true
│       │   ├── completedAt: Timestamp
│       │   ├── conducteur: {ConducteurInfoModel}
│       │   ├── vehicule: {VehiculeAccidentModel}
│       │   ├── assurance: {AssuranceInfoModel}
│       │   ├── isProprietaire: true
│       │   ├── proprietaire: {ProprietaireInfo}
│       │   ├── circonstances: ["en stationnement", "..."]
│       │   ├── degatsApparents: ["pare-choc avant", "..."]
│       │   ├── temoins: [{TemoinModel}, ...]
│       │   ├── photosAccident: ["url1", "url2", ...]
│       │   ├── photoPermis: "url"
│       │   ├── photoCarteGrise: "url"
│       │   ├── photoAttestation: "url"
│       │   ├── signature: "url"
│       │   └── observations: "Texte libre"
│       └── B/
│           ├── userId: "userId_conducteurB"
│           ├── email: "conducteurB@email.com"
│           ├── position: "B"
│           ├── isInvited: true
│           ├── hasJoined: true
│           ├── joinedAt: Timestamp
│           └── ... (même structure que A)
```

### **Collection : `session_codes`**
```
session_codes/
├── SESS_ABC123/
│   ├── sessionId: "sessionId_reference"
│   ├── createdAt: Timestamp
│   └── isActive: true
```

### **Collection : `constats_collaboratifs`**
```
constats_collaboratifs/
├── {constatId}/
│   ├── sessionId: "sessionId_reference"
│   ├── dateAccident: Timestamp
│   ├── lieuAccident: "Avenue Habib Bourguiba, Tunis"
│   ├── coordonnees: GeoPoint
│   ├── conducteurs: ["userId_A", "userId_B"]
│   ├── vehicules: ["vehiculeId_A", "vehiculeId_B"]
│   ├── status: "validated"
│   ├── pdfUrl: "url_du_constat_final"
│   ├── createdAt: Timestamp
│   └── validatedAt: Timestamp
```

---

## **🔄 FLUX DE DONNÉES**

### **1. Création de Session**
```dart
// 1. Créer session dans Firestore
final sessionId = await FirestoreSessionService.creerSessionCollaborative(session);

// 2. Envoyer invitations par email
for (String email in emails) {
  await FirebaseEmailService.envoyerInvitation(
    email: email,
    sessionCode: sessionCode,
    sessionId: sessionId,
  );
}
```

### **2. Rejoindre Session**
```dart
// 1. Rechercher session par code
final session = await FirestoreSessionService.getSessionByCode(sessionCode);

// 2. Attribuer position disponible
final position = await FirestoreSessionService.rejoindreSession(sessionCode, userId);

// 3. Rediriger vers formulaire
Navigator.push(context, ConducteurDeclarationScreen(
  sessionId: session.id,
  conducteurPosition: position,
  isCollaborative: true,
));
```

### **3. Sauvegarde Données**
```dart
// Sauvegarde automatique à chaque étape
await FirestoreSessionService.sauvegarderDonneesConducteur(
  sessionId: sessionId,
  position: position,
  conducteurInfo: conducteurInfo,
  vehiculeInfo: vehiculeInfo,
  assuranceInfo: assuranceInfo,
  // ... autres données
);
```

### **4. Validation Finale**
```dart
// Vérifier si toutes les parties sont complètes
final isComplete = await FirestoreSessionService.verifierSessionComplete(sessionId);

if (isComplete) {
  // Générer constat final
  await genererConstatFinal(sessionId);
}
```

---

## **📊 MODÈLE DE DONNÉES DÉTAILLÉ**

### **ConducteurSessionInfo**
```dart
class ConducteurSessionInfo {
  final String position;           // A, B, C, D, E, F
  final String? userId;           // ID utilisateur Firebase
  final String? email;            // Email d'invitation
  final bool isInvited;           // A été invité
  final bool hasJoined;           // A rejoint la session
  final bool isCompleted;         // A terminé son formulaire
  final DateTime? joinedAt;       // Date de connexion
  final DateTime? completedAt;    // Date de finalisation
  final bool isProprietaire;      // Propriétaire du véhicule
  
  // Données du constat
  final ConducteurInfoModel? conducteur;
  final VehiculeAccidentModel? vehicule;
  final AssuranceInfoModel? assurance;
  final ProprietaireInfo? proprietaire;
  final List<String>? circonstances;
  final List<String>? degatsApparents;
  final List<TemoinModel>? temoins;
  final List<String>? photosAccident;
  final String? photoPermis;
  final String? photoCarteGrise;
  final String? photoAttestation;
  final String? signature;
  final String? observations;
}
```

### **SessionConstatModel**
```dart
class SessionConstatModel {
  final String id;                                    // ID Firestore
  final String sessionCode;                           // Code unique (SESS_ABC123)
  final DateTime dateAccident;                        // Date de l'accident
  final String lieuAccident;                          // Lieu de l'accident
  final Map<String, dynamic>? coordonnees;            // Coordonnées GPS
  final int nombreConducteurs;                        // Nombre de véhicules
  final String createdBy;                             // Créateur de la session
  final DateTime createdAt;                           // Date de création
  final DateTime updatedAt;                           // Dernière mise à jour
  final SessionStatus status;                         // Statut de la session
  final Map<String, ConducteurSessionInfo> conducteursInfo; // Infos conducteurs
  final List<String> invitationsSent;                 // Emails invités
  final Map<String, bool> validationStatus;           // Statut validation par position
}
```

---

## **🎯 POINTS CLÉS DU SYSTÈME**

### **✅ Avantages**
- **Temps réel** : Synchronisation automatique
- **Fiabilité** : Données sauvegardées dans Firestore
- **Simplicité** : Code unique pour rejoindre
- **Traçabilité** : Historique complet des actions
- **Sécurité** : Authentification Firebase

### **🔧 Fonctionnalités**
- **Invitation par email** avec template professionnel
- **Attribution automatique** des positions
- **Sauvegarde progressive** des données
- **Validation croisée** entre conducteurs
- **Génération PDF** du constat final

### **📱 Expérience Utilisateur**
- **Interface intuitive** pour rejoindre
- **Feedback visuel** en temps réel
- **Messages d'erreur** clairs
- **Progression** visible pour chaque étape
- **Synchronisation** transparente

---

## **🚀 PROCHAINES ÉTAPES**

1. **Tester** le flux complet de bout en bout
2. **Optimiser** la synchronisation temps réel
3. **Ajouter** la génération PDF automatique
4. **Implémenter** les notifications push
5. **Créer** un tableau de bord admin

Ce système offre une expérience collaborative complète et professionnelle pour les constats d'accidents ! 🎉
