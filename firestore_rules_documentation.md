# 🔐 Documentation des Règles de Sécurité Firestore

## 📋 Vue d'ensemble

Ce document explique les règles de sécurité Firestore pour l'application **Constat Tunisie**, incluant la gestion des rôles, permissions et accès aux données.

## 👥 Rôles Utilisateurs

### 🚗 **Conducteur** (`conducteur`)
- Peut créer et modifier ses propres constats
- Accès en lecture à ses véhicules assurés
- Peut envoyer des invitations collaboratives
- Peut participer aux sessions collaboratives

### 🏢 **Assureur** (`assureur`)
- Accès complet aux véhicules assurés
- Peut vérifier les contrats d'assurance
- Accès en lecture à tous les constats
- Peut créer et modifier les données véhicules
- Accès aux expertises et rapports

### 🔍 **Expert** (`expert`)
- Accès aux constats pour expertise
- Peut créer et modifier les expertises
- Accès aux photos et documents
- Peut valider les déclarations

## 🗂️ Collections et Permissions

### 📊 **users**
```javascript
// Lecture : propriétaire + assureurs + experts
// Écriture : propriétaire seulement
// Création : utilisateur authentifié pour son propre document
```

### 🚗 **vehicules_assures**
```javascript
// Lecture : propriétaire + assureurs + experts
// Écriture : assureurs seulement
// Création : assureurs seulement
```

### 📋 **constats**
```javascript
// Lecture : conducteurs impliqués + assureurs + experts
// Écriture : conducteurs impliqués (si statut brouillon/en_cours) + experts
// Création : conducteurs seulement
```

### 🚨 **accidents**
```javascript
// Lecture : conducteurs impliqués + assureurs + experts
// Écriture : conducteurs impliqués + experts
// Création : conducteurs seulement
```

### 🔍 **expertises**
```javascript
// Lecture : expert assigné + assureurs + conducteurs concernés
// Écriture : expert assigné seulement
// Création : experts + assureurs
```

### 📧 **invitations**
```javascript
// Lecture : expéditeur + destinataire + assureurs + experts
// Écriture : expéditeur + destinataire
// Création : conducteurs seulement
```

### 💬 **messages**
```javascript
// Lecture : expéditeur + destinataire + participants + assureurs + experts
// Écriture : expéditeur seulement
// Création : utilisateurs authentifiés
```

### 🤝 **collaborative_sessions**
```javascript
// Lecture : créateur + participants + assureurs + experts
// Écriture : créateur + participants
// Création : conducteurs seulement
```

### 📸 **photos**
```javascript
// Lecture : propriétaire + assureurs + experts
// Écriture : propriétaire seulement
// Création : utilisateurs authentifiés
```

### 🔔 **notifications**
```javascript
// Lecture : destinataire seulement
// Écriture : destinataire seulement
// Création : utilisateurs authentifiés
```

### 📊 **audit_logs**
```javascript
// Lecture : assureurs + experts seulement
// Écriture : interdite (logs en lecture seule)
// Création : système seulement (via Cloud Functions)
```

## 🗄️ Firebase Storage

### 📁 Structure des fichiers
```
/vehicules/{vehiculeId}/{type}/{fileName}
/constats/{constatId}/{type}/{fileName}
/users/{userId}/{type}/{fileName}
/profile_pictures/{userId}
```

### 🔐 Permissions Storage
- **Véhicules** : Lecture libre, écriture pour propriétaire/assureur/expert
- **Constats** : Lecture libre, écriture pour participants
- **Utilisateurs** : Lecture pour propriétaire/assureur/expert, écriture pour propriétaire
- **Photos de profil** : Propriétaire seulement

## 🛡️ Fonctions de Sécurité

### 🔍 **Fonctions Utilitaires**
```javascript
isAuthenticated()           // Vérifie l'authentification
isOwner(userId)            // Vérifie la propriété
getUserData()              // Récupère les données utilisateur
hasRole(role)              // Vérifie le rôle
isConducteur()             // Vérifie si conducteur
isAssureur()               // Vérifie si assureur
isExpert()                 // Vérifie si expert
canAccessUserData(userId)  // Vérifie l'accès aux données utilisateur
```

## 🚀 Déploiement

### 📝 **Étapes de déploiement**

1. **Copier les règles** dans la console Firebase
2. **Tester** avec l'émulateur Firestore
3. **Déployer** en production
4. **Vérifier** les permissions

### 🧪 **Commandes de test**
```bash
# Démarrer l'émulateur
firebase emulators:start --only firestore

# Tester les règles
firebase firestore:rules:test

# Déployer les règles
firebase deploy --only firestore:rules
```

## ⚠️ Points d'attention

### 🔒 **Sécurité**
- Toujours vérifier l'authentification
- Utiliser les rôles pour contrôler l'accès
- Limiter les permissions au minimum nécessaire
- Auditer régulièrement les accès

### 📊 **Performance**
- Éviter les requêtes complexes dans les règles
- Utiliser des index appropriés
- Limiter les appels `get()` dans les règles
- Optimiser les structures de données

### 🐛 **Débogage**
- Utiliser l'émulateur pour tester
- Vérifier les logs Firebase
- Tester tous les scénarios d'usage
- Documenter les changements

## 📞 Support

Pour toute question sur les règles de sécurité :
1. Consulter la documentation Firebase
2. Tester avec l'émulateur
3. Vérifier les logs d'erreur
4. Contacter l'équipe de développement

---

**🔐 Sécurité avant tout !** Ces règles protègent les données sensibles de votre application.
