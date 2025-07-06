# 📝 Formulaire de Demande de Compte Professionnel

## 📍 **Où se trouve le formulaire ?**

### **🎯 Emplacement du code :**
```
lib/features/auth/presentation/screens/professional_account_request_screen.dart
```

### **🔗 Comment y accéder dans l'application :**

#### **1. Depuis l'écran de connexion :**
- Ouvrir l'application
- Aller à l'écran de connexion
- Cliquer sur le bouton **"Demande de compte professionnel"** (bouton bleu avec icône business_center)

#### **2. Depuis la sélection du type d'utilisateur :**
- Ouvrir l'application
- Aller à "Sélection du type d'utilisateur"
- Dans la section **"Compte Professionnel"** (encadré bleu)
- Cliquer sur **"Faire une demande"**

#### **3. Depuis le dashboard admin (pour test) :**
- Se connecter en tant qu'admin
- Dans le dashboard, cliquer sur **"🧪 Test Formulaire Professionnel"**

#### **4. Via navigation directe :**
```dart
Navigator.pushNamed(context, '/professional-request');
// ou
Navigator.pushNamed(context, AppRoutes.professionalRequest);
```

---

## 🎯 **Fonctionnalités du formulaire :**

### **📋 Étapes du formulaire :**
1. **Sélection du rôle** : Agent, Expert, Admin Compagnie, Admin Agence
2. **Informations personnelles** : Nom, email, téléphone, CIN
3. **Informations professionnelles** : Champs dynamiques selon le rôle
4. **Confirmation** : Résumé avant soumission

### **🎯 Rôles disponibles :**

#### **🧍‍💼 Agent d'agence :**
- Nom de l'agence ✅
- Compagnie d'assurance ✅
- Adresse de l'agence ✅
- Matricule interne (optionnel)

#### **🧑‍🔧 Expert automobile :**
- Numéro d'agrément professionnel ✅
- Compagnie d'assurance liée ✅
- Zone d'intervention (gouvernorat) ✅
- Années d'expérience (optionnel)
- Nom de l'agence (optionnel)

#### **🧑‍💼 Admin compagnie :**
- Nom de la compagnie ✅
- Fonction/Poste ✅
- Adresse du siège social ✅
- Numéro d'autorisation (optionnel)

#### **🏢 Admin agence :**
- Nom de l'agence ✅
- Compagnie d'assurance ✅
- Ville/Gouvernorat ✅
- Adresse de l'agence ✅
- Téléphone de l'agence (optionnel)

---

## ✅ **Validation et sécurité :**

### **📧 Validation email :**
- Format email valide
- Vérification d'unicité (pas de doublon)

### **📱 Validation téléphone :**
- Format tunisien : `21612345678` ou `12345678`
- Uniquement des chiffres

### **🆔 Validation CIN :**
- Minimum 8 caractères
- Lettres et chiffres autorisés

### **🏢 Listes prédéfinies :**
- **Compagnies d'assurance** : STAR, Maghrebia, GAT, Comar, Lloyd, etc.
- **Gouvernorats** : Tous les gouvernorats de Tunisie

---

## 🔄 **Workflow complet :**

### **1. Soumission utilisateur :**
```
Utilisateur → Formulaire → Validation → Firestore (/demandes_professionnels)
```

### **2. Notification admin :**
```
Soumission → Notification automatique → Dashboard admin
```

### **3. Validation admin :**
```
Admin → Dashboard → Approuver/Rejeter → Création compte (si approuvé)
```

### **4. Confirmation utilisateur :**
```
Validation admin → Email notification → Compte créé
```

---

## 🗄️ **Structure Firestore :**

### **Collection :** `/demandes_professionnels/{demandeId}`

### **Champs communs :**
```json
{
  "nom_complet": "Karim Jlassi",
  "email": "karim@star.tn",
  "tel": "21699322144",
  "cin": "09345122",
  "role_demande": "agent_agence",
  "status": "en_attente",
  "envoye_le": "2025-07-04T14:45:00Z"
}
```

### **Champs spécifiques (exemple agent) :**
```json
{
  "nom_agence": "Agence El Menzah 6",
  "compagnie": "STAR Assurances",
  "adresse_agence": "Av. Hédi Nouira, Tunis",
  "matricule_interne": "AG455"
}
```

---

## 🧪 **Comment tester :**

### **1. Test complet :**
1. Ouvrir l'application
2. Aller à l'écran de connexion
3. Cliquer sur "Demande de compte professionnel"
4. Sélectionner un rôle (ex: Agent d'agence)
5. Remplir les informations personnelles
6. Remplir les informations professionnelles
7. Confirmer et soumettre
8. Vérifier l'écran de succès

### **2. Test validation admin :**
1. Se connecter en tant qu'admin
2. Aller au dashboard admin
3. Voir la nouvelle demande dans les statistiques
4. Cliquer sur "Demandes en Attente"
5. Approuver ou rejeter la demande

### **3. Vérification Firestore :**
1. Ouvrir Firebase Console
2. Aller à Firestore Database
3. Vérifier la collection `/demandes_professionnels`
4. Voir les nouvelles demandes soumises

---

## 🎨 **Design et UX :**

### **🌟 Caractéristiques :**
- **Interface moderne** : Design élégant avec couleurs cohérentes
- **Navigation fluide** : Progression étape par étape
- **Validation temps réel** : Feedback immédiat sur les erreurs
- **Responsive** : S'adapte à toutes les tailles d'écran
- **Accessibilité** : Labels clairs, icônes explicites

### **🎯 Points forts :**
- **Formulaire dynamique** : S'adapte selon le rôle sélectionné
- **Validation avancée** : Email unique, téléphone tunisien, etc.
- **Écran de succès** : Confirmation avec prochaines étapes
- **Intégration complète** : Avec le système admin existant

---

## 🚀 **Prêt pour la production !**

Le formulaire de demande de compte professionnel est **entièrement fonctionnel** et prêt à être utilisé. Tous les composants sont intégrés et testés.

**✅ Fonctionnalités complètes :**
- Formulaire dynamique 4 étapes
- Validation complète des données
- Soumission vers Firestore
- Notifications automatiques
- Interface de validation admin
- Écran de succès utilisateur

**🎯 Prochaines étapes possibles :**
- Upload de documents (CV, diplômes)
- Géolocalisation automatique
- Notifications push
- Système de suivi de demande
