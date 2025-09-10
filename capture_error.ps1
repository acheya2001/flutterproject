#!/usr/bin/env pwsh

Write-Host "🔍 CAPTURE D'ERREUR - Script de débogage avancé" -ForegroundColor Cyan

# Nettoyer les logs précédents
if (Test-Path "error_log.txt") { Remove-Item "error_log.txt" }

Write-Host "🚀 Lancement Flutter avec capture d'erreur..." -ForegroundColor Green

# Lancer Flutter et capturer TOUTES les sorties
Start-Process -FilePath "flutter" -ArgumentList "run", "--debug" -RedirectStandardOutput "flutter_output.txt" -RedirectStandardError "flutter_error.txt" -NoNewWindow -Wait

Write-Host "📋 ANALYSE DES ERREURS:" -ForegroundColor Red

# Analyser les erreurs
if (Test-Path "flutter_error.txt") {
    Write-Host "`n❌ ERREURS FLUTTER:" -ForegroundColor Red
    Get-Content "flutter_error.txt" | Where-Object { $_ -match "showSnackBar|ScaffoldMessenger|Error|Exception" }
}

if (Test-Path "flutter_output.txt") {
    Write-Host "`n📊 LOGS PERTINENTS:" -ForegroundColor Blue
    Get-Content "flutter_output.txt" | Where-Object { $_ -match "🔥|ERROR|Exception|showSnackBar" }
}

Write-Host "`n✅ Analyse terminée. Vérifiez les fichiers flutter_output.txt et flutter_error.txt" -ForegroundColor Green
