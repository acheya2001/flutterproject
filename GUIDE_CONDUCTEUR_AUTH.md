# 📖 Guide d'Utilisation - Authentification Conducteur

## 🎯 Objectif
Ce guide explique comment utiliser le nouveau système d'authentification pour les conducteurs dans l'application Constat Tunisie.

## 📋 Fonctionnalités Implémentées

### 1. Inscription Conducteur
**Fichier**: `lib/features/auth/screens/conducteur_register_screen.dart`

**Champs requis**:
- 📛 Nom (obligatoire)
- 📛 Prénom (obligatoire)
- 🆔 Numéro CIN (8 chiffres, obligatoire)
- 📞 Téléphone (obligatoire)
- 📧 Email (format valide, obligatoire)
- 🔒 Mot de passe (min 6 caractères, obligatoire)
- 🔒 Confirmation mot de passe (doit correspondre)

**Validation**:
- Vérification format email
- Vérification longueur CIN (8 chiffres)
- Vérification longueur mot de passe (6+ caractères)
- Confirmation mot de passe

### 2. Connexion Conducteur
**Fichier**: `lib/features/auth/screens/conducteur_login_screen.dart`

**Fonctionnalités**:
- Connexion avec email/mot de passe
- Gestion des erreurs Firebase
- Redirection vers tableau de bord
- Lien vers inscription si pas de compte

### 3. Service d'Authentification
**Fichier**: `lib/services/conducteur_auth_service.dart`

**Méthodes disponibles**:
```dart
// Inscription
ConducteurAuthService.registerConducteur({
  nom: String,
  prenom: String,
  cin: String,
  telephone: String,
  email: String,
  password: String,
})

// Connexion
ConducteurAuthService.loginConducteur({
  email: String,
  password: String,
})

// Déconnexion
ConducteurAuthService.logout()

// Récupération données
ConducteurAuthService.getConducteurData(userId: String)
```

## 🚀 Utilisation

### 1. Inscription
```dart
// Navigation vers l'écran d'inscription
Navigator.pushNamed(context, AppRoutes.conducteurRegister);

// Ou utilisation directe du service
final result = await ConducteurAuthService.registerConducteur(
  nom: 'Nom',
  prenom: 'Prénom',
  cin: '12345678',
  telephone: '+21612345678',
  email: 'test@example.com',
  password: 'password123',
);
```

### 2. Connexion
```dart
// Navigation vers l'écran de connexion
Navigator.pushNamed(context, AppRoutes.conducteurLogin);

// Ou utilisation directe du service
final result = await ConducteurAuthService.loginConducteur(
  email: 'test@example.com',
  password: 'password123',
);
```

### 3. Gestion des États
Le service retourne un Map avec:
- `success`: booléen indiquant le succès
- `userId`: ID de l'utilisateur (si succès)
- `error`: message d'erreur (si échec)
- `conducteurData`: données du conducteur (si connexion)

## 🎨 Interface Utilisateur

### Écran d'Inscription
- Design moderne et adapté au marché tunisien
- Validation en temps réel
- Messages d'erreur clairs
- Indicateur de chargement

### Écran de Connexion
- Interface simple et intuitive
- Gestion des erreurs utilisateur
- Lien vers inscription et mot de passe oublié

## 🔧 Configuration

### Routes Ajoutées
```dart
static const String conducteurRegister = '/conducteur/register';
static const String conducteurLogin = '/conducteur/login';
```

### Dépendances
Aucune nouvelle dépendance n'a été ajoutée pour cette phase.

## 🧪 Tests
**Fichier**: `test/conducteur_auth_test.dart`

Tests unitaires disponibles pour:
- Inscription réussie
- Connexion réussie
- Gestion compte en attente
- Récupération données

## 📊 Structure des Données

### Collection Firestore: `conducteurs`
```json
{
  "userId": "string",
  "nom": "string",
  "prenom": "string",
  "cin": "string",
  "telephone": "string",
  "email": "string",
  "status": "pending|active|suspended",
  "createdAt": "timestamp",
  "updatedAt": "timestamp",
  "vehiculeIds": ["string"],
  "contratIds": ["string"]
}
```

## ⚠️ Notes Importantes

1. **Statut "Pending"**: Les nouveaux comptes sont créés avec le statut "pending" et doivent être validés par un agent.

2. **Validation CIN**: Le CIN doit contenir exactement 8 chiffres.

3. **Mot de passe**: Minimum 6 caractères requis.

4. **Téléphone**: Format tunisien recommandé (+216 XXXXXXXX).

5. **Sécurité**: Les mots de passe sont hashés par Firebase Auth.

## 🔄 Prochaines Étapes

1. Intégration sélection compagnie/agence
2. Scan QR code pour agence
3. Mode hors-ligne
4. Validation automatique CIN
5. Notifications push

## 📞 Support
Pour toute question ou problème, contactez l'équipe de développement.
