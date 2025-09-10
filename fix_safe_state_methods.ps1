# Script PowerShell pour corriger les méthodes safeInit et safeSetState
# Ajoute le mixin SafeStateMixin à tous les fichiers qui utilisent ces méthodes

Write-Host "🔧 Correction des méthodes safeInit et safeSetState..." -ForegroundColor Yellow

$totalFiles = 0
$fixedFiles = 0

# Fonction pour corriger un fichier
function Fix-SafeStateMethods {
    param([string]$filePath)
    
    if (-not (Test-Path $filePath)) {
        return $false
    }
    
    $content = Get-Content $filePath -Raw -Encoding UTF8
    $originalContent = $content
    $needsFix = $false
    
    # Vérifier si le fichier utilise safeInit ou safeSetState
    if ($content -match "safeInit\(" -or $content -match "safeSetState\(") {
        $needsFix = $true

        # Ajouter l'import du mixin si pas déjà présent
        if ($content -notmatch "import.*safe_state_mixin\.dart") {
            # Trouver la dernière ligne d'import
            $lines = $content -split "`n"
            $lastImportIndex = -1
            
            for ($i = 0; $i -lt $lines.Length; $i++) {
                if ($lines[$i] -match "^import\s+") {
                    $lastImportIndex = $i
                }
            }
            
            if ($lastImportIndex -ge 0) {
                # Calculer le chemin relatif vers le mixin
                $relativePath = ""
                $depth = ($filePath -split "\\").Length - ($PWD.Path -split "\\").Length - 2
                for ($i = 0; $i -lt $depth; $i++) {
                    $relativePath += "../"
                }
                $relativePath += "common/mixins/safe_state_mixin.dart"
                
                $importLine = "import '$relativePath';"
                $lines = $lines[0..$lastImportIndex] + $importLine + $lines[($lastImportIndex + 1)..($lines.Length - 1)]
                $content = $lines -join "`n"
            }
        }
        
        # Ajouter le mixin aux classes State qui n'en ont pas
        $content = $content -replace "class\s+(\w+)\s+extends\s+State<(\w+)>\s*\{", 'class $1 extends State<$2> with SafeStateMixin {'
        $content = $content -replace "class\s+(\w+)\s+extends\s+State<(\w+)>\s+with\s+TickerProviderStateMixin\s*\{", 'class $1 extends State<$2> with TickerProviderStateMixin, SafeStateMixin {'
        $content = $content -replace "class\s+(\w+)\s+extends\s+State<(\w+)>\s+with\s+(\w+)\s*\{", 'class $1 extends State<$2> with $3, SafeStateMixin {'
        
        # Éviter les doublons de SafeStateMixin
        $content = $content -replace "with\s+SafeStateMixin,\s+SafeStateMixin", "with SafeStateMixin"
        $content = $content -replace "with\s+(\w+),\s+SafeStateMixin,\s+SafeStateMixin", 'with $1, SafeStateMixin'
    }
    
    # Sauvegarder seulement si des changements ont été faits
    if ($content -ne $originalContent) {
        Set-Content $filePath $content -Encoding UTF8
        return $true
    }
    
    return $false
}

# Traiter tous les fichiers Dart
$dartFiles = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

foreach ($file in $dartFiles) {
    $totalFiles++
    
    if (Fix-SafeStateMethods -filePath $file.FullName) {
        $fixedFiles++
        Write-Host "✅ Corrigé: $($file.FullName)" -ForegroundColor Green
    }
}

Write-Host "`n📊 Résumé:" -ForegroundColor Cyan
Write-Host "   Fichiers traités: $totalFiles" -ForegroundColor White
Write-Host "   Fichiers corrigés: $fixedFiles" -ForegroundColor Green

if ($fixedFiles -gt 0) {
    Write-Host "`n🎉 Correction terminée! Vous pouvez maintenant compiler votre projet." -ForegroundColor Green
} else {
    Write-Host "`n ℹ️ Aucune correction nécessaire." -ForegroundColor Yellow
}
