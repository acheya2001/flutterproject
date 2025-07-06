# 🏢 Guide de Configuration - Hiérarchie des Assurances Tunisiennes

## 🎯 **Problème Résolu : Gestion Multi-Niveaux**

Vous avez maintenant un système complet pour gérer la hiérarchie des assurances tunisiennes :

```
🏢 Compagnie (STAR, GAT, BH, MAGHREBIA, LLOYD)
├── 🗺️ Gouvernorat (Tunis, Manouba, Ariana, etc.)
│   ├── 🏪 Agence 1 (Centre Ville)
│   │   ├── 👨‍💼 Agent 1 (Ahmed Ben Ali)
│   │   └── 👨‍💼 Agent 2 (Fatma Trabelsi)
│   ├── 🏪 Agence 2 (Bab Bhar)
│   └── 🏪 Agence n
└── 🗺️ Gouvernorat n
```

---

## 🚀 **Mise en Place Rapide**

### **Étape 1 : Initialiser la Hiérarchie**

1. **Ajoutez temporairement dans votre menu :**
   ```dart
   ListTile(
     leading: Icon(Icons.account_tree),
     title: Text('🏗️ Configuration Hiérarchie'),
     onTap: () => Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => HierarchySetupScreen(),
       ),
     ),
   ),
   ```

2. **Lancez l'initialisation :**
   - Ouvrez l'écran de configuration
   - Cliquez "Initialiser la Hiérarchie"
   - Attendez la création complète (quelques minutes)

### **Étape 2 : Vérifier la Structure**

La hiérarchie créée inclut :
- ✅ **5 Compagnies** : STAR, GAT, BH, MAGHREBIA, LLOYD
- ✅ **24 Gouvernorats** par compagnie (tous les gouvernorats tunisiens)
- ✅ **2-3 Agences** par gouvernorat
- ✅ **2 Agents** par agence

---

## 🏗️ **Structure Firebase Créée**

### **Collections Principales :**

```
insurance_companies/
├── STAR/
│   ├── gouvernorats/
│   │   ├── Tunis/
│   │   │   ├── agences/
│   │   │   │   ├── STAR_Tunis_AGE1/
│   │   │   │   │   └── agents/
│   │   │   │   │       ├── STAR_Tunis_AGE1_AGT001/
│   │   │   │   │       └── STAR_Tunis_AGE1_AGT002/
│   │   │   │   └── STAR_Tunis_AGE2/
│   │   │   └── Manouba/
│   │   └── ...
├── GAT/
├── BH/
├── MAGHREBIA/
└── LLOYD/
```

---

## 🔧 **Utilisation dans l'Application**

### **1. Sélection Hiérarchique lors de la Création de Contrats :**

```dart
// Dans create_contract_screen.dart
HierarchySelector(
  onSelectionChanged: (selection) {
    // selection contient :
    // - companyId, gouvernoratId, agenceId, agentId
    // - companyData, gouvernoratData, agenceData, agentData
  },
)
```

### **2. Filtrage par Hiérarchie :**

```dart
// Obtenir les agences d'un gouvernorat
final agences = await InsuranceHierarchyService.getAgences(
  'STAR',      // companyId
  'Tunis',     // gouvernoratId
);

// Obtenir les agents d'une agence
final agents = await InsuranceHierarchyService.getAgents(
  'STAR',           // companyId
  'Tunis',          // gouvernoratId
  'STAR_Tunis_AGE1', // agenceId
);
```

---

## 🎯 **Cas d'Usage Concrets**

### **Exemple 1 : Agent STAR Manouba**

```
🏢 STAR Assurances
└── 🗺️ Manouba
    └── 🏪 Agence Manouba Centre
        └── 👨‍💼 Ahmed Ben Ali
```

**Permissions :**
- ✅ Voir tous les contrats de son agence
- ✅ Créer des contrats pour sa zone
- ❌ Voir les contrats d'autres agences

### **Exemple 2 : Responsable Régional GAT**

```
🏢 GAT Assurances
└── 🗺️ Tunis (Responsable Régional)
    ├── 🏪 Agence Centre Ville
    └── 🏪 Agence Bab Bhar
```

**Permissions :**
- ✅ Voir tous les contrats du gouvernorat
- ✅ Gérer toutes les agences de sa région
- ❌ Voir les autres gouvernorats

---

## 🔐 **Règles de Sécurité Mises à Jour**

Les règles Firestore ont été mises à jour pour supporter :

1. **Accès par Compagnie :** Agents voient seulement leur compagnie
2. **Accès par Gouvernorat :** Responsables voient leur région
3. **Accès par Agence :** Agents voient leur agence
4. **Hiérarchie Respectée :** Pas d'accès cross-compagnie

---

## 📊 **Interface Utilisateur Améliorée**

### **Tableau de Bord Agent :**

```
🛡️ Tableau de Bord - Ahmed Ben Ali
📍 STAR Assurances > Manouba > Agence Centre

📊 Mes Statistiques
├── 📋 Contrats créés : 15
├── 🚗 Véhicules assurés : 12
└── 📅 Ce mois : 3

⚡ Actions Rapides
├── ➕ Nouveau Contrat
├── 🔍 Rechercher Conducteur
└── 📋 Mes Contrats (Agence)
```

### **Sélecteur Hiérarchique :**

```
🏢 Sélection Hiérarchique
├── 🏢 Compagnie : [STAR Assurances ▼]
├── 🗺️ Gouvernorat : [Manouba ▼]
├── 🏪 Agence : [Agence Centre ▼]
└── 👨‍💼 Agent : [Ahmed Ben Ali ▼]

📋 Résumé : STAR > Manouba > Centre > Ahmed
```

---

## 🧪 **Test de la Hiérarchie**

### **1. Créer un Agent de Test :**

```dart
// Dans Firebase Console ou via l'app
{
  "email": "agent.manouba@star.tn",
  "compagnie": "STAR",
  "gouvernorat": "Manouba", 
  "agence": "STAR_Manouba_AGE1",
  "role": "assureur"
}
```

### **2. Tester les Permissions :**

1. **Connexion Agent :** `agent.manouba@star.tn`
2. **Vérifier Accès :** Seulement contrats de son agence
3. **Créer Contrat :** Avec hiérarchie automatique
4. **Vérifier Filtrage :** Pas d'accès autres agences

---

## 🎉 **Avantages de cette Structure**

### **✅ Scalabilité :**
- Ajout facile de nouvelles compagnies
- Extension simple à d'autres pays
- Gestion centralisée des permissions

### **✅ Sécurité :**
- Isolation complète entre compagnies
- Accès basé sur la hiérarchie
- Audit trail complet

### **✅ Performance :**
- Requêtes optimisées par niveau
- Index automatiques Firestore
- Cache des données fréquentes

### **✅ Maintenance :**
- Structure claire et logique
- Règles de sécurité centralisées
- Logs détaillés des actions

---

## 🚀 **Prochaines Étapes**

1. **✅ Initialiser la hiérarchie** (via l'écran de config)
2. **✅ Tester avec un agent** de chaque compagnie
3. **✅ Vérifier les permissions** par niveau
4. **✅ Adapter l'interface** selon les besoins
5. **✅ Former les utilisateurs** sur la nouvelle structure

---

## 📞 **Support**

### **Problèmes Courants :**

1. **"Hiérarchie non trouvée"**
   - Lancez l'initialisation via l'écran de config
   - Vérifiez les règles Firestore

2. **"Permissions refusées"**
   - Vérifiez le rôle utilisateur dans `user_types`
   - Vérifiez l'affectation hiérarchique

3. **"Agences vides"**
   - Relancez l'initialisation
   - Vérifiez les logs dans l'écran de config

**La hiérarchie des assurances tunisiennes est maintenant complètement opérationnelle ! 🎉**
