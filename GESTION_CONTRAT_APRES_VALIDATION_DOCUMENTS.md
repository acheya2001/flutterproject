# 📋 **Gestion de Contrat Après Validation des Documents**

## 🎯 **Vue d'Ensemble du Processus**

Après que l'agent ait validé les documents du conducteur, le système entre dans une phase critique de **gestion de contrat** avec plusieurs étapes automatisées et manuelles.

---

## 🔄 **Workflow Complet de Gestion de Contrat**

### **📝 Étape 1: Validation des Documents par l'Agent**
**Statut Initial:** `pending_agent_review`

#### **Actions de l'Agent:**
- ✅ **Vérification des documents** (CIN, permis, carte grise)
- ✅ **Validation des informations véhicule** (marque, modèle, année)
- ✅ **Contrôle de conformité** des données soumises
- ✅ **Approbation finale** des documents

#### **Fichiers Impliqués:**
- `lib/features/agent/screens/pending_vehicles_management_screen.dart`
- `lib/services/digital_contract_service.dart`
- `lib/services/vehicle_workflow_service.dart`

#### **Code de Validation:**
```dart
await DigitalContractService.validateVehicleByAdmin(
  vehicleId: vehicleId,
  adminId: user.uid,
  assignedAgentId: agentId,
  notes: notes,
);
```

---

### **🏗️ Étape 2: Création du Contrat par l'Agent**
**Statut:** `contract_created_pending_payment`

#### **Interface Agent - Création de Contrat:**
**Écran:** `lib/features/agent/screens/contract_creation_screen.dart`

#### **Éléments de Configuration:**
1. **📋 Type de Contrat:**
   - 🛡️ **Responsabilité Civile** (300 DT base)
   - 🔒 **Tiers + Vol** (600 DT base)
   - 💎 **Tous Risques** (1200 DT base)
   - ⏰ **Temporaire** (150 DT base)

2. **💰 Calcul de Prime:**
   ```dart
   double get basePrime {
     switch (this) {
       case ContractType.responsabiliteCivile: return 300.0;
       case ContractType.tiersPlusVol: return 600.0;
       case ContractType.tousRisques: return 1200.0;
       case ContractType.temporaire: return 150.0;
     }
   }
   ```

3. **📅 Fréquence de Paiement:**
   - 📆 **Mensuel** (12 paiements)
   - 📆 **Trimestriel** (4 paiements)
   - 📆 **Annuel** (1 paiement)

4. **🛡️ Garanties Sélectionnables:**
   - ✅ Responsabilité civile (obligatoire)
   - ✅ Vol et incendie
   - ✅ Bris de glace
   - ✅ Catastrophes naturelles
   - ✅ Assistance dépannage

#### **Processus de Création:**
```dart
final contractId = await DigitalContractService.startContractCreation(
  vehicleId: widget.vehicleId,
  agentId: user.uid,
  contractType: _selectedContractType,
  garanties: selectedGarantiesList,
  primeAnnuelle: _calculatedPrime,
  paymentFrequency: _selectedPaymentFrequency,
);
```

#### **Actions Automatiques:**
1. **📄 Génération numéro de contrat** unique
2. **💾 Sauvegarde en base Firestore** (`contracts` collection)
3. **🔔 Notification au conducteur** via `NotificationService`
4. **📧 Email automatique** avec détails du contrat
5. **📊 Mise à jour statistiques** agent/agence

---

### **💳 Étape 3: Proposition de Contrat au Conducteur**
**Statut:** `contract_proposed`

#### **Interface Conducteur - Réception du Contrat:**
**Écran:** `lib/features/conducteur/screens/mes_contrats_dashboard.dart`

#### **Informations Affichées au Conducteur:**
```dart
// Détails du contrat proposé
Widget _buildContractDetails() {
  return Column(
    children: [
      _buildDetailRow('Numéro de contrat', contract['numeroContrat']),
      _buildDetailRow('Type', contract['typeContrat']),
      _buildDetailRow('Prime annuelle', '${contract['primeAnnuelle']} DT'),
      _buildDetailRow('Fréquence', contract['frequencePaiement']),
      _buildDetailRow('Date début', _formatDate(contract['dateDebut'])),
      _buildDetailRow('Date fin', _formatDate(contract['dateFin'])),
    ],
  );
}
```

#### **Actions Disponibles pour le Conducteur:**
1. **✅ Accepter le contrat** → Passage à l'étape paiement
2. **❌ Refuser le contrat** → Retour en négociation
3. **💬 Demander modification** → Contact agent
4. **📄 Télécharger PDF** → Aperçu contrat

---

### **💰 Étape 4: Gestion des Paiements**
**Statut:** `awaiting_payment`

#### **Modes de Paiement Supportés:**

1. **🏢 Paiement à l'Agence:**
   - 💵 Espèces
   - 💳 Terminal de paiement (TPE)
   - 📄 Reçu physique

2. **📱 Paiement Mobile D17:**
   - 📲 Application D17
   - 🔢 Code de transaction
   - ✅ Confirmation automatique

3. **🏦 Virement Bancaire:**
   - 📋 RIB de l'agence
   - 📄 Justificatif de virement
   - ✅ Validation manuelle

4. **📮 Chèque/Poste:**
   - 📝 Chèque bancaire
   - 📮 Mandat postal
   - ⏳ Délai d'encaissement

#### **Interface de Validation Paiement:**
**Écran:** `lib/features/agent/screens/validation_paiement_screen.dart`

```dart
Future<void> _validerPaiement() async {
  final success = await PaiementService.validerPaiement(
    paiementId: widget.paiement.id,
    agentId: widget.agentId,
    modePaiement: _modePaiementSelectionne,
    montantRecu: montantRecu,
  );
}
```

---

### **✅ Étape 5: Activation du Contrat**
**Statut:** `active` (Assuré)

#### **Actions Automatiques Après Paiement:**
1. **📄 Génération documents numériques:**
   - 🟢 **Carte Verte d'Assurance**
   - 📋 **Certificat d'Assurance**
   - 📄 **Conditions Générales**
   - 🔖 **Vignette Numérique**

2. **🔄 Mise à jour statuts:**
   ```dart
   await _firestore.collection('contracts').doc(contractId).update({
     'status': ContractStatus.active,
     'paymentStatus': 'paid',
     'paymentValidatedAt': FieldValue.serverTimestamp(),
     'paymentValidatedBy': agentId,
   });
   ```

3. **🔔 Notifications multiples:**
   - 📱 **Notification in-app** au conducteur
   - 📧 **Email de confirmation** avec documents
   - 📊 **Mise à jour dashboard** agent
   - 📈 **Statistiques agence/compagnie**

#### **Documents Générés:**
```dart
final documentsResult = await _generateDigitalDocuments(contractId);
// Génère: carte verte, certificat, conditions générales
```

---

### **📊 Étape 6: Suivi Post-Activation**
**Statut:** `active` → Gestion continue

#### **Fonctionnalités de Suivi:**

1. **📅 Gestion des Échéances:**
   - ⏰ Rappels de paiement automatiques
   - 📧 Notifications avant échéance
   - 🔄 Renouvellement automatique

2. **📋 Gestion des Sinistres:**
   - 🚗 Déclaration d'accident
   - 📸 Upload photos/documents
   - 👨‍💼 Assignation expert
   - 💰 Traitement indemnisation

3. **📈 Suivi Performance:**
   - 📊 Dashboard agent avec KPIs
   - 📈 Statistiques de conversion
   - 💰 Chiffre d'affaires généré
   - ⭐ Satisfaction client

---

## 🎯 **États de Contrat et Transitions**

### **📋 Énumération des États:**
```dart
enum ContractStatus {
  // Nouveau conducteur
  pendingValidation,     // En attente validation agent
  contractProposed,      // Contrat proposé
  awaitingPayment,       // En attente paiement
  active,               // Assuré actif
  
  // Migration papier
  paperMigration,       // En cours de migration
  activationPending,    // En attente activation conducteur
  synchronized,         // Synchronisé avec succès
  
  // États finaux
  expired,              // Expiré
  cancelled,            // Annulé
  suspended,            // Suspendu
}
```

### **🔄 Diagramme de Transition:**
```
pending_agent_review
        ↓ (agent valide documents)
contract_created_pending_payment
        ↓ (agent crée contrat)
contract_proposed
        ↓ (conducteur accepte)
awaiting_payment
        ↓ (paiement reçu)
active
        ↓ (contrat actif)
[expired/renewed/cancelled]
```

---

## 🛠️ **Services et Fichiers Clés**

### **📁 Services Principaux:**
- `CompleteInsuranceWorkflowService` - Workflow complet
- `DigitalContractService` - Gestion contrats numériques
- `OfflinePaymentService` - Validation paiements
- `PostContractService` - Actions post-création
- `NotificationService` - Notifications système

### **📱 Écrans Agent:**
- `AgentDashboardScreen` - Dashboard principal
- `ContractCreationScreen` - Création contrats
- `ValidationPaiementScreen` - Validation paiements
- `PendingVehiclesManagementScreen` - Gestion véhicules

### **📱 Écrans Conducteur:**
- `MesContratsDashboard` - Mes contrats
- `ContractDetailsScreen` - Détails contrat
- `PaymentScreen` - Interface paiement

---

## 🎯 **Métriques et KPIs**

### **📊 Indicateurs Agent:**
- ⏱️ **Temps moyen de traitement** des demandes
- 💰 **Taux de conversion** demande → contrat
- ⭐ **Satisfaction client** (notes/avis)
- 📈 **Chiffre d'affaires** généré

### **📈 Indicateurs Agence:**
- 📋 **Volume de contrats** créés
- 💰 **Prime moyenne** par contrat
- 🔄 **Taux de renouvellement**
- 📊 **Performance par agent**

Cette documentation couvre l'intégralité du processus de gestion de contrat après validation des documents, avec tous les détails techniques et les interfaces utilisateur impliquées.
