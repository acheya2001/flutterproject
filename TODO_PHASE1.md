# 📋 TODO - Phase 1: Amélioration Processus Conducteur

## ✅ Complété
- [x] Création du service d'authentification conducteur (`ConducteurAuthService`)
- [x] Écran d'inscription conducteur amélioré (`conducteur_register_screen.dart`)
- [x] Écran de connexion conducteur (`conducteur_login_screen.dart`)
- [x] Ajout des nouvelles routes dans `app_routes.dart`
- [x] Configuration des routes dans `main.dart`
- [x] Création du dashboard conducteur (`conducteur_dashboard_screen.dart`)
- [x] Écran de gestion des véhicules (`conducteur_vehicules_screen.dart`)
- [x] Écran de gestion des sinistres (`conducteur_accidents_screen.dart`)
- [x] Écran de gestion des invitations (`conducteur_invitations_screen.dart`)

## 🔄 En Cours
- [ ] Intégration de la sélection compagnie/agence avec QR code
- [ ] Gestion du statut "pending" jusqu'à validation agent
- [ ] Remplissage des listes avec données réelles

## 📋 Prochaines Étapes

### 1. Dashboard Conducteur Amélioré
- [ ] Créer/modifier le dashboard conducteur avec les sections :
  - 📄 Demande de contrat d'assurance
  - 🚘 Mes véhicules assurés
  - 🔔 Mes sinistres
  - 👤 Mon profil

### 2. Sélection Compagnie/Agence
- [ ] Ajouter dropdown de sélection compagnie d'assurance
- [ ] Ajouter dropdown de sélection agence
- [ ] Implémenter scan QR code pour sélection agence

### 3. Gestion Statut "Pending"
- [ ] Modifier le modèle conducteur pour inclure le statut
- [ ] Interface admin pour validation des comptes
- [ ] Notifications pour conducteurs en attente

### 4. Fonctionnalités Avancées
- [ ] Mode hors-ligne pour inscription
- [ ] Validation CIN automatique
- [ ] Vérification téléphone tunisien

## 🔧 Dépendances Techniques
- Packages à ajouter dans `pubspec.yaml` :
  ```yaml
  qr_flutter: ^4.1.0
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  ```

## 🎯 Objectifs Phase 1
- Processus d'inscription complet et fluide
- Gestion des deux types de conducteurs (nouveaux/existants)
- Interface utilisateur adaptée au marché tunisien
- Validation robuste des données

## ⏱️ Estimation Temps
- Dashboard conducteur : 2-3 jours
- Sélection compagnie/agence : 1-2 jours
- Gestion statut pending : 1 jour
- Tests et validation : 1-2 jours

**Total estimé : 5-7 jours de développement**
