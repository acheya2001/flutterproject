# 🔧 Script PowerShell pour corriger les apostrophes manquantes
# Ce script corrige les imports/exports Dart mal formés

Write-Host "🔍 Recherche des fichiers Dart avec apostrophes manquantes..." -ForegroundColor Cyan

$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse
$fixedFiles = 0
$totalIssues = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    $issuesInFile = 0
    
    # Corriger les imports/exports sans apostrophe fermante
    $content = $content -replace "^(import|export)\s+['\`"]([^'\`"]+)$", '$1 ''$2'';'
    
    # Corriger les imports/exports sans point-virgule
    $content = $content -replace "^(import|export)\s+['\`"]([^'\`"]+)['\`"]$", '$1 ''$2'';'
    
    # Compter les corrections
    if ($content -ne $originalContent) {
        $lines = $content -split "`n"
        $originalLines = $originalContent -split "`n"
        
        for ($i = 0; $i -lt $lines.Length; $i++) {
            if ($i -lt $originalLines.Length -and $lines[$i] -ne $originalLines[$i]) {
                $issuesInFile++
            }
        }
        
        # Sauvegarder le fichier corrigé
        Set-Content -Path $file.FullName -Value $content -NoNewline
        
        $fixedFiles++
        $totalIssues += $issuesInFile
        Write-Host "✅ Corrigé $issuesInFile problème(s) dans: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n🎉 Correction terminée !" -ForegroundColor Green
Write-Host "📊 Fichiers corrigés: $fixedFiles" -ForegroundColor Yellow
Write-Host "📊 Total problèmes résolus: $totalIssues" -ForegroundColor Yellow

# Nettoyer le cache Flutter
Write-Host "`n🧹 Nettoyage du cache Flutter..." -ForegroundColor Cyan
flutter clean

Write-Host "✅ Prêt pour les tests !" -ForegroundColor Green
