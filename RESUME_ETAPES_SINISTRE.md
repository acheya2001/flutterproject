# 🚨 RÉSUMÉ EXÉCUTIF - ÉTAPES DE DÉCLARATION DE SINISTRE

## 📋 PROCESSUS EN 8 ÉTAPES PRINCIPALES

### **ÉTAPE 1 : INITIATION** 🚀
**Acteur** : Conducteur  
**Écran** : `SinistreChoixRapideScreen`  
**Actions** :
- Accès depuis le dashboard conducteur
- Choix entre "Déclarer un Sinistre" ou "Rejoindre une Session"
- Sélection du type d'accident (collaboratif/individuel)

**Conditions** :
- ✅ Utilisateur authentifié
- ✅ Véhicule assuré sélectionné
- ✅ Connexion internet active

---

### **ÉTAPE 2 : CONFIGURATION** ⚙️
**Acteur** : Conducteur créateur  
**Écrans** : `ModernAccidentTypeScreen` → `CollaborativeVehicleCountScreen`  
**Actions** :
- Sélection du nombre de véhicules (2-6)
- Génération automatique du code session (6 caractères)
- Création du QR Code pour partage

**Conditions** :
- ✅ Type d'accident compatible avec le mode collaboratif
- ✅ Nombre de véhicules valide (2 minimum pour collaboratif)

---

### **ÉTAPE 3 : INVITATION** 📱
**Acteur** : Conducteur créateur + Participants  
**Écrans** : `CreationSessionScreen` → `ModernJoinSessionScreen`  
**Actions** :
- Partage du QR Code ou code session
- Rejoindre la session via scan ou saisie manuelle
- Validation des participants

**Conditions** :
- ✅ Code session valide et non expiré
- ✅ Nombre maximum de participants non atteint
- ✅ Participants authentifiés

---

### **ÉTAPE 4 : REMPLISSAGE COLLABORATIF** 📝
**Acteur** : Tous les participants
**Écrans** : `InfosCommunesScreen` + `VehicleSelectionScreen`/`ParticipantFormScreen`
**Actions** :
- **Informations communes** (partagées) :
  - Date, heure, lieu de l'accident
  - Présence de blessés et témoins
  - Circonstances générales

**🔄 Formulaires individuels ADAPTATIFS :**

**Conducteurs INSCRITS avec véhicules enregistrés :**
- ✅ **Sélection automatique** du véhicule (liste déroulante)
- ✅ **Remplissage automatique** : identité + véhicule + assurance
- ✅ **Saisie manuelle** : circonstances + dégâts + observations

**Conducteurs NON-INSCRITS :**
- ✅ **Saisie manuelle complète** de toutes les informations
- ⚠️ **Validation en temps réel** des contrats d'assurance

**Conditions** :
- ✅ Tous les champs obligatoires remplis
- ✅ Cohérence des données entre participants
- ✅ **CONTRATS D'ASSURANCE ACTIFS OBLIGATOIRES**
- ✅ Validation des numéros de contrat
- ✅ Géolocalisation dans les limites autorisées
- ❌ **BLOCAGE si contrat non actif**

---

### **ÉTAPE 5 : CROQUIS COLLABORATIF** 🎨
**Acteur** : Un conducteur dessine, tous valident  
**Écrans** : `ModernCollaborativeSketchScreen` → `CollaborativeSketchValidationScreen`  
**Actions** :
- Création du croquis par un participant (généralement le créateur)
- Outils de dessin : véhicules, routes, signalisation
- Validation par tous les autres participants
- Possibilité de refus avec commentaires obligatoires

**Conditions** :
- ✅ Croquis créé et sauvegardé
- ✅ **UNANIMITÉ REQUISE** : tous doivent accepter
- ✅ Si refus : commentaires fournis et retour à la modification
- ✅ Synchronisation temps réel entre participants

---

### **ÉTAPE 6 : SIGNATURES NUMÉRIQUES** ✍️
**Acteur** : Tous les participants  
**Écran** : `SignatureScreen`  
**Actions** :
- Génération code OTP par SMS (5 minutes de validité)
- Signature manuscrite sur écran tactile
- Validation du code OTP reçu
- Certification automatique avec horodatage

**Conditions** :
- ✅ Code OTP valide et non expiré
- ✅ Signature manuscrite non vide
- ✅ Téléphone vérifié pour réception SMS
- ✅ Toutes les signatures requises effectuées

---

### **ÉTAPE 7 : GÉNÉRATION PDF** 📄
**Acteur** : Système automatique  
**Service** : `ConstatPdfService`  
**Actions** :
- Compilation de toutes les données de la session
- Génération PDF multi-pages conforme aux standards légaux
- Intégration du croquis et des signatures certifiées
- Horodatage et certification du document final

**Conditions** :
- ✅ Toutes les données de session complètes
- ✅ Signatures certifiées valides
- ✅ Croquis validé par tous
- ✅ Aucune erreur de génération

---

### **ÉTAPE 8 : TRANSMISSION ET FINALISATION** 📤
**Acteur** : Système + Agents d'assurance  
**Actions** :
- Transmission automatique aux agences d'assurance concernées
- Notification aux conducteurs participants
- Archivage sécurisé du constat
- Création du dossier sinistre pour suivi

**Conditions** :
- ✅ PDF généré avec succès
- ✅ Transmission réussie aux agences
- ✅ Notifications envoyées
- ✅ Session marquée comme finalisée

---

## 🔄 STATUTS DE PROGRESSION

| Statut | Description | Progression |
|--------|-------------|-------------|
| `creation` | Session créée, QR Code généré | 10% |
| `attente_participants` | En attente que tous rejoignent | 20% |
| `en_cours` | Remplissage des formulaires | 50% |
| `validation_croquis` | Validation du croquis par tous | 75% |
| `pret_signature` | Prêt pour les signatures | 85% |
| `signe` | Toutes signatures effectuées | 95% |
| `finalise` | PDF généré et transmis | 100% |

## ⚠️ CONDITIONS CRITIQUES

### **Conditions bloquantes** (arrêt du processus)
- ❌ Utilisateur non authentifié
- ❌ Véhicule non assuré ou contrat expiré
- ❌ Refus unanime du croquis
- ❌ Échec de validation OTP (3 tentatives)
- ❌ Erreur de génération PDF

### **Conditions de validation** (étape par étape)
- ✅ **Étape 4** : Tous formulaires obligatoires complétés
- ✅ **Étape 5** : Croquis accepté par 100% des participants
- ✅ **Étape 6** : Signatures certifiées de tous les conducteurs
- ✅ **Étape 7** : PDF conforme aux standards légaux tunisiens

## 👥 RÔLES DANS LE PROCESSUS

### **Conducteurs** (Étapes 1-6)
- Initient et participent à la déclaration
- Remplissent leurs informations personnelles
- Valident le croquis collaboratif
- Signent numériquement le constat

### **Agents d'assurance** (Étape 8+)
- Reçoivent les constats finalisés
- Valident la conformité
- Assignent des experts si nécessaire
- Traitent les dossiers de sinistre

### **Experts** (Post-finalisation)
- Effectuent l'expertise technique
- Rédigent les rapports d'évaluation
- Proposent les solutions de réparation

### **Admins** (Supervision)
- Supervisent le processus global
- Gèrent les conflits et exceptions
- Accèdent aux statistiques et métriques

## 📊 MÉTRIQUES DE PERFORMANCE

### **Objectifs de performance**
- ⏱️ Temps moyen de création : < 2 minutes
- 📈 Taux de finalisation : > 85%
- ✅ Taux de succès OTP : > 95%
- 📄 Délai génération PDF : < 30 secondes

### **Indicateurs de qualité**
- 🎯 Précision des données : > 98%
- 🔒 Sécurité des signatures : 100%
- 📱 Compatibilité mobile : Tous appareils
- 🌐 Disponibilité service : 99.9%

## 🔐 SÉCURITÉ ET CONFORMITÉ

### **Mesures de sécurité**
- 🔐 Authentification Firebase obligatoire
- 📱 Validation OTP par SMS
- 🔒 Signatures numériques certifiées
- 📊 Audit trail complet
- 🏛️ Conformité légale tunisienne

### **Protection des données**
- 🛡️ Chiffrement des données sensibles
- 📍 Géolocalisation sécurisée
- 🗄️ Archivage redondant
- ⏰ Horodatage cryptographique
- 🔍 Traçabilité complète des actions
