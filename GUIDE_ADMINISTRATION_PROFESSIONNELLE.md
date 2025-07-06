# 🏛️ Guide d'Administration Professionnelle - Constat Tunisie

## 📋 Vue d'Ensemble

Ce système d'administration professionnelle permet de gérer une hiérarchie complète d'assurance avec :
- **Super Administrateur** : Gère tout le système
- **Compagnies d'Assurance** : Star, GAT, BH, etc.
- **Agences** : Réparties par gouvernorat
- **Agents** : Employés des agences avec matricules

---

## 🚀 Démarrage Rapide

### 1️⃣ **Initialisation du Système**

**Première étape obligatoire :**
1. Lancez l'application
2. Allez dans **Administration** → **Initialisation**
3. Cliquez sur **"Initialiser Maintenant"**
4. Notez les identifiants du Super Admin :
   ```
   Email: admin@constat-tunisie.tn
   Mot de passe: AdminConstat2024!
   ```

### 2️⃣ **Connexion Super Admin**

1. Déconnectez-vous si nécessaire
2. Allez à l'écran de connexion
3. Utilisez les identifiants du Super Admin
4. Vous accédez au **Dashboard Administrateur**

---

## 🏗️ Structure Hiérarchique

```
🏛️ SYSTÈME CONSTAT TUNISIE
├── 👑 Super Admin
│   ├── 🏢 Compagnie Star Assurance
│   │   ├── 🏪 Agence Star Tunis Centre
│   │   │   ├── 👨‍💼 Agent Ahmed Ben Ali
│   │   │   └── 👨‍💼 Agent Fatma Trabelsi
│   │   └── 🏪 Agence Star Manouba
│   ├── 🏢 Compagnie GAT
│   └── 🏢 Compagnie BH Assurance
└── 🚗 Conducteurs (Auto-inscription)
```

---

## 🛠️ Gestion des Compagnies

### ➕ **Créer une Compagnie**

1. **Dashboard Admin** → **Gestion Compagnies**
2. Cliquez sur **"+"** (Ajouter)
3. Remplissez les informations :
   - **Nom** : Star Assurance
   - **SIRET** : 12345678901234 (unique)
   - **Adresse Siège** : 123 Avenue Habib Bourguiba, Tunis
   - **Téléphone** : +216 71 123 456
   - **Email** : contact@star.tn
   - **Logo URL** : https://example.com/logo.png

### 📋 **Gérer les Compagnies**

- **Voir Détails** : Clic sur une compagnie
- **Modifier** : Menu ⋮ → Modifier
- **Voir Agences** : Menu ⋮ → Agences
- **Supprimer** : Menu ⋮ → Supprimer

---

## 🏪 Gestion des Agences

### ➕ **Créer une Agence**

1. **Gestion Compagnies** → Sélectionner une compagnie
2. **Menu ⋮** → **Agences**
3. Cliquez sur **"+"** (Ajouter)
4. Remplissez :
   - **Nom** : Agence Star Tunis Centre
   - **Code** : TUN001 (unique par compagnie)
   - **Gouvernorat** : Tunis
   - **Ville** : Tunis
   - **Adresse** : 456 Rue de la Liberté
   - **Email** : tunis@star.tn
   - **Téléphone** : +216 71 456 789

### 🗺️ **Répartition Géographique**

Les agences sont organisées par **gouvernorat** :
- **Tunis** : TUN001, TUN002, TUN003...
- **Manouba** : MAN001, MAN002...
- **Nabeul** : NAB001, NAB002...

---

## 👨‍💼 Gestion des Agents

### ➕ **Créer un Agent**

1. **Gestion Agences** → Sélectionner une agence
2. **Menu ⋮** → **Agents**
3. Cliquez sur **"+"** (Ajouter)
4. Remplissez :
   - **Nom** : Ben Ali
   - **Prénom** : Ahmed
   - **Email** : ahmed.benali@star.tn (unique)
   - **Téléphone** : +216 98 123 456
   - **Matricule** : AGT001 (unique par compagnie)
   - **Poste** : Agent Commercial
   - **Mot de passe** : Agent123!

### 🎯 **Postes Disponibles**

- **Agent Commercial**
- **Conseiller Clientèle**
- **Responsable Agence**
- **Superviseur**
- **Chargé de Sinistres**

---

## 🔐 Système de Permissions

### 👑 **Super Admin**
- ✅ Créer/modifier/supprimer les compagnies
- ✅ Voir toutes les agences et agents
- ✅ Accès aux statistiques globales
- ✅ Configuration système

### 🏢 **Responsable Compagnie**
- ✅ Créer/modifier les agences de sa compagnie
- ✅ Voir tous les agents de sa compagnie
- ❌ Accès aux autres compagnies

### 🏪 **Responsable Agence**
- ✅ Créer/modifier les agents de son agence
- ✅ Gérer les contrats de son agence
- ❌ Accès aux autres agences

### 👨‍💼 **Agent**
- ✅ Gérer les contrats clients
- ✅ Assigner des véhicules aux conducteurs
- ❌ Créer d'autres agents

---

## 🧪 Tests et Validation

### 🔬 **Écran de Test**

1. **Dashboard Admin** → **Test Système Admin**
2. Testez dans l'ordre :
   - **Initialiser Super Admin**
   - **Créer Compagnie Test**
   - **Créer Agence Test**
   - **Créer Agent Test**
   - **Lister Compagnies**

### ✅ **Validation du Système**

Vérifiez que :
- [ ] Le super admin peut se connecter
- [ ] Les compagnies sont créées avec SIRET unique
- [ ] Les agences ont des codes uniques par compagnie
- [ ] Les agents ont des matricules uniques par compagnie
- [ ] Les emails sont uniques dans tout le système

---

## 🚫 Restrictions d'Inscription

### ✅ **Qui peut s'inscrire directement ?**
- **Conducteurs uniquement** via l'écran d'inscription

### ❌ **Qui ne peut PAS s'inscrire directement ?**
- **Agents d'assurance** → Créés par les responsables d'agence
- **Experts** → Créés par les administrateurs
- **Responsables** → Créés par les super admins

### 📋 **Écran d'Information Professionnelle**
Les professionnels sont redirigés vers un écran expliquant :
- Comment obtenir un compte professionnel
- Qui contacter dans leur organisation
- Les étapes de validation requises

---

## 📊 Données de Test

### 🏢 **Compagnies Tunisiennes Réelles**
- **Star Assurance** (SIRET: 12345678901234)
- **GAT** (SIRET: 23456789012345)
- **BH Assurance** (SIRET: 34567890123456)
- **Maghrebia** (SIRET: 45678901234567)

### 🗺️ **Gouvernorats Couverts**
Tunis, Manouba, Nabeul, Sousse, Sfax, Kairouan, Bizerte, Gabès, Médenine, Tataouine, Gafsa, Tozeur, Kébili

---

## 🔧 Maintenance

### 🔄 **Mise à jour des Permissions**
Les règles Firestore sont automatiquement configurées pour :
- Vérifier l'appartenance hiérarchique
- Valider les permissions par rôle
- Empêcher les accès non autorisés

### 📈 **Évolutivité**
Le système est conçu pour supporter :
- Ajout de nouvelles compagnies
- Extension géographique
- Nouveaux types d'utilisateurs
- Intégration avec des systèmes externes

---

## 🆘 Dépannage

### ❌ **Problèmes Courants**

**"Permissions insuffisantes"**
- Vérifiez que l'utilisateur est connecté avec le bon rôle
- Confirmez l'appartenance à la bonne compagnie/agence

**"Email déjà existant"**
- Chaque email doit être unique dans tout le système
- Utilisez un format : prenom.nom@compagnie.tn

**"SIRET déjà existant"**
- Chaque compagnie doit avoir un SIRET unique
- Vérifiez la base de données existante

**"Matricule déjà existant"**
- Les matricules doivent être uniques par compagnie
- Format recommandé : AGT001, AGT002, etc.

---

## 📞 Support

Pour toute question ou problème :
1. Consultez d'abord ce guide
2. Testez avec l'écran de test intégré
3. Vérifiez les logs de l'application
4. Contactez l'équipe de développement

---

**🎉 Félicitations ! Votre système d'administration professionnelle est maintenant opérationnel !**
