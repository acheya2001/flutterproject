# 🚀 Guide d'Utilisation - Services Business Avancés

## 📋 Vue d'Ensemble

Votre application **Constat Tunisie** dispose maintenant de services business avancés pour gérer intelligemment les deux types de conducteurs :

### 🆕 **Nouveau Conducteur** (Digital Native)
- Inscription 100% mobile
- Validation automatique
- Paiement hors app sécurisé
- Documents numériques instantanés

### 👴 **Ancien Conducteur** (Migration Papier)
- Migration par l'agent
- Code d'activation SMS/Email
- Synchronisation des données existantes
- Conversion documents papier → digital

---

## 🛠️ Services Implémentés

### 1. 📱 **ConducteurOnboardingService**

#### **Nouveau Conducteur**
```dart
// Inscription complète d'un nouveau conducteur
final result = await ConducteurOnboardingService.createNewConducteur(
  conducteurData: {
    'nom': 'Ben Ali',
    'prenom': 'Ahmed',
    'cin': '12345678',
    'email': 'ahmed@email.com',
    'password': 'motdepasse123',
    'telephone': '+216 20 123 456',
    'adresse': 'Tunis, Tunisie',
  },
  vehicleData: {
    'numeroImmatriculation': '123 TUN 456',
    'marque': 'Peugeot',
    'modele': '208',
    'annee': 2020,
    'puissanceFiscale': 5,
  },
  selectedOfferId: 'offer_rc_basic',
);

if (result['success']) {
  print('✅ Conducteur créé: ${result['userId']}');
  print('🚗 Véhicule ajouté: ${result['vehicleId']}');
  print('📄 Contrat demandé: ${result['contractId']}');
}
```

#### **Migration Ancien Conducteur**
```dart
// Migration d'un conducteur existant par l'agent
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
  conducteurEmail: 'fatma@email.com',
);

print('🔑 Code d\'activation: ${result['activationCode']}');
```

#### **Activation Compte Migré**
```dart
// Le conducteur active son compte avec le code reçu
final result = await ConducteurOnboardingService.activateAccount(
  activationCode: '123456',
  password: 'nouveaumotdepasse',
);

if (result['success']) {
  print('✅ Compte activé: ${result['userId']}');
}
```

---

### 2. 📄 **HybridContractService**

#### **Créer Contrat Digital**
```dart
final contractId = await HybridContractService.createDigitalContract(
  vehicleData: vehicleInfo,
  conducteurData: conducteurInfo,
  agentId: 'agent_123',
  typeContrat: 'Tous Risques',
  primeAnnuelle: 650.0,
  dateDebut: DateTime.now(),
  dateFin: DateTime.now().add(Duration(days: 365)),
);

print('📋 Contrat créé: $contractId');
```

#### **Générer Documents PDF**
```dart
final documents = await HybridContractService.generateDigitalDocuments(contractId);

print('📄 Contrat PDF: ${documents['contractPdf']}');
print('🟢 Carte Verte: ${documents['carteVerte']}');
print('🧾 Quittance: ${documents['quittance']}');
```

#### **Activer Contrat après Paiement**
```dart
await HybridContractService.activateContract(
  contractId: contractId,
  agentId: 'agent_123',
  paymentInfo: {
    'method': 'D17',
    'amount': 650.0,
    'reference': 'D17-123456789',
    'date': DateTime.now(),
  },
);

print('✅ Contrat activé et documents générés');
```

---

### 3. 💳 **OfflinePaymentService**

#### **Générer Référence de Paiement**
```dart
final paymentRef = await OfflinePaymentService.generatePaymentReference(
  contractId: contractId,
  method: PaymentMethod.d17,
  amount: 650.0,
);

print('🔢 Référence: ${paymentRef.referenceNumber}');
print('📱 QR Code D17: ${paymentRef.qrCode}');
print('🏦 Détails bancaires: ${paymentRef.bankDetails}');
```

#### **Instructions de Paiement pour Conducteur**
```dart
final instructions = await OfflinePaymentService.getPaymentInstructions(
  contractId: contractId,
  method: PaymentMethod.d17,
);

print('📋 Titre: ${instructions['title']}');
print('📝 Description: ${instructions['description']}');
print('📱 QR Code: ${instructions['qrCode']}');

// Afficher les étapes
for (String step in instructions['steps']) {
  print('• $step');
}
```

#### **Valider Paiement par Agent**
```dart
final paymentProof = PaymentProof(
  contractId: contractId,
  method: PaymentMethod.d17,
  amount: 650.0,
  referenceNumber: 'D17-123456789',
  d17TransactionId: 'TXN789012345',
  paymentDate: DateTime.now(),
  agentId: 'agent_123',
  notes: 'Paiement validé via D17',
);

await OfflinePaymentService.validatePayment(
  contractId: contractId,
  paymentProof: paymentProof,
);

print('✅ Paiement validé et contrat activé');
```

---

## 📊 Statistiques et Analytics

### **Statistiques Onboarding**
```dart
final stats = await ConducteurOnboardingService.getOnboardingStats('agent_123');

print('🆕 Nouveaux conducteurs ce mois: ${stats['newConducteursThisMonth']}');
print('🔄 Migrations ce mois: ${stats['migrationsThisMonth']}');
print('⏳ Activations en attente: ${stats['pendingActivations']}');
```

### **Statistiques Contrats**
```dart
final contractStats = await HybridContractService.getContractStats(agentId: 'agent_123');

print('📋 Contrats ce mois: ${contractStats['totalThisMonth']}');
print('✅ Contrats actifs: ${contractStats['totalActive']}');
print('💳 En attente paiement: ${contractStats['awaitingPayment']}');
print('📈 Taux conversion: ${contractStats['conversionRate']}%');
```

### **Statistiques Paiements**
```dart
final paymentStats = await OfflinePaymentService.getPaymentStats(agentId: 'agent_123');

print('💰 Paiements ce mois: ${paymentStats['paymentsThisMonth']}');
print('💵 Montant total: ${paymentStats['totalAmountThisMonth']} DT');
print('⏳ Paiements en attente: ${paymentStats['pendingPayments']}');
print('📊 Répartition par méthode: ${paymentStats['methodBreakdown']}');
```

---

## 🔄 Flux Complets d'Usage

### **Scénario 1 : Nouveau Conducteur**

```dart
// 1. Inscription
final newConducteur = await ConducteurOnboardingService.createNewConducteur(
  conducteurData: userData,
  vehicleData: vehicleData,
  selectedOfferId: offerId,
);

// 2. Agent valide et crée le contrat
final contractId = await HybridContractService.createDigitalContract(
  vehicleData: vehicleData,
  conducteurData: userData,
  agentId: agentId,
  typeContrat: 'RC',
  primeAnnuelle: 400.0,
  dateDebut: DateTime.now(),
  dateFin: DateTime.now().add(Duration(days: 365)),
);

// 3. Génération référence paiement
final paymentRef = await OfflinePaymentService.generatePaymentReference(
  contractId: contractId,
  method: PaymentMethod.d17,
  amount: 400.0,
);

// 4. Conducteur paie via D17
// ... paiement externe ...

// 5. Agent valide le paiement
await OfflinePaymentService.validatePayment(
  contractId: contractId,
  paymentProof: paymentProof,
);

// ✅ Contrat activé, documents générés automatiquement
```

### **Scénario 2 : Migration Ancien Conducteur**

```dart
// 1. Agent migre le conducteur
final migration = await ConducteurOnboardingService.migratePaperConducteur(
  agentId: agentId,
  paperContract: paperContract,
  conducteurPhone: phone,
  conducteurEmail: email,
);

// 2. Conducteur reçoit SMS/Email avec code
// 3. Conducteur active son compte
final activation = await ConducteurOnboardingService.activateAccount(
  activationCode: receivedCode,
  password: newPassword,
);

// ✅ Compte activé, données synchronisées, documents disponibles
```

---

## 🎯 Avantages des Nouveaux Services

### **✅ Pour les Développeurs**
- Services modulaires et réutilisables
- Gestion d'erreurs robuste intégrée
- Logging automatique des opérations
- Code documenté et maintenable

### **✅ Pour les Agents**
- Interface unifiée pour tous les conducteurs
- Outils de migration simples
- Validation centralisée des paiements
- Statistiques en temps réel

### **✅ Pour les Conducteurs**
- Parcours fluide selon leur profil
- Paiements flexibles (D17, virement, agence)
- Documents numériques instantanés
- QR Code pour contrôles routiers

### **✅ Pour les Compagnies**
- Digitalisation progressive
- Réduction des coûts papier
- Analytics détaillées
- Processus standardisés

---

## 🔧 Intégration dans l'App Existante

Ces services s'intègrent parfaitement dans votre architecture existante :

1. **Utilisent vos services de sécurité** (AppConfig, LoggingService, Exceptions)
2. **Compatible avec Firebase** (Auth, Firestore, Storage)
3. **Respectent vos patterns** (async/await, error handling)
4. **Extensibles** pour futures fonctionnalités

**Votre application est maintenant prête pour gérer intelligemment tous les types de conducteurs !** 🚀✨
