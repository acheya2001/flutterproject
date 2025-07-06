# 🧪 **GUIDE DE TEST - ADMIN DEMANDES D'INSCRIPTION**

## ✅ **CORRECTIONS EFFECTUÉES**

### **1️⃣ Intégration Interface Admin**
- ✅ **Bouton ajouté** dans `SimpleAdminScreen` : "Demandes d'Inscription"
- ✅ **Navigation** vers `AdminDemandesScreen`
- ✅ **Bouton de test** : "Créer Test" pour générer des demandes

### **2️⃣ Utilitaire de Test**
- ✅ **`CreateTestDemande`** : Classe pour créer des demandes de test
- ✅ **Demandes multiples** : 3 agents de différentes compagnies
- ✅ **Données réalistes** : Informations complètes et cohérentes

## 🧪 **PROCÉDURE DE TEST COMPLÈTE**

### **Étape 1 : Connexion Admin**
1. **Ouvrir** l'application
2. **Aller** : Accueil → "Admin" → "Se connecter"
3. **Identifiants** : `constat.tunisie.app@gmail.com` / `Acheya123`
4. **Vérifier** : Arrivée sur `SimpleAdminScreen`

### **Étape 2 : Créer des Demandes de Test**
1. **Dans l'interface admin**, cliquer sur **"Créer Test"** (bouton violet)
2. **Attendre** le message : "✅ Demandes de test créées !"
3. **Vérifier** : 3 demandes créées dans Firestore

**Demandes créées** :
```
1. Mohamed Ben Ali (STAR Assurances, Tunis)
2. Fatma Trabelsi (GAT Assurances, Sousse)  
3. Ahmed Khelifi (BH Assurance, Sfax)
```

### **Étape 3 : Accéder aux Demandes**
1. **Cliquer** sur **"Demandes d'Inscription"** (bouton orange)
2. **Vérifier** : Navigation vers `AdminDemandesScreen`
3. **Voir** : Liste des 3 demandes en attente

### **Étape 4 : Examiner une Demande**
**Pour chaque demande, vérifier** :
- ✅ **Avatar** avec initiales
- ✅ **Nom complet** et email
- ✅ **Informations professionnelles** :
  - Compagnie d'assurance
  - Agence et gouvernorat
  - Poste occupé
  - Numéro d'agent
  - Téléphone
- ✅ **Boutons d'action** : "Approuver" (vert) et "Refuser" (rouge)

### **Étape 5 : Approuver une Demande**
1. **Choisir** une demande (ex: Mohamed Ben Ali)
2. **Cliquer** "Approuver"
3. **Attendre** le traitement
4. **Vérifier** le message : "✅ Demande approuvée: Mohamed Ben Ali"
5. **Constater** : La demande disparaît de la liste

### **Étape 6 : Vérifier la Création du Compte**
**Dans Firebase Console** :
1. **Authentication** → Vérifier le nouvel utilisateur
2. **Firestore** → Collection `agents_assurance` → Nouveau document
3. **Firestore** → Collection `demandes_inscription` → Statut "approuvee"

### **Étape 7 : Tester la Connexion de l'Agent Approuvé**
1. **Se déconnecter** de l'admin
2. **Aller** : Accueil → "Agent d'Assurance" → "Se connecter"
3. **Identifiants** : `agent1@star.tn` / `password123`
4. **Vérifier** : Connexion réussie vers interface assureur

### **Étape 8 : Refuser une Demande**
1. **Retourner** à l'interface admin
2. **Choisir** une autre demande (ex: Fatma Trabelsi)
3. **Cliquer** "Refuser"
4. **Vérifier** le message : "❌ Demande refusée"
5. **Constater** : La demande disparaît de la liste

### **Étape 9 : Tester la Connexion de l'Agent Refusé**
1. **Se déconnecter** de l'admin
2. **Aller** : Accueil → "Agent d'Assurance" → "Se connecter"
3. **Identifiants** : `agent2@gat.tn` / `password456`
4. **Vérifier** : Message "❌ Votre demande a été refusée. Contactez l'administration."

## 📊 **VÉRIFICATIONS FIRESTORE**

### **Collection `demandes_inscription`**
```
📁 demandes_inscription
├── {doc1} - statut: "approuvee" (Mohamed Ben Ali)
├── {doc2} - statut: "refusee" (Fatma Trabelsi)
└── {doc3} - statut: "en_attente" (Ahmed Khelifi)
```

### **Collection `agents_assurance`**
```
📁 agents_assurance
└── {uid} - Mohamed Ben Ali (agent approuvé)
```

### **Firebase Authentication**
```
👤 Utilisateurs
└── agent1@star.tn (compte créé pour Mohamed Ben Ali)
```

## 🚨 **PROBLÈMES POSSIBLES ET SOLUTIONS**

### **Problème 1 : Bouton "Demandes d'Inscription" invisible**
**Solution** : Vérifier que l'import `admin_demandes_screen.dart` est présent

### **Problème 2 : Aucune demande visible**
**Solutions** :
1. **Cliquer** "Créer Test" pour générer des demandes
2. **Vérifier** les règles Firestore (déployées ?)
3. **Consulter** Firebase Console → Firestore → `demandes_inscription`

### **Problème 3 : Erreur lors de l'approbation**
**Solutions** :
1. **Vérifier** la connexion Internet
2. **Consulter** les logs Flutter pour l'erreur exacte
3. **Vérifier** les permissions Firebase

### **Problème 4 : Interface admin ne charge pas**
**Solution** : Vérifier la connexion avec `constat.tunisie.app@gmail.com`

## 🎯 **RÉSULTATS ATTENDUS**

### **✅ Interface Admin Fonctionnelle**
- Bouton "Demandes d'Inscription" visible et cliquable
- Navigation fluide vers l'écran de gestion
- Bouton "Créer Test" pour générer des données

### **✅ Gestion des Demandes**
- Liste en temps réel des demandes en attente
- Informations complètes et bien formatées
- Boutons d'action fonctionnels

### **✅ Workflow Complet**
- Approbation → Création compte + profil Firestore
- Refus → Mise à jour statut uniquement
- Connexion agents selon statut

### **✅ Sécurité**
- Seuls les agents approuvés peuvent se connecter
- Messages explicites selon le statut
- Données cohérentes entre collections

## 📞 **INSTRUCTIONS FINALES**

1. **Testez** d'abord avec le bouton "Créer Test"
2. **Vérifiez** que les demandes apparaissent
3. **Approuvez** une demande et testez la connexion
4. **Refusez** une demande et vérifiez le blocage
5. **Consultez** Firestore pour confirmer les données

**Si tout fonctionne, le système d'approbation admin est opérationnel !** ✅

---

## 🔧 **COMMANDE À EXÉCUTER**

```bash
# Déployer les règles Firestore si pas encore fait
firebase deploy --only firestore:rules
```

**Votre système d'administration des demandes est maintenant complet !** 🎉
