# 🔧 Configuration OAuth Playground - Guide Rapide

## 🎯 Problème détecté
L'URI de redirection `https://developers.google.com/oauthplayground` n'est pas configuré dans votre Client ID Web.

## 🚀 Solution 1 : Modifier le Client ID existant

### Étapes dans Google Cloud Console :

1. **Aller sur :** https://console.cloud.google.com/apis/credentials
2. **Sélectionner le projet :** constattunisiemail-462921
3. **Cliquer sur le Client ID Web :** 324863789443-p91qv6l61mitdti5evhu7pu446fn95un.apps.googleusercontent.com
4. **Dans "URIs de redirection autorisés", ajouter :**
   ```
   https://developers.google.com/oauthplayground
   ```
5. **Cliquer "ENREGISTRER"**

## 🔄 Solution 2 : Méthode alternative avec gcloud

Si vous avez gcloud CLI installé :

```bash
# Se connecter à Google Cloud
gcloud auth login

# Sélectionner le projet
gcloud config set project constattunisiemail-462921

# Créer un nouveau Client ID pour OAuth Playground
gcloud alpha iap oauth-brands create --application_title="Constat Tunisie OAuth" --support_email="constat.tunisie.app@gmail.com"
```

## ✅ Après configuration

1. **Retourner sur :** https://developers.google.com/oauthplayground
2. **Configurer avec votre Client ID**
3. **Sélectionner Gmail API scope :** `https://www.googleapis.com/auth/gmail.send`
4. **Autoriser avec :** constat.tunisie.app@gmail.com
5. **Obtenir le Refresh Token**

## 🎯 Client ID à utiliser (Gmail Token Generator - Web)
```
1059917372502-qb8ivqvhhh2h3iqbh357h0hekb5qdtrg.apps.googleusercontent.com
```

## 📧 Email à utiliser
```
constat.tunisie.app@gmail.com
```
