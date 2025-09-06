# 🧪 Guide de Test - Workflow d'Assurance Complet

## 🎯 **Objectif du Test**
Vérifier le bon fonctionnement du nouveau système d'assurance auto tunisien sans module de paiement intégré.

---

## 📋 **Prérequis**

### 🔧 **Configuration Technique**
- Flutter SDK installé
- Firebase configuré avec Firestore
- Comptes test conducteur et agent
- Règles Firestore appropriées

### 👥 **Utilisateurs de Test**
- **1 Conducteur** avec compte Firebase
- **1 Agent** avec permissions d'agence
- **1 Administrateur** pour vérification

---

## 🔄 **Scénarios de Test à Exécuter**

### 1. **Test de Soumission de Demande (Conducteur)**
```bash
# Lancer l'application
flutter run
```

**Étapes:**
1. Se connecter en tant que conducteur
2. Aller à l'écran "Nouvelle demande d'assurance"
3. Remplir le formulaire véhicule + conducteur
4. Soumettre la demande
5. Vérifier que le statut passe à "pending_agent_review"

**Vérifications:**
- ✅ Données sauvegardées dans Firestore
- ✅ Workflow step à 1/5
- ✅ Notification créée pour l'agent

### 2. **Test de Création de Contrat (Agent)**
```bash
# Ouvrir l'écran nouvelles demandes
flutter run --dart-define=ROUTE=/agent-demandes
```

**Étapes:**
1. Se connecter en tant qu'agent
2. Aller à l'écran "Nouvelles Demandes"
3. Sélectionner une demande en attente
4. Cliquer sur "Créer contrat"
5. Remplir les détails (prime, fréquence, garanties)
6. Valider la création

**Vérifications:**
- ✅ Contrat créé dans Firestore
- ✅ Statut passe à "contract_created_pending_payment"
- ✅ Référence de paiement générée
- ✅ Notification envoyée au conducteur

### 3. **Test de Paiement et Validation (Agent)**
**Étapes:**
1. Conducteur effectue le paiement hors app (simuler)
2. Agent valide le paiement reçu
3. Enregistrer la validation dans le système

**Vérifications:**
- ✅ Statut passe à "completed_insured"
- ✅ Documents générés (PDF, carte verte)
- ✅ Notifications de confirmation

### 4. **Test de Génération de Documents**
**Vérifications:**
- ✅ Contrat PDF généré avec signature électronique
- ✅ Quittance de paiement créée
- ✅ Carte verte digitale avec QR Code
- ✅ Email/SMS envoyé au conducteur

---

## 🧪 **Tests Techniques à Effectuer**

### 🔍 **Tests Unitaires**
```bash
# Lancer les tests unitaires
flutter test test/services_test.dart
flutter test test/simple_test.dart
```

**Services à tester:**
- `CompleteInsuranceWorkflowService`
- `HybridContractService` 
- `OfflinePaymentService`

### 🌐 **Tests d'Intégration Firebase**
```bash
# Vérifier les règles Firestore
firebase deploy --only firestore:rules
```

**Collections à vérifier:**
- `insurance_requests`
- `contracts`
- `notifications`
- `payment_references`

### 📱 **Tests d'Interface Utilisateur**
```bash
# Tests d'interface
flutter test integration_test/app_test.dart
```

**Écrans à tester:**
- `add_vehicle_for_insurance_screen`
- `mes_demandes_assurance_screen`
- `nouvelles_demandes_screen`

---

## 🚨 **Scénarios d'Erreur à Tester**

### 1. **Données manquantes**
- Soumission sans données obligatoires
- Création contrat sans montant

### 2. **Permissions insuffisantes**
- Agent sans accès à l'agence
- Conducteur accédant aux demandes d'autres

### 3. **Connexion perdue**
- Perte connexion pendant soumission
- Reconnexion automatique

### 4. **Données invalides**
- Formats de date incorrects
- Numéros de téléphone invalides
- Immatriculations mal formatées

---

## 📊 **Checklist de Validation**

### ✅ **Fonctionnalités Principales**
- [ ] Soumission demande conducteur
- [ ] Visualisation demandes agent
- [ ] Création contrat avec paramètres
- [ ] Génération référence paiement
- [ ] Validation paiement manuel
- [ ] Génération documents automatique
- [ ] Notifications push/email

### ✅ **Sécurité et Permissions**
- [ ] Règles Firestore fonctionnelles
- [ ] Accès restreints par agence
- [ ] Données sensibles protégées
- [ ] Validation côté serveur

### ✅ **Performance et UX**
- [ ] Temps de chargement acceptable
- [ ] Interface intuitive
- [ ] Messages d'erreur clairs
- [ ] Feedback utilisateur

---

## 🔧 **Outils de Debugging**

### 📝 **Logging**
```dart
// Vérifier les logs en temps réel
LoggingService.info('Test', 'Message de test');
LoggingService.error('Test', 'Erreur test', error);
```

### 🔍 **Inspection Firestore**
```bash
# Voir les données en direct
firebase firestore:list insurance_requests
firebase firestore:list contracts
```

### 📧 **Test Notifications**
```bash
# Vérifier les notifications
firebase functions:log --only sendNotification
```

---

## 📈 **Métriques à Mesurer**

### ⏱️ **Performance**
- Temps de soumission demande: < 3s
- Temps génération contrat: < 2s
- Temps génération documents: < 5s

### 📊 **Utilisation**
- Nombre demandes traitées/heure
- Taux de conversion demande→contrat
- Temps moyen de traitement

### 🐛 **Stabilité**
- Taux d'erreurs < 1%
- Temps uptime > 99.9%
- Recovery time < 1 minute

---

## 🆘 **Résolution de Problèmes**

### ❌ **Demandes non visibles**
```bash
# Vérifier les règles Firestore
firebase firestore:rules
```

### ❌ **Erreurs de création contrat**
```dart
// Vérifier les données
LoggingService.debug('Contract', 'Données: $contractDetails');
```

### ❌ **Documents non générés**
```bash
# Vérifier Cloudinary/PDF service
firebase functions:log --only generateDocuments
```

### ❌ **Notifications non envoyées**
```bash
# Vérifier la configuration email
firebase functions:config:get
```

---

## 🎯 **Plan de Test Recommandé**

### Phase 1: **Tests Développeur** (Maintenant)
- Tests unitaires des services
- Tests d'intégration Firebase
- Validation des règles de sécurité

### Phase 2: **Tests Interne** (1-2 jours)
- Tests fonctionnels complets
- Tests de charge légère
- Validation UX/UI

### Phase 3: **Tests Bêta** (3-5 jours)
- Tests avec vrais utilisateurs
- Feedback et améliorations
- Optimisation performance

### Phase 4: **Déploiement Production** (1 semaine)
- Déploiement progressif
- Monitoring intensif
- Support utilisateurs

---

## ✅ **Critères de Réussite**

### 🟢 **Acceptation Technique**
- 0 erreur de compilation
- 100% des tests unitaires passés
- Règles Firestore validées
- Performance acceptable

### 🟢 **Acceptation Fonctionnelle**
- Workflow complet fonctionnel
- Interface utilisable
- Documents générés correctement
- Notifications opérationnelles

### 🟢 **Acceptation Métier**
- Processus adapté marché tunisien
- Gain de temps pour les agents
- Expérience conducteur satisfaisante
- Réduction des coûts démontrée

---

## 🚀 **Lancement des Tests**

### Commandes de démarrage:
```bash
# Tests unitaires
flutter test

# Tests d'intégration
flutter test integration_test/

# Lancement application
flutter run
```

### Surveillance en temps réel:
```bash
# Logs Firebase
firebase functions:log

# Monitoring Firestore
firebase firestore:list --watch
```

**Le système est prêt pour les tests complets !** 🎉

Commencez par les tests unitaires, puis passez aux tests fonctionnels et enfin aux tests d'intégration complète.
