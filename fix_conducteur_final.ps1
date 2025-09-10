# Script pour corriger le fichier conducteur_dashboard_complete.dart
Write-Host "Correction du fichier conducteur..." -ForegroundColor Yellow

$file = "lib\features\conducteur\screens\conducteur_dashboard_complete.dart"

if (Test-Path $file) {
    $content = Get-Content $file -Raw -Encoding UTF8
    
    # Supprimer les fonctions problématiques qui utilisent context/mounted en dehors de la classe
    $lines = $content -split "`n"
    $newLines = @()
    $skipFunction = $false
    $braceCount = 0
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        # Détecter les fonctions problématiques
        if ($line -match "^\s*(void|Future).*\(.*\).*\{" -and 
            ($line -match "context" -or $line -match "mounted" -or $line -match "_isLoading" -or $line -match "_vehicules")) {
            $skipFunction = $true
            $braceCount = 1
            continue
        }
        
        if ($skipFunction) {
            $openBraces = ($line -split '\{').Length - 1
            $closeBraces = ($line -split '\}').Length - 1
            $braceCount += $openBraces - $closeBraces
            
            if ($braceCount -eq 0) {
                $skipFunction = $false
            }
            continue
        }
        
        $newLines += $line
    }
    
    $newContent = $newLines -join "`n"
    Set-Content $file $newContent -Encoding UTF8
    Write-Host "Fichier corrigé!" -ForegroundColor Green
}

Write-Host "Terminé!" -ForegroundColor Green
