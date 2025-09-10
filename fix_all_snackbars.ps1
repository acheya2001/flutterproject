#!/usr/bin/env pwsh

Write-Host "🔧 CORRECTION DE TOUS LES SNACKBARS" -ForegroundColor Cyan

$filePath = "lib/conducteur/screens/modern_single_accident_info_screen.dart"

if (Test-Path $filePath) {
    Write-Host "📝 Lecture du fichier..." -ForegroundColor Yellow
    $content = Get-Content $filePath -Raw
    
    Write-Host "🔄 Remplacement des ScaffoldMessenger..." -ForegroundColor Yellow
    
    # Remplacer les patterns les plus courants
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(\s*content: Text\(''([^'']+)''\),\s*backgroundColor: Colors\.green,', 'SafeSnackBar.showSuccess(context, ''$1'');'
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(\s*content: Text\(''([^'']+)''\),\s*backgroundColor: Colors\.red,', 'SafeSnackBar.showError(context, ''$1'');'
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*const SnackBar\(\s*content: Text\(''([^'']+)''\),\s*backgroundColor: Colors\.orange,', 'SafeSnackBar.showWarning(context, ''$1'');'
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(''([^'']+)''\),\s*backgroundColor: Colors\.green,', 'SafeSnackBar.showSuccess(context, ''$1'');'
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(''([^'']+)''\),\s*backgroundColor: Colors\.red,', 'SafeSnackBar.showError(context, ''$1'');'
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(''([^'']+)''\),\s*backgroundColor: Colors\.orange,', 'SafeSnackBar.showWarning(context, ''$1'');'
    
    # Patterns avec variables
    $content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(\s*SnackBar\(\s*content: Text\(''Erreur: \$e''\),\s*backgroundColor: Colors\.red,', 'SafeSnackBar.showError(context, ''Erreur: $e'');'
    
    Write-Host "💾 Sauvegarde du fichier corrigé..." -ForegroundColor Yellow
    $content | Set-Content $filePath -Encoding UTF8
    
    Write-Host "✅ Correction terminée !" -ForegroundColor Green
    Write-Host "📊 Vérification des ScaffoldMessenger restants..." -ForegroundColor Blue
    
    $remaining = Select-String -Path $filePath -Pattern "ScaffoldMessenger\.of\(context\)\.showSnackBar" | Measure-Object
    Write-Host "🔍 ScaffoldMessenger restants: $($remaining.Count)" -ForegroundColor $(if ($remaining.Count -eq 0) { "Green" } else { "Red" })
    
} else {
    Write-Host "❌ Fichier non trouvé: $filePath" -ForegroundColor Red
}
