# 🏗️ Guide de la Hiérarchie d'Assurance - Système Complet

## 🎯 **Vue d'Ensemble de la Hiérarchie**

```
👑 Super Admin
    ↓ crée
🏢 Compagnies d'Assurance (STAR, COMAR, GAT, etc.)
    ↓ crée
👤 Admin Compagnie (1 par compagnie)
    ↓ crée
🏪 Agences (multiples par compagnie)
    ↓ crée
👥 Admin Agence (1 par agence)
    ↓ crée
🔧 Agents & 🔍 Experts Auto
```

## 🚀 **Accès au Système**

### **1. Connexion Super Admin**
- **Email**: `constat.tunisie.app@gmail.com`
- **Mot de passe**: `Acheya123`
- **Dashboard**: Super Admin Dashboard → **"Gestion Hiérarchique"**

## 📊 **Processus de Création Étape par Étape**

### **🏢 ÉTAPE 1 : Création de Compagnie (Super Admin)**

**Accès :** Dashboard → Gestion Hiérarchique → Onglet "🏢 Compagnies"

**Champs obligatoires :**
- ✅ **Nom** : Nom complet de la compagnie
- ✅ **Code** : Code unique (ex: STAR, COMAR, GAT)

**Champs optionnels :**
- Adresse, Téléphone, Email, Ville

**Exemple :**
```
Nom: STAR Assurance
Code: STAR
Adresse: Avenue Habib Bourguiba, Tunis
Téléphone: 71 234 567
Email: contact@star.tn
Ville: Tunis
```

**Résultat :** Compagnie créée dans la collection `companies`

---

### **👤 ÉTAPE 2 : Création Admin Compagnie (Super Admin)**

**Accès :** Dashboard → Gestion Hiérarchique → Onglet "👤 Admin Compagnie"

**Champs obligatoires :**
- ✅ **ID Compagnie** : Code de la compagnie créée (ex: STAR)
- ✅ **Nom** : Nom de famille
- ✅ **Prénom** : Prénom

**Champs optionnels :**
- Téléphone, Adresse

**⚠️ IMPORTANT :**
- **Email généré automatiquement** : `admin.star@assurance.tn`
- **Mot de passe généré automatiquement** : Affiché dans l'interface
- **PAS d'envoi d'email** : Identifiants transmis manuellement

**Exemple :**
```
ID Compagnie: STAR
Nom: Ben Ali
Prénom: Ahmed
Téléphone: 71 111 111
```

**Résultat :**
```
✅ Admin Compagnie créé avec succès !
📧 Email: admin.star@assurance.tn
🔑 Mot de passe: Xy9#mK2$pL8!
⚠️ Transmettez ces identifiants manuellement au client
```

---

### **🏪 ÉTAPE 3 : Création d'Agences (Super Admin)**

**Accès :** Dashboard → Gestion Hiérarchique → Onglet "🏪 Agences"

**Champs obligatoires :**
- ✅ **ID Compagnie** : Code de la compagnie (ex: STAR)
- ✅ **Nom** : Nom de l'agence
- ✅ **Adresse** : Adresse complète
- ✅ **Ville** : Ville

**Champs optionnels :**
- Téléphone, Responsable

**Exemple :**
```
ID Compagnie: STAR
Nom: Agence Tunis Centre
Adresse: Rue de la Kasbah, Tunis
Ville: Tunis
Téléphone: 71 222 222
Responsable: Mme Fatma Trabelsi
```

**Résultat :** Agence créée dans la collection `agencies`

---

### **👥 ÉTAPE 4 : Création Admin Agence (Admin Compagnie)**

**Accès :** Dashboard Admin Compagnie → Gestion Hiérarchique → Onglet "👥 Admin Agence"

**Champs obligatoires :**
- ✅ **ID Agence** : ID de l'agence créée
- ✅ **Nom** : Nom de famille
- ✅ **Prénom** : Prénom
- ✅ **Email** : Email personnel

**Champs optionnels :**
- Téléphone

**⚠️ IMPORTANT :**
- **Mot de passe généré automatiquement**
- **Email envoyé automatiquement** avec les identifiants

**Exemple :**
```
ID Agence: STAR-agence-tunis-centre-1234567890
Nom: Gharbi
Prénom: Salma
Email: salma.gharbi@star.tn
Téléphone: 71 333 333
```

**Résultat :**
```
✅ Admin Agence créé avec succès ! Email envoyé.
📧 Email de bienvenue envoyé à salma.gharbi@star.tn
```

---

## 📊 **Collections Firestore Créées**

### **🏢 Collection `companies`**
```json
{
  "STAR": {
    "id": "STAR",
    "nom": "STAR Assurance",
    "code": "STAR",
    "adresse": "Avenue Habib Bourguiba, Tunis",
    "telephone": "71 234 567",
    "email": "contact@star.tn",
    "ville": "Tunis",
    "pays": "Tunisie",
    "status": "actif",
    "created_at": "timestamp",
    "created_by": "super_admin_uid"
  }
}
```

### **🏪 Collection `agencies`**
```json
{
  "STAR-agence-tunis-centre-1234567890": {
    "id": "STAR-agence-tunis-centre-1234567890",
    "nom": "Agence Tunis Centre",
    "compagnieId": "STAR",
    "compagnieNom": "STAR Assurance",
    "adresse": "Rue de la Kasbah, Tunis",
    "ville": "Tunis",
    "telephone": "71 222 222",
    "responsable": "Mme Fatma Trabelsi",
    "status": "actif",
    "created_at": "timestamp"
  }
}
```

### **👥 Collection `users`**
```json
{
  "admin-star-1234567890": {
    "uid": "admin-star-1234567890",
    "email": "admin.star@assurance.tn",
    "nom": "Ben Ali",
    "prenom": "Ahmed",
    "role": "admin_compagnie",
    "compagnieId": "STAR",
    "compagnieNom": "STAR Assurance",
    "password": "Xy9#mK2$pL8!",
    "authMethod": "firestore_only",
    "status": "actif",
    "created_by": "super_admin_uid"
  },
  "firebase_auth_uid_123": {
    "uid": "firebase_auth_uid_123",
    "email": "salma.gharbi@star.tn",
    "nom": "Gharbi",
    "prenom": "Salma",
    "role": "admin_agence",
    "agenceId": "STAR-agence-tunis-centre-1234567890",
    "agenceNom": "Agence Tunis Centre",
    "compagnieId": "STAR",
    "compagnieNom": "STAR Assurance",
    "authMethod": "firebase_auth",
    "status": "actif",
    "created_by": "admin_compagnie_uid"
  }
}
```

## 🔐 **Système d'Authentification**

### **Super Admin**
- ✅ Firebase Auth + Firestore
- ✅ Email fixe : `constat.tunisie.app@gmail.com`

### **Admin Compagnie**
- ⚠️ **Firestore uniquement** (pas Firebase Auth)
- ✅ Email généré : `admin.{compagnie}@assurance.tn`
- ✅ Mot de passe affiché dans l'interface

### **Admin Agence**
- ✅ Firebase Auth + Firestore
- ✅ Email personnalisé fourni
- ✅ Mot de passe envoyé par email

### **Agents & Experts**
- ✅ Firebase Auth + Firestore
- ✅ Email personnalisé fourni
- ✅ Mot de passe envoyé par email

## 📧 **Système d'Email**

### **Admin Compagnie**
- ❌ **PAS d'email automatique**
- ✅ Identifiants affichés dans l'interface
- ✅ Transmission manuelle par le Super Admin

### **Admin Agence, Agents, Experts**
- ✅ **Email automatique** avec identifiants
- ✅ Template de bienvenue personnalisé
- ✅ Instructions de première connexion

## 🔍 **Vérifications de Sécurité**

### **Contrôles d'Accès**
- ✅ Seul le Super Admin peut créer des compagnies
- ✅ Seul le Super Admin peut créer des Admin Compagnie
- ✅ Seul le Super Admin peut créer des agences
- ✅ Seul l'Admin Compagnie peut créer des Admin Agence
- ✅ Seul l'Admin Agence peut créer des Agents/Experts

### **Validations**
- ✅ Unicité des codes de compagnie
- ✅ Un seul Admin Compagnie par compagnie
- ✅ Vérification de l'existence des entités parentes
- ✅ Validation des permissions hiérarchiques

## 🚀 **Prochaines Étapes**

### **À Implémenter**
1. **🔧 Création d'Agents** (par Admin Agence)
2. **🔍 Création d'Experts Auto** (par Admin Agence)
3. **📧 Service d'email complet** avec templates HTML
4. **🔐 Système de connexion** pour Admin Compagnie
5. **📊 Dashboards spécifiques** par rôle

### **Améliorations**
1. **📱 Interface mobile** optimisée
2. **🔔 Notifications** en temps réel
3. **📈 Analytics** et rapports
4. **🔒 2FA** pour les comptes sensibles

---

## 📞 **Support**

**En cas de problème :**
- 📧 **Email** : support@constat-tunisie.tn
- 📱 **Téléphone** : +216 71 XXX XXX
- 💬 **Chat** : Disponible dans l'application

---

*Guide créé le 17/07/2025 - Version 1.0*
