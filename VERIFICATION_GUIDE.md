# 🔍 GUIDE DE VÉRIFICATION DES DONNÉES FIRESTORE

## 📱 **MÉTHODE 1: Application Mobile**

### 🚀 **Étapes rapides**
1. Lancez l'application de test:
   ```bash
   flutter run lib/test_main.dart
   ```

2. Appuyez sur **"📊 Vérification Données"**

3. Vérifiez que vous voyez:
   - ✅ Nombre de véhicules assurés
   - ✅ Nombre de constats
   - ✅ Compagnies d'assurance (8)
   - ✅ Analytics générées

### 🧪 **Tests automatiques**
- Appuyez sur **"Tester Requêtes"** pour vérifier que toutes les requêtes fonctionnent
- Vérifiez les échantillons de données pour voir si elles sont réalistes

---

## 🌐 **MÉTHODE 2: Console Firebase (Recommandée)**

### 🔗 **Accès direct**
1. Ouvrez: https://console.firebase.google.com/project/constattunisiemail-462921/firestore
2. Connectez-vous avec votre compte Google

### 📊 **Collections à vérifier**

#### **🚗 vehicules_assures**
- **Attendu**: 1000+ documents
- **Vérifiez**:
  - Marques réalistes (Peugeot, Renault, VW...)
  - Immatriculations tunisiennes (123 TUN 456)
  - Contrats avec dates valides
  - Propriétaires avec noms tunisiens

#### **📋 constats**
- **Attendu**: 200+ documents
- **Vérifiez**:
  - Dates d'accident récentes
  - Lieux dans les gouvernorats tunisiens
  - Statuts variés (brouillon, soumis, validé)
  - Montants estimés réalistes

#### **🏢 assureurs_compagnies**
- **Attendu**: 8 documents
- **Vérifiez**:
  - STAR, Maghrebia, GAT, Lloyd...
  - Agences par gouvernorat
  - Statistiques réalistes

#### **📊 analytics**
- **Attendu**: 1+ document
- **Vérifiez**:
  - KPIs calculés
  - Tendances sur 6 mois
  - Zones accidentogènes

---

## 🔍 **MÉTHODE 3: Requêtes de Test**

### 📱 **Dans l'application**
```dart
// Test dans l'écran de vérification
await _firestore
  .collection('vehicules_assures')
  .where('statut', isEqualTo: 'actif')
  .limit(10)
  .get();
```

### 🌐 **Dans la console Firebase**
1. Allez dans **Firestore Database**
2. Cliquez sur une collection
3. Utilisez les filtres pour tester:
   - `statut == 'actif'`
   - `assureur_id == 'STAR'`
   - `created_at > [date récente]`

---

## ✅ **CHECKLIST DE VÉRIFICATION**

### 📊 **Quantités**
- [ ] 1000+ véhicules assurés
- [ ] 200+ constats d'accident
- [ ] 8 compagnies d'assurance
- [ ] 1+ analytics générées

### 🎯 **Qualité des données**
- [ ] Noms tunisiens réalistes
- [ ] Immatriculations au format tunisien
- [ ] Marques de voitures populaires
- [ ] Dates cohérentes (pas dans le futur)
- [ ] Montants réalistes (500-8000 TND)

### 🔧 **Fonctionnalités**
- [ ] Requêtes Firestore fonctionnent
- [ ] Règles de sécurité actives
- [ ] Index automatiques créés
- [ ] Pas d'erreurs dans les logs

### 🏢 **Business Logic**
- [ ] Contrats actifs/expirés
- [ ] Historique sinistres cohérent
- [ ] Répartition géographique (24 gouvernorats)
- [ ] Analytics calculées automatiquement

---

## 🚨 **PROBLÈMES COURANTS**

### ❌ **"Aucune donnée"**
- Vérifiez votre connexion Internet
- Assurez-vous d'être connecté au bon projet Firebase
- Relancez la génération de données

### ❌ **"Erreur de permission"**
- Vérifiez les règles Firestore
- Assurez-vous d'être authentifié
- Vérifiez la configuration Firebase

### ❌ **"Données incohérentes"**
- Relancez le générateur de données
- Vérifiez les logs de l'application
- Nettoyez et régénérez si nécessaire

---

## 🎯 **VALIDATION POUR PFE**

### 📊 **Critères de réussite**
1. **Volume**: Minimum 1000 véhicules
2. **Réalisme**: Données tunisiennes authentiques
3. **Cohérence**: Pas d'erreurs logiques
4. **Performance**: Requêtes < 2 secondes
5. **Sécurité**: Règles Firestore actives

### 🎉 **Démonstration**
- Montrez la console Firebase avec les données
- Testez les requêtes en temps réel
- Affichez les analytics automatiques
- Démontrez la recherche et filtrage

---

## 📞 **SUPPORT**

Si vous rencontrez des problèmes:
1. Vérifiez d'abord la console Firebase
2. Consultez les logs de l'application
3. Utilisez l'écran de vérification intégré
4. Régénérez les données si nécessaire

**Votre base de données est prête pour la soutenance ! 🎓**
