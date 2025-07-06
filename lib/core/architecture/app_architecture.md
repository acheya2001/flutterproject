# 🏗️ Architecture Moderne de l'Application d'Assurance

## 📁 Structure des Dossiers Professionnelle

```
lib/
├── core/                           # 🔧 Fonctionnalités centrales
│   ├── config/                     # Configuration app
│   ├── constants/                  # Constantes globales
│   ├── services/                   # Services partagés
│   ├── utils/                      # Utilitaires
│   ├── widgets/                    # Widgets réutilisables
│   ├── theme/                      # Thèmes et styles
│   └── errors/                     # Gestion d'erreurs
│
├── features/                       # 🎯 Fonctionnalités métier
│   ├── auth/                       # 🔐 Authentification
│   │   ├── data/                   # Sources de données
│   │   ├── domain/                 # Logique métier
│   │   ├── presentation/           # UI et états
│   │   └── models/                 # Modèles de données
│   │
│   ├── admin/                      # 👨‍💼 Administration
│   │   ├── super_admin/            # Super administrateur
│   │   ├── company_admin/          # Admin compagnie
│   │   ├── agency_admin/           # Admin agence
│   │   └── shared/                 # Composants partagés admin
│   │
│   ├── agent/                      # 🏢 Agents d'assurance
│   │   ├── contracts/              # Gestion contrats
│   │   ├── clients/                # Gestion clients
│   │   ├── vehicles/               # Gestion véhicules
│   │   └── attestations/           # Génération attestations
│   │
│   ├── driver/                     # 🚗 Conducteurs/Clients
│   │   ├── profile/                # Profil conducteur
│   │   ├── vehicles/               # Mes véhicules
│   │   ├── contracts/              # Mes contrats
│   │   ├── claims/                 # Déclarations sinistres
│   │   └── documents/              # Mes documents
│   │
│   ├── expert/                     # 🔍 Experts
│   │   ├── evaluations/            # Évaluations
│   │   ├── reports/                # Rapports
│   │   └── assignments/            # Affectations
│   │
│   ├── insurance/                  # 🏛️ Système d'assurance
│   │   ├── companies/              # Compagnies
│   │   ├── agencies/               # Agences
│   │   ├── contracts/              # Contrats
│   │   └── policies/               # Polices
│   │
│   ├── claims/                     # 📋 Gestion sinistres
│   │   ├── declaration/            # Déclaration
│   │   ├── processing/             # Traitement
│   │   ├── expertise/              # Expertise
│   │   └── settlement/             # Règlement
│   │
│   ├── documents/                  # 📄 Gestion documents
│   │   ├── generation/             # Génération
│   │   ├── storage/                # Stockage
│   │   └── sharing/                # Partage
│   │
│   ├── notifications/              # 🔔 Notifications
│   │   ├── push/                   # Push notifications
│   │   ├── email/                  # Email
│   │   └── in_app/                 # In-app
│   │
│   └── messaging/                  # 💬 Messagerie
│       ├── chat/                   # Chat temps réel
│       ├── collaboration/          # Collaboration
│       └── invitations/            # Invitations
│
├── shared/                         # 🤝 Composants partagés
│   ├── models/                     # Modèles communs
│   ├── widgets/                    # Widgets partagés
│   ├── services/                   # Services partagés
│   └── utils/                      # Utilitaires partagés
│
└── main.dart                       # 🚀 Point d'entrée
```

## 🎯 Principes Architecturaux

### 1. Clean Architecture
- **Domain Layer**: Logique métier pure
- **Data Layer**: Sources de données (Firebase, API)
- **Presentation Layer**: UI et gestion d'état

### 2. Feature-First Organization
- Chaque fonctionnalité est autonome
- Réutilisabilité maximale
- Maintenance facilitée

### 3. Separation of Concerns
- Responsabilités bien définies
- Couplage faible
- Cohésion forte

## 🔧 Technologies Utilisées

- **State Management**: Riverpod
- **Backend**: Firebase (Auth, Firestore, Storage, Functions)
- **Navigation**: GoRouter
- **Dependency Injection**: get_it
- **Code Generation**: freezed, json_annotation

## 📊 Flux de Données

```
UI → Provider → Repository → DataSource → Firebase
   ←          ←            ←           ←
```

## 🛡️ Sécurité

- Authentification Firebase
- Règles Firestore strictes
- Validation côté client et serveur
- Chiffrement des données sensibles
