# Script simple pour remplacer safeInit et safeSetState
Write-Host "🔧 Remplacement des méthodes safeInit et safeSetState..." -ForegroundColor Yellow

$totalFiles = 0
$fixedFiles = 0

# Traiter tous les fichiers Dart
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $dartFiles) {
    $totalFiles++
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Remplacer safeInit par WidgetsBinding.instance.addPostFrameCallback
    $content = $content -replace "safeInit\(\(\)\s*\{", "WidgetsBinding.instance.addPostFrameCallback((_) {"
    
    # Remplacer safeSetState par if (mounted) setState
    $content = $content -replace "safeSetState\(", "if (mounted) setState("
    
    # Sauvegarder si des changements ont été faits
    if ($content -ne $originalContent) {
        Set-Content $file.FullName $content -Encoding UTF8
        $fixedFiles++
        Write-Host "✅ Corrigé: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "`n📊 Résumé:" -ForegroundColor Cyan
Write-Host "   Fichiers traités: $totalFiles" -ForegroundColor White
Write-Host "   Fichiers corrigés: $fixedFiles" -ForegroundColor Green

Write-Host "`n🎉 Correction terminée!" -ForegroundColor Green
