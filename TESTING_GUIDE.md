# 🧪 Guide de Test - Services Business Constat Tunisie

## ✅ **Compilation Réussie !**
```
√ Built build\app\outputs\flutter-apk\app-debug.apk (1342s)
```

---

## 🎯 **Plan de Test Complet**

### **Phase 1 : Tests de Base (15 min)**
1. **Démarrage Application** ✅
2. **Authentification** ✅
3. **Navigation Principale** ✅

### **Phase 2 : Tests Services Business (30 min)**
4. **Nouveau Conducteur** 🆕
5. **Migration Ancien Conducteur** 👴
6. **Paiements Hors App** 💳
7. **Génération Documents** 📄

### **Phase 3 : Tests Avancés (15 min)**
8. **Statistiques** 📊
9. **Gestion d'Erreurs** ⚠️
10. **Performance** ⚡

---

## 🚀 **Étapes de Test Détaillées**

### **1. 📱 Préparation de l'Environnement**

#### **A) Installation de l'APK**
```bash
# Connecter votre téléphone Android
adb devices

# Installer l'APK
adb install build/app/outputs/flutter-apk/app-debug.apk

# Ou copier l'APK sur le téléphone et installer manuellement
```

#### **B) Vérification Firebase**
1. Ouvrir Firebase Console
2. Vérifier que Firestore est actif
3. Vérifier Authentication
4. Vérifier Storage (pour Cloudinary)

#### **C) Préparation des Données de Test**
```
👤 Compte Agent Test:
Email: agent.test@constat.tn
Password: Test123456

👤 Nouveau Conducteur Test:
Nom: Ben Ali
Prénom: Ahmed
CIN: 12345678
Email: ahmed.test@email.com
Téléphone: +216 20 123 456

🚗 Véhicule Test:
Immatriculation: 123 TUN 456
Marque: Peugeot
Modèle: 208
Année: 2020
```

---

### **2. 🔐 Tests de Base (15 min)**

#### **Test 1 : Démarrage Sécurisé**
```
✅ Actions à tester:
1. Lancer l'application
2. Vérifier le splash screen
3. Vérifier que l'app ne plante pas
4. Vérifier les logs de démarrage

🎯 Résultat attendu:
- App démarre sans erreur
- Configuration AppConfig chargée
- LoggingService initialisé
- Firebase connecté
```

#### **Test 2 : Authentification**
```
✅ Actions à tester:
1. Aller à l'écran de connexion
2. Se connecter comme Agent
3. Vérifier le dashboard agent
4. Se déconnecter
5. Se connecter comme Conducteur

🎯 Résultat attendu:
- Connexion réussie
- Redirection vers bon dashboard
- Données utilisateur affichées
```

#### **Test 3 : Navigation Principale**
```
✅ Actions à tester:
1. Naviguer entre les écrans principaux
2. Tester les boutons de navigation
3. Vérifier les permissions par rôle

🎯 Résultat attendu:
- Navigation fluide
- Pas d'erreurs de compilation
- Écrans s'affichent correctement
```

---

### **3. 🆕 Test Nouveau Conducteur (10 min)**

#### **Scénario Complet**
```
📱 Étapes à suivre:

1. **Inscription Nouveau Conducteur**
   - Ouvrir l'app
   - Sélectionner "Nouveau Conducteur"
   - Remplir le formulaire d'inscription
   - Ajouter un véhicule
   - Soumettre la demande

2. **Validation Agent**
   - Se connecter comme Agent
   - Aller dans "Véhicules en Attente"
   - Valider le véhicule du nouveau conducteur
   - Créer un contrat d'assurance

3. **Vérifications**
   ✅ Conducteur créé dans Firestore
   ✅ Véhicule ajouté avec statut "En attente"
   ✅ Contrat proposé généré
   ✅ Notifications envoyées

🎯 Test de Service:
```dart
// Dans Flutter Console ou test unitaire
final result = await ConducteurOnboardingService.createNewConducteur(
  conducteurData: {
    'nom': 'Ben Ali',
    'prenom': 'Ahmed',
    'cin': '12345678',
    'email': 'ahmed.test@email.com',
    'password': 'Test123456',
    'telephone': '+216 20 123 456',
  },
  vehicleData: {
    'numeroImmatriculation': '123 TUN 456',
    'marque': 'Peugeot',
    'modele': '208',
    'annee': 2020,
  },
  selectedOfferId: 'offer_rc_basic',
);

print('✅ Résultat: ${result['success']}');
print('👤 User ID: ${result['userId']}');
print('🚗 Vehicle ID: ${result['vehicleId']}');
```

---

### **4. 👴 Test Migration Ancien Conducteur (10 min)**

#### **Scénario Complet**
```
📱 Étapes à suivre:

1. **Migration par Agent**
   - Se connecter comme Agent
   - Aller dans "Migration Conducteurs"
   - Saisir les données du contrat papier
   - Générer le code d'activation

2. **Activation par Conducteur**
   - Simuler réception SMS/Email
   - Télécharger l'app
   - Saisir le code d'activation
   - Créer mot de passe

3. **Vérifications**
   ✅ Profil migré créé
   ✅ Code d'activation généré
   ✅ Compte activé avec succès
   ✅ Données synchronisées

🎯 Test de Service:
```dart
// Test de migration
final paperContract = PaperContract(
  contractNumber: 'OLD-2023-001',
  conducteurCin: '87654321',
  conducteurName: 'Fatma Trabelsi',
  vehiclePlate: '789 TUN 012',
  vehicleBrand: 'Renault',
  vehicleModel: 'Clio',
  vehicleYear: 2019,
  annualPremium: 450.0,
  startDate: DateTime(2023, 1, 1),
  endDate: DateTime(2023, 12, 31),
  companyName: 'STAR Assurance',
  agencyName: 'Agence Tunis Centre',
  agentId: 'agent_123',
);

final result = await ConducteurOnboardingService.migratePaperConducteur(
  agentId: 'agent_123',
  paperContract: paperContract,
  conducteurPhone: '+216 25 987 654',
  conducteurEmail: 'fatma.test@email.com',
);

print('🔑 Code d\'activation: ${result['activationCode']}');

// Test d'activation
final activation = await ConducteurOnboardingService.activateAccount(
  activationCode: result['activationCode'],
  password: 'NouveauMotDePasse123',
);

print('✅ Activation: ${activation['success']}');
```

---

### **5. 💳 Test Paiements Hors App (10 min)**

#### **Test Méthodes de Paiement**
```
📱 Étapes à suivre:

1. **Génération Référence D17**
   - Créer un contrat en attente de paiement
   - Générer référence D17
   - Vérifier QR Code généré

2. **Génération Référence Virement**
   - Générer référence virement bancaire
   - Vérifier détails bancaires
   - Vérifier instructions

3. **Validation Paiement Agent**
   - Simuler paiement effectué
   - Agent valide le paiement
   - Vérifier activation contrat

🎯 Test de Service:
```dart
// Test génération référence D17
final paymentRef = await OfflinePaymentService.generatePaymentReference(
  contractId: 'contract_123',
  method: PaymentMethod.d17,
  amount: 650.0,
);

print('🔢 Référence: ${paymentRef.referenceNumber}');
print('📱 QR Code: ${paymentRef.qrCode}');

// Test validation paiement
final paymentProof = PaymentProof(
  contractId: 'contract_123',
  method: PaymentMethod.d17,
  amount: 650.0,
  referenceNumber: paymentRef.referenceNumber,
  d17TransactionId: 'TXN789012345',
  paymentDate: DateTime.now(),
  agentId: 'agent_123',
);

await OfflinePaymentService.validatePayment(
  contractId: 'contract_123',
  paymentProof: paymentProof,
);

print('✅ Paiement validé et contrat activé');
```

---

### **6. 📄 Test Génération Documents (5 min)**

#### **Test Documents PDF**
```
📱 Étapes à suivre:

1. **Génération Automatique**
   - Activer un contrat
   - Vérifier génération automatique des PDFs
   - Tester téléchargement documents

2. **Vérifications**
   ✅ Contrat PDF généré
   ✅ Carte Verte PDF générée
   ✅ Quittance PDF générée
   ✅ URLs Cloudinary valides

🎯 Test de Service:
```dart
final documents = await HybridContractService.generateDigitalDocuments('contract_123');

print('📄 Contrat: ${documents['contractPdf']}');
print('🟢 Carte Verte: ${documents['carteVerte']}');
print('🧾 Quittance: ${documents['quittance']}');
```

---

### **7. 📊 Test Statistiques (5 min)**

#### **Test Analytics**
```
🎯 Test de Service:
```dart
// Statistiques onboarding
final onboardingStats = await ConducteurOnboardingService.getOnboardingStats('agent_123');
print('🆕 Nouveaux: ${onboardingStats['newConducteursThisMonth']}');
print('🔄 Migrations: ${onboardingStats['migrationsThisMonth']}');

// Statistiques contrats
final contractStats = await HybridContractService.getContractStats(agentId: 'agent_123');
print('📋 Contrats: ${contractStats['totalThisMonth']}');
print('📈 Conversion: ${contractStats['conversionRate']}%');

// Statistiques paiements
final paymentStats = await OfflinePaymentService.getPaymentStats(agentId: 'agent_123');
print('💰 Paiements: ${paymentStats['paymentsThisMonth']}');
print('💵 Total: ${paymentStats['totalAmountThisMonth']} DT');
```

---

### **8. ⚠️ Test Gestion d'Erreurs (5 min)**

#### **Scénarios d'Erreur**
```
📱 Tests à effectuer:

1. **Erreurs Réseau**
   - Désactiver WiFi/Data
   - Tenter une opération
   - Vérifier message d'erreur utilisateur

2. **Erreurs de Validation**
   - Saisir données invalides
   - Vérifier messages d'erreur
   - Tester code d'activation expiré

3. **Erreurs Permissions**
   - Tenter action sans droits
   - Vérifier blocage approprié

🎯 Résultats attendus:
✅ Messages d'erreur clairs pour l'utilisateur
✅ Logs techniques détaillés
✅ Pas de plantage de l'app
✅ Récupération gracieuse
```

---

## 📋 **Checklist de Validation**

### **✅ Tests Fonctionnels**
- [ ] App démarre sans erreur
- [ ] Authentification fonctionne
- [ ] Navigation fluide
- [ ] Nouveau conducteur peut s'inscrire
- [ ] Migration ancien conducteur fonctionne
- [ ] Codes d'activation valides
- [ ] Paiements D17/Virement/Agence
- [ ] Documents PDF générés
- [ ] Statistiques affichées

### **✅ Tests Techniques**
- [ ] Services compilent sans erreur
- [ ] Firestore connecté
- [ ] Logging fonctionne
- [ ] Gestion d'erreurs robuste
- [ ] Performance acceptable
- [ ] Pas de fuites mémoire

### **✅ Tests Business**
- [ ] Workflow nouveau conducteur complet
- [ ] Workflow migration complet
- [ ] Tous les types de paiement
- [ ] Documents conformes
- [ ] Analytics précises

---

## 🎯 **Résultats Attendus**

### **✅ Succès si :**
- Tous les workflows fonctionnent de bout en bout
- Aucune erreur critique
- Performance acceptable (< 3s par opération)
- Documents générés correctement
- Statistiques cohérentes

### **⚠️ Points d'Attention :**
- Connexion réseau requise pour la plupart des opérations
- Codes d'activation expirent après 7 jours
- Upload PDF vers Cloudinary (actuellement simulé)
- Notifications SMS/Email (actuellement simulées)

---

## 🚀 **Prochaines Étapes après Tests**

1. **Si tests OK :** Déploiement en production
2. **Si problèmes mineurs :** Corrections et re-test
3. **Si problèmes majeurs :** Debug et refactoring

**Votre application est maintenant prête pour des tests complets !** 🧪✨

**Commencez par les tests de base, puis progressez vers les scénarios business avancés.** 📱🎯
