# 🚀 Scénarios Business - Constat Tunisie

## 📋 Vue d'Ensemble

Votre application doit gérer **deux types de conducteurs** avec des parcours différents :

### 🆕 **Nouveau Conducteur** (100% Digital)
- Jamais assuré avant
- S'inscrit directement via l'app
- Parcours entièrement numérique

### 👴 **Ancien Conducteur** (Migration Papier → Digital)
- Déjà client avec contrats papier
- Migré par l'agent vers l'app
- Synchronisation des données existantes

---

## 🔄 Scénario 1 : Nouveau Conducteur (Digital Native)

### **Étapes du Flux :**

1. **📱 Inscription Mobile**
   ```
   Conducteur → Télécharge l'app → Crée son compte
   ├── Informations personnelles (CIN, nom, prénom, etc.)
   ├── Upload documents (CIN, permis de conduire)
   └── Validation email/SMS
   ```

2. **🚗 Ajout Véhicule**
   ```
   Conducteur → Ajoute son véhicule
   ├── Carte grise (scan/photo)
   ├── Photos du véhicule
   ├── Informations techniques
   └── Statut: "En attente de validation"
   ```

3. **💼 Demande de Contrat**
   ```
   Conducteur → Choisit son offre
   ├── Type: RC, Tiers+, Tous Risques
   ├── Options supplémentaires
   └── Statut: "Demande soumise"
   ```

4. **✅ Validation Agent**
   ```
   Agent → Reçoit la demande
   ├── Vérifie les documents
   ├── Valide l'identité et le véhicule
   ├── Calcule la prime
   └── Statut: "Contrat proposé"
   ```

5. **💳 Paiement (Hors App)**
   ```
   Conducteur → Reçoit les détails de paiement
   ├── QR Code pour D17
   ├── Référence pour virement
   ├── Adresse agence pour paiement cash
   └── Statut: "En attente de paiement"
   ```

6. **🔒 Activation Assurance**
   ```
   Agent → Confirme le paiement
   ├── Valide la réception
   ├── Active le contrat
   └── Statut: "Assuré" ✅
   ```

7. **📄 Documents Numériques**
   ```
   Système → Génère automatiquement
   ├── Contrat PDF signé électroniquement
   ├── Carte verte digitale avec QR Code
   ├── Quittance de paiement
   └── Envoi push + email
   ```

---

## 🔄 Scénario 2 : Ancien Conducteur (Migration)

### **Étapes du Flux :**

1. **👨‍💼 Création par l'Agent**
   ```
   Agent → Crée le profil digital
   ├── Import depuis base papier
   ├── Saisie manuelle des données
   ├── Scan des contrats existants
   └── Génération code d'activation
   ```

2. **📧 Invitation Conducteur**
   ```
   Système → Envoie invitation
   ├── SMS avec lien de téléchargement
   ├── Email avec code d'activation
   └── Instructions d'installation
   ```

3. **📱 Activation Compte**
   ```
   Conducteur → Active son compte
   ├── Télécharge l'app
   ├── Saisit le code d'activation
   ├── Définit son mot de passe
   └── Statut: "Compte activé"
   ```

4. **🔄 Synchronisation Données**
   ```
   Système → Synchronise automatiquement
   ├── Historique d'assurance
   ├── Véhicules assurés
   ├── Contrats en cours
   ├── Dates d'échéance
   └── Documents numérisés
   ```

5. **📄 Conversion Numérique**
   ```
   Système → Convertit les documents
   ├── Contrat papier → PDF numérique
   ├── Génération carte verte digitale
   ├── Création QR Code officiel
   └── Archivage sécurisé
   ```

6. **🔔 Notifications Futures**
   ```
   Système → Active les notifications
   ├── Rappels d'échéance
   ├── Renouvellement automatique
   └── Suivi digital complet
   ```

---

## 🏗️ Implémentation Technique Recommandée

### **1. Nouveaux Services à Créer**

```dart
// Service de gestion des parcours conducteur
class ConducteurOnboardingService {
  // Nouveau conducteur
  static Future<void> createNewConducteur(ConducteurData data);
  
  // Migration ancien conducteur
  static Future<void> migratePaperConducteur(String agentId, PaperContractData data);
  
  // Activation compte
  static Future<void> activateAccount(String activationCode);
}

// Service de gestion des contrats hybrides
class HybridContractService {
  // Contrat numérique (nouveau)
  static Future<String> createDigitalContract(VehicleData vehicle, ConducteurData conducteur);
  
  // Migration contrat papier
  static Future<String> migrateFromPaper(PaperContract paperContract);
  
  // Génération documents
  static Future<void> generateDigitalDocuments(String contractId);
}

// Service de paiement hors app
class OfflinePaymentService {
  // Génération références paiement
  static Future<PaymentReference> generatePaymentReference(String contractId);
  
  // Validation paiement par agent
  static Future<void> validatePayment(String contractId, PaymentProof proof);
}
```

### **2. Nouveaux États de Contrat**

```dart
enum ContractStatus {
  // Nouveau conducteur
  pendingValidation,     // En attente validation agent
  contractProposed,      // Contrat proposé
  awaitingPayment,       // En attente paiement
  active,               // Assuré actif
  
  // Migration
  paperMigration,       // En cours de migration
  activationPending,    // En attente activation conducteur
  synchronized,         // Synchronisé avec succès
  
  // Communs
  expired,              // Expiré
  cancelled,            // Annulé
}
```

### **3. Écrans à Ajouter/Modifier**

```
📱 Nouveaux Écrans:
├── onboarding/
│   ├── conducteur_type_selection_screen.dart
│   ├── new_conducteur_registration_screen.dart
│   └── account_activation_screen.dart
├── migration/
│   ├── paper_migration_screen.dart (pour agents)
│   └── activation_success_screen.dart
└── payment/
    ├── offline_payment_options_screen.dart
    └── payment_confirmation_screen.dart
```

---

## 📊 Avantages de cette Approche

### **✅ Pour les Nouveaux Conducteurs**
- Expérience 100% digitale moderne
- Processus rapide et intuitif
- Documents immédiatement disponibles
- QR Code pour contrôles routiers

### **✅ Pour les Anciens Conducteurs**
- Migration douce sans perte de données
- Pas de rupture de service
- Historique préservé
- Adoption progressive du digital

### **✅ Pour les Compagnies d'Assurance**
- Digitalisation progressive de la clientèle
- Réduction des coûts papier
- Meilleur suivi et analytics
- Processus standardisés

### **✅ Pour les Agents**
- Outils unifiés pour tous les clients
- Moins de paperasse
- Validation centralisée
- Efficacité améliorée

---

## 🎯 Prochaines Étapes d'Implémentation

1. **Phase 1** : Créer les services de base (ConducteurOnboardingService)
2. **Phase 2** : Implémenter les écrans de parcours
3. **Phase 3** : Ajouter la gestion des paiements hors app
4. **Phase 4** : Créer les outils de migration pour agents
5. **Phase 5** : Tests et déploiement progressif

**Voulez-vous que je commence l'implémentation de ces scénarios dans votre architecture existante ?** 🚀
