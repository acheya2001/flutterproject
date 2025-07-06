# 🔥 Guide de Déploiement des Règles Firestore

## 📋 Vue d'ensemble

Ce guide vous explique comment déployer les nouvelles règles Firestore pour supporter le système d'inscription professionnelle amélioré avec validation admin, notifications et gestion des permissions.

## 🆕 Nouvelles Collections Ajoutées

### 1. **notifications**
- **Description** : Stocke toutes les notifications système
- **Permissions** : Lecture/écriture pour le destinataire et les admins
- **Champs principaux** : `recipientId`, `type`, `title`, `message`, `isRead`

### 2. **professional_account_requests**
- **Description** : Demandes de comptes professionnels en attente
- **Permissions** : Lecture pour le demandeur et admins, écriture pour admins uniquement
- **Champs principaux** : `userId`, `userType`, `status`, `documents`

## 🔧 Étapes de Déploiement

### Étape 1 : Sauvegarder les Règles Actuelles

```bash
# Exporter les règles actuelles
firebase firestore:rules > firestore_rules_backup.rules
```

### Étape 2 : Déployer les Nouvelles Règles

1. **Copier le contenu** du fichier `firestore_rules_update.rules`
2. **Remplacer** le contenu de votre fichier `firestore.rules`
3. **Déployer** les nouvelles règles :

```bash
# Déployer les règles Firestore
firebase deploy --only firestore:rules
```

### Étape 3 : Vérifier le Déploiement

```bash
# Vérifier que les règles sont actives
firebase firestore:rules
```

## 🔐 Nouvelles Fonctionnalités de Sécurité

### 1. **Gestion des Statuts de Compte**
- `AccountStatus.pending` : Compte en attente de validation
- `AccountStatus.approved` : Compte approuvé par l'admin
- `AccountStatus.rejected` : Compte rejeté
- `AccountStatus.suspended` : Compte suspendu
- `AccountStatus.active` : Compte actif et opérationnel

### 2. **Permissions Granulaires**
Les utilisateurs peuvent avoir des permissions spécifiques :
- `view_contracts` : Voir les contrats
- `create_contracts` : Créer des contrats
- `edit_contracts` : Modifier les contrats
- `delete_contracts` : Supprimer des contrats
- `view_claims` : Voir les sinistres
- `process_claims` : Traiter les sinistres
- `manage_users` : Gérer les utilisateurs
- `validate_agents` : Valider les agents

### 3. **Contrôle d'Accès par Rôle**
- **Conducteurs** : Accès à leurs propres données
- **Assureurs** : Accès aux contrats et sinistres
- **Experts** : Accès aux expertises et rapports
- **Admins** : Accès complet avec permissions spéciales

## 📊 Structure des Nouvelles Collections

### Collection `notifications`
```javascript
{
  id: "auto-generated",
  recipientId: "user-id",
  senderId: "sender-id", // optionnel
  type: "accountPending|accountApproved|accountRejected|...",
  title: "Titre de la notification",
  message: "Message détaillé",
  data: {}, // Données supplémentaires
  isRead: false,
  createdAt: timestamp,
  readAt: timestamp // optionnel
}
```

### Collection `professional_account_requests`
```javascript
{
  id: "auto-generated",
  userId: "user-id",
  email: "user@example.com",
  nom: "Nom",
  prenom: "Prénom",
  telephone: "12345678",
  userType: "assureur|expert",
  
  // Champs spécifiques aux assureurs
  compagnie: "Nom de la compagnie",
  matricule: "Matricule agent",
  gouvernorat: "Tunis",
  
  // Champs spécifiques aux experts
  cabinet: "Nom du cabinet",
  agrement: "Numéro d'agrément",
  
  // Statut et validation
  status: "pending|approved|rejected",
  rejectionReason: "Raison du rejet", // optionnel
  reviewedAt: timestamp, // optionnel
  reviewedBy: "admin-id", // optionnel
  createdAt: timestamp
}
```

## 🚀 Fonctions de Validation

### Nouvelles Fonctions Utilitaires
```javascript
// Vérifier si le compte est actif
function isAccountActive() {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('accountStatus', 'active') == 'active';
}

// Vérifier les permissions
function hasPermission(permission) {
  return isAuthenticated() && 
         exists(/databases/$(database)/documents/users/$(request.auth.uid)) &&
         permission in get(/databases/$(database)/documents/users/$(request.auth.uid)).data.get('permissions', []);
}
```

## ⚠️ Points d'Attention

### 1. **Migration des Données Existantes**
Les utilisateurs existants auront automatiquement :
- `accountStatus: 'active'` par défaut
- `permissions: []` (tableau vide)

### 2. **Compatibilité Descendante**
Les règles sont conçues pour être compatibles avec l'existant :
- Les anciennes collections continuent de fonctionner
- Les nouveaux champs sont optionnels

### 3. **Performance**
- Les règles utilisent des index optimisés
- Les requêtes complexes sont limitées aux admins

## 🧪 Tests Recommandés

### 1. **Test des Notifications**
```javascript
// Créer une notification
await firestore.collection('notifications').add({
  recipientId: 'test-user-id',
  type: 'accountPending',
  title: 'Test',
  message: 'Message de test',
  isRead: false,
  createdAt: new Date()
});
```

### 2. **Test des Demandes de Compte**
```javascript
// Créer une demande
await firestore.collection('professional_account_requests').add({
  userId: 'test-user-id',
  email: 'test@example.com',
  nom: 'Test',
  prenom: 'User',
  userType: 'assureur',
  status: 'pending',
  createdAt: new Date()
});
```

### 3. **Test des Permissions**
```javascript
// Mettre à jour les permissions d'un utilisateur
await firestore.collection('users').doc('user-id').update({
  permissions: ['view_contracts', 'create_contracts']
});
```

## 🔄 Rollback en Cas de Problème

Si vous rencontrez des problèmes, vous pouvez revenir aux anciennes règles :

```bash
# Restaurer les règles de sauvegarde
firebase deploy --only firestore:rules --project your-project-id
```

## 📞 Support

En cas de problème lors du déploiement :
1. Vérifiez les logs Firebase Console
2. Testez les règles avec l'émulateur Firestore
3. Contactez l'équipe de développement

## ✅ Checklist de Déploiement

- [ ] Sauvegarde des règles actuelles effectuée
- [ ] Nouvelles règles déployées avec succès
- [ ] Tests de base effectués sur les nouvelles collections
- [ ] Vérification des permissions existantes
- [ ] Monitoring des erreurs activé
- [ ] Documentation mise à jour

---

**Date de création** : $(date)
**Version** : 1.0
**Auteur** : Équipe Développement Constat Tunisie
