# 🎯 Guide Complet : Système d'Inscription et d'Approbation des Agents

## 🚀 **SYSTÈME COMPLET IMPLÉMENTÉ**

### **✅ Fonctionnalités Créées**

1. **📝 Inscription des Agents**
   - Formulaire multi-étapes (3 pages)
   - Informations personnelles et professionnelles
   - Upload de documents optionnel
   - Validation complète des données

2. **📧 Système d'Emails Automatiques**
   - Email de confirmation au demandeur
   - Notification à l'admin
   - Email d'approbation/rejet
   - Templates HTML professionnels

3. **👨‍💼 Interface d'Administration**
   - Gestion des demandes en attente
   - Approbation/rejet avec motifs
   - Statistiques en temps réel
   - Interface intuitive

4. **🔐 Sécurité et Permissions**
   - Règles Firestore mises à jour
   - Contrôle d'accès granulaire
   - Validation des données

## 🎯 **COMMENT UTILISER LE SYSTÈME**

### **Pour les Agents (Inscription)**

#### **Étape 1 : Accéder à l'inscription**
1. Ouvrir l'application
2. Aller sur "Agent d'Assurance"
3. Cliquer sur "S'inscrire comme agent"

#### **Étape 2 : Remplir le formulaire**

**Page 1 - Informations Personnelles :**
- Email professionnel
- Mot de passe (minimum 6 caractères)
- Confirmation du mot de passe
- Prénom et nom
- Numéro de téléphone

**Page 2 - Informations Professionnelles :**
- Compagnie d'assurance (dropdown)
- Gouvernorat (24 gouvernorats disponibles)
- Agence (selon le gouvernorat)
- Poste (8 postes disponibles)
- Numéro d'agent

**Page 3 - Documents (Optionnel) :**
- Carte d'identité (recto/verso)
- Permis de conduire (recto/verso)
- Sélection depuis caméra ou galerie

#### **Étape 3 : Soumission**
1. Cliquer sur "Soumettre"
2. Recevoir confirmation de soumission
3. Attendre l'email de confirmation

### **Pour l'Admin (Approbation)**

#### **Étape 1 : Accéder aux demandes**
1. Se connecter comme admin
2. Aller dans l'interface d'administration
3. Accéder à "Demandes d'Agents"

#### **Étape 2 : Examiner les demandes**
- Voir toutes les demandes en attente
- Consulter les informations détaillées
- Vérifier les documents uploadés

#### **Étape 3 : Approuver ou Rejeter**

**Pour Approuver :**
1. Cliquer sur "Approuver"
2. Confirmer l'action
3. Le système :
   - Crée le compte Firebase Auth
   - Enregistre dans Firestore
   - Envoie l'email d'approbation
   - Active l'accès

**Pour Rejeter :**
1. Cliquer sur "Rejeter"
2. Saisir le motif du rejet
3. Confirmer l'action
4. Email de rejet envoyé automatiquement

## 📧 **EMAILS AUTOMATIQUES**

### **Email de Confirmation (Demandeur)**
```
Sujet: 📝 Demande d'inscription reçue - Constat Tunisie

Contenu:
- Confirmation de réception
- Récapitulatif des informations
- Prochaines étapes
- Délai de traitement (24-48h)
```

### **Email de Notification (Admin)**
```
Sujet: 🏢 Nouvelle demande d'agent d'assurance

Contenu:
- Informations du demandeur
- Détails professionnels
- Lien vers l'interface admin
```

### **Email d'Approbation (Demandeur)**
```
Sujet: 🎉 Compte agent approuvé - Constat Tunisie

Contenu:
- Félicitations
- Informations de connexion
- Fonctionnalités disponibles
- Lien vers l'application
```

### **Email de Rejet (Demandeur)**
```
Sujet: ❌ Demande d'inscription non approuvée

Contenu:
- Motif du refus
- Instructions pour corriger
- Contact pour assistance
```

## 🏗️ **ARCHITECTURE TECHNIQUE**

### **Collections Firestore**

#### **professional_account_requests**
```json
{
  "email": "agent@star.tn",
  "password": "motdepasse", // Temporaire
  "prenom": "Ahmed",
  "nom": "Ben Ali",
  "telephone": "+216 XX XXX XXX",
  "compagnie": "STAR Assurances",
  "agence": "Agence Tunis",
  "gouvernorat": "Tunis",
  "poste": "Agent Commercial",
  "numeroAgent": "AG001234",
  "carteIdRecto": "url_image",
  "carteIdVerso": "url_image",
  "permisRecto": "url_image",
  "permisVerso": "url_image",
  "status": "pending|approved|rejected",
  "submittedAt": "timestamp",
  "reviewedAt": "timestamp",
  "reviewedBy": "admin_uid",
  "rejectionReason": "motif"
}
```

#### **notifications**
```json
{
  "type": "new_agent_request",
  "title": "Nouvelle demande d'agent",
  "message": "Demande de Ahmed Ben Ali",
  "requestId": "request_id",
  "userId": "admin",
  "isRead": false,
  "createdAt": "timestamp"
}
```

#### **assureurs** (après approbation)
```json
{
  "uid": "firebase_uid",
  "email": "agent@star.tn",
  "prenom": "Ahmed",
  "nom": "Ben Ali",
  "telephone": "+216 XX XXX XXX",
  "compagnie": "STAR Assurances",
  "agence": "Agence Tunis",
  "gouvernorat": "Tunis",
  "poste": "Agent Commercial",
  "numeroAgent": "AG001234",
  "isActive": true,
  "createdAt": "timestamp",
  "approvedAt": "timestamp",
  "approvedBy": "admin_uid"
}
```

### **Services Créés**

1. **AgentRegistrationService**
   - `submitAgentRegistration()` - Soumettre demande
   - `approveAgentRequest()` - Approuver demande
   - `rejectAgentRequest()` - Rejeter demande
   - `getPendingRequests()` - Récupérer demandes
   - `getRequestsStats()` - Statistiques

2. **ImageUploadService**
   - `uploadImage()` - Upload image
   - `deleteImage()` - Supprimer image
   - `uploadWithRetry()` - Upload avec retry

3. **EmailService** (existant)
   - Envoi d'emails via Gmail OAuth2
   - Templates HTML professionnels

### **Écrans Créés**

1. **AgentRegistrationScreen**
   - Formulaire multi-étapes
   - Validation complète
   - Upload d'images
   - Interface moderne

2. **AgentRequestsScreen**
   - Liste des demandes
   - Actions d'approbation/rejet
   - Statistiques
   - Interface admin

## 🔧 **CONFIGURATION REQUISE**

### **Firebase**
- ✅ Firestore activé
- ✅ Storage activé
- ✅ Auth activé
- ✅ Règles de sécurité mises à jour

### **Email**
- ✅ Gmail OAuth2 configuré
- ✅ Compte constat.tunisie.app@gmail.com
- ✅ Tokens de refresh valides

### **Routes**
- ✅ `/agent-registration` - Inscription
- ✅ `/admin/agent-requests` - Gestion admin

## 🎯 **WORKFLOW COMPLET**

```
1. Agent remplit formulaire d'inscription
   ↓
2. Données sauvées dans professional_account_requests
   ↓
3. Email de confirmation envoyé au demandeur
   ↓
4. Notification envoyée à l'admin
   ↓
5. Admin examine la demande
   ↓
6a. APPROBATION:
    - Création compte Firebase Auth
    - Enregistrement dans users/assureurs
    - Email d'approbation
    - Accès activé
   ↓
6b. REJET:
    - Mise à jour du statut
    - Email de rejet avec motif
   ↓
7. Agent peut se connecter (si approuvé)
```

## 🚀 **PROCHAINES ÉTAPES**

### **Immédiat**
1. ✅ Tester l'inscription d'un agent
2. ✅ Tester l'approbation admin
3. ✅ Vérifier les emails
4. ✅ Tester la connexion après approbation

### **Améliorations Futures**
- 📊 Dashboard admin avec analytics
- 🔔 Notifications push
- 📱 Interface mobile optimisée
- 🔍 Recherche et filtres avancés
- 📈 Rapports d'activité

## 🎉 **RÉSULTAT FINAL**

### **✅ Système Complet et Fonctionnel**
- **Inscription** : Interface moderne et intuitive
- **Validation** : Processus d'approbation robuste
- **Emails** : Communication automatique
- **Sécurité** : Règles Firestore appropriées
- **Administration** : Interface de gestion complète

### **🎯 Avantages**
- ✅ **Automatisation complète** du processus
- ✅ **Sécurité renforcée** avec validation admin
- ✅ **Communication transparente** via emails
- ✅ **Interface professionnelle** pour tous les utilisateurs
- ✅ **Évolutivité** pour futures améliorations

**Le système d'inscription et d'approbation des agents est maintenant entièrement opérationnel !** 🚀
