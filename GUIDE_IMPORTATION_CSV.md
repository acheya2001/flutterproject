# 📊 Guide d'Importation CSV - Application d'Assurance

## 🎯 **Vue d'Ensemble**

Le système d'importation CSV permet aux Super Admins d'importer facilement des données en masse dans l'application d'assurance. Le système détecte automatiquement le type de données et les importe dans les bonnes collections Firestore.

## 🚀 **Accès à l'Importation CSV**

### **1. Connexion Super Admin**
- Connectez-vous avec un compte Super Admin
- Accédez au Dashboard Super Admin

### **2. Navigation vers l'Import CSV**
- Dans le menu latéral, cliquez sur **"Import CSV"** 📊
- Ou utilisez l'onglet correspondant dans le dashboard

## 📁 **Types de Données Supportés**

### **🏢 Compagnies d'Assurance**
**Colonnes requises :**
```csv
nom,code,adresse,telephone,email,ville,pays
STAR Assurance,STAR,Avenue Habib Bourguiba,71234567,contact@star.tn,Tunis,Tunisie
```

**Colonnes détectées automatiquement :**
- `nom` ou `raison` : Nom de la compagnie
- `code` ou `id` : Code unique de la compagnie
- `adresse` : Adresse physique
- `telephone` ou `tel` : Numéro de téléphone
- `email` ou `mail` : Adresse email
- `ville` : Ville
- `pays` : Pays (par défaut : Tunisie)

### **🏪 Agences** (À implémenter)
```csv
nom,compagnie,adresse,ville,telephone
Agence Tunis Centre,STAR,Rue de la Kasbah,Tunis,71111111
```

### **👥 Agents** (À implémenter)
```csv
nom,prenom,email,telephone,agence
Dupont,Jean,jean.dupont@star.tn,71222222,Agence Tunis Centre
```

### **🚗 Conducteurs** (À implémenter)
```csv
nom,prenom,cin,permis,telephone
Ben Ali,Ahmed,12345678,P123456,71333333
```

### **🚙 Véhicules** (À implémenter)
```csv
immatriculation,marque,modele,annee
123TUN456,Peugeot,208,2020
```

### **📄 Contrats** (À implémenter)
```csv
numero,conducteur,vehicule,validite
C001,Ahmed Ben Ali,123TUN456,2024-12-31
```

## 🔧 **Comment Utiliser l'Importation**

### **Méthode 1 : Copier-Coller**

1. **Préparez vos données CSV**
   - Ouvrez votre fichier CSV dans Excel/LibreOffice
   - Copiez tout le contenu (Ctrl+A puis Ctrl+C)

2. **Dans l'application**
   - Allez dans **Super Admin Dashboard > Import CSV**
   - Collez les données dans la zone de texte
   - Cliquez sur **"Importer depuis le texte"**

3. **Vérification**
   - Le système détecte automatiquement le type de données
   - Affiche un résumé de l'importation
   - Montre les erreurs éventuelles

### **Exemple Pratique**

**Fichier CSV :**
```csv
nom,code,adresse,telephone,email,ville
STAR Assurance,STAR,Avenue Habib Bourguiba,71234567,contact@star.tn,Tunis
COMAR Assurance,COMAR,Rue de la Liberté,71345678,info@comar.tn,Tunis
```

**Résultat :**
- ✅ Type détecté : Compagnies d'assurance
- ✅ 2 lignes importées avec succès
- ✅ 0 erreur

## 📊 **Résultats d'Importation**

### **Statistiques Affichées**
- **Type de données** : Compagnies, Agences, etc.
- **Total lignes** : Nombre de lignes dans le CSV
- **Succès** : Nombre d'enregistrements importés
- **Erreurs** : Nombre d'échecs
- **Taux de succès** : Pourcentage de réussite

### **Gestion des Erreurs**
- **Données manquantes** : Champs obligatoires vides
- **Format incorrect** : Données mal formatées
- **Doublons** : Enregistrements déjà existants
- **Type non reconnu** : En-têtes CSV non détectés

## ⚠️ **Bonnes Pratiques**

### **Préparation des Données**
1. **Vérifiez les en-têtes** : Utilisez les noms de colonnes recommandés
2. **Nettoyez les données** : Supprimez les espaces inutiles
3. **Testez avec peu de données** : Commencez par 2-3 lignes
4. **Sauvegardez** : Gardez une copie de vos données originales

### **Format CSV**
- **Encodage** : UTF-8 recommandé
- **Séparateur** : Virgule (,)
- **Guillemets** : Pour les textes contenant des virgules
- **Première ligne** : En-têtes de colonnes

### **Sécurité**
- ⚠️ **Accès restreint** : Seuls les Super Admins peuvent importer
- 🔒 **Validation** : Toutes les données sont validées
- 📝 **Logs** : Toutes les importations sont enregistrées
- 🔄 **Sauvegarde** : Les données existantes ne sont pas écrasées

## 🛠️ **Dépannage**

### **Problèmes Courants**

**❌ "Type de données non reconnu"**
- Vérifiez les noms des colonnes
- Assurez-vous d'avoir les colonnes obligatoires
- Exemple : Pour les compagnies, il faut `nom` ET (`code` OU `adresse`)

**❌ "Champs obligatoires manquants"**
- Vérifiez que toutes les lignes ont des valeurs
- Pour les compagnies : `nom` est obligatoire

**❌ "Erreur de format"**
- Vérifiez l'encodage du fichier (UTF-8)
- Assurez-vous que le séparateur est une virgule
- Supprimez les caractères spéciaux

### **Support**
- 📧 **Email** : support@constat-tunisie.tn
- 📱 **Téléphone** : +216 71 XXX XXX
- 💬 **Chat** : Disponible dans l'application

## 🔮 **Fonctionnalités Futures**

- 📁 **Import de fichiers** : Sélection directe de fichiers CSV
- 🔄 **Import automatique** : Planification d'imports réguliers
- 📊 **Validation avancée** : Règles métier personnalisées
- 🌐 **Import Excel** : Support des fichiers .xlsx
- 📈 **Statistiques détaillées** : Rapports d'importation

---

## 📝 **Exemple Complet**

Voici un exemple complet d'importation de compagnies d'assurance :

```csv
nom,code,adresse,telephone,email,ville,pays
STAR Assurance,STAR,Avenue Habib Bourguiba Tunis,71234567,contact@star.tn,Tunis,Tunisie
COMAR Assurance,COMAR,Rue de la Liberté Tunis,71345678,info@comar.tn,Tunis,Tunisie
GAT Assurance,GAT,Avenue Mohamed V Sfax,74456789,contact@gat.tn,Sfax,Tunisie
Maghrebia Assurance,MAGHREBIA,Boulevard du 7 Novembre Sousse,73567890,info@maghrebia.tn,Sousse,Tunisie
```

**Résultat attendu :**
- ✅ 4 compagnies importées
- ✅ Toutes les données validées
- ✅ Disponibles immédiatement dans l'application

---

*Guide créé le 17/07/2025 - Version 1.0*
