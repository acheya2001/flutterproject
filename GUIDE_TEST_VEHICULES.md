# 🚗 GUIDE DE TEST - VÉHICULES ASSURÉS

## 🎯 **OBJECTIF**
Tester la fonctionnalité de sélection de véhicules pour la déclaration d'accident.

---

## 📱 **ÉTAPES DE TEST**

### **1. 🚀 Lancer l'application**
```bash
flutter run lib/test_main.dart
```

### **2. 🏠 Depuis l'écran principal**
- Appuyez sur **"Créer Toutes les Données"** (si pas encore fait)
- Attendez le message de succès ✅

### **3. 🚗 Tester la sélection de véhicules**
- Appuyez sur **"Déclarer un Accident"**
- Vous devriez voir l'écran **"Sélectionnez votre véhicule"**

### **4. 🧪 Si aucun véhicule n'apparaît**
- Appuyez sur **"🧪 Créer des véhicules de test"**
- Attendez le message de succès
- Les véhicules devraient maintenant apparaître

### **5. ✅ Vérifier les véhicules**
Vous devriez voir 3 véhicules de test :
- **Peugeot 208** (2022) - STAR Assurances
- **Renault Clio** (2021) - Maghrebia Assurances  
- **Volkswagen Golf** (2023) - GAT Assurances

### **6. 🎯 Sélectionner un véhicule**
- Appuyez sur un véhicule
- Vous devriez être redirigé vers la déclaration d'accident

---

## 🔧 **RÉSOLUTION DES PROBLÈMES**

### **❌ Erreur "Aucun véhicule trouvé"**
**Solution :**
1. Appuyez sur **"🧪 Créer des véhicules de test"**
2. Vérifiez que l'authentification fonctionne
3. Redémarrez l'application si nécessaire

### **❌ Erreur de connexion Firebase**
**Solution :**
1. Vérifiez votre connexion Internet
2. Redémarrez l'application
3. Vérifiez les règles Firestore (voir `firestore_rules_dev.txt`)

### **❌ Erreur de parsing des données**
**Solution :**
- Le service utilise maintenant un système de fallback
- Les véhicules devraient s'afficher même avec des données incomplètes

---

## 📊 **DONNÉES DE TEST CRÉÉES**

### **Véhicule 1 - Peugeot 208**
- **Immatriculation :** 123 TUN 456
- **Contrat :** STAR-2024-001234
- **Assureur :** STAR
- **Couverture :** Tous Risques

### **Véhicule 2 - Renault Clio**
- **Immatriculation :** 789 TUN 012
- **Contrat :** MAG-2024-005678
- **Assureur :** MAGHREBIA
- **Couverture :** Tiers Complet

### **Véhicule 3 - Volkswagen Golf**
- **Immatriculation :** 345 TUN 678
- **Contrat :** GAT-2024-009876
- **Assureur :** GAT
- **Couverture :** Tous Risques

---

## 🎉 **RÉSULTAT ATTENDU**

✅ **Succès si :**
- Les véhicules s'affichent correctement
- Vous pouvez sélectionner un véhicule
- La navigation vers la déclaration d'accident fonctionne
- Aucune erreur dans les logs

❌ **Échec si :**
- Erreur de connexion persistante
- Véhicules ne s'affichent pas après création
- Crash de l'application

---

## 🔍 **VÉRIFICATION DANS FIREBASE**

### **Console Firebase :**
1. Allez sur : https://console.firebase.google.com/project/constattunisiemail-462921/firestore
2. Vérifiez la collection **`vehicules_assures`**
3. Vous devriez voir 3 documents avec vos données de test

### **Structure attendue :**
```json
{
  "client_id": "user_id_firebase",
  "assureur_id": "STAR",
  "numero_contrat": "STAR-2024-001234",
  "marque": "Peugeot",
  "modele": "208",
  "immatriculation": "123 TUN 456",
  "statut": "actif"
}
```

---

## 📞 **SUPPORT**

Si vous rencontrez des problèmes :
1. Vérifiez les logs Flutter dans le terminal
2. Consultez le fichier `firestore_rules_dev.txt` pour les règles de développement
3. Redémarrez l'application complètement

**L'erreur initiale est maintenant corrigée ! 🎉**
