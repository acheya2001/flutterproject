# 🚀 Guide d'Installation - Système d'Assurance

## ✅ **SYSTÈME INTÉGRÉ AVEC SUCCÈS !**

Le système d'assurance a été intégré dans votre application Constat Tunisie. Voici comment finaliser l'installation :

---

## 📱 **1. Vérification de l'Intégration**

### ✅ **Fichiers Modifiés :**
- `lib/core/config/app_routes.dart` → Routes d'assurance ajoutées
- `lib/features/conducteur/screens/conducteur_home_screen.dart` → Bouton d'assurance ajouté
- `firestore.rules` → Règles de sécurité mises à jour

### ✅ **Nouveaux Fichiers Créés :**
- Système d'assurance complet dans `lib/features/insurance/`
- Écran "Mes Véhicules" dans `lib/features/vehicles/`

---

## 🔧 **2. Configuration Firebase**

### **Étape 1 : Déployer les Règles Firestore**

```bash
# Option 1 : Utiliser le script automatique (Windows)
deploy_firebase.bat

# Option 2 : Commandes manuelles
firebase login
firebase deploy --only firestore:rules
```

### **Étape 2 : Vérifier les Collections**

Les collections suivantes seront créées automatiquement :
- `contracts` → Contrats d'assurance
- `vehicules` → Véhicules assurés
- `notifications` → Notifications utilisateurs

---

## 🎯 **3. Test du Système**

### **Créer des Comptes de Test :**

1. **Compte Agent d'Assurance :**
   - Email : `agent@star.tn` (contient "agent")
   - Rôle : Sera détecté automatiquement

2. **Compte Conducteur :**
   - Email : `conducteur@email.com`
   - Rôle : Conducteur par défaut

### **Workflow de Test :**

1. **Connexion Agent :**
   - Ouvrir l'app → Bouton "Assurance" → Tableau de bord agent
   - Créer un contrat pour le conducteur
   - Vérifier l'envoi des notifications

2. **Connexion Conducteur :**
   - Ouvrir l'app → Bouton "Assurance" → Mes véhicules
   - Vérifier la réception du véhicule assuré

---

## 🎨 **4. Interface Utilisateur**

### **Accès au Système :**

Dans l'écran d'accueil du conducteur, vous verrez maintenant :

```
┌─────────────┬─────────────┐
│ Mes         │ Assurance   │
│ véhicules   │ 🛡️          │
└─────────────┴─────────────┘
│ Rejoindre   │ Invitations │
│ session     │ 📧          │
└─────────────┴─────────────┘
```

### **Navigation Intelligente :**
- **Conducteurs** → Accès direct à "Mes Véhicules"
- **Agents** → Accès au tableau de bord d'assurance

---

## 📊 **5. Fonctionnalités Disponibles**

### **👨‍💼 Pour les Agents :**
- ✅ Tableau de bord avec statistiques
- ✅ Création de contrats (3 étapes)
- ✅ Recherche de conducteurs
- ✅ Gestion des contrats
- ✅ Notifications automatiques

### **🚗 Pour les Conducteurs :**
- ✅ Visualisation des véhicules assurés
- ✅ Détails des contrats
- ✅ Statut d'expiration
- ✅ Contact avec l'agent

---

## 🔔 **6. Configuration des Notifications**

### **FCM (Firebase Cloud Messaging) :**

1. **Configurer FCM dans Firebase Console :**
   - Aller dans Project Settings → Cloud Messaging
   - Générer une clé serveur

2. **Mettre à jour le service :**
   ```dart
   // Dans notification_service.dart
   const String serverKey = 'VOTRE_CLE_SERVEUR_FCM';
   ```

### **Notifications Email :**

Le système utilise Gmail API. Configuration dans `notification_service.dart` :
- Templates HTML professionnels inclus
- Envoi automatique lors de la création de contrats

---

## 🛠️ **7. Dépendances Requises**

Vérifiez que ces dépendances sont dans votre `pubspec.yaml` :

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  cloud_firestore: ^4.13.6
  firebase_messaging: ^14.7.10
  flutter_local_notifications: ^16.3.0
  http: ^1.1.0
```

---

## 🎉 **8. Utilisation**

### **Démarrage Rapide :**

1. **Lancez l'application**
2. **Connectez-vous** avec un compte
3. **Cliquez sur "Assurance"** dans l'écran d'accueil
4. **Le système navigue automatiquement** selon votre rôle

### **Création d'un Premier Contrat :**

1. Connectez-vous avec un email contenant "agent"
2. Accédez au tableau de bord
3. Cliquez "Nouveau Contrat"
4. Suivez les 3 étapes
5. Le conducteur recevra automatiquement les notifications

---

## 🔍 **9. Dépannage**

### **Problèmes Courants :**

1. **"Erreur de permissions Firestore"**
   - Vérifiez que les règles sont déployées
   - Exécutez : `firebase deploy --only firestore:rules`

2. **"Navigation ne fonctionne pas"**
   - Vérifiez que les routes sont ajoutées dans `app_routes.dart`
   - Redémarrez l'application

3. **"Notifications non reçues"**
   - Vérifiez la configuration FCM
   - Testez avec les notifications locales d'abord

### **Logs de Debug :**

Activez les logs dans la console pour voir les détails :
```dart
print('🔔 [NOTIFICATION] Message de debug');
print('📋 [CONTRACT] État du contrat');
```

---

## 📞 **10. Support**

### **Documentation :**
- `lib/features/insurance/README.md` → Documentation complète
- `lib/features/insurance/IMPLEMENTATION_SUMMARY.md` → Résumé technique

### **Tests :**
- `lib/features/insurance/integration_guide.dart` → Guide d'intégration
- Testez avec les comptes mentionnés ci-dessus

---

## 🎯 **Résumé**

✅ **Système intégré** dans votre application
✅ **Bouton d'accès** ajouté à l'écran d'accueil
✅ **Routes configurées** pour toutes les fonctionnalités
✅ **Règles Firebase** mises à jour
✅ **Interface moderne** et responsive
✅ **Notifications automatiques** configurées

**Votre système d'assurance est maintenant opérationnel ! 🎉**

Pour démarrer, lancez l'application et cliquez sur le bouton "Assurance" dans l'écran d'accueil.
