# 🔥 Configuration Firebase Functions + SendGrid

## 📋 **Guide Complet d'Installation**

### **Étape 1 : Configuration SendGrid**

1. **Créer un compte SendGrid**
   - Allez sur [SendGrid.com](https://sendgrid.com)
   - Créez un compte gratuit (100 emails/jour)

2. **Créer une clé API**
   - Connectez-vous à SendGrid
   - Allez dans **Settings > API Keys**
   - Cliquez **Create API Key**
   - Nom: `Constat Tunisie App`
   - Permissions: **Restricted Access**
   - Cochez **Mail Send** (Full Access)
   - Cliquez **Create & View**
   - **COPIEZ LA CLÉ** (elle commence par `SG.`)

3. **Vérifier votre email d'expéditeur**
   - Allez dans **Settings > Sender Authentication**
   - Cliquez **Verify a Single Sender**
   - Remplissez avec votre email: `hammami123rahma@gmail.com`
   - Vérifiez votre email et cliquez le lien de confirmation

### **Étape 2 : Configuration Firebase**

1. **Configurer la clé SendGrid dans Firebase**
   ```bash
   firebase functions:config:set sendgrid.key="VOTRE_CLE_SENDGRID_ICI"
   ```
   
   Remplacez `VOTRE_CLE_SENDGRID_ICI` par votre vraie clé SendGrid.

2. **Vérifier la configuration**
   ```bash
   firebase functions:config:get
   ```

3. **Déployer les fonctions**
   ```bash
   firebase deploy --only functions
   ```

### **Étape 3 : Test de l'Installation**

1. **Lancez votre app Flutter**
2. **Allez dans l'écran d'invitation**
3. **Cliquez "Test Firebase"**
4. **Vérifiez votre email** `hammami123rahma@gmail.com`

### **🚨 Résolution des Problèmes**

#### **Erreur: "sendgrid.key is not defined"**
```bash
firebase functions:config:set sendgrid.key="SG.votre_cle_ici"
firebase deploy --only functions
```

#### **Erreur: "Unauthorized sender"**
- Vérifiez que votre email est confirmé dans SendGrid
- Attendez 5-10 minutes après la vérification

#### **Erreur: "Function not found"**
```bash
firebase deploy --only functions
```

#### **Emails non reçus**
- Vérifiez le dossier spam
- Vérifiez les logs Firebase:
  ```bash
  firebase functions:log
  ```

### **📊 Commandes Utiles**

```bash
# Voir les logs en temps réel
firebase functions:log --follow

# Voir la configuration
firebase functions:config:get

# Redéployer les fonctions
firebase deploy --only functions

# Tester localement (optionnel)
firebase emulators:start --only functions
```

### **✅ Vérification Finale**

Votre configuration est prête quand :
- ✅ Clé SendGrid configurée dans Firebase
- ✅ Email expéditeur vérifié dans SendGrid  
- ✅ Fonctions déployées sur Firebase
- ✅ Test Firebase réussi dans l'app
- ✅ Email reçu dans votre boîte

### **🎯 Utilisation dans le Code**

```dart
// Envoyer une invitation
final success = await FirebaseEmailService.envoyerInvitation(
  email: 'destinataire@example.com',
  sessionCode: 'ABC123',
  sessionId: 'session_id_unique',
);

// Envoyer un email simple
final success = await FirebaseEmailService.sendEmail(
  to: 'destinataire@example.com',
  subject: 'Mon sujet',
  body: 'Mon message',
  isHtml: false,
);
```

### **💰 Limites SendGrid Gratuit**

- **100 emails/jour** (suffisant pour les tests)
- **Upgrade** si vous avez besoin de plus
- **Alternative**: Gmail SMTP (plus complexe)

---

## 🚀 **Commandes de Configuration Rapide**

Copiez-collez ces commandes dans votre terminal :

```bash
# 1. Configurer SendGrid (remplacez par votre vraie clé)
firebase functions:config:set sendgrid.key="SG.VOTRE_CLE_SENDGRID_ICI"

# 2. Déployer les fonctions
firebase deploy --only functions

# 3. Vérifier la configuration
firebase functions:config:get

# 4. Voir les logs
firebase functions:log --follow
```

**🎉 C'est tout ! Votre système d'email est prêt !**
