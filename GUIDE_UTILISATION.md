# 📱 Guide d'Utilisation - Système de Gestion des Sinistres

## 🎯 Comment Tester les Nouvelles Fonctionnalités

### 🚀 Démarrage de l'Application

1. **Lancer l'application** avec `flutter run`
2. **Se connecter** avec un compte conducteur existant
3. **Accéder au dashboard** conducteur

---

## 🔄 Test du Workflow Conducteur Inscrit

### 📋 Étapes de Test

1. **Créer une nouvelle session**
   - Aller dans le dashboard conducteur
   - Cliquer sur "Déclarer Sinistre"
   - Suivre le processus de création de session
   - Noter le **code de session** généré

2. **Rejoindre la session en tant que conducteur inscrit**
   - Aller dans "Rejoindre une Session"
   - Choisir "Oui, je suis inscrit"
   - Saisir le code de session
   - Sélectionner un véhicule
   - Remplir le formulaire de constat

3. **Vérifier l'affichage des sinistres**
   - Retourner au dashboard
   - Vérifier l'onglet "Sinistres"
   - Voir les nouveaux sinistres avec statuts

---

## 👥 Test du Workflow Conducteur Invité

### 📋 Étapes de Test

1. **Simuler un conducteur invité**
   - Utiliser le même code de session
   - Choisir "Non, je suis invité"
   - Remplir le formulaire complet en 3 étapes :

2. **Étape 1 : Informations Personnelles**
   - Nom, prénom, email, téléphone
   - CIN, adresse, date de naissance

3. **Étape 2 : Informations Véhicule**
   - Marque, modèle, immatriculation
   - Année, couleur

4. **Étape 3 : Informations Assurance**
   - Sélectionner une compagnie d'assurance
   - Sélectionner une agence (chargement dynamique)
   - Numéro de contrat, police, dates

5. **Remplir le constat**
   - Accéder au formulaire unifié
   - Voir les informations pré-remplies
   - Compléter les onglets

---

## 📊 Test des Statuts Intelligents

### 🔄 Vérification des Statuts

1. **Statut "En attente des participants"**
   - Créer une session
   - Vérifier le statut initial

2. **Statut "En cours de remplissage"**
   - Faire rejoindre tous les participants
   - Vérifier le changement de statut

3. **Statut "Terminé"**
   - Compléter tous les formulaires
   - Vérifier le statut final

4. **Statut "Envoyé à l'agence"**
   - Vérifier l'envoi automatique
   - Consulter la collection `agences/{id}/sinistres_recus`

---

## 🏢 Test Interface Admin Agence

### 📋 Accès Admin Agence

1. **Se connecter en tant qu'admin agence**
   - Utiliser un compte avec role `admin_agence`
   - Vérifier que `agenceId` est défini

2. **Consulter les sinistres reçus**
   - Naviguer vers l'écran des sinistres reçus
   - Voir les sinistres envoyés par les conducteurs

3. **Traiter les sinistres**
   - Filtrer par statut (nouveau, en cours, traité)
   - Cliquer sur "Traiter" pour changer le statut
   - Voir les détails complets

---

## 🔍 Points de Vérification

### ✅ Dashboard Conducteur

- [ ] Les sinistres s'affichent correctement
- [ ] Les statuts sont visuellement distincts
- [ ] Les sessions en cours apparaissent
- [ ] Les cartes sont modernes et élégantes

### ✅ Création de Session

- [ ] Le code de session est généré
- [ ] Les informations sont sauvegardées
- [ ] Le statut initial est correct

### ✅ Rejoindre Session (Inscrit)

- [ ] La vérification du code fonctionne
- [ ] Les véhicules se chargent automatiquement
- [ ] Les informations sont pré-remplies
- [ ] Le formulaire est accessible

### ✅ Rejoindre Session (Invité)

- [ ] Le formulaire en 3 étapes fonctionne
- [ ] Les compagnies se chargent depuis Firestore
- [ ] Les agences se chargent dynamiquement
- [ ] La validation fonctionne à chaque étape

### ✅ Formulaire de Constat

- [ ] Les 4 onglets sont accessibles
- [ ] Les informations sont affichées correctement
- [ ] La validation par onglet fonctionne
- [ ] L'envoi final réussit

### ✅ Statuts en Temps Réel

- [ ] Les statuts se mettent à jour automatiquement
- [ ] Les couleurs correspondent aux statuts
- [ ] Les pourcentages de progression sont corrects
- [ ] Les participants sont listés

### ✅ Interface Admin Agence

- [ ] Les sinistres reçus s'affichent
- [ ] Le filtrage par statut fonctionne
- [ ] Les actions de traitement fonctionnent
- [ ] Les détails sont complets

---

## 🐛 Dépannage

### ❌ Problèmes Courants

1. **Sinistres ne s'affichent pas**
   - Vérifier les collections Firestore
   - Vérifier les champs `conducteurId`, `conducteurDeclarantId`, `createdBy`
   - Vérifier les permissions Firestore

2. **Erreur de chargement des compagnies/agences**
   - Vérifier la collection `compagnies_assurance`
   - Vérifier la sous-collection `agences`
   - Vérifier la connexion Internet

3. **Statuts ne se mettent pas à jour**
   - Vérifier les StreamBuilder
   - Vérifier les règles Firestore
   - Redémarrer l'application

4. **Erreur d'envoi vers l'agence**
   - Vérifier que `agenceId` est défini
   - Vérifier les permissions d'écriture
   - Vérifier la structure des données

---

## 📱 Interface Mobile

### 🎨 Éléments Visuels à Vérifier

- **Cartes modernes** avec ombres et bordures colorées
- **Indicateurs de statut** avec couleurs appropriées
- **Barres de progression** pour les sessions
- **Animations fluides** lors des transitions
- **Feedback visuel** pour les actions utilisateur

### 📊 Données en Temps Réel

- **Mise à jour automatique** des statuts
- **Synchronisation** entre les participants
- **Notifications visuelles** des changements
- **Persistance** des données hors ligne

---

## 🎉 Validation Finale

Une fois tous les tests réussis, le système de gestion des sinistres sera **entièrement fonctionnel** avec :

✅ **Workflows différenciés** selon le type de conducteur
✅ **Interface moderne et élégante**
✅ **Statuts intelligents en temps réel**
✅ **Envoi automatique vers les agences**
✅ **Consultation croisée des formulaires**
✅ **Gestion administrative complète**

Le système est prêt pour la production ! 🚀
