# 🔧 Création Manuelle des Admins Compagnie

## 🎯 Solution Immédiate

Si les outils automatiques ne fonctionnent pas, voici comment créer manuellement les Admin Compagnie dans Firebase Console.

## 📋 Étapes de Création

### Étape 1: Accéder à Firestore
1. Aller sur [Firebase Console - Firestore](https://console.firebase.google.com/project/assuranceaccident-2c2fa/firestore/data)
2. Se connecter avec votre compte Google

### Étape 2: Créer la Collection `users`
1. Si la collection `users` n'existe pas, cliquer sur **"Commencer une collection"**
2. Nom de la collection : `users`
3. Continuer vers la création du premier document

### Étape 3: Créer les Documents Admin

#### 🏢 Admin STAR Assurance
**ID du document :** `admin_star_assurance_2025`

**Champs à ajouter :**
```json
{
  "uid": "admin_star_assurance_2025",
  "email": "admin.star@assurance.tn",
  "nom": "Admin",
  "prenom": "STAR Assurance",
  "role": "admin_compagnie",
  "status": "actif",
  "compagnieId": "star-assurance",
  "compagnieNom": "STAR Assurance",
  "created_at": [Timestamp - Maintenant],
  "created_by": "manual_creation",
  "source": "firebase_console",
  "isLegitimate": true,
  "isActive": true,
  "password_reset_required": true,
  "last_login": null
}
```

#### 🏢 Admin COMAR Assurance
**ID du document :** `admin_comar_assurance_2025`

**Champs à ajouter :**
```json
{
  "uid": "admin_comar_assurance_2025",
  "email": "admin.comar@assurance.tn",
  "nom": "Admin",
  "prenom": "COMAR Assurance",
  "role": "admin_compagnie",
  "status": "actif",
  "compagnieId": "comar-assurance",
  "compagnieNom": "COMAR Assurance",
  "created_at": [Timestamp - Maintenant],
  "created_by": "manual_creation",
  "source": "firebase_console",
  "isLegitimate": true,
  "isActive": true,
  "password_reset_required": true,
  "last_login": null
}
```

#### 🏢 Admin GAT Assurance
**ID du document :** `admin_gat_assurance_2025`

**Champs à ajouter :**
```json
{
  "uid": "admin_gat_assurance_2025",
  "email": "admin.gat@assurance.tn",
  "nom": "Admin",
  "prenom": "GAT Assurance",
  "role": "admin_compagnie",
  "status": "actif",
  "compagnieId": "gat-assurance",
  "compagnieNom": "GAT Assurance",
  "created_at": [Timestamp - Maintenant],
  "created_by": "manual_creation",
  "source": "firebase_console",
  "isLegitimate": true,
  "isActive": true,
  "password_reset_required": true,
  "last_login": null
}
```

#### 🏢 Admin Maghrebia Assurance
**ID du document :** `admin_maghrebia_assurance_2025`

**Champs à ajouter :**
```json
{
  "uid": "admin_maghrebia_assurance_2025",
  "email": "admin.maghrebia@assurance.tn",
  "nom": "Admin",
  "prenom": "Maghrebia Assurance",
  "role": "admin_compagnie",
  "status": "actif",
  "compagnieId": "maghrebia-assurance",
  "compagnieNom": "Maghrebia Assurance",
  "created_at": [Timestamp - Maintenant],
  "created_by": "manual_creation",
  "source": "firebase_console",
  "isLegitimate": true,
  "isActive": true,
  "password_reset_required": true,
  "last_login": null
}
```

## 📝 Instructions Détaillées pour Chaque Champ

### Types de Champs dans Firebase Console

| Nom du Champ | Type | Valeur |
|---------------|------|--------|
| `uid` | string | ID unique de l'admin |
| `email` | string | Email de connexion |
| `nom` | string | Nom de famille |
| `prenom` | string | Prénom ou nom de la compagnie |
| `role` | string | `admin_compagnie` |
| `status` | string | `actif` |
| `compagnieId` | string | ID unique de la compagnie |
| `compagnieNom` | string | Nom complet de la compagnie |
| `created_at` | timestamp | Date/heure actuelle |
| `created_by` | string | `manual_creation` |
| `source` | string | `firebase_console` |
| `isLegitimate` | boolean | `true` |
| `isActive` | boolean | `true` |
| `password_reset_required` | boolean | `true` |
| `last_login` | null | `null` |

## 🔧 Procédure Pas à Pas

### Pour Chaque Admin :

1. **Cliquer sur "Ajouter un document"**
2. **ID du document :** Saisir l'ID spécifique (ex: `admin_star_assurance_2025`)
3. **Ajouter les champs un par un :**
   - Cliquer sur "Ajouter un champ"
   - Saisir le nom du champ
   - Sélectionner le type approprié
   - Saisir la valeur
   - Répéter pour tous les champs
4. **Cliquer sur "Enregistrer"**

### ⚠️ Points Importants

- **Respecter exactement** les noms de champs (sensible à la casse)
- **Utiliser les bons types** (string, boolean, timestamp, null)
- **Vérifier l'orthographe** des emails et IDs
- **Utiliser des IDs uniques** pour chaque document

## ✅ Vérification

Après création, vous devriez voir :
1. **Collection `users`** dans Firestore
2. **4 documents** avec les IDs spécifiés
3. **Tous les champs** correctement renseignés
4. **Types de données** appropriés

## 🎯 Test de Fonctionnement

Une fois les admins créés :
1. **Redémarrer l'application Flutter**
2. **Tester la connexion** avec un des emails créés
3. **Vérifier l'accès** au dashboard Admin Compagnie
4. **Confirmer les permissions** appropriées

## 🚨 En Cas de Problème

### Erreur "Document déjà existant"
- Utiliser un ID différent ou supprimer l'existant

### Erreur "Type de champ incorrect"
- Vérifier que les types correspondent au tableau

### Erreur "Permissions insuffisantes"
- Vérifier les règles Firestore
- Utiliser temporairement des règles permissives

## 📞 Support

Si vous rencontrez des difficultés :
1. **Capturer une capture d'écran** de l'erreur
2. **Vérifier les règles Firestore**
3. **Tester avec un seul admin d'abord**

---

**Note :** Cette méthode manuelle garantit la création des admins même en cas de problème de connectivité dans l'application.
