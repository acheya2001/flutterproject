# 🏢 Modèle Hiérarchique du Secteur de l'Assurance

## 📊 Structure Organisationnelle

```
🏢 COMPAGNIE D'ASSURANCE (Ex: STAR, Lloyd, Maghrebia)
│
├── 🏪 AGENCES (Tunis Centre, Sfax Nord, Sousse...)
│   │
│   ├── 👨‍💼 AGENTS/CONSEILLERS
│   │   │
│   │   └── 📋 PORTEFEUILLE CLIENTS
│   │       │
│   │       ├── 👤 ASSURÉS/SOUSCRIPTEURS
│   │       └── 📄 CONTRATS (Auto, Santé, Habitation...)
│   │
│   └── 📊 STATISTIQUES AGENCE
│
└── 🏛️ SIÈGE SOCIAL
    │
    ├── 🔍 EXPERTS INDÉPENDANTS
    ├── 📈 DIRECTION TECHNIQUE
    └── 💾 SYSTÈMES CENTRAUX
```

## 🗄️ Collections Firestore Proposées

### 1. 🏢 **compagnies_assurance**
```javascript
{
  id: "STAR",
  nom: "STAR Assurances",
  siret: "123456789",
  adresse_siege: "Avenue Habib Bourguiba, Tunis",
  telephone: "+216 71 123 456",
  email: "contact@star.tn",
  logo_url: "https://...",
  agences: ["tunis_centre", "sfax_nord", "sousse"],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 2. 🏪 **agences**
```javascript
{
  id: "tunis_centre",
  compagnie_id: "STAR",
  nom: "STAR Tunis Centre",
  code_agence: "TC001",
  adresse: "Rue de la Liberté, Tunis",
  telephone: "+216 71 234 567",
  email: "tunis.centre@star.tn",
  directeur: {
    nom: "Ben Ali",
    prenom: "Mohamed",
    telephone: "+216 98 123 456"
  },
  agents: ["agent_001", "agent_002"],
  zone_geographique: ["Tunis", "Ariana", "Ben Arous"],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 3. 👨‍💼 **agents_assurance**
```javascript
{
  id: "agent_001",
  user_id: "firebase_user_id", // Lien vers users
  compagnie_id: "STAR",
  agence_id: "tunis_centre",
  matricule_agent: "AG001",
  specialites: ["auto", "habitation"],
  portefeuille_clients: ["client_001", "client_002"],
  objectifs_mensuels: {
    nouveaux_contrats: 10,
    chiffre_affaires: 50000
  },
  performance: {
    contrats_signes: 8,
    ca_realise: 45000
  },
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 4. 👤 **clients_assures**
```javascript
{
  id: "client_001",
  user_id: "firebase_user_id", // Lien vers users (si client connecté)
  compagnie_id: "STAR",
  agence_id: "tunis_centre",
  agent_referent: "agent_001",
  type_client: "particulier", // ou "entreprise"
  informations_personnelles: {
    nom: "Hammami",
    prenom: "Rahma",
    cin: "12345678",
    date_naissance: "1990-05-15",
    adresse: "Rue de la Paix, Tunis",
    telephone: "+216 98 765 432",
    email: "rahma.hammami@email.com"
  },
  contrats_actifs: ["contrat_001", "contrat_002"],
  historique_sinistres: ["sinistre_001"],
  score_client: 85, // Score de fidélité/risque
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 5. 📄 **contrats_assurance**
```javascript
{
  id: "contrat_001",
  numero_contrat: "STAR-AUTO-2024-001234",
  compagnie_id: "STAR",
  agence_id: "tunis_centre",
  agent_souscripteur: "agent_001",
  client_id: "client_001",
  type_assurance: "automobile",
  vehicule_id: "vehicule_001",
  garanties: {
    responsabilite_civile: true,
    tous_risques: true,
    vol: true,
    incendie: true,
    bris_de_glace: false
  },
  montants: {
    prime_annuelle: 1200.00,
    franchise: 200.00,
    plafond_garantie: 50000.00
  },
  periode: {
    date_debut: "2024-01-01",
    date_fin: "2024-12-31",
    duree_mois: 12
  },
  statut: "actif", // actif, suspendu, résilié, expiré
  mode_paiement: "annuel", // annuel, semestriel, trimestriel
  documents: ["police_assurance.pdf", "conditions_generales.pdf"],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### 6. 🔍 **experts_independants**
```javascript
{
  id: "expert_001",
  user_id: "firebase_user_id", // Lien vers users
  cabinet: "Cabinet Expertise Auto Tunisie",
  numero_agrement: "EXP-2024-001",
  specialites: ["automobile", "habitation", "industriel"],
  zone_intervention: ["Grand Tunis", "Sfax", "Sousse"],
  compagnies_partenaires: ["STAR", "MAGHREBIA", "LLOYD"],
  tarifs: {
    expertise_auto: 150.00,
    expertise_habitation: 200.00,
    deplacement_km: 0.50
  },
  disponibilite: true,
  expertises_en_cours: ["expertise_001", "expertise_002"],
  rating: 4.8,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

## 🔗 Relations et Hiérarchie

### **Flux de données typique :**

1. **Client** → contacte son **Agent**
2. **Agent** → appartient à une **Agence**
3. **Agence** → fait partie d'une **Compagnie**
4. **Contrat** → lie Client + Véhicule + Compagnie
5. **Sinistre** → déclenche intervention **Expert**

### **Permissions par rôle :**

| Rôle | Accès Données |
|------|---------------|
| **Client/Assuré** | Ses contrats, ses sinistres, ses véhicules |
| **Agent** | Son portefeuille clients, contrats de son agence |
| **Directeur Agence** | Tous les clients/contrats de son agence |
| **Assureur (Siège)** | Toutes les données de la compagnie |
| **Expert** | Dossiers qui lui sont assignés |

## 🎯 Avantages de cette Structure

✅ **Réalisme métier** : Reflète la vraie organisation des assurances
✅ **Scalabilité** : Peut gérer plusieurs compagnies/agences
✅ **Sécurité** : Permissions granulaires par niveau hiérarchique
✅ **Traçabilité** : Chaque action est liée à un agent/agence
✅ **Analytics** : Statistiques par agence, agent, région
✅ **Workflow** : Processus métier respectés

## 🚀 Prochaines Étapes

1. **Créer les modèles Dart** pour ces collections
2. **Adapter les règles Firestore** à cette hiérarchie
3. **Modifier l'interface utilisateur** selon le rôle
4. **Générer des données de test** réalistes
5. **Implémenter les workflows métier**
