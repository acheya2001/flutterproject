# 🚀 GUIDE DE MISE À JOUR GITHUB - CONSTAT TUNISIE

## 📋 PRÉREQUIS

### 1. Compte GitHub
- Avoir un compte GitHub actif
- Créer un nouveau repository nommé `constat_tunisie` (ou utiliser un existant)

### 2. Git installé
- Vérifier que Git est installé : `git --version`
- Si non installé, télécharger depuis : https://git-scm.com/

### 3. Authentification GitHub
- Token d'accès personnel (recommandé)
- Ou authentification SSH configurée

## 🎯 MÉTHODES DE MISE À JOUR

### MÉTHODE 1 : Script Automatique (Recommandé)

#### Option A : PowerShell (Windows)
```powershell
# Exécuter dans PowerShell en tant qu'administrateur
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\update_github.ps1
```

#### Option B : Batch (Windows)
```cmd
# Double-cliquer sur le fichier ou exécuter dans cmd
update_github.bat
```

### MÉTHODE 2 : Commandes Manuelles

#### Étape 1 : Initialisation
```bash
# Initialiser le repository Git
git init

# Configurer Git (remplacer par vos informations)
git config user.name "Votre Nom"
git config user.email "votre.email@example.com"
```

#### Étape 2 : Ajout des fichiers
```bash
# Ajouter tous les fichiers
git add .

# Créer le commit initial
git commit -m "Version finale du système d'assurance Constat Tunisie"
```

#### Étape 3 : Configuration du remote
```bash
# Configurer la branche principale
git branch -M main

# Ajouter le remote GitHub (remplacer YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/constat_tunisie.git
```

#### Étape 4 : Push vers GitHub
```bash
# Pousser vers GitHub
git push -u origin main
```

## 🔧 RÉSOLUTION DES PROBLÈMES COURANTS

### Problème 1 : Git non reconnu
**Solution :**
1. Installer Git depuis https://git-scm.com/
2. Redémarrer le terminal/PowerShell
3. Vérifier avec `git --version`

### Problème 2 : Authentification échouée
**Solutions :**
1. **Token d'accès :** Utiliser un Personal Access Token au lieu du mot de passe
2. **SSH :** Configurer une clé SSH
3. **GitHub CLI :** Installer et utiliser `gh auth login`

### Problème 3 : Repository existe déjà
**Solutions :**
```bash
# Option 1 : Forcer le push
git push -f origin main

# Option 2 : Pull puis push
git pull origin main --allow-unrelated-histories
git push origin main
```

### Problème 4 : Fichiers trop volumineux
**Solution :**
```bash
# Vérifier les gros fichiers
find . -size +100M -type f

# Ajouter au .gitignore si nécessaire
echo "fichier_volumineux.ext" >> .gitignore
```

## 📁 STRUCTURE DU PROJET UPLOADÉ

```
constat_tunisie/
├── lib/                          # Code source Flutter
│   ├── features/                 # Fonctionnalités par module
│   │   ├── admin/               # Interfaces administrateur
│   │   ├── agent/               # Interfaces agent
│   │   ├── conducteur/          # Interfaces conducteur
│   │   ├── expert/              # Interfaces expert
│   │   └── insurance/           # Système d'assurance
│   ├── services/                # Services métier
│   ├── models/                  # Modèles de données
│   └── core/                    # Fonctionnalités core
├── android/                     # Configuration Android
├── ios/                         # Configuration iOS
├── web/                         # Configuration Web
├── assets/                      # Ressources (images, fonts)
├── functions/                   # Firebase Cloud Functions
├── firestore.rules             # Règles de sécurité Firestore
├── firebase.json               # Configuration Firebase
└── docs/                       # Documentation
```

## 🎯 FONCTIONNALITÉS INCLUSES

### ✅ Système d'Assurance Complet
- Workflow de contrats en 12 étapes
- Gestion multi-rôles (6 types d'utilisateurs)
- Processus de demande → validation → création → signature → paiement → activation

### ✅ Interfaces Modernes
- Design élégant et responsive
- Navigation intuitive par rôle
- Tableaux de bord personnalisés

### ✅ Sécurité Renforcée
- Règles Firestore strictes
- Authentification multi-niveaux
- Traçabilité complète des actions

### ✅ Gestion Documentaire
- Upload et validation de documents
- Génération automatique (Carte Verte, Police, Échéancier)
- Signature numérique

### ✅ Système de Notifications
- Notifications push et email
- Workflow automatisé
- Suivi en temps réel

## 🔄 MISES À JOUR FUTURES

### Pour mettre à jour le repository :
```bash
# Ajouter les nouveaux changements
git add .

# Créer un nouveau commit
git commit -m "Description des changements"

# Pousser vers GitHub
git push origin main
```

### Pour créer une nouvelle version :
```bash
# Créer un tag de version
git tag -a v1.0.0 -m "Version 1.0.0 - Système complet"

# Pousser le tag
git push origin v1.0.0
```

## 📞 SUPPORT

En cas de problème :
1. Vérifier les logs d'erreur
2. Consulter la documentation GitHub
3. Vérifier les permissions du repository
4. S'assurer que tous les prérequis sont installés

## 🎉 SUCCÈS !

Une fois la mise à jour terminée, votre projet sera disponible sur :
`https://github.com/VOTRE_USERNAME/constat_tunisie`

Vous pourrez alors :
- Partager le code avec d'autres développeurs
- Créer des branches pour de nouvelles fonctionnalités
- Suivre l'historique des modifications
- Collaborer efficacement sur le projet
