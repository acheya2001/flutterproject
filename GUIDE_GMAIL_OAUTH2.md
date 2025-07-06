# 🚀 Guide Complet : Gmail OAuth2 pour Constat Tunisie

## 🎯 Objectif Final
Quand un conducteur crée une session dans votre app, une Firebase Function envoie un email depuis `constat.tunisie.app@gmail.com` vers n'importe quel email avec un code session.

## 📋 Plan en 5 Étapes

### ✅ Étape 1 : Créer le compte Gmail
1. **Allez sur Gmail** : https://gmail.com
2. **Créez un nouveau compte** :
   - Email : `constat.tunisie.app@gmail.com`
   - Mot de passe : Fort et sécurisé
   - **Important** : Utilisez ce compte UNIQUEMENT pour l'envoi d'emails

### ☁️ Étape 2 : Configuration Google Cloud Console

#### 📌 Créer un projet
1. **Allez sur** : https://console.cloud.google.com
2. **Cliquez** : "Créer un projet"
3. **Nom** : `ConstatTunisieMail`
4. **Validez**

#### 📌 Activer l'API Gmail
1. **Menu gauche** → API & Services → Library
2. **Recherchez** : "Gmail API"
3. **Cliquez** : "Enable"

#### 📌 Créer les identifiants OAuth2
1. **Menu** → API & Services → Identifiants
2. **Cliquez** : "Créer des identifiants" → "ID client OAuth 2.0"
3. **Type d'application** : "Application de bureau"
4. **Récupérez** :
   - `client_id`
   - `client_secret`

#### 📌 Obtenir le refresh_token

**🔧 ÉTAPE 1 : Créer une page HTML temporaire**

Créez un fichier `oauth_test.html` :

```html
<!DOCTYPE html>
<html>
<head>
    <title>Gmail OAuth2 Token Generator</title>
</head>
<body>
    <h1>Gmail OAuth2 Token Generator</h1>
    <button onclick="authorize()">Autoriser Gmail</button>
    <div id="result"></div>

    <script>
        const CLIENT_ID = 'VOTRE_CLIENT_ID_ICI';
        const CLIENT_SECRET = 'VOTRE_CLIENT_SECRET_ICI';
        const REDIRECT_URI = 'http://localhost:8080';
        const SCOPE = 'https://www.googleapis.com/auth/gmail.send';

        function authorize() {
            const authUrl = `https://accounts.google.com/o/oauth2/v2/auth?` +
                `client_id=${CLIENT_ID}&` +
                `redirect_uri=${encodeURIComponent(REDIRECT_URI)}&` +
                `scope=${encodeURIComponent(SCOPE)}&` +
                `response_type=code&` +
                `access_type=offline&` +
                `prompt=consent`;

            window.location.href = authUrl;
        }

        // Récupérer le code depuis l'URL
        const urlParams = new URLSearchParams(window.location.search);
        const code = urlParams.get('code');

        if (code) {
            exchangeCodeForToken(code);
        }

        async function exchangeCodeForToken(code) {
            try {
                const response = await fetch('https://oauth2.googleapis.com/token', {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/x-www-form-urlencoded',
                    },
                    body: new URLSearchParams({
                        client_id: CLIENT_ID,
                        client_secret: CLIENT_SECRET,
                        code: code,
                        grant_type: 'authorization_code',
                        redirect_uri: REDIRECT_URI,
                    }),
                });

                const data = await response.json();

                if (data.refresh_token) {
                    document.getElementById('result').innerHTML = `
                        <h2>✅ Succès !</h2>
                        <p><strong>Refresh Token:</strong></p>
                        <textarea rows="3" cols="80">${data.refresh_token}</textarea>
                        <p><strong>Access Token:</strong></p>
                        <textarea rows="3" cols="80">${data.access_token}</textarea>
                        <p>Copiez le refresh_token pour votre configuration !</p>
                    `;
                } else {
                    document.getElementById('result').innerHTML = `
                        <h2>❌ Erreur</h2>
                        <pre>${JSON.stringify(data, null, 2)}</pre>
                    `;
                }
            } catch (error) {
                document.getElementById('result').innerHTML = `
                    <h2>❌ Erreur</h2>
                    <p>${error.message}</p>
                `;
            }
        }
    </script>
</body>
</html>
```

**🔧 ÉTAPE 2 : Configurer les credentials**

1. Remplacez `VOTRE_CLIENT_ID_ICI` par votre Client ID
2. Remplacez `VOTRE_CLIENT_SECRET_ICI` par votre Client Secret
3. Assurez-vous que `http://localhost:8080` est dans vos URIs de redirection

**🔧 ÉTAPE 3 : Lancer un serveur local**

```bash
# Option 1 : Python
python -m http.server 8080

# Option 2 : Node.js
npx http-server -p 8080

# Option 3 : PHP
php -S localhost:8080
```

**🔧 ÉTAPE 4 : Obtenir le token**

1. Ouvrez `http://localhost:8080/oauth_test.html`
2. Cliquez sur "Autoriser Gmail"
3. Connectez-vous avec votre compte Gmail
4. Copiez le refresh_token affiché
1. **Allez sur** : https://developers.google.com/oauthplayground
2. **Étapes** :
   - Cliquez sur l'engrenage (⚙️) en haut à droite
   - Cochez "Use your own OAuth credentials"
   - Entrez votre `client_id` et `client_secret`
   - Dans la liste de gauche, sélectionnez "Gmail API v1"
   - Sélectionnez "https://www.googleapis.com/auth/gmail.send"
   - Cliquez "Authorize APIs"
   - Connectez-vous avec `constat.tunisie.app@gmail.com`
   - Cliquez "Exchange authorization code for tokens"
   - **Copiez le `refresh_token`**

### 🔧 Étape 3 : Configuration du Code

#### Modifiez `functions/index.js` :
```javascript
// Remplacez ces valeurs par vos vraies valeurs :
const CLIENT_ID = 'VOTRE_VRAI_CLIENT_ID';
const CLIENT_SECRET = 'VOTRE_VRAI_CLIENT_SECRET';
const REFRESH_TOKEN = 'VOTRE_VRAI_REFRESH_TOKEN';
const GMAIL_USER = 'constat.tunisie.app@gmail.com';
```

### 📦 Étape 4 : Installation des Dépendances

```bash
cd functions
npm install
```

### 🚀 Étape 5 : Déploiement et Test

#### Déployer :
```bash
firebase deploy --only functions
```

#### Tester depuis Flutter :
```dart
final callable = FirebaseFunctions.instance.httpsCallable('sendEmailGmail');
final result = await callable.call({
  'to': 'hammami123rahma@gmail.com',
  'sessionCode': 'CS123456',
  'conducteurNom': 'Test User'
});
```

## 🎯 Avantages de cette Solution

✅ **100% GRATUIT** (500 emails/jour)
✅ **FIABLE** (pas de problème de réputation)
✅ **SÉCURISÉ** (OAuth2 officiel Google)
✅ **FONCTIONNE PARTOUT** (tous destinataires)
✅ **PAS DE DOMAINE REQUIS**

## 🔍 Vérification

Après configuration, vous devriez voir dans les logs Firebase :
```
🚀 Gmail OAuth2 configuré avec succès
Email envoyé avec succès à xxx@gmail.com via Gmail OAuth2.
```

## 🆘 Support

Si vous avez des questions, suivez ce guide étape par étape et testez chaque étape !
