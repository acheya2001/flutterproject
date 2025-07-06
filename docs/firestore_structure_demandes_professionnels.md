# 📋 Structure Firestore - Demandes de Comptes Professionnels

## 🗂️ Collection: `/demandes_professionnels/{demandeId}`

Chaque document représente une demande unique de création de compte professionnel.

---

## 🔖 Champs Communs à Toutes les Demandes

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `nom_complet` | `string` | ✅ | Nom et prénom du demandeur |
| `email` | `string` | ✅ | Email professionnel |
| `tel` | `string` | ✅ | Numéro de téléphone |
| `cin` | `string` | ✅ | Numéro de carte d'identité ou passeport |
| `role_demande` | `string` | ✅ | Type de compte demandé |
| `status` | `string` | ✅ | Statut de la demande |
| `envoye_le` | `timestamp` | ✅ | Date de soumission |
| `commentaire_admin` | `string` | ❌ | Remarque admin |

### Valeurs possibles pour `role_demande`:
- `"agent_agence"` - Agent d'agence
- `"expert_auto"` - Expert automobile  
- `"admin_compagnie"` - Admin compagnie
- `"admin_agence"` - Admin agence

### Valeurs possibles pour `status`:
- `"en_attente"` - En attente de traitement
- `"acceptee"` - Demande acceptée
- `"rejetee"` - Demande rejetée

---

## 🔸 Champs de Traitement

| Champ | Type | Description |
|-------|------|-------------|
| `traite_par_uid` | `string` | UID de l'admin qui a traité |
| `traite_le` | `timestamp` | Date de traitement |

---

## 🎯 Champs Spécifiques par Rôle

### 🧍‍💼 1. Agent d'agence (`role_demande: "agent_agence"`)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `nom_agence` | `string` | ✅ | Nom de l'agence |
| `compagnie` | `string` | ✅ | Compagnie d'assurance |
| `adresse_agence` | `string` | ✅ | Adresse de l'agence |
| `matricule_interne` | `string` | ❌ | Matricule interne |

### 🧑‍🔧 2. Expert Auto (`role_demande: "expert_auto"`)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `num_agrement` | `string` | ✅ | Numéro d'agrément professionnel |
| `compagnie` | `string` | ✅ | Compagnie d'assurance liée |
| `zone_intervention` | `string` | ✅ | Gouvernorat d'intervention |
| `experience_annees` | `int` | ❌ | Années d'expérience |
| `nom_agence` | `string` | ❌ | Agence si intégré |

### 🧑‍💼 3. Admin Compagnie (`role_demande: "admin_compagnie"`)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `nom_compagnie` | `string` | ✅ | Nom de la compagnie |
| `fonction` | `string` | ✅ | Poste/Fonction |
| `adresse_siege` | `string` | ✅ | Adresse siège social |
| `num_autorisation` | `string` | ❌ | Numéro autorisation |

### 🏢 4. Admin Agence (`role_demande: "admin_agence"`)

| Champ | Type | Obligatoire | Description |
|-------|------|-------------|-------------|
| `nom_agence` | `string` | ✅ | Nom de l'agence |
| `compagnie` | `string` | ✅ | Compagnie d'assurance |
| `ville` | `string` | ✅ | Ville/Gouvernorat |
| `adresse_agence` | `string` | ✅ | Adresse de l'agence |
| `tel_agence` | `string` | ❌ | Téléphone agence |

---

## 📋 Exemples de Documents

### 🧍‍💼 Agent d'agence
```json
{
  "nom_complet": "Karim Jlassi",
  "email": "karim@star.tn",
  "tel": "21699322144",
  "cin": "09345122",
  "role_demande": "agent_agence",
  "status": "en_attente",
  "envoye_le": "2025-07-04T14:45:00Z",
  
  "nom_agence": "Agence El Menzah 6",
  "compagnie": "STAR Assurances",
  "adresse_agence": "Av. Hédi Nouira, Tunis",
  "matricule_interne": "AG455"
}
```

### 🧑‍🔧 Expert Auto
```json
{
  "nom_complet": "Ahmed Ben Salem",
  "email": "ahmed.expert@gmail.com",
  "tel": "21698765432",
  "cin": "08123456",
  "role_demande": "expert_auto",
  "status": "en_attente",
  "envoye_le": "2025-07-04T15:30:00Z",
  
  "num_agrement": "EXP2024001",
  "compagnie": "Maghrebia Assurances",
  "zone_intervention": "Tunis",
  "experience_annees": 8,
  "nom_agence": "Agence Lac 2"
}
```

### 🧑‍💼 Admin Compagnie
```json
{
  "nom_complet": "Fatma Trabelsi",
  "email": "fatma@gat.tn",
  "tel": "21671234567",
  "cin": "07987654",
  "role_demande": "admin_compagnie",
  "status": "en_attente",
  "envoye_le": "2025-07-04T16:15:00Z",
  
  "nom_compagnie": "GAT Assurances",
  "fonction": "Directrice Régionale",
  "adresse_siege": "Avenue Habib Bourguiba, Tunis",
  "num_autorisation": "AUTH2024GAT"
}
```

### 🏢 Admin Agence
```json
{
  "nom_complet": "Mohamed Bouazizi",
  "email": "mohamed@comar-sfax.tn",
  "tel": "21674555666",
  "cin": "06111222",
  "role_demande": "admin_agence",
  "status": "en_attente",
  "envoye_le": "2025-07-04T17:00:00Z",
  
  "nom_agence": "Agence Comar Sfax Centre",
  "compagnie": "Comar Assurances",
  "ville": "Sfax",
  "adresse_agence": "Rue Mongi Slim, Sfax",
  "tel_agence": "74123456"
}
```

### ✅ Demande Acceptée
```json
{
  "nom_complet": "Sarra Mansouri",
  "email": "sarra@lloyd.tn",
  "tel": "21695123456",
  "cin": "05789123",
  "role_demande": "agent_agence",
  "status": "acceptee",
  "envoye_le": "2025-07-01T10:00:00Z",
  "traite_par_uid": "super_admin_uid",
  "traite_le": "2025-07-03T14:30:00Z",
  "commentaire_admin": "Dossier complet, compte créé avec succès",
  
  "nom_agence": "Agence Lloyd Sousse",
  "compagnie": "Lloyd Tunisien",
  "adresse_agence": "Avenue Léopold Sédar Senghor, Sousse"
}
```

### ❌ Demande Rejetée
```json
{
  "nom_complet": "Ali Rejeb",
  "email": "ali.rejeb@email.com",
  "tel": "21692999888",
  "cin": "04567890",
  "role_demande": "expert_auto",
  "status": "rejetee",
  "envoye_le": "2024-12-30T09:00:00Z",
  "traite_par_uid": "super_admin_uid",
  "traite_le": "2025-07-02T11:15:00Z",
  "commentaire_admin": "Numéro d'agrément invalide. Veuillez fournir un agrément valide.",
  
  "num_agrement": "INVALID123",
  "compagnie": "STAR Assurances",
  "zone_intervention": "Bizerte"
}
```

---

## 🗄️ Index Firestore Recommandés

Pour des requêtes performantes:

```
Collection: demandes_professionnels
Index composés:
  - role_demande + status
  - compagnie + status  
  - status + envoye_le (desc)
  - traite_par_uid + traite_le (desc)
```

---

## 🔒 Règles de Sécurité Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /demandes_professionnels/{demandeId} {
      // Lecture: Seuls les admins
      allow read: if request.auth != null && 
                     request.auth.token.role in ['super_admin', 'admin_compagnie'];
      
      // Écriture: Création par utilisateurs, modification par admins
      allow create: if request.auth != null;
      allow update: if request.auth != null && 
                       request.auth.token.role in ['super_admin', 'admin_compagnie'];
      
      // Suppression: Seuls super admins
      allow delete: if request.auth != null && 
                       request.auth.token.role == 'super_admin';
    }
  }
}
```

---

## 📊 Compagnies d'Assurance Prédéfinies

- STAR Assurances
- Maghrebia Assurances  
- Assurances Salim
- GAT Assurances
- Comar Assurances
- Lloyd Tunisien
- Zitouna Takaful
- Attijari Assurance

## 📍 Gouvernorats de Tunisie

Tunis, Ariana, Ben Arous, Manouba, Nabeul, Zaghouan, Bizerte, Béja, Jendouba, Kef, Siliana, Sousse, Monastir, Mahdia, Sfax, Kairouan, Kasserine, Sidi Bouzid, Gabès, Medenine, Tataouine, Gafsa, Tozeur, Kebili
