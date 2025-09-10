#!/usr/bin/env pwsh

Write-Host "🔍 DEBUG: Script de débogage pour l'erreur showSnackBar" -ForegroundColor Cyan

# Nettoyer les logs précédents
Write-Host "🧹 Nettoyage des logs précédents..." -ForegroundColor Yellow
if (Test-Path "debug_logs.txt") {
    Remove-Item "debug_logs.txt"
}

# Lancer l'application avec logs détaillés
Write-Host "🚀 Lancement de l'application avec logs détaillés..." -ForegroundColor Green
flutter run --debug --verbose 2>&1 | Tee-Object -FilePath "debug_logs.txt"

Write-Host "✅ Logs sauvegardés dans debug_logs.txt" -ForegroundColor Green
Write-Host "🔍 Recherche des erreurs showSnackBar..." -ForegroundColor Cyan

# Rechercher les erreurs spécifiques
if (Test-Path "debug_logs.txt") {
    Write-Host "`n📋 ERREURS SHOWSNACKBAR TROUVÉES:" -ForegroundColor Red
    Select-String -Path "debug_logs.txt" -Pattern "showSnackBar|ScaffoldMessenger" -Context 3
    
    Write-Host "`n📋 ERREURS FLUTTER GÉNÉRALES:" -ForegroundColor Red
    Select-String -Path "debug_logs.txt" -Pattern "FlutterError|Exception|Error:" -Context 2
    
    Write-Host "`n📋 LOGS DEBUG PERSONNALISÉS:" -ForegroundColor Blue
    Select-String -Path "debug_logs.txt" -Pattern "🔍 DEBUG|❌ DEBUG|🎯" -Context 1
}
