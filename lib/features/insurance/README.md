# 🛡️ Système d'Assurance - Constat Tunisie

## 📋 Vue d'ensemble

Le système d'assurance permet aux agents d'assurance de créer des contrats pour les conducteurs et aux conducteurs de visualiser leurs véhicules assurés. Le système inclut des notifications automatiques et une interface utilisateur moderne.

## 🏗️ Architecture

```
lib/features/insurance/
├── models/
│   └── insurance_contract.dart      # Modèles de données
├── services/
│   ├── contract_service.dart        # Gestion des contrats
│   └── notification_service.dart    # Notifications
├── screens/
│   ├── insurance_dashboard.dart     # Tableau de bord agent
│   ├── create_contract_screen.dart  # Création de contrat
│   ├── contracts_list_screen.dart   # Liste des contrats
│   └── search_driver_screen.dart    # Recherche conducteur
├── widgets/
│   ├── stats_card.dart             # Cartes statistiques
│   ├── quick_action_card.dart      # Actions rapides
│   └── insurance_navigation.dart    # Navigation et utilitaires
└── example_integration.dart         # Exemple d'intégration
```

## 🚀 Fonctionnalités

### Pour les Agents d'Assurance

#### 🏠 Tableau de Bord
- **Statistiques** : Total contrats, contrats actifs, contrats du mois
- **Actions rapides** : Nouveau contrat, recherche conducteur, liste contrats
- **Contrats récents** : Aperçu des derniers contrats créés

#### 📝 Création de Contrat
- **Étape 1** : Informations du contrat (numéro, email conducteur, compagnie, dates)
- **Étape 2** : Informations du véhicule (immatriculation, marque, modèle, etc.)
- **Étape 3** : Garanties et finalisation (type contrat, prime, garanties)

#### 🔍 Recherche de Conducteur
- Recherche par email
- Vérification de l'existence du compte
- Création directe de contrat

#### 📋 Gestion des Contrats
- Liste complète des contrats
- Filtrage par statut (actif, expiré, bientôt expiré)
- Recherche par immatriculation/conducteur
- Renouvellement de contrats

### Pour les Conducteurs

#### 🚗 Mes Véhicules
- Liste des véhicules assurés
- Statut d'assurance (actif, expiré, bientôt expiré)
- Détails du contrat d'assurance
- Contact avec l'agent

#### 🔔 Notifications
- Notification de nouveau contrat
- Email de confirmation
- Notifications push (FCM)

## 🛠️ Installation et Configuration

### 1. Dépendances

Ajoutez ces dépendances dans `pubspec.yaml` :

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  http: ^1.1.0
```

### 2. Configuration Firebase

#### Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Utilisateurs
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Contrats d'assurance
    match /contracts/{contractId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.createdBy || 
         request.auth.uid == resource.data.conducteurId);
    }
    
    // Véhicules
    match /vehicules/{vehiculeId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.conducteurId;
    }
    
    // Notifications
    match /notifications/{notificationId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == resource.data.userId;
    }
  }
}
```

### 3. Structure de Données Firestore

#### Collection `users`
```json
{
  "email": "conducteur@email.com",
  "nom": "Nom",
  "prenom": "Prénom",
  "telephone": "+216 XX XXX XXX",
  "role": "conducteur", // ou "assureur"
  "fcmToken": "token_fcm",
  "createdAt": "timestamp"
}
```

#### Collection `contracts`
```json
{
  "numeroContrat": "STAR-2025-001234",
  "conducteurId": "user_id",
  "conducteurEmail": "conducteur@email.com",
  "compagnie": {
    "nom": "STAR",
    "code": "STA",
    "adresse": "Adresse",
    "telephone": "+216 71 123 456",
    "email": "contact@star.tn",
    "logo": "assets/logos/star.png"
  },
  "vehicule": {
    "immatriculation": "225 TUN 2215",
    "marque": "Peugeot",
    "modele": "308",
    "annee": 2020,
    "couleur": "Blanc"
  },
  "dateDebut": "timestamp",
  "dateFin": "timestamp",
  "prime": 1200.0,
  "typeContrat": "Tous Risques",
  "garanties": ["Responsabilité Civile", "Vol et Incendie"],
  "status": "active",
  "createdAt": "timestamp"
}
```

## 🎯 Utilisation

### 1. Intégration dans l'App Principale

```dart
import 'package:flutter/material.dart';
import 'features/insurance/widgets/insurance_navigation.dart';

class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Autres widgets...
          
          // Bouton d'accès à l'assurance
          InsuranceNavigation.buildInsuranceAccessButton(context),
          
          // Ou carte d'assurance
          InsuranceNavigation.buildInsuranceCard(context),
        ],
      ),
    );
  }
}
```

### 2. Navigation Basée sur le Rôle

```dart
// Navigation automatique selon le rôle
await InsuranceNavigation.navigateBasedOnRole(context);

// Navigation directe
InsuranceNavigation.navigateToInsuranceDashboard(context); // Agent
InsuranceNavigation.navigateToMyVehicles(context);         // Conducteur
```

### 3. Création de Contrat

```dart
final contract = InsuranceContract(
  numeroContrat: 'STAR-2025-001234',
  compagnie: CompagnieAssurance(/* ... */),
  vehicule: VehiculeAssure(/* ... */),
  // ...
);

final result = await ContractService.createAndAssignContract(
  contract: contract,
  conducteurEmail: 'conducteur@email.com',
);
```

### 4. Notifications

```dart
// Envoyer une notification
await InsuranceNotificationService.sendContractNotification(
  conducteurEmail: 'conducteur@email.com',
  numeroContrat: 'STAR-2025-001234',
  vehiculeImmatriculation: '225 TUN 2215',
  compagnieNom: 'STAR',
  agentNom: 'Agent Test',
);

// Écouter les notifications
InsuranceNotificationService.getUserNotifications(userId).listen((notifications) {
  // Traiter les notifications
});
```

## 🎨 Personnalisation

### Couleurs et Styles

```dart
// Utiliser les couleurs du thème
Container(
  color: InsuranceNavigation.InsuranceColors.primary,
  child: Text(
    'Titre',
    style: InsuranceNavigation.InsuranceStyles.titleLarge,
  ),
)
```

### Utilitaires

```dart
// Formater un montant
String amount = InsuranceNavigation.InsuranceUtils.formatAmount(1200.0);

// Vérifier expiration
bool expiring = InsuranceNavigation.InsuranceUtils.isExpiringSoon(endDate);

// Obtenir couleur de statut
Color color = InsuranceNavigation.InsuranceUtils.getStatusColor(true, false);
```

## 🔧 Configuration Avancée

### 1. Email Service (Gmail API)

Configurez le service d'email dans `notification_service.dart` :

```dart
// Remplacez YOUR_FCM_SERVER_KEY par votre clé serveur FCM
const String serverKey = 'YOUR_FCM_SERVER_KEY';
```

### 2. Notifications Push

Configurez FCM dans votre projet Firebase et ajoutez les fichiers de configuration.

### 3. Personnalisation des Templates

Modifiez les templates d'email dans `notification_service.dart` selon vos besoins.

## 🐛 Dépannage

### Problèmes Courants

1. **Erreur de permissions Firestore** : Vérifiez les règles de sécurité
2. **Notifications non reçues** : Vérifiez la configuration FCM
3. **Erreur de navigation** : Vérifiez l'authentification utilisateur

### Logs de Debug

Activez les logs pour le debugging :

```dart
print('🔔 [NOTIFICATION] Message de debug');
print('📋 [CONTRACT] État du contrat');
```

## 📞 Support

Pour toute question ou problème, consultez la documentation Firebase ou contactez l'équipe de développement.
