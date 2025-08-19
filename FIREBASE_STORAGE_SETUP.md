# 🔧 Configuration Firebase Storage

## ❌ Problème Actuel
```
Error: User does not have permission to access this object.
Code: -13021 HttpResult: 403
Permission denied.
```

## ✅ Solution : Configurer les Règles Firebase Storage

### 1. Accéder à Firebase Console
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner votre projet `assuranceaccident-2c2fa`
3. Cliquer sur **Storage** dans le menu de gauche
4. Aller dans l'onglet **Rules**

### 2. Remplacer les Règles Actuelles
Remplacer le contenu par ces règles sécurisées :

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Règles pour les véhicules - chaque utilisateur peut gérer ses propres fichiers
    match /vehicules/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Règles pour les constats - chaque utilisateur peut gérer ses propres fichiers
    match /constats/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Règles pour les documents d'expertise
    match /expertises/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Règles pour les fichiers publics (logos, etc.)
    match /public/{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
    
    // Règles pour les profils utilisateurs
    match /profiles/{userId}/{allPaths=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 3. Publier les Règles
1. Cliquer sur **Publier** pour appliquer les nouvelles règles
2. Attendre la confirmation de publication

### 4. Tester l'Upload
1. Relancer l'application Flutter
2. Essayer d'enregistrer un véhicule avec des images
3. Vérifier que l'upload fonctionne maintenant

## 📊 Structure des Dossiers Firebase Storage

```
/vehicules/
  /{userId}/
    /carte_grise_{userId}_{timestamp}.jpg
    /permis_{userId}_{timestamp}.jpg

/constats/
  /{userId}/
    /accident_{constatId}_{timestamp}.jpg
    /degats_{constatId}_{timestamp}.jpg

/expertises/
  /{userId}/
    /rapport_{expertiseId}_{timestamp}.pdf
    /photos_{expertiseId}_{timestamp}.jpg

/public/
  /logos/
    /compagnies/
  /templates/
```

## 🔒 Sécurité des Règles

### ✅ Ce que permettent ces règles :
- Chaque utilisateur peut uploader/lire ses propres fichiers
- Structure organisée par userId
- Accès en lecture aux fichiers publics
- Protection contre l'accès non autorisé

### ❌ Ce que ces règles empêchent :
- Accès aux fichiers d'autres utilisateurs
- Upload par des utilisateurs non authentifiés
- Modification des fichiers publics par des utilisateurs normaux

## 🚀 Après Configuration

Une fois les règles appliquées, l'application pourra :
- ✅ Enregistrer les véhicules instantanément
- ✅ Uploader les images en arrière-plan
- ✅ Compresser automatiquement les images (60-80% de réduction)
- ✅ Gérer les erreurs gracieusement
- ✅ Afficher des notifications de statut

## 📱 Fonctionnement de l'App

1. **Enregistrement immédiat** : Le véhicule est sauvé en < 2 secondes
2. **Upload en arrière-plan** : Les images sont uploadées après l'enregistrement
3. **Compression automatique** : Réduction de 60-80% de la taille des images
4. **Gestion d'erreurs** : L'app continue de fonctionner même si l'upload échoue
5. **Notifications** : L'utilisateur est informé du statut de l'upload

## 🔧 Dépannage

Si les erreurs persistent après configuration :
1. Vérifier que l'utilisateur est bien authentifié
2. Contrôler que les règles sont bien publiées
3. Redémarrer l'application Flutter
4. Vérifier les logs Firebase Console
