# 🧪 Guide de Test - Statuts des Constats PDF

## 📋 Problème Résolu

Le système de gestion des statuts des constats PDF a été corrigé pour assurer un flux cohérent :

1. **Conducteur** → Sessions → Voir Détails → **"Notifier les Agents"**
2. Statut passe à **"Envoyée à l'agent"** ✅
3. Quand un **agent assigne un expert**, statut passe à **"Assigné à un expert"** ✅

## 🔧 Corrections Apportées

### 1. Service de Notification des Agents
**Fichier :** `lib/services/constat_agent_notification_service.dart`

- ✅ Ajout du champ `statutSession` pour compatibilité dashboard
- ✅ Nouvelle fonction `mettreAJourStatutExpertAssigne()` pour gérer l'assignation d'expert
- ✅ Mise à jour automatique du statut dans `constats_finalises`

### 2. Services d'Assignation d'Expert
**Fichiers :** 
- `lib/services/sinistre_expert_assignment_service.dart`
- `lib/services/expert_multi_compagnie_service.dart`

- ✅ Intégration avec le service de notification
- ✅ Mise à jour automatique du statut quand un expert est assigné
- ✅ Propagation des changements vers `constats_finalises`

### 3. Dashboard Conducteur
**Fichier :** `lib/features/conducteur/screens/conducteur_dashboard_complete.dart`

- ✅ Affichage correct des statuts depuis `constats_finalises`
- ✅ Support des nouveaux statuts : `envoye`, `expert_assigne`, `en_expertise`
- ✅ Couleurs et icônes appropriées pour chaque statut

## 🧪 Comment Tester

### Option 1 : Test Automatique (Recommandé)

1. **Ouvrir une session finalisée** dans l'app
2. **Aller dans "Détails de session"**
3. **Cliquer sur l'icône de bug** (🐛) dans l'AppBar (mode debug uniquement)
4. **Suivre les logs** dans la console pour voir le flux complet

### Option 2 : Test Manuel

#### Étape 1 : Notification des Agents
1. Ouvrir une session avec statut `finalise`
2. Aller dans l'onglet **"PDF Agent"**
3. Cliquer sur **"Notifier les Agents"**
4. ✅ Vérifier que le statut passe à **"Envoyé à l'agent"**

#### Étape 2 : Assignation d'Expert
1. Connectez-vous en tant qu'**agent**
2. Allez dans la liste des **constats reçus**
3. **Assignez un expert** à un sinistre
4. ✅ Vérifier que le statut passe à **"Expert assigné"**

#### Étape 3 : Vérification Dashboard Conducteur
1. Retournez au **dashboard conducteur**
2. Allez dans **"Sessions"**
3. ✅ Vérifier l'affichage correct des statuts

## 📊 Statuts Supportés

| Statut | Affichage | Couleur | Description |
|--------|-----------|---------|-------------|
| `finalise` | "Terminé" | Vert | Constat finalisé, prêt à envoyer |
| `envoye` | "Envoyé à l'agent" | Orange | Constat envoyé aux agents d'assurance |
| `expert_assigne` | "Expert assigné" | Violet | Un expert a été assigné au dossier |
| `en_expertise` | "Expertise en cours" | Violet foncé | L'expert examine le véhicule |
| `expertise_terminee` | "Expertise terminée" | Vert | Rapport d'expertise disponible |

## 🔍 Vérification des Données

### Collections Firestore Impliquées

1. **`constats_finalises`** - Collection principale pour le suivi conducteur
   - Champs : `statut`, `statutSession`, `dateEnvoi`, `expertAssigne`

2. **`agent_constats`** - Constats reçus par les agents
   - Champs : `statutTraitement`, `agentEmail`, `sessionId`

3. **`missions_expertise`** - Missions d'expertise
   - Champs : `statut`, `expertId`, `sessionId`

### Logs de Debug

Recherchez ces messages dans la console :

```
🔧 [STATUT] Mise à jour statut expert assigné pour session: xxx
✅ [STATUT] Statut expert assigné mis à jour avec succès
🧪 [TEST] Simulation envoi agent pour session: xxx
🧪 [TEST] Simulation assignation expert pour session: xxx
```

## 🚨 Dépannage

### Problème : Statut ne se met pas à jour
1. Vérifiez les logs de debug
2. Vérifiez que `sessionId` existe dans les données du sinistre
3. Utilisez le bouton de test automatique pour diagnostiquer

### Problème : Expert assigné mais statut incorrect
1. Vérifiez que le service d'assignation appelle bien `mettreAJourStatutExpertAssigne()`
2. Vérifiez les données dans `constats_finalises`

### Problème : Dashboard ne reflète pas les changements
1. Actualisez le dashboard (bouton refresh)
2. Vérifiez que `_getConstatStatusForSession()` lit bien `constats_finalises`

## 📝 Notes Techniques

- Le système utilise `SetOptions(merge: true)` pour éviter d'écraser les données existantes
- Les statuts sont synchronisés entre `constats_finalises` et les autres collections
- Le champ `statutSession` assure la compatibilité avec l'affichage dashboard
- Les fonctions de test sont disponibles uniquement en mode debug (`kDebugMode`)

## ✅ Validation

Le système est considéré comme fonctionnel si :

1. ✅ Notification agents → statut "Envoyé à l'agent"
2. ✅ Assignation expert → statut "Expert assigné"
3. ✅ Dashboard conducteur affiche les bons statuts
4. ✅ Couleurs et icônes appropriées
5. ✅ Logs de debug cohérents
