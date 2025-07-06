# 🧪 Guide de Test Étape par Étape - Système d'Assurance

## 🎯 **Accès au Menu de Test**

Vous avez maintenant un **bouton "Tests"** (violet) dans l'écran d'accueil de votre application qui donne accès à tous les outils de test.

---

## 📋 **Séquence de Test Complète**

### **🔧 ÉTAPE 1 : Configuration Initiale**

#### **1.1 Initialiser la Hiérarchie des Assurances**

1. **Lancez votre application**
2. **Cliquez sur le bouton "Tests"** (violet) dans l'écran d'accueil
3. **Sélectionnez "Configuration Hiérarchie"**
4. **Cliquez "Initialiser la Hiérarchie"**
5. **Attendez la création** (2-3 minutes)

**✅ Résultat attendu :**
```
✅ Hiérarchie initialisée avec succès !
📊 Structure créée :
  - 5 compagnies d'assurance
  - 24 gouvernorats par compagnie  
  - 2-3 agences par gouvernorat
  - 2 agents par agence
```

#### **1.2 Créer les Utilisateurs de Test**

1. **Retour au menu de test**
2. **Sélectionnez "Utilisateurs de Test"**
3. **Cliquez "Créer Agent de Test"**
4. **Cliquez "Créer Conducteur de Test"**

**✅ Résultat attendu :**
```
✅ Agent de test créé avec succès
Email: agent.test@star.tn
Password: Test123456

✅ Conducteur de test créé avec succès  
Email: conducteur.test@email.com
Password: Test123456
```

---

### **🧪 ÉTAPE 2 : Test du Système**

#### **2.1 Test Agent d'Assurance**

1. **Déconnectez-vous** de votre compte actuel
2. **Connectez-vous avec :**
   - Email : `agent.test@star.tn`
   - Mot de passe : `Test123456`

3. **Vérifiez la navigation :**
   - Écran d'accueil → Bouton "Assurance"
   - **Devrait afficher le tableau de bord agent**

**✅ Interface attendue :**
```
🛡️ Tableau de Bord Agent
├── 📊 Statistiques (0 contrats)
├── ⚡ Actions Rapides
│   ├── ➕ Nouveau Contrat
│   ├── 🔍 Rechercher Conducteur  
│   └── 📋 Mes Contrats
└── 📈 Activité Récente
```

#### **2.2 Créer un Contrat de Test**

1. **Cliquez "Nouveau Contrat"**
2. **Étape 1 - Informations Contrat :**
   - Numéro : `TEST-001`
   - Email conducteur : `conducteur.test@email.com`
   - Compagnie : `STAR`
   - Agence : `Tunis Centre`

3. **Étape 2 - Informations Véhicule :**
   - Immatriculation : `TEST 123 TN`
   - Marque : `Peugeot`
   - Modèle : `308`
   - Année : `2020`

4. **Étape 3 - Garanties :**
   - Type : `Tous Risques`
   - Prime : `1200`
   - Garanties : Sélectionnez toutes

5. **Cliquez "Créer le Contrat"**

**✅ Résultat attendu :**
```
✅ Contrat créé et affecté avec succès
📧 Notifications envoyées
🚗 Véhicule ajouté au conducteur
```

#### **2.3 Test Conducteur**

1. **Déconnectez-vous**
2. **Connectez-vous avec :**
   - Email : `conducteur.test@email.com`
   - Mot de passe : `Test123456`

3. **Vérifiez la navigation :**
   - Écran d'accueil → Bouton "Assurance"
   - **Devrait afficher "Mes Véhicules"**

**✅ Interface attendue :**
```
🚗 Mes Véhicules
├── 📋 TEST 123 TN - Peugeot 308
│   ├── 🛡️ Statut : Actif
│   ├── 📅 Expire : Dans 365 jours
│   └── 🏢 STAR Assurances
└── 📞 Contact Agent
```

---

### **🔍 ÉTAPE 3 : Vérifications Firebase**

#### **3.1 Vérifier les Collections**

Ouvrez **Firebase Console** → **Firestore** et vérifiez :

1. **Collection `insurance_companies`** :
   ```
   ├── STAR/
   ├── GAT/
   ├── BH/
   ├── MAGHREBIA/
   └── LLOYD/
   ```

2. **Collection `contracts`** :
   ```
   └── [contract-id]/
       ├── numeroContrat: "TEST-001"
       ├── conducteurEmail: "conducteur.test@email.com"
       └── status: "active"
   ```

3. **Collection `vehicules`** :
   ```
   └── [vehicle-id]/
       ├── immatriculation: "TEST 123 TN"
       ├── conducteurId: [conducteur-uid]
       └── assurance: {...}
   ```

#### **3.2 Vérifier les Notifications**

1. **Collection `notifications`** :
   ```
   └── [notification-id]/
       ├── userId: [conducteur-uid]
       ├── type: "contract_created"
       └── read: false
   ```

---

### **🎯 ÉTAPE 4 : Tests Avancés**

#### **4.1 Test Hiérarchie Complète**

1. **Menu Tests → "Test Système Assurance"**
2. **Cliquez "Test Création Contrat"**
3. **Vérifiez les logs détaillés**

#### **4.2 Test Recherche Conducteur**

1. **Tableau de bord agent → "Rechercher Conducteur"**
2. **Tapez :** `conducteur.test@email.com`
3. **Vérifiez que le conducteur est trouvé**

#### **4.3 Test Permissions**

1. **Créez un deuxième agent** avec une autre compagnie
2. **Vérifiez qu'il ne voit pas** les contrats STAR
3. **Testez l'isolation des données**

---

## 🚨 **Résolution de Problèmes**

### **Problème 1 : "Type d'utilisateur non trouvé"**

**Solution :**
1. Firebase Console → Firestore → `user_types`
2. Trouvez votre document utilisateur
3. Changez `type` de `conducteur` à `assureur`

### **Problème 2 : "Hiérarchie non initialisée"**

**Solution :**
1. Menu Tests → Configuration Hiérarchie
2. Cliquez "Vérifier la Hiérarchie"
3. Si vide, relancez "Initialiser la Hiérarchie"

### **Problème 3 : "Erreur de permissions"**

**Solution :**
1. Déployez les règles Firestore :
   ```bash
   firebase deploy --only firestore:rules
   ```

### **Problème 4 : "Navigation incorrecte"**

**Solution :**
1. Redémarrez l'application
2. Vérifiez la connexion utilisateur
3. Vérifiez le type dans `user_types`

---

## ✅ **Checklist de Test Complet**

### **Configuration :**
- [ ] Hiérarchie initialisée (5 compagnies)
- [ ] Agent de test créé
- [ ] Conducteur de test créé
- [ ] Règles Firestore déployées

### **Tests Agent :**
- [ ] Connexion agent réussie
- [ ] Tableau de bord affiché
- [ ] Création contrat fonctionnelle
- [ ] Notifications envoyées

### **Tests Conducteur :**
- [ ] Connexion conducteur réussie
- [ ] "Mes Véhicules" affiché
- [ ] Véhicule visible avec statut
- [ ] Détails contrat accessibles

### **Vérifications Firebase :**
- [ ] Collections créées
- [ ] Données contrat stockées
- [ ] Véhicule affecté
- [ ] Notifications enregistrées

---

## 🎉 **Test Réussi !**

Si tous les points sont validés, votre système d'assurance hiérarchique fonctionne parfaitement !

### **Prochaines Étapes :**
1. **Supprimez le bouton de test** de l'écran d'accueil
2. **Créez vos vrais comptes** d'agents
3. **Configurez les vraies compagnies** si nécessaire
4. **Formez vos utilisateurs** sur le nouveau système

**Le système est prêt pour la production ! 🚀**
