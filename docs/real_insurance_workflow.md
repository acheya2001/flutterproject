# 🏢 Workflow Réel du Système d'Assurance

## 🎯 Vision Professionnelle

### **Étapes du Processus Réel :**

1. **👤 Client physique** → Se rend dans une agence d'assurance
2. **🏢 Agent d'assurance** → Crée le contrat + enregistre le véhicule
3. **📧 Liaison numérique** → Agent donne accès au conducteur via email
4. **📱 Application mobile** → Conducteur accède à SES véhicules
5. **🚨 Déclaration accident** → Recherche véhicule tiers par assurance/contrat

---

## 👥 Rôles et Responsabilités

### 🔑 **ADMIN (Super Utilisateur)**
- ✅ Valider les inscriptions des agents d'assurance
- ✅ Gérer les compagnies d'assurance autorisées  
- ✅ Superviser le système global
- ✅ Modérer les conflits entre utilisateurs
- ✅ Accès aux statistiques globales
- ✅ Gestion des paramètres système
- ✅ Approuver/Rejeter les demandes d'inscription

### 🏢 **AGENT D'ASSURANCE**
- ✅ S'inscrire avec validation admin
- ✅ Indiquer son agence et zone géographique
- ✅ Ajouter/Modifier/Supprimer des clients assurés
- ✅ Créer des contrats véhicules
- ✅ Affecter véhicules aux conducteurs via email
- ✅ Gérer son portefeuille clients
- ✅ Vérifier les sinistres de ses clients

### 🚗 **CONDUCTEUR**
- ✅ S'inscrire normalement
- ✅ Voir SES véhicules (affectés par les assureurs)
- ✅ Déclarer des accidents
- ✅ Rechercher véhicules tiers (assurance/contrat/immatriculation)
- ✅ Participer aux sessions collaboratives

### 🔍 **EXPERT**
- ✅ S'inscrire avec validation admin
- ✅ Recevoir des missions d'expertise
- ✅ Évaluer les dommages
- ✅ Rédiger des rapports d'expertise

---

## 🔄 Flux de Données

### **1. Création d'un Contrat Véhicule :**
```
Agent → Crée Client → Crée Véhicule → Crée Contrat → Affecte au Conducteur (email)
```

### **2. Accès Conducteur :**
```
Conducteur connecté → Voit UNIQUEMENT ses véhicules affectés
```

### **3. Déclaration Accident :**
```
Conducteur → Sélectionne SON véhicule → Recherche véhicule TIERS → Déclare accident
```

### **4. Recherche Véhicule Tiers :**
```
Interface : [Assurance ▼] [N° Contrat] [Immatriculation] [🔍 Chercher]
```

---

## 🗄️ Structure Base de Données

### **Nouvelles Collections :**

#### 👨‍💼 **admins**
```javascript
{
  id: "admin_001",
  user_id: "firebase_user_id",
  niveau_acces: "super_admin", // super_admin, admin_regional
  zone_responsabilite: ["Tunis", "Ariana"], // Pour admin régional
  permissions: ["validate_agents", "manage_companies", "view_stats"],
  createdAt: timestamp,
  updatedAt: timestamp
}
```

#### 🏢 **agents_validation**
```javascript
{
  id: "validation_001",
  user_id: "firebase_user_id",
  compagnie_demandee: "STAR",
  agence_demandee: "tunis_centre",
  zone_geographique: ["Tunis", "Manouba", "Nabeul"],
  delegation: "Centre Ville",
  documents: ["carte_agent.pdf", "attestation_travail.pdf"],
  statut: "en_attente", // en_attente, approuve, rejete
  admin_validateur: "admin_001",
  date_validation: timestamp,
  commentaire_admin: "Documents conformes",
  createdAt: timestamp
}
```

#### 🚗 **vehicules_conducteurs** (Liaison)
```javascript
{
  id: "liaison_001",
  vehicule_id: "vehicule_001",
  conducteur_email: "rahma@email.com",
  conducteur_id: "conducteur_001", // Rempli quand conducteur s'inscrit
  agent_affecteur: "agent_001",
  date_affectation: timestamp,
  statut: "actif", // actif, suspendu, expire
  droits: ["conduire", "declarer_sinistre"], // Permissions spécifiques
  createdAt: timestamp
}
```

#### 🔍 **recherches_vehicules**
```javascript
{
  id: "recherche_001",
  conducteur_rechercheur: "conducteur_001",
  criteres: {
    assurance: "STAR",
    numero_contrat: "STAR-2024-001234",
    immatriculation: "123 TUN 456"
  },
  resultat_trouve: true,
  vehicule_trouve: "vehicule_002",
  date_recherche: timestamp,
  contexte: "declaration_accident" // declaration_accident, verification
}
```

---

## 🎨 Interfaces Utilisateur

### **1. Interface Agent - Affectation Véhicule :**
```
┌─────────────────────────────────────┐
│ 🚗 Affecter Véhicule au Conducteur │
├─────────────────────────────────────┤
│ Email conducteur: [____________]    │
│ Véhicule: [Peugeot 208 - 123TUN456] │
│ Droits: ☑️ Conduire ☑️ Déclarer     │
│ [📧 Envoyer Invitation]            │
└─────────────────────────────────────┘
```

### **2. Interface Conducteur - Mes Véhicules :**
```
┌─────────────────────────────────────┐
│ 🚗 Mes Véhicules                   │
├─────────────────────────────────────┤
│ 🚙 Peugeot 208 - 123TUN456         │
│    STAR Assurance - Agent: Ali     │
│    [📋 Déclarer Accident]          │
├─────────────────────────────────────┤
│ 🚗 Renault Clio - 789TUN012        │
│    Maghrebia - Agent: Fatma        │
│    [📋 Déclarer Accident]          │
└─────────────────────────────────────┘
```

### **3. Interface Recherche Véhicule Tiers :**
```
┌─────────────────────────────────────┐
│ 🔍 Identifier Véhicule Tiers       │
├─────────────────────────────────────┤
│ Assurance: [STAR        ▼]         │
│ N° Contrat: [_______________]       │
│ Immatriculation: [_______________]  │
│ [🔍 Chercher Véhicule]             │
├─────────────────────────────────────┤
│ ✅ Véhicule trouvé:                │
│ 🚗 Toyota Corolla - 456TUN789      │
│ Propriétaire: Mohamed Ben Ali       │
│ [✅ Confirmer ce véhicule]         │
└─────────────────────────────────────┘
```

---

## 🚀 Prochaines Étapes

1. **Créer le rôle Admin** avec interface de validation
2. **Modifier l'inscription Agent** avec demande de validation
3. **Créer le système d'affectation** véhicule → conducteur
4. **Implémenter la recherche** véhicule tiers
5. **Adapter l'interface conducteur** pour voir uniquement SES véhicules
6. **Créer le workflow** de déclaration d'accident avec recherche

---

## ✅ Avantages de cette Approche

- ✅ **Réalisme professionnel** : Reflète le vrai processus d'assurance
- ✅ **Sécurité renforcée** : Validation admin obligatoire
- ✅ **Traçabilité complète** : Chaque action est enregistrée
- ✅ **Workflow naturel** : Correspond aux habitudes métier
- ✅ **Évolutivité** : Peut s'adapter à différentes compagnies
- ✅ **Contrôle qualité** : Évite les faux comptes et abus
