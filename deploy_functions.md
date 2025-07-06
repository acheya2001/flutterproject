# 📧 Guide de déploiement des Cloud Functions

## 🚀 Étapes de déploiement

### 1. Prérequis
```bash
# Installer Firebase CLI (si pas déjà fait)
npm install -g firebase-tools

# Se connecter à Firebase
firebase login
```

### 2. Configuration du projet
```bash
# Aller dans le dossier functions
cd functions

# Installer les dépendances
npm install
```

### 3. Déployer les fonctions
```bash
# Déployer toutes les fonctions
firebase deploy --only functions

# Ou déployer une fonction spécifique
firebase deploy --only functions:sendAcceptanceEmail
firebase deploy --only functions:sendRejectionEmail
firebase deploy --only functions:sendNewRequestNotification
```

### 4. Vérifier le déploiement
```bash
# Voir les logs
firebase functions:log

# Tester une fonction
firebase functions:shell
```

## 🔧 Configuration Gmail

### Variables d'environnement Firebase
```bash
# Configurer le client secret Gmail (si nécessaire)
firebase functions:config:set gmail.client_secret="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"

# Voir la configuration actuelle
firebase functions:config:get
```

## 📧 Fonctions disponibles

### 1. `sendAcceptanceEmail`
- **Région**: europe-west1
- **Trigger**: HTTPS Callable
- **Paramètres**: email, nomComplet, role, motDePasse, appName, loginUrl

### 2. `sendRejectionEmail`
- **Région**: europe-west1
- **Trigger**: HTTPS Callable
- **Paramètres**: email, nomComplet, role, motifRejet, appName, supportEmail

### 3. `sendNewRequestNotification`
- **Région**: europe-west1
- **Trigger**: HTTPS Callable
- **Paramètres**: nomComplet, email, role, requestId, adminEmail, dashboardUrl

### 4. `sendEmail` (existante)
- **Région**: europe-west1
- **Trigger**: HTTPS Callable
- **Paramètres**: to, subject, text, html, sessionCode, sessionId, conducteurNom

## 🧪 Test des fonctions

### Test local avec émulateur
```bash
# Démarrer l'émulateur
firebase emulators:start --only functions

# L'émulateur sera disponible sur http://localhost:5001
```

### Test en production
```bash
# Appeler une fonction depuis Firebase Console
# Ou utiliser l'application Flutter
```

## ⚠️ Résolution des problèmes

### Erreur "NOT_FOUND"
- Vérifier que les fonctions sont bien déployées
- Vérifier la région (europe-west1)
- Vérifier les noms des fonctions

### Erreur d'authentification Gmail
- Vérifier l'App Password Gmail
- Vérifier les credentials OAuth2
- Vérifier la configuration Firebase

### Erreur de permissions
- Vérifier les règles Firestore
- Vérifier les permissions IAM
- Vérifier la configuration du projet Firebase

## 📝 Commandes utiles

```bash
# Voir les fonctions déployées
firebase functions:list

# Supprimer une fonction
firebase functions:delete nomDeLaFonction

# Voir les logs en temps réel
firebase functions:log --follow

# Redéployer après modification
firebase deploy --only functions
```

## 🔄 Réactiver les emails dans l'app

Une fois les fonctions déployées, décommenter dans le fichier :
`lib/features/auth/presentation/services/professional_request_submission_service.dart`

```dart
// Remplacer le commentaire par :
await EmailNotificationService.sendNewRequestNotificationToAdmins(
  nomComplet: request.nomComplet,
  email: request.email,
  role: request.roleFormate,
  requestId: docRef.id,
);
```
