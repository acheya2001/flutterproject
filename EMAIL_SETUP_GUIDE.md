# 📧 Guide de Configuration du Système d'Email

## 📋 Vue d'ensemble

Ce guide explique comment configurer le système d'envoi d'emails automatiques pour les notifications de comptes professionnels via Gmail API.

## 🔧 Configuration Actuelle

### Compte Gmail Configuré
- **Email** : `constat.tunisie.app@gmail.com`
- **Mot de passe** : `Acheya123`
- **Client ID** : `1059917372502-bcja6qd5feh9rpndg3klveh1pcihruj5.apps.googleusercontent.com`
- **Refresh Token** : `1//04fqCR47aG8PuCgYIARAAGAQSNwF-L9IrbmVfT1Ip925nf40rYtGez0sw_fJH341WZM9UHDhdWnkShe5AONoFyep4P6lS2E1VsFw`

## 🚀 Fonctionnalités Implémentées

### 1. **Emails Automatiques**
- ✅ **Compte approuvé** : Email de félicitations avec instructions
- ❌ **Compte rejeté** : Email avec raison du rejet et conseils
- 🆕 **Nouvelle demande** : Notification aux admins

### 2. **Templates HTML Professionnels**
- Design responsive et moderne
- Branding Constat Tunisie
- Boutons d'action cliquables
- Version texte de fallback

### 3. **Intégration Complète**
- Envoi automatique lors des actions admin
- Gestion des erreurs et retry
- Logs détaillés pour le debugging

## 📧 Types d'Emails Envoyés

### 1. **Email d'Approbation de Compte**
**Déclencheur** : Admin approuve une demande de compte
**Destinataire** : Utilisateur demandeur
**Contenu** :
- Message de félicitations
- Instructions de connexion
- Liste des fonctionnalités disponibles
- Bouton d'action "Se connecter"

### 2. **Email de Rejet de Compte**
**Déclencheur** : Admin rejette une demande de compte
**Destinataire** : Utilisateur demandeur
**Contenu** :
- Explication du rejet
- Raison détaillée fournie par l'admin
- Instructions pour corriger et repostuler
- Bouton "Contacter le Support"

### 3. **Email de Notification aux Admins**
**Déclencheur** : Nouvelle demande de compte soumise
**Destinataire** : Tous les administrateurs
**Contenu** :
- Détails du demandeur
- Type de compte demandé
- Bouton "Examiner la Demande"
- Rappel d'urgence de traitement

## 🔐 Sécurité et Authentification

### OAuth2 Flow
1. **Refresh Token** : Stocké de manière sécurisée
2. **Access Token** : Généré dynamiquement à chaque envoi
3. **Expiration** : Gestion automatique du renouvellement

### Bonnes Pratiques
- Tokens stockés dans des variables d'environnement (production)
- Logs d'erreur sans exposition des credentials
- Rate limiting pour éviter le spam

## 🛠️ Configuration pour Production

### 1. **Variables d'Environnement**
Créez un fichier `.env` :
```env
GMAIL_CLIENT_ID=1059917372502-bcja6qd5feh9rpndg3klveh1pcihruj5.apps.googleusercontent.com
GMAIL_REFRESH_TOKEN=1//04fqCR47aG8PuCgYIARAAGAQSNwF-L9IrbmVfT1Ip925nf40rYtGez0sw_fJH341WZM9UHDhdWnkShe5AONoFyep4P6lS2E1VsFw
GMAIL_SENDER_EMAIL=constat.tunisie.app@gmail.com
```

### 2. **Mise à Jour du Service**
Modifiez `email_service.dart` pour utiliser les variables d'environnement :
```dart
static const String _clientId = String.fromEnvironment('GMAIL_CLIENT_ID');
static const String _refreshToken = String.fromEnvironment('GMAIL_REFRESH_TOKEN');
static const String _senderEmail = String.fromEnvironment('GMAIL_SENDER_EMAIL');
```

### 3. **Configuration Firebase**
Ajoutez les variables dans Firebase Functions (si utilisé) :
```bash
firebase functions:config:set gmail.client_id="your-client-id"
firebase functions:config:set gmail.refresh_token="your-refresh-token"
firebase functions:config:set gmail.sender_email="your-email"
```

## 📱 Intégration Mobile

### Permissions Android
Ajoutez dans `android/app/src/main/AndroidManifest.xml` :
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### Dépendances Flutter
Ajoutez dans `pubspec.yaml` :
```yaml
dependencies:
  http: ^1.1.0
  # Déjà inclus dans le projet
```

## 🧪 Tests et Validation

### 1. **Test d'Envoi Simple**
```dart
// Test d'envoi d'email
final success = await EmailService.sendEmail(
  to: 'test@example.com',
  subject: 'Test Email',
  htmlBody: '<h1>Test</h1><p>Ceci est un test.</p>',
);
print('Email envoyé: $success');
```

### 2. **Test des Templates**
```dart
// Test email d'approbation
final success = await EmailService.sendAccountApprovedEmail(
  to: 'user@example.com',
  userName: 'John Doe',
  userType: 'assureur',
);
```

### 3. **Test de Notification Admin**
```dart
// Test notification aux admins
final success = await EmailService.sendNewRequestNotificationToAdmins(
  applicantName: 'Jane Smith',
  applicantEmail: 'jane@example.com',
  userType: 'expert',
  adminEmails: ['admin1@example.com', 'admin2@example.com'],
);
```

## 🔍 Monitoring et Logs

### Logs d'Activité
Le service génère des logs détaillés :
```
✅ Email envoyé avec succès à user@example.com
❌ Erreur envoi email: 401 - Unauthorized
❌ Exception envoi email: SocketException
```

### Métriques Recommandées
- Taux de succès d'envoi
- Temps de réponse de l'API Gmail
- Nombre d'emails envoyés par jour
- Erreurs par type

## ⚠️ Limitations et Quotas

### Quotas Gmail API
- **Envois par jour** : 1 milliard (largement suffisant)
- **Requêtes par seconde** : 250
- **Requêtes par minute** : 15,000

### Gestion des Erreurs
- **401 Unauthorized** : Refresh token expiré
- **403 Forbidden** : Quota dépassé
- **429 Too Many Requests** : Rate limiting
- **500 Server Error** : Erreur temporaire Gmail

## 🔄 Maintenance

### Renouvellement des Tokens
Les refresh tokens Gmail n'expirent pas sauf si :
- L'utilisateur révoque l'accès
- Le token n'est pas utilisé pendant 6 mois
- L'utilisateur change son mot de passe

### Surveillance Recommandée
- Monitoring des erreurs 401/403
- Alertes sur échec d'envoi critique
- Backup des templates d'email

## 📞 Dépannage

### Problèmes Courants

#### 1. **Erreur 401 - Token Invalide**
```
Solution: Régénérer le refresh token
1. Aller sur Google Cloud Console
2. Révoquer et recréer les credentials
3. Mettre à jour le token dans l'app
```

#### 2. **Erreur 403 - Quota Dépassé**
```
Solution: Vérifier les quotas
1. Google Cloud Console > APIs & Services > Quotas
2. Augmenter les limites si nécessaire
3. Implémenter un rate limiting
```

#### 3. **Emails Non Reçus**
```
Solution: Vérifier les spams et la configuration
1. Vérifier les dossiers spam
2. Configurer SPF/DKIM pour le domaine
3. Tester avec différents fournisseurs email
```

## ✅ Checklist de Déploiement

- [ ] Variables d'environnement configurées
- [ ] Tokens Gmail valides et testés
- [ ] Templates d'email validés
- [ ] Tests d'envoi effectués
- [ ] Monitoring configuré
- [ ] Documentation mise à jour
- [ ] Équipe formée sur le système

---

**Date de création** : $(date)
**Version** : 1.0
**Auteur** : Équipe Développement Constat Tunisie
