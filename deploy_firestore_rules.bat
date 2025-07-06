@echo off
echo ========================================
echo   DEPLOIEMENT DES REGLES FIRESTORE
echo ========================================
echo.

echo 🔥 Deploiement des nouvelles regles Firestore...
firebase deploy --only firestore:rules

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ✅ SUCCES: Les regles Firestore ont ete deployees avec succes !
    echo.
    echo 📋 Nouvelles collections supportees:
    echo    - professional_account_requests
    echo    - notifications
    echo    - users (avec nouveaux champs)
    echo.
    echo 🔐 Nouvelles fonctionnalites de securite:
    echo    - Validation des statuts de compte
    echo    - Permissions granulaires
    echo    - Controle d'acces base sur les roles
    echo.
    echo 🚀 Votre application peut maintenant:
    echo    - Creer des demandes de comptes professionnels
    echo    - Gerer les notifications
    echo    - Valider les comptes par les admins
    echo.
) else (
    echo.
    echo ❌ ERREUR: Echec du deploiement des regles Firestore
    echo.
    echo 🔧 Solutions possibles:
    echo    1. Verifiez que Firebase CLI est installe
    echo    2. Connectez-vous avec: firebase login
    echo    3. Initialisez le projet avec: firebase init
    echo    4. Verifiez la syntaxe du fichier firestore.rules
    echo.
)

echo.
echo Appuyez sur une touche pour continuer...
pause >nul
