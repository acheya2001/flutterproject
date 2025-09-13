# 🚨 PROCESSUS COMPLET DE DÉCLARATION DE SINISTRE

## 📋 Vue d'ensemble

Le processus de déclaration de sinistre dans l'application d'assurance tunisienne suit un workflow collaboratif moderne avec validation multi-niveaux et génération automatique de constats PDF conformes aux standards légaux.

## 👥 RÔLES ET RESPONSABILITÉS

### 🚗 **CONDUCTEUR**
- **Permissions** : Créer des sessions d'accident, inviter d'autres conducteurs, remplir formulaires
- **Responsabilités** :
  - Initier la déclaration de sinistre
  - Inviter les autres parties impliquées
  - Remplir ses informations personnelles et véhicule
  - Valider ou refuser le croquis collaboratif
  - Signer numériquement le constat
- **Conditions** : Doit être authentifié et avoir un véhicule assuré

### 👨‍💼 **AGENT D'ASSURANCE**
- **Permissions** : Consulter les sinistres de ses clients, valider les constats, assigner des experts
- **Responsabilités** :
  - Recevoir les constats finalisés
  - Valider la conformité des déclarations
  - Assigner des experts pour expertise
  - Traiter les dossiers de sinistre
- **Conditions** : Doit être assigné à l'agence du conducteur

### 🏢 **ADMIN AGENCE**
- **Permissions** : Superviser tous les sinistres de l'agence, gérer les agents
- **Responsabilités** :
  - Superviser le traitement des sinistres
  - Valider les décisions des agents
  - Gérer l'affectation des dossiers
- **Conditions** : Doit être responsable de l'agence concernée

### 🏛️ **ADMIN COMPAGNIE**
- **Permissions** : Accès aux sinistres de toute la compagnie, statistiques globales
- **Responsabilités** :
  - Supervision globale des sinistres
  - Validation des cas complexes
  - Gestion des conflits inter-agences
- **Conditions** : Doit être admin de la compagnie d'assurance

### 🔍 **EXPERT**
- **Permissions** : Accès multi-compagnies, création de rapports d'expertise
- **Responsabilités** :
  - Effectuer l'expertise technique
  - Rédiger le rapport d'expertise
  - Évaluer les dommages
  - Proposer des solutions de réparation
- **Conditions** : Doit être assigné au sinistre par un agent/admin

### 👑 **SUPER ADMIN**
- **Permissions** : Accès total au système, gestion des utilisateurs
- **Responsabilités** :
  - Supervision globale du système
  - Gestion des compagnies et agences
  - Résolution des conflits majeurs
  - Maintenance du système

## 🔄 WORKFLOW COMPLET

### **Phase 1 : Initiation (Conducteur)**

#### Étape 1.1 : Accès au système
```
Dashboard Conducteur → Bouton "Déclarer un Accident" → SinistreChoixRapideScreen
```

#### Étape 1.2 : Choix du type de déclaration
```
Options disponibles :
- Déclarer un Sinistre (créer nouvelle session)
- Rejoindre une Session (via QR code ou code)
```

#### Étape 1.3 : Sélection du type d'accident
```
ModernAccidentTypeScreen → Types disponibles :
- Collision entre véhicules (collaboratif)
- Sortie de route (individuel)
- Collision avec objet fixe (individuel)
- Accident avec piéton/cycliste (collaboratif)
- Carambolage (multi-véhicules)
```

### **Phase 2 : Configuration de la session**

#### Étape 2.1 : Nombre de véhicules
```
Écran : CollaborativeVehicleCountScreen
Action : Sélection 2-6 véhicules impliqués
Validation : Nombre minimum 2, maximum 6
Progression : 0% → 10%
```

**Détails de la session :**
```
SessionData {
  sessionId: String (UUID généré)
  createdBy: String (userId du créateur)
  vehicleCount: int (2-6)
  status: 'CONFIGURATION'
  createdAt: Timestamp
  participants: [] (vide initialement)
  maxParticipants: vehicleCount
  currentStep: 'VEHICLE_COUNT'
  progression: {
    global: 10,
    steps: {
      configuration: 10,
      invitation: 0,
      remplissage: 0,
      croquis: 0,
      signatures: 0,
      finalisation: 0
    }
  }
}
```

#### Étape 2.2 : Création de session collaborative
```
Service : CollaborativeSessionService.creerSessionCollaborative()
Actions :
- Génération code session unique (6 caractères alphanumériques)
- Création QR code pour partage rapide
- Initialisation structure participants
- Enregistrement en Firestore
- Activation géolocalisation
Progression : 10% → 20%
```

**Structure session créée :**
```
SessionCollaborative {
  sessionId: "ABC123" (code unique)
  qrCodeData: String (données QR)
  createdBy: userId
  vehicleCount: int
  status: 'WAITING_PARTICIPANTS'
  location: {
    latitude: double,
    longitude: double,
    address: String
  }
  participants: [
    {
      userId: createdBy,
      role: 'CREATOR',
      status: 'JOINED',
      joinedAt: Timestamp,
      vehicleIndex: 0
    }
  ]
  waitingFor: vehicleCount - 1,
  currentStep: 'INVITATION'
}
```

### **Phase 3 : Invitation des participants**

#### Étape 3.1 : Méthodes d'invitation
```
Écran : SessionInvitationScreen
Options disponibles :
- QR Code (scan direct avec caméra)
- Code session (saisie manuelle 6 caractères)
- SMS/Email (si contacts fournis)
- Partage lien direct

```

**Processus d'invitation détaillé :**
```
1. CRÉATEUR partage :
   - Affichage QR Code + Code session
   - Options de partage (SMS, Email, WhatsApp)
   - Attente participants en temps réel

2. PARTICIPANT rejoint :
   - Scan QR Code OU saisie code
   - Vérification validité session
   - Attribution index véhicule automatique
   - Notification temps réel au créateur

3. SYNCHRONISATION :
   - Mise à jour liste participants
   - Calcul progression globale
   - Vérification nombre maximum
   - Activation étape suivante si complet
```

#### Étape 3.2 : Rejoindre la session
```
Écran : ModernJoinSessionScreen
Actions :
- Validation du code session
- Vérification disponibilité places
- Attribution index véhicule
- Ajout à la liste participants
- Notification temps réel
Progression : +15% par participant
```

**Mise à jour session en temps réel :**
```
Participant rejoint → SessionData mise à jour :
{
  participants: [
    ...existants,
    {
      userId: nouveauParticipant,
      role: 'PARTICIPANT',
      status: 'JOINED',
      joinedAt: Timestamp.now(),
      vehicleIndex: nextAvailableIndex,
      formCompleted: false,
      sketchValidated: false,
      signatureCompleted: false
    }
  ],
  waitingFor: waitingFor - 1,
  progression: {
    global: calculerProgressionGlobale(),
    participants: calculerProgressionParticipants()
  }
}

Si tous participants rejoints :
- status: 'WAITING_PARTICIPANTS' → 'FORM_FILLING'
- currentStep: 'INVITATION' → 'REMPLISSAGE'
- progression.global: 75% → 80%
```

### **Phase 4 : Remplissage collaboratif**

#### Étape 4.1 : Informations générales (partagées)
```
Écran : InfosCommunesScreen
Responsable : CRÉATEUR de la session (seul autorisé)
Champs obligatoires :
- Date et heure de l'accident (picker datetime)
- Lieu précis (GPS automatique + correction manuelle)
- Présence de blessés (oui/non + détails si oui)
- Témoins (optionnel : nom, contact)
- Circonstances générales (liste prédéfinie)
- Photos générales (optionnel, max 5)
Progression : 80% → 85%
```

**Synchronisation temps réel :**
```
Créateur saisit → Firestore mise à jour → Tous participants voient :
{
  commonInfo: {
    dateAccident: Timestamp,
    location: {
      latitude: double,
      longitude: double,
      address: String
    },
    hasInjuries: boolean,
    injuryDetails: String?,
    witnesses: [
      {name: String, contact: String}
    ],
    circumstances: String,
    generalPhotos: [String] // URLs Firebase Storage
  },
  status: 'COMMON_INFO_COMPLETED',
  progression: {
    global: 85,
    commonInfo: 100,
    individualForms: 0
  }
}
```

#### Étape 4.2 : Informations par véhicule (individuelles)

**🔄 PROCESSUS ADAPTATIF SELON LE STATUT DU CONDUCTEUR**

**Pour les conducteurs INSCRITS avec véhicules enregistrés :**
```
Écran : VehicleSelectionScreen → Auto-remplissage
Processus automatique :
1. Sélection du véhicule (liste déroulante)
2. Remplissage automatique instantané :
   ✅ Identité du conducteur (depuis profil)
   ✅ Informations véhicule (depuis véhicule sélectionné)
   ✅ Assurance et contrat (depuis contrat actif)
3. Saisie manuelle requise :
   - Circonstances spécifiques (liste + texte libre)
   - Dégâts apparents (zones + photos)
   - Observations personnelles (texte libre)
Progression : +10% par formulaire complété
Temps estimé : 3-5 minutes

Conditions requises :
- Conducteur inscrit dans l'application
- Véhicule(s) enregistré(s) dans le profil
- Contrat d'assurance ACTIF lié au véhicule
```

**Progression détaillée pour conducteur inscrit :**
```
Étapes de progression :
1. Sélection véhicule → +2%
2. Auto-remplissage → +5% (instantané)
3. Circonstances → +1%
4. Dégâts → +1%
5. Observations → +1%
Total par participant : +10%

Mise à jour temps réel :
participantData[vehicleIndex] = {
  userId: currentUser,
  formProgress: {
    vehicleSelected: true,    // +2%
    autoFilled: true,        // +5%
    circumstances: false,     // +1%
    damages: false,          // +1%
    observations: false      // +1%
  },
  formCompleted: false,
  lastUpdated: Timestamp.now()
}
```

**Pour les conducteurs NON-INSCRITS ou sans véhicules enregistrés :**
```
Écran : ParticipantFormScreen
Sections obligatoires (remplissage manuel complet) :
1. Identité du conducteur (nom, prénom, permis, adresse)
2. Informations véhicule (marque, modèle, immatriculation, châssis)
3. Assurance et contrat (compagnie, police, échéance, couverture)
4. Circonstances spécifiques (liste + texte libre)
5. Dégâts apparents (zones + photos)
6. Observations personnelles (texte libre)
Progression : +10% par formulaire complété
Temps estimé : 8-12 minutes

⚠️ RESTRICTION : Si contrat d'assurance NON ACTIF → Déclaration impossible
```

**Progression détaillée pour conducteur non-inscrit :**
```
Étapes de progression :
1. Identité conducteur → +2%
2. Infos véhicule → +2%
3. Assurance/contrat → +3% (avec validation temps réel)
4. Circonstances → +1%
5. Dégâts → +1%
6. Observations → +1%
Total par participant : +10%

Validation en temps réel :
- Numéro permis → Vérification format
- Immatriculation → Contrôle validité
- Contrat assurance → API validation
- Si contrat inactif → Blocage immédiat

participantData[vehicleIndex] = {
  userId: currentUser,
  formProgress: {
    identity: false,         // +2%
    vehicle: false,          // +2%
    insurance: false,        // +3%
    circumstances: false,    // +1%
    damages: false,          // +1%
    observations: false      // +1%
  },
  validationStatus: {
    identityValid: false,
    vehicleValid: false,
    insuranceActive: false  // CRITIQUE
  },
  formCompleted: false
}
```

### **Phase 5 : Validation des données**

#### Étape 5.1 : Vérification automatique

**🔄 VALIDATION ADAPTATIVE SELON LE STATUT DU CONDUCTEUR**

**Pour les conducteurs INSCRITS avec véhicules enregistrés :**
```
Validation automatique simplifiée :
✅ Données pré-validées (profil + véhicule + contrat actif)
✅ Cohérence automatique des informations
✅ Validation instantanée des contrats
✅ Vérification automatique des immatriculations
- Seules les circonstances et dégâts nécessitent validation manuelle
```

**Pour les conducteurs NON-INSCRITS :**
```
Validation complète manuelle :
- Tous les champs obligatoires remplis
- Cohérence des données entre participants
- Validation des numéros de contrat
- Vérification des immatriculations
- Contrôle de validité des permis
- Vérification de l'activité des contrats d'assurance

⚠️ BLOCAGE : Contrat non actif = Validation impossible
```

#### Étape 5.2 : Progression tracking et synchronisation
```
Service : CollaborativeDataSyncService.calculerProgression()
Calculs en temps réel :
- participantsRejoints / nombreVehicules → Progression invitation
- formulairesTermines / nombreVehicules → Progression remplissage
- validationsReussies / nombreVehicules → Progression validation
- Statut global de la session
Progression : 85% → 90% (tous formulaires validés)
```

**Algorithme de progression détaillé :**
```
calculerProgressionGlobale() {
  // Phase 1-3 : Configuration + Invitation (0-75%)
  invitationProgress = (participantsRejoints / vehicleCount) * 75

  // Phase 4 : Remplissage (75-90%)
  remplissageProgress = 0
  for (participant in participants) {
    if (participant.formCompleted) {
      remplissageProgress += 10 // 10% par formulaire
    } else {
      remplissageProgress += participant.formProgress.total
    }
  }

  // Phase 5 : Validation (90-92%)
  validationProgress = (formulairesValides / vehicleCount) * 2

  // Phase 6 : Croquis (92-96%)
  croquisProgress = 0
  if (croquisCree) croquisProgress += 2
  if (croquisValideParTous) croquisProgress += 2

  // Phase 7 : Signatures (96-99%)
  signatureProgress = (signaturesCompletes / vehicleCount) * 3

  // Phase 8 : Finalisation (99-100%)
  finalisationProgress = pdfGenere ? 1 : 0

  return invitationProgress + remplissageProgress +
         validationProgress + croquisProgress +
         signatureProgress + finalisationProgress
}
```

### **Phase 6 : Croquis collaboratif**

#### Étape 6.1 : Création du croquis
```
Écran : ModernCollaborativeSketchScreen
Responsable : Un seul conducteur (généralement le créateur)
Actions :
- Dessin interactif avec outils spécialisés
- Placement véhicules (formes prédéfinies)
- Ajout routes, signalisation, obstacles
- Sauvegarde automatique en temps réel
- Synchronisation immédiate avec tous participants
Progression : 90% → 92%
```

**Détails techniques du croquis :**
```
CroquisData {
  sessionId: String,
  createdBy: userId,
  elements: [
    {
      type: 'VEHICLE',
      vehicleIndex: int,
      position: {x: double, y: double},
      rotation: double,
      color: String
    },
    {
      type: 'ROAD',
      points: [{x: double, y: double}],
      width: double
    },
    {
      type: 'SIGN',
      signType: String,
      position: {x: double, y: double}
    }
  ],
  lastModified: Timestamp,
  status: 'CREATION'
}

Synchronisation temps réel :
- Chaque trait → Firestore update
- Tous participants voient en direct
- Indicateur "En cours de dessin par [Nom]"
```

#### Étape 6.2 : Validation unanime par tous les participants
```
Écran : CollaborativeSketchValidationScreen
Processus :
- Affichage croquis finalisé à tous
- Chaque participant vote : ACCEPTER / REFUSER
- Si REFUSER → Commentaire obligatoire
- Unanimité requise pour continuer
- Possibilité retour modification si refus
Progression : 92% → 94% (si unanimité)
```

**Processus de validation détaillé :**
```
ValidationCroquis {
  sessionId: String,
  croquisId: String,
  validations: [
    {
      userId: String,
      vote: 'PENDING' | 'ACCEPTED' | 'REFUSED',
      comment: String?, // Obligatoire si REFUSED
      timestamp: Timestamp
    }
  ],
  status: 'PENDING' | 'ACCEPTED' | 'REFUSED',
  refusCount: int,
  acceptCount: int
}

Logique de validation :
1. Tous PENDING → Attente votes
2. Un seul REFUSED → Status REFUSED, retour modification
3. Tous ACCEPTED → Status ACCEPTED, progression continue
4. Si refus → Notification créateur + possibilité modification

Progression temps réel :
- Chaque vote → Mise à jour compteurs
- Interface mise à jour pour tous
- Indicateurs visuels : ✅ Accepté, ❌ Refusé, ⏳ En attente
```

### **Phase 7 : Signatures numériques**

#### Étape 7.1 : Processus de signature sécurisée
```
Écran : SecureSignatureScreen
Service : SignatureValidationService.initierSignatureSecurisee()
Actions :
- Génération code OTP unique (validité 5 minutes)
- Envoi SMS automatique au numéro du conducteur
- Interface signature tactile haute résolution
- Capture signature avec métadonnées
- Horodatage précis et géolocalisation
Progression : +3% par signature complétée
```

**Structure signature sécurisée :**
```
SignatureData {
  sessionId: String,
  userId: String,
  vehicleIndex: int,
  signatureImage: String, // Base64 ou URL Firebase Storage
  otpCode: String, // Code 6 chiffres
  otpGeneratedAt: Timestamp,
  otpValidatedAt: Timestamp?,
  phoneNumber: String,
  metadata: {
    deviceInfo: String,
    ipAddress: String,
    location: {
      latitude: double,
      longitude: double
    },
    timestamp: Timestamp,
    signatureQuality: double // Score qualité signature
  },
  status: 'PENDING_OTP' | 'VALIDATED' | 'EXPIRED' | 'FAILED'
}
```

#### Étape 7.2 : Validation OTP et certification
```
Écran : OTPValidationScreen
Processus détaillé :
1. Saisie signature manuscrite sur écran tactile
2. Génération et envoi OTP par SMS (6 chiffres)
3. Saisie code OTP dans les 5 minutes
4. Validation croisée : signature + OTP + métadonnées
5. Certification numérique avec hash SHA-256
6. Enregistrement sécurisé en Firestore
7. Notification temps réel aux autres participants
Progression : 94% → 97% (toutes signatures validées)
```

**Processus de validation OTP :**
```
validateSignatureOTP(sessionId, userId, otpCode) {
  // 1. Vérification validité temporelle
  if (now() - otpGeneratedAt > 5 minutes) {
    return {status: 'EXPIRED', message: 'Code expiré'}
  }

  // 2. Vérification code OTP
  if (otpCode !== storedOtpCode) {
    return {status: 'INVALID', message: 'Code incorrect'}
  }

  // 3. Certification signature
  signatureHash = SHA256(signatureImage + metadata + timestamp)

  // 4. Mise à jour statut
  updateSignatureStatus(userId, 'VALIDATED', signatureHash)

  // 5. Vérification progression globale
  if (allSignaturesValidated()) {
    updateSessionStatus('SIGNATURES_COMPLETED')
    triggerPDFGeneration()
  }

  return {status: 'SUCCESS', hash: signatureHash}
}

Synchronisation temps réel :
- Chaque signature validée → Notification à tous
- Progression mise à jour instantanément
- Interface indique : ✅ Signé, ⏳ En attente, ❌ Expiré
```

### **Phase 8 : Finalisation**

#### Étape 8.1 : Génération du constat PDF intelligent multi-véhicules
```
Écran : PDFGenerationScreen
Service : IntelligentConstatPdfService.genererConstatMultiVehicules()
Actions :
- Compilation automatique de TOUTES les données session collaborative
- Génération PDF multi-pages conforme au constat papier tunisien
- Inclusion croquis vectoriel + signatures certifiées + photos dégâts
- Adaptation dynamique selon nombre de véhicules (2 à N véhicules)
- Conformité légale tunisienne (format officiel amélioré)
- Génération QR code de vérification + métadonnées
- Horodatage et certification numérique
Progression : 97% → 99%
Temps estimé : 30-90 secondes (selon nombre véhicules)
```

**Structure PDF intelligente générée :**
```
ConstatPDFIntelligent {
  // PAGE 1 : COUVERTURE ET INFORMATIONS GÉNÉRALES
  - En-tête officiel République Tunisienne + logos compagnies
  - Numéro constat unique (format: CNT-2024-XXXXXX)
  - QR code de vérification + URL validation
  - Informations générales accident :
    * Date, heure précise (avec secondes)
    * Lieu détaillé (GPS + adresse complète)
    * Conditions météo et visibilité
    * Présence blessés/témoins
    * Photos générales de la scène
  - Récapitulatif participants (N véhicules)

  // PAGES 2 à N+1 : DÉTAILS PAR VÉHICULE (1 page par véhicule)
  Véhicule A, B, C... (selon nombre) :
  ┌─ SECTION 1 : IDENTITÉ CONDUCTEUR
  │  - Nom, prénom, date naissance
  │  - Adresse complète
  │  - Permis de conduire (numéro, date délivrance)
  │  - Photo pièce d'identité (si fournie)
  │
  ┌─ SECTION 2 : INFORMATIONS VÉHICULE
  │  - Marque, modèle, année, couleur
  │  - Immatriculation + numéro châssis
  │  - Carte grise (numéro, date)
  │  - Type carburant, puissance
  │
  ┌─ SECTION 3 : ASSURANCE ET CONTRAT
  │  - Compagnie d'assurance + logo
  │  - Numéro police + date échéance
  │  - Type couverture + garanties
  │  - Agence gestionnaire + contact
  │
  ┌─ SECTION 4 : CIRCONSTANCES SPÉCIFIQUES
  │  - Cases cochées (comme constat papier)
  │  - Circonstances détaillées
  │  - Vitesse estimée + conditions
  │
  ┌─ SECTION 5 : DÉGÂTS APPARENTS + PHOTOS
  │  - Schéma véhicule avec zones endommagées
  │  - Photos des dégâts (haute résolution)
  │  - Description détaillée des dommages
  │  - Estimation gravité (léger/moyen/grave)
  │
  ┌─ SECTION 6 : OBSERVATIONS PERSONNELLES
  │  - Texte libre du conducteur
  │  - Contestations éventuelles
  │
  ┌─ SECTION 7 : SIGNATURE NUMÉRIQUE CERTIFIÉE
  │  - Signature manuscrite numérisée
  │  - Horodatage précis + géolocalisation
  │  - Hash de certification + OTP validé
  │  - Métadonnées de sécurité

  // PAGE FINALE : CROQUIS COLLABORATIF ET SYNTHÈSE
  ┌─ SECTION 1 : CROQUIS HAUTE RÉSOLUTION
  │  - Croquis collaboratif vectoriel
  │  - Légende avec couleurs par véhicule
  │  - Éléments route/signalisation
  │  - Flèches de mouvement/impact
  │
  ┌─ SECTION 2 : SYNTHÈSE GLOBALE
  │  - Récapitulatif des responsabilités
  │  - Cohérence des déclarations
  │  - Points de convergence/divergence
  │
  ┌─ SECTION 3 : SIGNATURES COLLECTIV ES
  │  - Signatures de tous les participants
  │  - Validation unanime du croquis
  │  - Horodatage final de clôture
  │
  ┌─ SECTION 4 : MÉTADONNÉES TECHNIQUES
  │  - Hash SHA-256 du document complet
  │  - Identifiants session et participants
  │  - Géolocalisation de génération
  │  - Version application + timestamp
  │  - Certificat de conformité numérique
}

Fonctionnalités avancées :
✅ Adaptation automatique selon nombre de véhicules
✅ Photos haute résolution intégrées
✅ Croquis vectoriel redimensionnable
✅ Signatures certifiées avec OTP
✅ QR code de vérification en ligne
✅ Métadonnées de sécurité complètes
✅ Format conforme réglementation tunisienne
✅ Optimisation pour impression A4
```

#### Étape 8.2 : Transmission intelligente aux agents d'assurance
```
Écran : TransmissionScreen
Service : IntelligentNotificationService.transmettreConstatAuxAgents()
Destinataires automatiques INTELLIGENTS :
- Agents d'assurance spécifiques par véhicule (email + API + notification)
- Agences d'assurance de tous les véhicules (copie hiérarchique)
- Conducteurs participants (email + notification push + SMS)
- Système central de suivi des sinistres
- Autorités compétentes (si blessés déclarés)
Progression : 99% → 100%
```

**Processus de transmission intelligent détaillé :**
```
transmettreConstatIntelligent(sessionId, pdfUrl, sessionData) {
  // 1. IDENTIFICATION DES AGENTS RESPONSABLES
  agentsResponsables = []

  for (vehicule in session.vehicules) {
    // Récupérer l'agent qui gère ce véhicule spécifiquement
    contratActif = getContratActif(vehicule.numeroPolice)
    agentResponsable = getAgentResponsable(contratActif.agentId)

    agentsResponsables.add({
      vehiculeId: vehicule.id,
      vehiculeInfo: vehicule.marque + " " + vehicule.modele + " (" + vehicule.immatriculation + ")",
      agentId: agentResponsable.id,
      agentNom: agentResponsable.prenom + " " + agentResponsable.nom,
      agentEmail: agentResponsable.email,
      agentPhone: agentResponsable.phone,
      agenceNom: agentResponsable.agence.nom,
      compagnieNom: agentResponsable.compagnie.nom,
      numeroPolice: contratActif.numeroPolice,
      typeContrat: contratActif.typeContrat
    })
  }

  // 2. GÉNÉRATION EMAIL PERSONNALISÉ PAR AGENT
  for (agent in agentsResponsables) {
    emailPersonnalise = genererEmailAgent({
      agentNom: agent.agentNom,
      vehiculeInfo: agent.vehiculeInfo,
      numeroPolice: agent.numeroPolice,
      dateAccident: session.dateAccident,
      lieuAccident: session.localisation.adresse,
      nombreVehicules: session.vehicules.length,
      presenceBlessés: session.blesses,
      conducteurNom: getVehicule(agent.vehiculeId).conducteur.nom,
      pdfUrl: pdfUrl,
      sessionId: sessionId,
      urgence: determinerUrgence(session)
    })

    // Envoi email avec PDF en pièce jointe
    sendEmailWithAttachment({
      to: agent.agentEmail,
      subject: "🚨 NOUVEAU CONSTAT - " + agent.vehiculeInfo + " - " + session.dateAccident,
      htmlContent: emailPersonnalise,
      attachments: [
        {
          filename: "constat_" + sessionId + "_" + agent.vehiculeId + ".pdf",
          url: pdfUrl
        }
      ]
    })

    // Notification push si agent connecté
    if (isAgentOnline(agent.agentId)) {
      sendPushNotification(agent.agentId, {
        title: "🚨 Nouveau constat d'accident",
        body: "Véhicule " + agent.vehiculeInfo + " impliqué",
        data: {
          sessionId: sessionId,
          vehiculeId: agent.vehiculeId,
          type: "nouveau_constat",
          urgence: determinerUrgence(session)
        }
      })
    }

    // SMS si urgence élevée
    if (determinerUrgence(session) >= 3) {
      sendSMS(agent.agentPhone,
        "🚨 URGENT: Nouveau constat accident véhicule " + agent.vehiculeInfo +
        ". Consultez votre email. Session: " + sessionId)
    }
  }

  // 3. NOTIFICATION AGENCES (COPIE HIÉRARCHIQUE)
  for (agence in getAgencesImpliquees(agentsResponsables)) {
    sendEmailToAgency({
      agenceEmail: agence.email,
      subject: "📋 Copie constat - " + session.vehicules.length + " véhicules",
      content: genererEmailAgence(agence, session, agentsResponsables),
      pdfAttachment: pdfUrl
    })
  }

  // 4. NOTIFICATION CONDUCTEURS
  for (conducteur in session.conducteurs) {
    sendEmailWithAttachment({
      to: conducteur.email,
      subject: "✅ Votre constat d'accident - " + session.dateAccident,
      content: genererEmailConducteur(conducteur, session),
      attachment: pdfUrl
    })

    sendPushNotification(conducteur.userId, {
      title: "✅ Constat finalisé",
      body: "Votre constat d'accident a été généré et transmis",
      data: { sessionId: sessionId, pdfUrl: pdfUrl }
    })

    sendSMS(conducteur.phone,
      "✅ Constat accident finalisé. PDF envoyé par email. " +
      "Votre agent d'assurance a été notifié. Session: " + sessionId)
  }

  // 5. SYSTÈME CENTRAL ET AUTORITÉS
  if (session.blesses) {
    notifierAutoritesCompetentes(session, pdfUrl)
  }

  notifierSystemeCentral({
    sessionId: sessionId,
    nombreVehicules: session.vehicules.length,
    agentsNotifies: agentsResponsables.length,
    timestamp: now(),
    pdfUrl: pdfUrl
  })

  // 6. LOGGING ET SUIVI
  logTransmissionComplete({
    sessionId: sessionId,
    agentsNotifies: agentsResponsables,
    agencesNotifiees: getAgencesImpliquees(agentsResponsables),
    conducteursNotifies: session.conducteurs,
    timestamp: now(),
    pdfSize: getPdfSize(pdfUrl),
    transmissionDuration: calculateDuration()
  })

  // 7. FINALISATION SESSION
  updateSessionStatus('COMPLETED')
  updateProgression(100)

  // 8. PROGRAMMATION SUIVI AUTOMATIQUE
  scheduleFollowUp({
    sessionId: sessionId,
    agentsResponsables: agentsResponsables,
    delaiSuivi: 24, // heures
    typeRappel: 'traitement_constat'
  })
}

// Fonction pour déterminer le niveau d'urgence
determinerUrgence(session) {
  urgence = 1 // Normal

  if (session.blesses) urgence += 2        // Blessés = +2
  if (session.vehicules.length > 2) urgence += 1  // Multi-véhicules = +1
  if (session.degatsImportants) urgence += 1      // Dégâts importants = +1
  if (isWeekend() || isNightTime()) urgence += 1  // Hors heures = +1

  return min(urgence, 5) // Max 5
}
```

## 📊 SYSTÈME DE PROGRESSION ET SESSIONS COLLABORATIVES

### **🔄 Gestion des sessions en temps réel**

#### **Structure complète d'une session collaborative :**
```
SessionCollaborative {
  // Identifiants
  sessionId: String (UUID),
  sessionCode: String (6 caractères),
  qrCodeData: String,

  // Métadonnées
  createdBy: String (userId),
  createdAt: Timestamp,
  lastActivity: Timestamp,
  expiresAt: Timestamp (24h après création),

  // Configuration
  vehicleCount: int (2-6),
  maxParticipants: vehicleCount,

  // Participants
  participants: [
    {
      userId: String,
      role: 'CREATOR' | 'PARTICIPANT',
      status: 'JOINED' | 'ACTIVE' | 'COMPLETED' | 'DISCONNECTED',
      joinedAt: Timestamp,
      lastSeen: Timestamp,
      vehicleIndex: int (0-5),

      // Progression individuelle
      progress: {
        formStarted: boolean,
        formCompleted: boolean,
        formValidated: boolean,
        sketchValidated: boolean,
        signatureCompleted: boolean,
        percentComplete: int (0-100)
      }
    }
  ],

  // État global
  status: 'CONFIGURATION' | 'WAITING_PARTICIPANTS' | 'FORM_FILLING' |
          'FORM_VALIDATION' | 'SKETCH_CREATION' | 'SKETCH_VALIDATION' |
          'SIGNATURES' | 'PDF_GENERATION' | 'COMPLETED' | 'EXPIRED',

  // Progression globale
  progression: {
    global: int (0-100),
    phases: {
      configuration: int (0-20),
      invitation: int (0-75),
      remplissage: int (0-90),
      validation: int (0-92),
      croquis: int (0-96),
      signatures: int (0-99),
      finalisation: int (0-100)
    },
    details: {
      participantsRejoints: int,
      formulairesCompletes: int,
      formulairesValides: int,
      croquisValide: boolean,
      signaturesCompletes: int,
      pdfGenere: boolean
    }
  },

  // Données métier
  location: {
    latitude: double,
    longitude: double,
    address: String,
    accuracy: double
  },

  commonInfo: {
    dateAccident: Timestamp,
    hasInjuries: boolean,
    injuryDetails: String?,
    witnesses: [{name: String, contact: String}],
    circumstances: String,
    generalPhotos: [String] // URLs Firebase Storage
  },

  participantData: [
    {
      vehicleIndex: int,
      userId: String,

      // Données conducteur
      driver: {
        nom: String,
        prenom: String,
        permis: String,
        dateNaissance: Date,
        adresse: String
      },

      // Données véhicule
      vehicle: {
        marque: String,
        modele: String,
        annee: int,
        immatriculation: String,
        chassis: String,
        couleur: String
      },

      // Assurance
      insurance: {
        compagnie: String,
        numeroPolice: String,
        dateEcheance: Date,
        typeCouverture: String,
        agenceId: String,
        isActive: boolean
      },

      // Circonstances et dégâts
      circumstances: String,
      damages: [
        {
          zone: String,
          severity: 'LEGER' | 'MOYEN' | 'GRAVE',
          description: String,
          photos: [String]
        }
      ],
      observations: String,

      // Validation
      validationStatus: {
        identityValid: boolean,
        vehicleValid: boolean,
        insuranceActive: boolean,
        formComplete: boolean
      }
    }
  ],

  // Croquis collaboratif
  sketch: {
    createdBy: String,
    elements: [
      {
        type: 'VEHICLE' | 'ROAD' | 'SIGN' | 'OBSTACLE',
        data: Object, // Spécifique au type
        position: {x: double, y: double},
        rotation: double?
      }
    ],
    validations: [
      {
        userId: String,
        vote: 'PENDING' | 'ACCEPTED' | 'REFUSED',
        comment: String?,
        timestamp: Timestamp
      }
    ],
    status: 'CREATION' | 'VALIDATION' | 'ACCEPTED' | 'REFUSED'
  },

  // Signatures
  signatures: [
    {
      userId: String,
      vehicleIndex: int,
      signatureImage: String,
      otpCode: String,
      otpValidatedAt: Timestamp?,
      metadata: {
        deviceInfo: String,
        location: {latitude: double, longitude: double},
        timestamp: Timestamp,
        hash: String
      },
      status: 'PENDING_OTP' | 'VALIDATED' | 'EXPIRED'
    }
  ],

  // Finalisation
  finalisation: {
    pdfUrl: String?,
    pdfGeneratedAt: Timestamp?,
    transmissionStatus: {
      agencesNotified: [String], // agenceIds
      conducteursNotified: [String], // userIds
      systemNotified: boolean,
      completedAt: Timestamp?
    }
  }
}
```

### **📈 Algorithme de progression en temps réel**

#### **Calcul de progression globale :**
```
calculateGlobalProgress(session) {
  let progress = 0

  // Phase 1 : Configuration (0-20%)
  if (session.vehicleCount > 0) progress += 10
  if (session.sessionCode && session.qrCodeData) progress += 10

  // Phase 2 : Invitation (20-75%)
  const invitationProgress = (session.participants.length / session.vehicleCount) * 55
  progress += invitationProgress

  // Phase 3 : Remplissage (75-90%)
  if (session.participants.length === session.vehicleCount) {
    const formProgress = session.participantData.filter(p => p.validationStatus.formComplete).length
    progress += (formProgress / session.vehicleCount) * 15
  }

  // Phase 4 : Validation (90-92%)
  if (session.commonInfo && session.commonInfo.dateAccident) {
    const validatedForms = session.participantData.filter(p => p.validationStatus.insuranceActive).length
    progress += (validatedForms / session.vehicleCount) * 2
  }

  // Phase 5 : Croquis (92-96%)
  if (session.sketch && session.sketch.elements.length > 0) progress += 2
  if (session.sketch && session.sketch.status === 'ACCEPTED') progress += 2

  // Phase 6 : Signatures (96-99%)
  const validatedSignatures = session.signatures.filter(s => s.status === 'VALIDATED').length
  progress += (validatedSignatures / session.vehicleCount) * 3

  // Phase 7 : Finalisation (99-100%)
  if (session.finalisation.pdfUrl) progress += 1

  return Math.min(100, Math.round(progress))
}
```

#### **Synchronisation temps réel avec Firestore :**
```
// Listeners temps réel pour tous les participants
setupRealtimeListeners(sessionId) {
  // 1. Écoute des changements de session
  db.collection('sessions_collaboratives')
    .doc(sessionId)
    .onSnapshot((doc) => {
      const session = doc.data()
      updateUIProgress(session.progression.global)
      updateParticipantsList(session.participants)
      updateSessionStatus(session.status)
    })

  // 2. Écoute des données participants
  db.collection('sessions_collaboratives')
    .doc(sessionId)
    .collection('participant_data')
    .onSnapshot((snapshot) => {
      snapshot.docChanges().forEach((change) => {
        if (change.type === 'modified') {
          updateParticipantProgress(change.doc.data())
        }
      })
    })

  // 3. Écoute du croquis
  db.collection('sessions_collaboratives')
    .doc(sessionId)
    .collection('sketch_data')
    .onSnapshot((doc) => {
      if (doc.exists) {
        updateSketchDisplay(doc.data())
      }
    })
}
```

## 🛠️ **SERVICES TECHNIQUES CLÉS AMÉLIORÉS**

### **📋 Services de Session Collaborative**
- `CollaborativeSessionService` - Gestion des sessions multi-participants
- `CollaborativeDataSyncService` - Synchronisation temps réel des données
- `SessionProgressTracker` - Suivi de progression par phase
- `ParticipantManagementService` - Gestion des participants et statuts

### **🎨 Services de Croquis et Validation**
- `CollaborativeSketchService` - Croquis collaboratif temps réel
- `SketchValidationService` - Validation unanime des croquis
- `VectorDrawingEngine` - Moteur de dessin vectoriel
- `SketchSyncService` - Synchronisation des modifications

### **✍️ Services de Signature et Sécurité**
- `SignatureValidationService` - Signatures numériques avec OTP SMS
- `OTPVerificationService` - Validation par codes SMS sécurisés
- `DigitalCertificationService` - Certification des signatures
- `SecurityHashService` - Génération de hash de sécurité

### **📄 Services de Génération PDF INTELLIGENTS**
- `IntelligentConstatPdfService` - **NOUVEAU** PDF intelligent multi-véhicules
- `ConstatPdfService` - Génération PDF standard (legacy)
- `CollaborativePdfService` - PDF collaboratif multi-participants
- `ModernPdfAgentService` - PDF moderne pour agents
- `SimplePdfAgentService` - PDF simplifié pour transmission

### **📧 Services de Notification INTELLIGENTS**
- `IntelligentNotificationService` - **NOUVEAU** Transmission intelligente aux agents
- `NotificationService` - Notifications push et email (legacy)
- `EmailNotificationService` - Templates HTML professionnels
- `SMSNotificationService` - Notifications SMS d'urgence
- `AgentNotificationService` - Notifications spécifiques agents

### **🤖 Fonctionnalités Avancées Ajoutées**
- ✅ **PDF adaptatif** selon nombre de véhicules (2 à N véhicules)
- ✅ **Identification automatique** des agents responsables par véhicule
- ✅ **Emails personnalisés** avec templates HTML professionnels
- ✅ **Notifications push** avec niveaux d'urgence
- ✅ **SMS urgents** pour situations critiques
- ✅ **Copie hiérarchique** aux agences d'assurance
- ✅ **Suivi automatique** programmé à 24h
- ✅ **Logging complet** de toutes les transmissions
- ✅ **Métadonnées de sécurité** avec hash et certification

---

## ⚠️ CONDITIONS ET VALIDATIONS

### **Conditions techniques**
- ✅ Connexion internet stable
- ✅ Géolocalisation activée
- ✅ Caméra pour photos (optionnel)
- ✅ SMS pour validation OTP

### **Conditions métier**
- ✅ Véhicules assurés et contrats valides
- ✅ Conducteurs identifiés
- ✅ Lieu d'accident en Tunisie
- ✅ Accident récent (< 5 jours)

### **🚗 Gestion des véhicules et contrats**

**Conducteurs INSCRITS :**
- ✅ Sélection automatique parmi les véhicules enregistrés
- ✅ Remplissage automatique des informations
- ✅ Validation instantanée des contrats actifs
- ⚠️ **RESTRICTION :** Seuls les véhicules avec contrats ACTIFS sont disponibles

**Conducteurs NON-INSCRITS :**
- ✅ Saisie manuelle de toutes les informations
- ✅ Validation en temps réel des numéros de contrat
- ❌ **BLOCAGE :** Impossible de procéder si contrat non actif
- ❌ **BLOCAGE :** Impossible de procéder si véhicule non assuré

### **Validations automatiques**
- ✅ Vérification des numéros de contrat
- ✅ Validation des immatriculations
- ✅ Cohérence des données temporelles
- ✅ Géolocalisation dans les limites autorisées

### **Conditions de finalisation**
- ✅ Tous les formulaires complétés
- ✅ Croquis validé par tous
- ✅ Signatures certifiées de tous les participants
- ✅ Photos obligatoires ajoutées
- ✅ Aucun conflit de données

## 🔐 SÉCURITÉ ET CONFORMITÉ

### **Authentification**
- Firebase Auth avec vérification email/SMS
- Tokens JWT avec expiration
- Validation des rôles et permissions

### **Intégrité des données**
- Horodatage cryptographique
- Signatures numériques certifiées
- Audit trail complet
- Sauvegarde redondante

### **Conformité légale**
- Respect du code des assurances tunisien
- Format de constat officiel
- Signatures électroniques conformes ANF
- Archivage sécurisé 10 ans

## 📊 STATUTS DE SESSION

```
creation → attente_participants → en_cours → validation_croquis → pret_signature → signe → finalise
```

### **Transitions automatiques**
- `creation` → `attente_participants` : Dès qu'un participant rejoint
- `attente_participants` → `en_cours` : Tous les participants ont rejoint
- `en_cours` → `validation_croquis` : Tous les formulaires terminés
- `validation_croquis` → `pret_signature` : Croquis validé par tous
- `pret_signature` → `signe` : Toutes les signatures effectuées
- `signe` → `finalise` : PDF généré et transmis

## 🚫 GESTION DES ERREURS

### **Erreurs bloquantes**
- Perte de connexion pendant signature
- Échec de validation OTP
- Conflit de données entre participants
- Véhicule non assuré détecté

### **Erreurs récupérables**
- Timeout de session (extension automatique)
- Échec d'upload photo (retry automatique)
- Géolocalisation imprécise (saisie manuelle)
- Participant qui quitte (notification aux autres)

### **Mécanismes de récupération**
- Sauvegarde automatique toutes les 30 secondes
- Synchronisation en temps réel
- Mode hors ligne avec sync différée
- Notifications push pour les actions requises

## 📱 DÉTAILS TECHNIQUES D'IMPLÉMENTATION

### **Services principaux**

#### 🎯 CollaborativeSessionService
```dart
// Création de session
static Future<CollaborativeSession> creerSessionCollaborative({
  required String typeAccident,
  required int nombreVehicules,
  required String nomCreateur,
  required String prenomCreateur,
  required String emailCreateur,
  required String telephoneCreateur,
})

// Finalisation avec PDF
static Future<String> finaliserSession(String sessionId)
```

#### 🔄 CollaborativeDataSyncService
```dart
// Synchronisation temps réel
static Stream<CollaborativeSession?> streamSession(String sessionId)

// Validation croquis
static Future<void> validerCroquis({
  required String sessionId,
  required String participantId,
  required bool accepte,
  String? commentaire,
})

// Calcul progression
static Future<Map<String, dynamic>> calculerProgression(String sessionId)
```

#### ✍️ SignatureValidationService
```dart
// Signature sécurisée avec OTP
static Future<Map<String, dynamic>> initierSignatureSecurisee({
  required String sessionId,
  required String role,
  required String telephone,
  required String nomComplet,
  required bool accepteResponsabilite,
})

// Validation finale
static Future<Map<String, dynamic>> validerSignatureAvecOTP({
  required String validationId,
  required String codeOTP,
  required Uint8List signatureBytes,
})
```

### **Écrans et navigation**

#### 📱 Écrans principaux
1. **SinistreChoixRapideScreen** : Point d'entrée
2. **ModernAccidentTypeScreen** : Sélection type accident
3. **CollaborativeVehicleCountScreen** : Nombre véhicules
4. **CreationSessionScreen** : Création session avec QR
5. **ModernJoinSessionScreen** : Rejoindre via code
6. **InfosCommunesScreen** : Informations partagées
7. **ParticipantFormScreen** : Formulaire individuel
8. **ModernCollaborativeSketchScreen** : Croquis collaboratif
9. **CollaborativeSketchValidationScreen** : Validation croquis
10. **SignatureScreen** : Signature avec OTP

### **Conditions de validation détaillées**

#### ✅ Validation formulaire participant
```dart
bool _validateCurrentPage() {
  switch (_currentPage) {
    case 0: // Identité
      return _nomController.text.trim().isNotEmpty &&
             _prenomController.text.trim().isNotEmpty &&
             _adresseController.text.trim().isNotEmpty &&
             _telController.text.trim().isNotEmpty &&
             _emailController.text.trim().isNotEmpty &&
             _cinController.text.trim().isNotEmpty &&
             _permisNumController.text.trim().isNotEmpty;
    case 1: // Assurance
      return _policeNumController.text.trim().isNotEmpty;
    case 2: // Véhicule
      return _vehMarqueController.text.trim().isNotEmpty &&
             _vehTypeController.text.trim().isNotEmpty &&
             _immatriculationController.text.trim().isNotEmpty;
    case 3: // Circonstances - validation optionnelle
      return true;
    case 4: // Dégâts
      return _degatsTextController.text.trim().isNotEmpty;
  }
}
```

#### ✅ Validation informations communes
```dart
bool _validateCurrentPage() {
  switch (_currentPage) {
    case 0: // Date et heure
      return _dateController.text.isNotEmpty &&
             _heureController.text.isNotEmpty;
    case 1: // Lieu
      return _adresseController.text.trim().isNotEmpty;
    case 2: // Circonstances - optionnel
      return true;
    case 3: // Témoins - optionnel
      return true;
    case 4: // Observations - optionnel
      return true;
  }
}
```

### **Progression et statuts**

#### 📊 Calcul de progression
```dart
static Future<Map<String, dynamic>> calculerProgression(String sessionId) {
  // Facteurs de progression :
  // - participantsRejoints / nombreVehicules (25%)
  // - formulairesTermines / nombreVehicules (25%)
  // - croquisValides / nombreVehicules (25%)
  // - signaturesEffectuees / nombreVehicules (25%)

  final progression = (
    (participantsRejoints * 0.25) +
    (formulairesTermines * 0.25) +
    (croquisValides * 0.25) +
    (signaturesEffectuees * 0.25)
  ) * 100;
}
```

#### 🔄 Transitions de statut automatiques
```dart
String _determinerStatutSession(Map<String, dynamic> sessionData) {
  if (tousOntSigne) return 'finalise';
  if (tousOntValideEtPretsPourSignature) return 'pret_signature';
  if (croquisValideParTous) return 'validation_croquis';
  if (tousFormulairesTermines) return 'validation_croquis';
  if (tousParticipantsRejoints) return 'en_cours';
  if (auMoinsUnParticipant) return 'attente_participants';
  return 'creation';
}
```

## 🔐 SÉCURITÉ FIRESTORE

### **Règles de sécurité pour sinistres**
```javascript
// Collection sinistres
match /sinistres/{sinistreId} {
  // Lecture : Super Admin + Admin Compagnie + Agent + Expert + Conducteur impliqué
  allow read: if request.auth != null && (
    isSuperAdmin() ||
    isAdminOfCompanyFromResource(resource.data.compagnieId) ||
    isAgentOfAgencyFromResource(resource.data.agenceId) ||
    isExpertAssigned(sinistreId) ||
    isConducteurInvolved(resource.data.conducteurIds)
  );

  // Écriture : Super Admin + Admin Compagnie + Agent + Expert assigné
  allow write: if request.auth != null && (
    isSuperAdmin() ||
    (isAdminCompagnie() && isAdminOfCompanyFromResource(resource.data.compagnieId)) ||
    (isAgent() && isAgentOfAgencyFromResource(resource.data.agenceId)) ||
    (isExpert() && isExpertAssigned(sinistreId))
  );
}
```

### **Collections Firestore utilisées**
- `sessions_collaboratives` : Sessions d'accident en cours
- `accident_sessions_complete` : Sessions finalisées
- `sinistres` : Sinistres créés depuis les sessions
- `signatures_certifiees` : Signatures avec certification OTP
- `expert_assignations` : Assignations d'experts
- `constats_collaboratifs` : Constats PDF finalisés

## 📈 MÉTRIQUES ET SUIVI

### **KPIs de performance**
- Temps moyen de création de session : < 2 minutes
- Taux de finalisation des sessions : > 85%
- Temps moyen de validation croquis : < 5 minutes
- Taux de succès des signatures OTP : > 95%
- Délai de génération PDF : < 30 secondes

### **Audit et traçabilité**
- Horodatage de chaque action
- Logs de toutes les modifications
- Traçabilité des validations
- Historique des statuts
- Géolocalisation des actions
