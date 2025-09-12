@echo off
echo ========================================
echo MISE A JOUR GITHUB - CONSTAT TUNISIE
echo ========================================

echo.
echo 1. Verification de Git...
git --version
if %errorlevel% neq 0 (
    echo ERREUR: Git n'est pas installe ou non accessible
    pause
    exit /b 1
)

echo.
echo 2. Initialisation du repository (si necessaire)...
git init

echo.
echo 3. Configuration Git (si necessaire)...
git config user.name "Constat Tunisie Developer"
git config user.email "constat.tunisie.app@gmail.com"

echo.
echo 4. Verification du statut...
git status

echo.
echo 5. Ajout de tous les fichiers...
git add .

echo.
echo 6. Creation du commit...
git commit -m "Mise a jour complete du systeme d'assurance - Version finale avec processus de contrats complet"

echo.
echo 7. Verification de la branche principale...
git branch -M main

echo.
echo 8. Ajout du remote GitHub (si necessaire)...
git remote remove origin 2>nul
git remote add origin https://github.com/YOUR_USERNAME/constat_tunisie.git

echo.
echo 9. Push vers GitHub...
git push -u origin main

echo.
echo ========================================
echo MISE A JOUR TERMINEE !
echo ========================================
echo.
echo INSTRUCTIONS IMPORTANTES :
echo 1. Remplacez YOUR_USERNAME par votre nom d'utilisateur GitHub
echo 2. Assurez-vous d'avoir cree le repository 'constat_tunisie' sur GitHub
echo 3. Si c'est la premiere fois, vous devrez vous authentifier
echo.
pause
