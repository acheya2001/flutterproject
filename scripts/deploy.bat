@echo off
echo 🚀 Script de déploiement Constat Tunisie
echo ==========================================

echo.
echo 📋 Vérification du statut Git...
git status

echo.
echo 📦 Ajout des fichiers modifiés...
git add .

echo.
set /p commit_message="💬 Entrez le message de commit: "

echo.
echo 📝 Création du commit...
git commit -m "%commit_message%"

echo.
echo 🔄 Récupération des dernières modifications...
git pull origin main

echo.
echo 🚀 Push vers GitHub...
git push origin main

echo.
echo ✅ Déploiement terminé !
echo 🌐 Votre projet est maintenant à jour sur GitHub
echo.

pause
