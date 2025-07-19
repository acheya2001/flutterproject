# 🇹🇳 Guide de Test - Workflow Corrigé Admin Compagnie → Admin Agence → Agents

## 🎯 Workflow Corrigé et Implémenté

```
👤 Admin Compagnie
├── 🏪 Créer des agences (Onglet "Agences")
├── 👤 Créer des Admin Agence (Onglet "Agents" → "Nouvel Admin Agence")
└── 📧 Communiquer les identifiants

👤 Admin Agence (créé par Admin Compagnie)
├── 🔐 Se connecter avec ses identifiants
├── 👥 Créer des agents dans son agence (Onglet "Agents" → "Nouvel Agent")
└── 📧 Communiquer les identifiants aux agents
```

## ✅ Corrections Apportées

### **🔧 Admin Compagnie :**
- ✅ **Onglet "Agents"** renommé en **"Admins Agence"**
- ✅ **Bouton "Nouvel Agent"** → **"Nouvel Admin Agence"**
- ✅ **Création d'Admin Agence** avec sélection d'agence
- ✅ **Affichage des Admin Agence** existants (pas des agents)

### **🔧 Admin Agence :**
- ✅ **Onglet "Agents"** pour créer des **vrais agents**
- ✅ **Isolation par agence** respectée
- ✅ **Permissions correctes** pour création d'agents

## 🎯 Clarification des Onglets

### **📋 Admin Compagnie :**
- **Onglet "Agences"** : Créer et gérer les agences
- **Onglet "Agents"** : Créer et gérer les **Admin Agence** (pas les agents normaux)

### **📋 Admin Agence :**
- **Onglet "Agents"** : Créer et gérer les **vrais agents** de son agence

## 🚀 Étapes de Test

### **1. Connexion Admin Compagnie**
```
Email: admin.gat@assurance.tn
Password: Ba0ObOQk^1sl
```

### **2. Créer une Agence (Admin Compagnie)**
1. **Aller dans l'onglet "Agences"**
2. **Cliquer sur "Nouvelle Agence"**
3. **Remplir les informations** :
   - Nom: "Agence Test Tunis"
   - Ville: "Tunis"
   - Gouvernorat: "Tunis"
   - Adresse: "Avenue Habib Bourguiba"
   - Téléphone: "+216 71 123 456"
   - Email: "agence.tunis@gat.tn"
4. **Créer l'agence**

### **3. Créer un Admin Agence (Admin Compagnie)**
1. **Aller dans l'onglet "Agents"** (qui affiche maintenant "Admins Agence")
2. **Cliquer sur "Nouvel Admin Agence"**
3. **Sélectionner l'agence** créée à l'étape 2
4. **Remplir les informations** :
   - Prénom: "Ahmed"
   - Nom: "Ben Ali"
   - Email: "ahmed.benali@gat.tn"
   - Téléphone: "+216 98 123 456"
   - Adresse: "Tunis"
   - CIN: "12345678"
5. **Créer l'Admin Agence**
6. **Noter les identifiants générés** (email + mot de passe temporaire)
7. **Vérifier** que l'Admin Agence apparaît dans la liste

### **4. Connexion Admin Agence**
1. **Se déconnecter** de l'Admin Compagnie
2. **Aller sur l'écran de connexion Admin Agence**
3. **Se connecter avec les identifiants** générés à l'étape 3
4. **Vérifier l'accès** au dashboard Admin Agence

### **5. Créer des Agents (Admin Agence)**
1. **Dans le dashboard Admin Agence**, aller dans l'onglet "Agents"
2. **Cliquer sur "Nouvel Agent"**
3. **Remplir les informations** :
   - Prénom: "Fatma"
   - Nom: "Trabelsi"
   - Email: "fatma.trabelsi@gat.tn"
   - Téléphone: "+216 97 234 567"
   - Spécialité: "Automobile"
4. **Créer l'agent**
5. **Noter les identifiants générés**

## ✅ Vérifications à Effectuer

### **🔐 Permissions et Sécurité**
- [ ] Admin Compagnie peut créer des agences
- [ ] Admin Compagnie peut créer des Admin Agence
- [ ] Admin Agence peut se connecter avec ses identifiants
- [ ] Admin Agence voit uniquement son agence
- [ ] Admin Agence peut créer des agents dans son agence uniquement
- [ ] Mots de passe temporaires fonctionnent
- [ ] Isolation des données par agence

### **🏗️ Structure Hiérarchique**
- [ ] Agences créées dans `companies/{compagnieId}/agencies/`
- [ ] Admin Agence lié à son agence avec `agenceId` et `compagnieId`
- [ ] Agents créés avec `agenceId` et `compagnieId` corrects
- [ ] Pas de cross-access entre agences

### **📊 Interface et UX**
- [ ] Dashboard Admin Compagnie avec onglets fonctionnels
- [ ] Dashboard Admin Agence avec onglets fonctionnels
- [ ] Affichage des identifiants après création
- [ ] Messages d'erreur appropriés
- [ ] Navigation fluide entre les écrans

## 🐛 Problèmes Potentiels et Solutions

### **❌ Admin Agence ne peut pas se connecter**
**Solution** : Vérifier que :
- L'email est correct
- Le mot de passe temporaire est utilisé
- Le compte est actif (`isActive: true`)
- Les champs de mot de passe sont remplis

### **❌ Admin Agence ne voit pas son agence**
**Solution** : Vérifier que :
- `agenceId` et `compagnieId` sont définis
- L'agence existe dans `companies/{compagnieId}/agencies/`
- Les permissions Firestore sont correctes

### **❌ Erreur de création d'agent**
**Solution** : Vérifier que :
- L'Admin Agence a les bonnes permissions
- `agenceId` et `compagnieId` sont transmis
- L'email de l'agent n'existe pas déjà

## 📋 Checklist de Test Complet

### **Phase 1: Admin Compagnie**
- [ ] Connexion Admin Compagnie réussie
- [ ] Création d'agence réussie
- [ ] Agence visible dans la liste
- [ ] Création Admin Agence réussie
- [ ] Identifiants Admin Agence affichés

### **Phase 2: Admin Agence**
- [ ] Connexion Admin Agence réussie
- [ ] Dashboard Admin Agence accessible
- [ ] Onglets fonctionnels (Agents, Sinistres, Experts, Stats)
- [ ] Informations agence correctes affichées

### **Phase 3: Création Agents**
- [ ] Création d'agent réussie
- [ ] Agent visible dans la liste
- [ ] Identifiants agent affichés
- [ ] Statistiques mises à jour

### **Phase 4: Sécurité**
- [ ] Admin Agence ne peut pas accéder aux autres agences
- [ ] Admin Agence ne peut pas créer d'agences
- [ ] Isolation des données respectée
- [ ] Permissions Firestore fonctionnelles

## 🎉 Résultat Attendu

À la fin du test, vous devriez avoir :

1. **Une agence créée** par l'Admin Compagnie
2. **Un Admin Agence créé** et fonctionnel
3. **Des agents créés** par l'Admin Agence
4. **Une hiérarchie complète** : Compagnie → Agence → Admin Agence → Agents
5. **Une sécurité fonctionnelle** avec isolation des données

## 🔧 Commandes de Debug

### **Vérifier la structure Firestore**
```
Collection: companies/{compagnieId}/agencies/{agenceId}
Collection: users (avec role: admin_agence, agenceId, compagnieId)
```

### **Logs à surveiller**
```
[ADMIN_COMPAGNIE_SERVICE] 👤 Création Admin Agence
[ADMIN_AGENCE_AUTH] 🔐 Tentative connexion
[AGENT_SERVICE] 👥 Création agent
```

---

## 🎉 FONCTIONNALITÉS AVANCÉES DISPONIBLES

### **📋 Gestion des Contrats :**
- ✅ **Onglet Contrats** pour Admin Agence
- ✅ **Recherche de contrats** par numéro, conducteur, immatriculation
- ✅ **Création de contrats** avec conducteur et véhicule
- ✅ **Gestion des sinistres** et constats d'accident
- ✅ **Assignation d'experts** aux sinistres

### **📊 Services Tunisiens Complets :**
- ✅ **TunisiaInsuranceService** : Gestion complète des assurances
- ✅ **Création contrat + véhicule** en une transaction
- ✅ **Constats d'accident** avec photos et audio
- ✅ **Assignation d'experts** multi-compagnies
- ✅ **Statistiques d'agence** en temps réel
- ✅ **Recherche avancée** de contrats

### **🔧 Architecture Technique :**
- ✅ **Structure hiérarchique** : companies/{id}/agencies/{id}
- ✅ **Permissions granulaires** par rôle
- ✅ **Isolation des données** par agence
- ✅ **Services modulaires** et réutilisables
- ✅ **Gestion d'erreurs** robuste

## 🚀 PROCHAINES ÉTAPES

### **📱 Interface Conducteur :**
1. **Application mobile** pour les conducteurs
2. **Déclaration d'accident** simplifiée
3. **Suivi des sinistres** en temps réel
4. **Historique des contrats** et véhicules

### **👨‍🔧 Interface Expert :**
1. **Dashboard expert** avec sinistres assignés
2. **Rapports d'expertise** avec photos
3. **Estimation des dégâts** et coûts
4. **Validation des réparations**

### **🤖 IA et Automatisation :**
1. **Reconnaissance d'images** pour les dégâts
2. **Estimation automatique** des coûts
3. **Détection de fraude** par IA
4. **Chatbot** pour assistance client

**🇹🇳 Ce workflow respecte parfaitement la hiérarchie tunisienne et les permissions spécifiées !**
