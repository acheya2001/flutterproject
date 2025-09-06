# 🧪 Guide de Test - Système d'Assurance Tunisien

Ce guide vous explique comment tester complètement le système d'assurance automobile tunisien.

## 📋 Table des Matières

1. [Tests Automatisés](#tests-automatisés)
2. [Tests Manuels](#tests-manuels)
3. [Tests d'Interface](#tests-dinterface)
4. [Tests de Performance](#tests-de-performance)
5. [Données de Test](#données-de-test)
6. [Scénarios de Test](#scénarios-de-test)

## 🤖 Tests Automatisés

### Installation des Dépendances

```bash
# Installer les dépendances de test
flutter pub get

# Installer lcov pour les rapports de couverture (Linux/Mac)
sudo apt-get install lcov  # Ubuntu/Debian
brew install lcov          # macOS
```

### Lancement des Tests

```bash
# Tous les tests
dart test_runner.dart

# Tests unitaires uniquement
dart test_runner.dart --unit

# Tests avec couverture de code
dart test_runner.dart --coverage

# Tests en mode verbose
dart test_runner.dart --verbose

# Tests spécifiques
flutter test test/services/tunisian_insurance_calculator_test.dart
flutter test test/services/tunisian_payment_service_test.dart
```

### Tests Unitaires Disponibles

#### 🧮 Calculateur de Prime
- ✅ Calcul de base (voiture standard)
- ✅ Majoration jeune conducteur
- ✅ Comparaison couvertures (RC vs Tous Risques)
- ✅ Impact zone géographique
- ✅ Impact antécédents d'accidents
- ✅ Options supplémentaires
- ✅ Simulation de toutes les options
- ✅ Garanties par type de couverture
- ✅ Génération de recommandations

#### 💳 Service de Paiement
- ✅ Calcul frais par fréquence
- ✅ Paiement annuel (sans frais)
- ✅ Paiement mensuel (8% frais)
- ✅ Paiement trimestriel (5% frais)
- ✅ Paiement semestriel (2% frais)
- ✅ Types de paiement tunisiens
- ✅ Économies paiement annuel

## 📱 Tests Manuels

### 1. Test du Dashboard de Test

```bash
# Lancer l'app en mode debug
flutter run --debug

# Naviguer vers le TestDashboardScreen
# (Ajouter un bouton dans votre main.dart)
```

#### Actions à Tester :
1. **Génération de données** : Cliquer sur "Générer Données"
2. **Statistiques** : Vérifier les compteurs
3. **Tests calculateur** : Tester tous les boutons
4. **Tests paiement** : Vérifier les calculs
5. **Navigation** : Accéder aux dashboards

### 2. Test Dashboard Agent

#### Prérequis :
- Données de test générées
- Agent ID et Agence ID disponibles

#### Scénarios :
1. **Connexion Agent**
   - Vérifier affichage des informations
   - Contrôler les statistiques
   - Tester les actions principales

2. **Création de Contrat**
   - Workflow complet en 5 étapes
   - Validation des documents
   - Calcul automatique de prime
   - Choix de couverture
   - Processus de paiement
   - Génération des documents

3. **Gestion des Renouvellements**
   - Affichage contrats à renouveler
   - Traitement des urgences
   - Notifications

### 3. Test Dashboard Conducteur

#### Scénarios :
1. **Mes Véhicules**
   - Affichage des véhicules
   - Statut d'assurance
   - Ajout de véhicule

2. **Mes Contrats**
   - Contrats actifs
   - Échéances
   - Détails des contrats

3. **Actions Rapides**
   - Déclaration de sinistre
   - Téléchargement documents
   - Scanner QR Code

## 🎯 Tests d'Interface

### Tests de Responsivité

```bash
# Tester sur différentes tailles d'écran
flutter run -d chrome --web-renderer html
flutter run -d "iPhone 14"
flutter run -d "Pixel 7"
```

### Tests d'Accessibilité

```bash
# Activer les outils d'accessibilité
flutter run --enable-accessibility
```

### Tests de Performance

```bash
# Profiler les performances
flutter run --profile
flutter drive --target=test_driver/app.dart --profile
```

## 📊 Données de Test

### Génération Automatique

Le `TestDataService` génère automatiquement :

- **3 Compagnies** : COMAR, STAR, GAT
- **2 Agences** par compagnie
- **2 Agents** par agence
- **1 Conducteur** de test
- **2 Véhicules** par conducteur
- **2 Contrats** par véhicule

### Données Manuelles

```dart
// Exemple de données de test manuelles
final testVehicule = {
  'numeroImmatriculation': '123 TUN 456',
  'marque': 'Toyota',
  'modele': 'Corolla',
  'annee': 2020,
  'puissanceFiscale': 6,
  'typeVehicule': 'voiture',
};

final testConducteur = {
  'nom': 'Ben Salem',
  'prenom': 'Karim',
  'cin': '12345678',
  'age': 30,
  'antecedents': 'aucun',
};
```

## 🎬 Scénarios de Test Complets

### Scénario 1 : Création Contrat Complet

1. **Agent se connecte**
2. **Client arrive avec ses documents**
   - CIN : 12345678
   - Permis : PERMIS-001
   - Carte grise : CG-2024-001
3. **Agent vérifie les documents**
4. **Système calcule la prime**
   - Véhicule : Toyota Corolla 2020, 6 CV
   - Conducteur : 30 ans, aucun antécédent
   - Zone : Tunis
   - Couverture : Tous risques
5. **Client choisit paiement annuel en espèces**
6. **Agent encaisse 450 TND**
7. **Système génère automatiquement** :
   - Police d'assurance
   - Quittance de paiement
   - Macaron vert 2024
8. **Client repart avec tous ses documents**

### Scénario 2 : Renouvellement Automatique

1. **Système détecte contrat expirant dans 30 jours**
2. **Notification envoyée au conducteur**
3. **Agent traite le renouvellement**
4. **Nouveau contrat généré automatiquement**
5. **Documents mis à jour**

### Scénario 3 : Calcul Prime Complexe

1. **Jeune conducteur (22 ans)**
2. **Véhicule puissant (10 CV)**
3. **Antécédents d'accidents (2 accidents)**
4. **Zone à risque (Tunis)**
5. **Tous risques + options**
6. **Vérifier majoration correcte**

## 🐛 Tests de Régression

### Checklist Avant Release

- [ ] Tous les tests unitaires passent
- [ ] Calculateur de prime fonctionne
- [ ] Paiements traités correctement
- [ ] Documents générés avec QR codes
- [ ] Interfaces responsives
- [ ] Données de test nettoyées
- [ ] Performance acceptable
- [ ] Pas de fuites mémoire

### Tests de Charge

```bash
# Générer beaucoup de données de test
for i in {1..100}; do
  # Créer 100 contrats
  # Tester les performances
done
```

## 📈 Métriques de Qualité

### Couverture de Code Cible

- **Services** : > 90%
- **Modèles** : > 80%
- **Interfaces** : > 70%
- **Global** : > 85%

### Performance Cible

- **Calcul de prime** : < 100ms
- **Génération documents** : < 2s
- **Chargement dashboard** : < 1s
- **Navigation** : < 500ms

## 🔧 Outils de Debug

### Logs de Debug

```dart
// Activer les logs détaillés
debugPrint('[INSURANCE] Calcul prime pour véhicule $vehiculeId');
debugPrint('[PAYMENT] Traitement paiement $montant TND');
debugPrint('[DOCUMENTS] Génération police $numeroContrat');
```

### Firebase Debug

```bash
# Activer les logs Firestore
flutter run --dart-define=FIRESTORE_DEBUG=true
```

### Inspection des Données

```dart
// Vérifier les données dans Firestore
await FirebaseFirestore.instance
    .collection('contrats_assurance')
    .where('isFakeData', isEqualTo: true)
    .get();
```

## 🚀 Tests de Déploiement

### Tests Pre-Production

1. **Build de release**
   ```bash
   flutter build apk --release
   flutter build web --release
   ```

2. **Tests sur vrais appareils**
3. **Validation avec vraies données**
4. **Tests de sécurité**
5. **Tests de sauvegarde/restauration**

---

## 📞 Support

Pour toute question sur les tests :
- Consulter les logs dans la console
- Vérifier les données de test générées
- Utiliser le TestDashboard pour débugger
- Nettoyer les données de test si nécessaire

**Bon testing ! 🧪✨**
