# Script PowerShell pour mettre à jour le projet sur GitHub
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MISE A JOUR GITHUB - CONSTAT TUNISIE" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

try {
    # 1. Vérification de Git
    Write-Host "`n1. Verification de Git..." -ForegroundColor Yellow
    $gitVersion = git --version 2>$null
    if ($LASTEXITCODE -ne 0) {
        throw "Git n'est pas installé ou non accessible"
    }
    Write-Host "Git detecte: $gitVersion" -ForegroundColor Green

    # 2. Initialisation du repository
    Write-Host "`n2. Initialisation du repository..." -ForegroundColor Yellow
    git init
    
    # 3. Configuration Git
    Write-Host "`n3. Configuration Git..." -ForegroundColor Yellow
    git config user.name "Constat Tunisie Developer"
    git config user.email "constat.tunisie.app@gmail.com"
    
    # 4. Vérification du statut
    Write-Host "`n4. Verification du statut..." -ForegroundColor Yellow
    git status --porcelain
    
    # 5. Ajout des fichiers
    Write-Host "`n5. Ajout de tous les fichiers..." -ForegroundColor Yellow
    git add .
    
    # 6. Commit
    Write-Host "`n6. Creation du commit..." -ForegroundColor Yellow
    $commitMessage = "Mise à jour complète du système d'assurance - Version finale avec processus de contrats complet

Features incluses:
- Système complet de gestion des contrats d'assurance
- Workflow détaillé en 12 étapes (Conducteur → Admin → Agent → Activation)
- Interface moderne pour tous les rôles (Super Admin, Admin Compagnie, Admin Agence, Agent, Conducteur, Expert)
- Gestion des demandes d'assurance avec assignation automatique/manuelle
- Création de contrats avec calcul de prime et choix de garanties
- Signature numérique et processus de paiement
- Génération automatique des documents (Carte Verte, Police, Échéancier)
- Système de notifications et traçabilité complète
- Sécurité renforcée avec règles Firestore strictes
- Support multi-compagnies et multi-agences
- Gestion des sinistres et expertises
- Système de renouvellement automatique"

    git commit -m $commitMessage
    
    # 7. Branche principale
    Write-Host "`n7. Configuration de la branche principale..." -ForegroundColor Yellow
    git branch -M main
    
    # 8. Remote GitHub
    Write-Host "`n8. Configuration du remote GitHub..." -ForegroundColor Yellow
    git remote remove origin 2>$null
    
    # Demander l'URL du repository GitHub
    Write-Host "`nVeuillez entrer l'URL de votre repository GitHub:" -ForegroundColor Cyan
    Write-Host "Format: https://github.com/VOTRE_USERNAME/constat_tunisie.git" -ForegroundColor Gray
    $repoUrl = Read-Host "URL du repository"
    
    if ([string]::IsNullOrWhiteSpace($repoUrl)) {
        $repoUrl = "https://github.com/YOUR_USERNAME/constat_tunisie.git"
        Write-Host "URL par defaut utilisee: $repoUrl" -ForegroundColor Yellow
        Write-Host "ATTENTION: Vous devrez modifier YOUR_USERNAME" -ForegroundColor Red
    }
    
    git remote add origin $repoUrl
    
    # 9. Push vers GitHub
    Write-Host "`n9. Push vers GitHub..." -ForegroundColor Yellow
    Write-Host "Authentification GitHub requise..." -ForegroundColor Cyan
    git push -u origin main
    
    Write-Host "`n========================================" -ForegroundColor Green
    Write-Host "MISE A JOUR REUSSIE !" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    
} catch {
    Write-Host "`n========================================" -ForegroundColor Red
    Write-Host "ERREUR LORS DE LA MISE A JOUR" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "Erreur: $($_.Exception.Message)" -ForegroundColor Red
    
    Write-Host "`nSOLUTIONS POSSIBLES:" -ForegroundColor Yellow
    Write-Host "1. Verifiez que Git est installe et accessible" -ForegroundColor White
    Write-Host "2. Verifiez votre connexion internet" -ForegroundColor White
    Write-Host "3. Verifiez que le repository GitHub existe" -ForegroundColor White
    Write-Host "4. Verifiez vos permissions GitHub" -ForegroundColor White
}

Write-Host "`nAppuyez sur une touche pour continuer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
