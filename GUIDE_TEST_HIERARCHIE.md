# 🧪 Guide de Test - Système Hiérarchique d'Assurance

## 🎯 **Objectif des Tests**

Valider le fonctionnement complet de la hiérarchie d'assurance :
- ✅ Création de compagnies
- ✅ Création d'Admin Compagnie (avec affichage des identifiants)
- ✅ Création d'agences
- ✅ Création d'Admin Agence (avec envoi d'email)
- ✅ Importation CSV
- ✅ Contrôles de sécurité

## 🚀 **Préparation des Tests**

### **1. Lancement de l'Application**
```bash
cd c:\FlutterProjects\constat_tunisie
flutter run
```

### **2. Connexion Super Admin**
- **Email** : `constat.tunisie.app@gmail.com`
- **Mot de passe** : `Acheya123`

### **3. Accès aux Outils de Test**
- **Dashboard Super Admin** → Menu latéral → **"Test Rapide"** 🧪
- **Dashboard Super Admin** → Menu latéral → **"Gestion Hiérarchique"** 🏗️
- **Dashboard Super Admin** → Menu latéral → **"Import CSV"** 📊

## 🧪 **Tests Automatisés (Test Rapide)**

### **Test 1 : Création de Compagnie**
1. Cliquez sur **"Test Compagnie"**
2. **Résultat attendu** :
   ```
   ✅ Compagnie créée: TEST123
   ```
3. **Vérification** : Allez dans Firebase Console → Firestore → Collection `companies`

### **Test 2 : Création Admin Compagnie**
1. Cliquez sur **"Test Admin Compagnie"**
2. **Résultat attendu** :
   ```
   ✅ Compagnie créée: TESTADMIN
   ✅ Admin créé: admin.testadmin@assurance.tn
   🔑 Mot de passe: Xy9#mK2$pL8!
   ```
3. **Vérification** : Collection `users` avec `role: admin_compagnie`

### **Test 3 : Création d'Agence**
1. Cliquez sur **"Test Agence"**
2. **Résultat attendu** :
   ```
   ✅ Compagnie créée: TESTAGENCE
   ✅ Agence créée: TESTAGENCE-agence-test-123456789
   ```
3. **Vérification** : Collection `agencies`

### **Test 4 : Séquence Complète**
1. Cliquez sur **"Test Complet"**
2. **Résultat attendu** :
   ```
   🔍 Étape 1: Création compagnie...
   ✅ Compagnie créée: FULL123456789
   🔍 Étape 2: Création admin compagnie...
   ✅ Admin créé: admin.full123456789@assurance.tn
   🔑 Mot de passe: Ab3#xY7$qM9!
   🔍 Étape 3: Création agence...
   ✅ Agence créée: FULL123456789-agence-full-test-123456789
   🎉 === SÉQUENCE COMPLÈTE RÉUSSIE ===
   ```

## 🎨 **Tests Manuels (Gestion Hiérarchique)**

### **Test 5 : Interface de Création de Compagnie**
1. Allez dans **"Gestion Hiérarchique"** → Onglet **"🏢 Compagnies"**
2. Remplissez :
   ```
   Nom: STAR Assurance Test
   Code: STARTEST
   Adresse: Avenue Habib Bourguiba
   Téléphone: 71234567
   Email: contact@startest.tn
   Ville: Tunis
   ```
3. Cliquez **"Créer la Compagnie"**
4. **Résultat attendu** : Message de succès vert

### **Test 6 : Interface Admin Compagnie**
1. Onglet **"👤 Admin Compagnie"**
2. Remplissez :
   ```
   ID Compagnie: STARTEST
   Nom: Ben Ali
   Prénom: Ahmed
   Téléphone: 71111111
   ```
3. Cliquez **"Créer Admin Compagnie"**
4. **Résultat attendu** :
   - Message de succès
   - **Encadré vert** avec identifiants :
     ```
     ✅ Admin Compagnie créé avec succès !
     Email: admin.startest@assurance.tn
     Mot de passe: [mot de passe généré]
     ⚠️ Transmettez ces identifiants manuellement au client
     ```
   - **Boutons de copie** pour email et mot de passe

### **Test 7 : Interface Agence**
1. Onglet **"🏪 Agences"**
2. Remplissez :
   ```
   ID Compagnie: STARTEST
   Nom: Agence Tunis Test
   Adresse: Rue de la Kasbah
   Ville: Tunis
   Téléphone: 71222222
   Responsable: Fatma Trabelsi
   ```
3. Cliquez **"Créer l'Agence"**
4. **Résultat attendu** : Message de succès

## 📊 **Tests d'Importation CSV**

### **Test 8 : Import Compagnies**
1. Allez dans **"Import CSV"**
2. Copiez le contenu de `test_data_hierarchie.csv` :
   ```csv
   nom,code,adresse,telephone,email,ville,pays
   STAR Assurance,STAR,Avenue Habib Bourguiba Tunis,71234567,contact@star.tn,Tunis,Tunisie
   COMAR Assurance,COMAR,Rue de la Liberté Tunis,71345678,info@comar.tn,Tunis,Tunisie
   ```
3. Collez dans la zone de texte
4. Cliquez **"Importer depuis le texte"**
5. **Résultat attendu** :
   ```
   ✅ Type détecté: compagnies
   ✅ 10 compagnies importées avec succès !
   ✅ Taux de succès: 100%
   ```

### **Test 9 : Import Agences**
1. Copiez le contenu de `test_agences.csv` :
   ```csv
   nom,compagnie,adresse,ville,telephone,responsable
   Agence Tunis Centre,STAR,Rue de la Kasbah Tunis,Tunis,71111111,Ahmed Ben Ali
   ```
2. Collez et importez
3. **Résultat attendu** : Détection automatique du type "agences"

## 🔐 **Tests de Sécurité**

### **Test 10 : Contrôles d'Accès**
1. **Test unicité compagnie** :
   - Essayez de créer deux compagnies avec le même code
   - **Résultat attendu** : Erreur "Une compagnie avec ce code existe déjà"

2. **Test admin unique** :
   - Essayez de créer deux Admin Compagnie pour la même compagnie
   - **Résultat attendu** : Erreur "Un Admin Compagnie existe déjà"

3. **Test compagnie inexistante** :
   - Essayez de créer un Admin Compagnie pour une compagnie qui n'existe pas
   - **Résultat attendu** : Erreur "Compagnie non trouvée"

## 📱 **Tests d'Interface**

### **Test 11 : Responsive Design**
1. Redimensionnez la fenêtre
2. **Vérifiez** :
   - ✅ Pas de débordement de texte
   - ✅ Boutons accessibles
   - ✅ Formulaires utilisables

### **Test 12 : Navigation**
1. **Testez** :
   - ✅ Changement d'onglets fluide
   - ✅ Menu latéral fonctionnel
   - ✅ Retour au dashboard

## 🔍 **Vérifications Firebase**

### **Collections à Vérifier**

#### **1. Collection `companies`**
```json
{
  "STARTEST": {
    "id": "STARTEST",
    "nom": "STAR Assurance Test",
    "code": "STARTEST",
    "status": "actif",
    "created_by": "super_admin_uid"
  }
}
```

#### **2. Collection `users`**
```json
{
  "admin-startest-123456789": {
    "email": "admin.startest@assurance.tn",
    "role": "admin_compagnie",
    "compagnieId": "STARTEST",
    "authMethod": "firestore_only",
    "password": "Xy9#mK2$pL8!"
  }
}
```

#### **3. Collection `agencies`**
```json
{
  "STARTEST-agence-tunis-test-123456789": {
    "nom": "Agence Tunis Test",
    "compagnieId": "STARTEST",
    "ville": "Tunis",
    "status": "actif"
  }
}
```

## ✅ **Checklist de Validation**

### **Fonctionnalités Core**
- [ ] Création de compagnies
- [ ] Création d'Admin Compagnie avec affichage des identifiants
- [ ] Création d'agences
- [ ] Import CSV compagnies
- [ ] Import CSV agences
- [ ] Contrôles de sécurité

### **Interface Utilisateur**
- [ ] Navigation fluide
- [ ] Messages d'erreur clairs
- [ ] Messages de succès visibles
- [ ] Formulaires intuitifs
- [ ] Copie des identifiants

### **Base de Données**
- [ ] Collections créées correctement
- [ ] Données structurées
- [ ] Relations hiérarchiques respectées
- [ ] Timestamps présents

### **Sécurité**
- [ ] Validation des permissions
- [ ] Contrôles d'unicité
- [ ] Vérification des entités parentes
- [ ] Génération de mots de passe sécurisés

## 🚨 **Problèmes Connus et Solutions**

### **Problème : Firestore unavailable**
**Solution** : Vérifiez la connexion internet et redémarrez l'émulateur

### **Problème : Identifiants non affichés**
**Solution** : Vérifiez que la création s'est bien passée et rafraîchissez l'interface

### **Problème : Import CSV échoue**
**Solution** : Vérifiez le format des données et les en-têtes de colonnes

---

## 📞 **Support**

**En cas de problème pendant les tests :**
- 📧 **Email** : support@constat-tunisie.tn
- 📱 **Téléphone** : +216 71 XXX XXX
- 💬 **Chat** : Disponible dans l'application

---

*Guide de test créé le 17/07/2025 - Version 1.0*
