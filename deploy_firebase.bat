@echo off
echo 🚀 Déploiement des règles Firebase pour Constat Tunisie
echo.

echo 📋 Vérification de Firebase CLI...
firebase --version
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI n'est pas installé
    echo 💡 Installez-le avec: npm install -g firebase-tools
    pause
    exit /b 1
)

echo.
echo 🔐 Connexion à Firebase...
firebase login

echo.
echo 📊 Déploiement des règles Firestore...
firebase deploy --only firestore:rules

echo.
echo ✅ Déploiement terminé !
echo.
echo 📱 Votre système d'assurance est maintenant configuré dans Firebase
echo 🔗 Accédez à votre console: https://console.firebase.google.com
echo.
pause
