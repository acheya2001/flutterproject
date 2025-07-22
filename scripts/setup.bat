@echo off
echo 🛠️ Script de configuration Constat Tunisie
echo ============================================

echo.
echo 📦 Installation des dépendances Flutter...
flutter pub get

echo.
echo 🔧 Nettoyage du cache...
flutter clean

echo.
echo 📱 Vérification de la configuration Flutter...
flutter doctor

echo.
echo 🔥 Vérification de la configuration Firebase...
echo Assurez-vous que les fichiers suivants existent :
echo - android/app/google-services.json
echo - ios/Runner/GoogleService-Info.plist

if exist "android\app\google-services.json" (
    echo ✅ google-services.json trouvé
) else (
    echo ❌ google-services.json manquant
)

if exist "ios\Runner\GoogleService-Info.plist" (
    echo ✅ GoogleService-Info.plist trouvé
) else (
    echo ❌ GoogleService-Info.plist manquant
)

echo.
echo 🚀 Génération des fichiers Firebase...
flutter packages pub run build_runner build

echo.
echo ✅ Configuration terminée !
echo 📱 Vous pouvez maintenant lancer l'application avec : flutter run
echo.

pause
