# 🗄️ STRUCTURE BASE DE DONNÉES FIREBASE - CONSTAT TUNISIE

## 📊 COLLECTIONS PRINCIPALES

### 1. 🏢 **ASSUREURS** (`assureurs`)
```json
{
  "assureur_id": {
    "nom": "STAR Assurances",
    "code": "STAR",
    "logo_url": "https://...",
    "contact": {
      "telephone": "+216 71 123 456",
      "email": "contact@star.tn",
      "adresse": "Avenue Habib Bourguiba, Tunis"
    },
    "agences": [
      {
        "agence_id": "STAR_TUNIS_001",
        "nom": "Agence Tunis Centre",
        "adresse": "...",
        "responsable": "Ahmed Ben Ali"
      }
    ],
    "statistiques": {
      "total_contrats": 15420,
      "constats_traites": 1250,
      "montant_total_sinistres": 2500000
    },
    "created_at": "timestamp",
    "updated_at": "timestamp"
  }
}
```

### 2. 🚗 **VÉHICULES ASSURÉS** (`vehicules_assures`)
```json
{
  "vehicule_id": {
    "assureur_id": "STAR",
    "numero_contrat": "STAR-2024-001234",
    "proprietaire": {
      "nom": "Ben Ahmed",
      "prenom": "Mohamed",
      "cin": "12345678",
      "telephone": "+216 98 123 456"
    },
    "vehicule": {
      "marque": "Peugeot",
      "modele": "208",
      "annee": 2020,
      "couleur": "Blanc",
      "immatriculation": "123 TUN 456",
      "numero_chassis": "VF3...",
      "puissance_fiscale": 7
    },
    "contrat": {
      "date_debut": "2024-01-01",
      "date_fin": "2024-12-31",
      "type_couverture": "Tous Risques",
      "franchise": 200,
      "prime_annuelle": 850
    },
    "statut": "actif", // actif, suspendu, expire
    "historique_sinistres": [
      {
        "date": "2024-03-15",
        "numero_sinistre": "SIN-2024-001",
        "montant": 1500,
        "statut": "cloture"
      }
    ]
  }
}
```

### 3. 👨‍💼 **UTILISATEURS** (`users`)
```json
{
  "user_id": {
    "role": "conducteur", // conducteur, assureur, expert
    "profile": {
      "nom": "Ben Salem",
      "prenom": "Fatma",
      "email": "fatma@email.com",
      "telephone": "+216 98 765 432",
      "cin": "87654321",
      "photo_url": "https://..."
    },
    "assureur_info": { // Si role = assureur
      "assureur_id": "STAR",
      "agence_id": "STAR_TUNIS_001",
      "poste": "Agent Commercial",
      "permissions": ["view_constats", "validate_sinistres"]
    },
    "expert_info": { // Si role = expert
      "numero_agrement": "EXP-2024-001",
      "specialites": ["automobile", "incendie"],
      "zone_intervention": ["Tunis", "Ariana"]
    },
    "vehicules_assures": [ // Si role = conducteur
      "vehicule_id_1",
      "vehicule_id_2"
    ],
    "created_at": "timestamp"
  }
}
```

### 4. 📋 **CONSTATS** (`constats`)
```json
{
  "constat_id": {
    "numero_constat": "CST-2024-001234",
    "type": "collaboratif", // individuel, collaboratif
    "statut": "en_cours", // brouillon, en_cours, termine, valide, expertise
    
    "accident": {
      "date": "2024-06-22",
      "heure": "14:30",
      "lieu": {
        "adresse": "Avenue Habib Bourguiba, Tunis",
        "coordonnees": {
          "latitude": 36.8065,
          "longitude": 10.1815
        }
      },
      "conditions": {
        "meteo": "ensoleille",
        "visibilite": "bonne",
        "etat_route": "seche"
      }
    },
    
    "vehicules": [
      {
        "vehicule_id": "vehicule_1",
        "conducteur_id": "user_1",
        "assureur_id": "STAR",
        "numero_contrat": "STAR-2024-001234",
        "degats": {
          "description": "Choc avant droit",
          "gravite": "moyen",
          "photos": ["photo1.jpg", "photo2.jpg"],
          "estimation_cout": 2500
        },
        "responsabilite": 50 // Pourcentage de responsabilité
      }
    ],
    
    "analyse_ia": {
      "photos_analysees": ["photo1.jpg", "photo2.jpg"],
      "vehicules_detectes": 2,
      "degats_estimes": {
        "vehicule_1": "moyen",
        "vehicule_2": "leger"
      },
      "scenario_probable": "Collision latérale à intersection",
      "confidence_score": 0.85
    },
    
    "workflow": {
      "etape_actuelle": "remplissage", // remplissage, validation, expertise, cloture
      "historique": [
        {
          "etape": "creation",
          "date": "2024-06-22T14:35:00Z",
          "user_id": "user_1",
          "action": "Création du constat"
        }
      ]
    },
    
    "assignations": {
      "expert_id": "expert_1",
      "date_assignation": "2024-06-22T15:00:00Z",
      "priorite": "normale" // urgente, normale, faible
    }
  }
}
```

### 5. 🔍 **EXPERTISES** (`expertises`)
```json
{
  "expertise_id": {
    "constat_id": "constat_1",
    "expert_id": "expert_1",
    "statut": "en_cours", // assignee, en_cours, terminee
    
    "evaluation": {
      "date_visite": "2024-06-23",
      "lieu_expertise": "Garage Agreé XYZ",
      "vehicules_expertises": [
        {
          "vehicule_id": "vehicule_1",
          "degats_confirmes": {
            "pieces_endommagees": ["pare-choc avant", "phare droit"],
            "cout_reparation": 2800,
            "duree_immobilisation": "5 jours"
          },
          "photos_expertise": ["exp1.jpg", "exp2.jpg"]
        }
      ],
      "responsabilites": {
        "vehicule_1": 30,
        "vehicule_2": 70
      },
      "rapport_final": "Collision due à non-respect de priorité"
    },
    
    "created_at": "timestamp",
    "completed_at": "timestamp"
  }
}
```

### 6. 📊 **BUSINESS INTELLIGENCE** (`analytics`)
```json
{
  "analytics_id": {
    "periode": "2024-06", // mensuel
    "type": "assureur", // assureur, global, expert
    "assureur_id": "STAR",
    
    "kpis": {
      "nombre_constats": 125,
      "montant_sinistres": 350000,
      "delai_moyen_traitement": 5.2, // jours
      "taux_satisfaction": 4.2, // sur 5
      "fraudes_detectees": 3
    },
    
    "tendances": {
      "evolution_sinistres": [
        {"mois": "2024-01", "nombre": 98, "montant": 280000},
        {"mois": "2024-02", "nombre": 110, "montant": 320000}
      ],
      "zones_accidentogenes": [
        {"zone": "Centre Ville Tunis", "accidents": 45},
        {"zone": "Autoroute A1", "accidents": 32}
      ]
    },
    
    "predictions": {
      "sinistres_prevus_mois_prochain": 135,
      "budget_previsionnel": 380000,
      "zones_risque_eleve": ["Sfax Centre", "Sousse Nord"]
    }
  }
}
```

## 🔐 RÈGLES DE SÉCURITÉ FIRESTORE

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Règles pour les assureurs
    match /assureurs/{assureurId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && 
                      resource.data.admin_users.hasAny([request.auth.uid]);
    }
    
    // Règles pour les véhicules assurés
    match /vehicules_assures/{vehiculeId} {
      allow read: if request.auth != null && (
        request.auth.uid == resource.data.proprietaire.user_id ||
        request.auth.token.role == 'assureur' ||
        request.auth.token.role == 'expert'
      );
      allow write: if request.auth.token.role == 'assureur';
    }
    
    // Règles pour les constats
    match /constats/{constatId} {
      allow read: if request.auth != null && (
        request.auth.uid in resource.data.participants ||
        request.auth.token.role in ['assureur', 'expert']
      );
      allow write: if request.auth != null && 
                      request.auth.uid in resource.data.participants;
    }
    
    // Règles pour les analytics (BI)
    match /analytics/{analyticsId} {
      allow read: if request.auth != null && 
                     request.auth.token.role in ['assureur', 'expert', 'admin'];
      allow write: if request.auth.token.role == 'admin';
    }
  }
}
```
