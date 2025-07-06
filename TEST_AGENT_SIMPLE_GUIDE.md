# 🧪 **GUIDE DE TEST - SYSTÈME AGENT SIMPLIFIÉ**

## 🎯 **PROBLÈMES RÉSOLUS**

**✅ NAVIGATION CORRIGÉE** : L'application utilisait `ProfessionalLoginScreen` au lieu de `AgentLoginScreen`

**✅ ERREUR PIGEONUSERDETAILS CORRIGÉE** : Gestion automatique des comptes Firebase Auth sans données Firestore

**✅ MODIFICATIONS APPLIQUÉES** :
- `user_type_selection_screen.dart` → Navigation vers `AgentLoginScreen` pour les assureurs
- `user_type_selection_screen.dart` → Navigation vers `AgentRegistrationScreen` pour l'inscription
- `simple_agent_service.dart` → Récupération automatique des profils manquants
- `simple_agent_service.dart` → Méthode de nettoyage et recréation des données de test

## 📱 **ÉTAPES DE TEST**

### **1️⃣ Accéder à l'Écran Agent**

1. **Lancer l'application**
2. **Cliquer sur "Agent d'Assurance"** (carte bleue avec icône business)
3. **Cliquer sur "Se connecter"**

**✅ RÉSULTAT ATTENDU** : Vous devriez maintenant voir l'écran avec :
- **Titre** : "Connexion Agent d'Assurance"
- **Bouton 🧪** dans l'AppBar (en haut à droite)
- **Message bleu** : "🔐 CONNEXION AGENT SIMPLIFIÉE"
- **Instructions** : "Cliquez sur 'Créer agents de test' (🧪) puis utilisez: agent@star.tn / agent123"

### **2️⃣ Nettoyer et Recréer les Données de Test**

1. **Cliquer sur l'icône 🧪** dans l'AppBar
2. **Attendre le dialog de chargement** : "Création des agents de test..."
3. **Vérifier le message de succès** : "✅ Agents de test créés avec succès !"

**🔧 NOUVEAU** : Cette action nettoie automatiquement les anciens comptes problématiques et recrée des données propres.

### **3️⃣ Tester la Connexion**

1. **Saisir** : `agent@star.tn`
2. **Saisir** : `agent123`
3. **Cliquer** : "🔐 SE CONNECTER" (bouton bleu)

**✅ RÉSULTAT ATTENDU** :
- **Message de bienvenue** : "✅ Bienvenue Ahmed Ben Ali\nSTAR Assurances - Agence Tunis Centre\nTunis - Agent Commercial"
- **Navigation** vers l'interface assureur

### **4️⃣ Tester l'Inscription**

1. **Retourner** à la sélection de type d'utilisateur
2. **Cliquer** sur "Agent d'Assurance"
3. **Cliquer** sur "S'inscrire"

**✅ RÉSULTAT ATTENDU** : Vous devriez voir l'écran d'inscription avec :
- **Titre** : "Inscription Agent d'Assurance"
- **Formulaire en 3 étapes**
- **Bouton email de test** (si présent)

## 🔍 **VÉRIFICATIONS TECHNIQUES**

### **Navigation Corrigée**

**AVANT** :
```dart
// Utilisait toujours ProfessionalLoginScreen
Navigator.push(context, MaterialPageRoute(
  builder: (context) => ProfessionalLoginScreen(userType: userType)
));
```

**APRÈS** :
```dart
// Utilise AgentLoginScreen pour les assureurs
if (userType == 'assureur') {
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => const AgentLoginScreen()
  ));
} else {
  // Garde l'ancien système pour les experts
  Navigator.push(context, MaterialPageRoute(
    builder: (context) => ProfessionalLoginScreen(userType: userType)
  ));
}
```

### **Fichiers Modifiés**

1. **`user_type_selection_screen.dart`** :
   - ✅ Import `agent_login_screen.dart`
   - ✅ Import `agent_registration_screen.dart`
   - ✅ Navigation conditionnelle pour assureurs
   - ✅ Navigation conditionnelle pour inscription

2. **`agent_login_screen.dart`** :
   - ✅ Bouton 🧪 dans l'AppBar
   - ✅ Méthode `_createTestData()`
   - ✅ Service `SimpleAgentService`
   - ✅ Interface bleue moderne

3. **`agent_registration_screen.dart`** :
   - ✅ Service `SimpleAgentService`
   - ✅ Inscription directe
   - ✅ Message de succès adapté

## 🎯 **COMPTES DE TEST DISPONIBLES**

Après avoir cliqué sur 🧪, ces comptes seront créés :

```
📧 agent@star.tn
🔑 agent123
🏢 STAR Assurances - Agence Tunis Centre
📍 Tunis - Agent Commercial
```

```
📧 agent@gat.tn
🔑 agent123
🏢 GAT Assurances - Agence Ariana
📍 Ariana - Conseiller Clientèle
```

```
📧 agent@bh.tn
🔑 agent123
🏢 BH Assurances - Agence Sousse
📍 Sousse - Chargé de Sinistres
```

```
📧 hammami123rahma@gmail.com
🔑 Acheya123
🏢 STAR Assurances - Agence Manouba
📍 Manouba - Responsable Agence
```

## 🚨 **SI ÇA NE FONCTIONNE TOUJOURS PAS**

### **Vérifications à Faire**

1. **Hot Reload** : Appuyez sur `r` dans le terminal Flutter
2. **Hot Restart** : Appuyez sur `R` dans le terminal Flutter
3. **Rebuild complet** : Arrêtez et relancez `flutter run`

### **Vérifier les Logs**

Dans le terminal Flutter, cherchez :
```
[AgentLogin] 🧪 Création des données de test...
[AgentTestData] 🧪 Création des agents de test...
[AgentTestData] ✅ Agent créé: Ahmed Ben Ali (agent@star.tn)
```

### **Vérifier la Navigation**

Si vous voyez encore l'ancien écran :
1. **Vérifiez** que vous cliquez bien sur "Agent d'Assurance" (pas Expert)
2. **Vérifiez** que vous cliquez sur "Se connecter" dans le modal
3. **Redémarrez** complètement l'application

## 🎉 **RÉSULTAT FINAL ATTENDU**

**✅ Interface Agent Moderne** :
- Écran bleu avec bouton de test
- Création automatique des agents
- Connexion simple et fiable
- Navigation vers l'interface assureur

**✅ Système Opérationnel** :
- Inscription directe (comme conducteurs)
- Connexion immédiate (comme conducteurs)
- Pas d'erreurs PigeonUserDetails
- Pas de problèmes réseau complexes

---

## 📞 **SUPPORT**

Si le problème persiste après ces vérifications :
1. **Vérifiez** les logs dans le terminal
2. **Testez** avec un autre compte
3. **Redémarrez** l'application complètement

**Le système devrait maintenant fonctionner exactement comme celui des conducteurs !** 🎯
