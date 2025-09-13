# 🔧 GUIDE DE DÉPANNAGE - WORKFLOW PAIEMENT

## 🎯 Problème Résolu

**Symptôme :** L'agent valide les documents mais le conducteur ne reçoit pas la notification "Dossier Validé - Paiement Requis"

**Cause :** La fonction `_marquerDocumentsCompletes` ne créait que le statut `documents_completes` sans envoyer la notification de paiement requis.

## ✅ Solution Appliquée

### 1. Correction de la Fonction Agent
**Fichier :** `lib/features/agent/screens/agent_requests_screen.dart`

**Changements :**
- Fonction `_marquerDocumentsCompletes` modifiée pour envoyer la notification `paiement_requis`
- Génération automatique du numéro de contrat
- Création de la notification avec priorité haute
- Logs détaillés pour le débogage

### 2. Correction de la Validation Conducteur
**Fichier :** `lib/features/conducteur/screens/notifications_screen.dart`

**Changements :**
- Fonction `_navigateToChoixFrequence` accepte maintenant le statut `documents_completes`
- Vérification élargie des statuts valides pour le paiement

## 🔄 Workflow Corrigé

### Étape 1 : Agent Valide Documents
```
Agent clique "Valider Documents" 
→ Statut: affectee → documents_completes
→ Génération numéro de contrat
→ Création notification paiement_requis
→ Message: "Documents validés ! Notification envoyée au conducteur"
```

### Étape 2 : Conducteur Reçoit Notification
```
Notification: "Dossier Validé - Paiement Requis"
→ Conducteur clique sur la notification
→ Navigation vers ChoixFrequencePaiementScreen
→ Choix de la fréquence (annuel/trimestriel/mensuel)
```

### Étape 3 : Conducteur Choisit Fréquence
```
Conducteur sélectionne fréquence
→ Statut: documents_completes → frequence_choisie
→ Création du paiement en attente
→ Notification à l'agent
```

### Étape 4 : Agent Encaisse
```
Agent voit demande dans onglet "Prêt 💰"
→ Bouton "💰 Encaisser" disponible
→ Validation du paiement
→ Statut: frequence_choisie → contrat_actif
```

## 🧪 Test du Workflow

### Test Automatique
```bash
# Exécuter le script de test
dart test_workflow_paiement.dart
```

### Test Manuel

#### 1. Côté Agent
1. Se connecter en tant qu'agent
2. Aller dans "Demandes Affectées"
3. Sélectionner une demande avec statut "affectee"
4. Cliquer "Valider Documents"
5. Vérifier le message de succès

#### 2. Côté Conducteur
1. Se connecter en tant que conducteur
2. Aller dans "Mes Notifications"
3. Vérifier la présence de "Dossier Validé - Paiement Requis"
4. Cliquer sur la notification
5. Vérifier l'ouverture de l'écran de choix de paiement

#### 3. Retour Agent
1. Après choix du conducteur
2. Vérifier l'onglet "Prêt 💰"
3. Voir la demande avec bouton "Encaisser"

## 🔍 Points de Vérification

### Base de Données Firestore

#### Collection `demandes_contrats`
```json
{
  "statut": "documents_completes",
  "numeroContrat": "CTR1234567890",
  "dateDocumentsCompletes": "timestamp",
  "agentDocuments": "agent_id"
}
```

#### Collection `notifications`
```json
{
  "conducteurId": "conducteur_id",
  "type": "paiement_requis",
  "titre": "Dossier Validé - Paiement Requis",
  "message": "Votre dossier est complet ! Merci de vous présenter...",
  "demandeId": "demande_id",
  "numeroContrat": "CTR1234567890",
  "priorite": "haute",
  "lu": false
}
```

## 🚨 Dépannage Avancé

### Problème : Notification Non Reçue

#### Vérifications :
1. **Firestore Rules :** Vérifier que le conducteur peut lire ses notifications
2. **ID Conducteur :** S'assurer que `conducteurId` est correct
3. **Logs Console :** Vérifier les logs dans la console de débogage

#### Solutions :
```dart
// Vérifier les notifications en console
print('🔍 Vérification notifications pour: $conducteurId');
final notifications = await FirebaseFirestore.instance
    .collection('notifications')
    .where('conducteurId', isEqualTo: conducteurId)
    .where('type', isEqualTo: 'paiement_requis')
    .get();
print('📧 Notifications trouvées: ${notifications.docs.length}');
```

### Problème : Navigation Échoue

#### Vérifications :
1. **Statut Demande :** Vérifier que le statut est `documents_completes`
2. **Données Demande :** S'assurer que toutes les données requises sont présentes
3. **Permissions :** Vérifier les permissions Firestore

#### Solutions :
```dart
// Debug navigation
print('📋 Données demande: $demandeData');
print('📊 Statut actuel: ${demandeData['statut']}');
print('🔢 Numéro contrat: ${demandeData['numeroContrat']}');
```

### Problème : Bouton Encaisser Absent

#### Vérifications :
1. **Statut :** Demande doit être `frequence_choisie`
2. **Paiement :** Un paiement en attente doit exister
3. **Agent :** L'agent doit être le bon agent assigné

#### Solutions :
```dart
// Vérifier paiement
final paiements = await FirebaseFirestore.instance
    .collection('paiements')
    .where('demandeId', isEqualTo: demandeId)
    .where('statut', isEqualTo: 'en_attente')
    .get();
print('💰 Paiements en attente: ${paiements.docs.length}');
```

## 📞 Support

En cas de problème persistant :

1. **Logs :** Activer les logs détaillés
2. **Firestore :** Vérifier directement dans la console Firebase
3. **Test :** Utiliser le script de test automatique
4. **Reset :** Recréer une demande de test si nécessaire

## 🎉 Validation du Succès

Le workflow fonctionne correctement quand :

✅ Agent peut valider les documents  
✅ Conducteur reçoit la notification  
✅ Conducteur peut choisir la fréquence  
✅ Agent peut encaisser le paiement  
✅ Contrat devient actif  

**Le système est maintenant opérationnel pour le processus complet de gestion des contrats !**
