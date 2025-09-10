# Script ultra-rapide pour supprimer les fonctions en dehors de la classe
Write-Host "Suppression des fonctions problématiques..." -ForegroundColor Yellow

$file = "lib\features\conducteur\screens\conducteur_dashboard_complete.dart"

if (Test-Path $file) {
    $content = Get-Content $file -Raw -Encoding UTF8
    $lines = $content -split "`n"
    $newLines = @()
    $inClass = $false
    $braceCount = 0
    $classFound = $false
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        # Détecter le début de la classe State
        if ($line -match "class _.*State.*extends.*State.*\{" -and -not $classFound) {
            $inClass = $true
            $classFound = $true
            $braceCount = 1
            $newLines += $line
            continue
        }
        
        # Si on est dans la classe, compter les accolades
        if ($inClass) {
            $openBraces = ($line -split '\{').Length - 1
            $closeBraces = ($line -split '\}').Length - 1
            $braceCount += $openBraces - $closeBraces
            
            $newLines += $line
            
            # Si on sort de la classe principale
            if ($braceCount -eq 0) {
                $inClass = $false
                # Ajouter la fermeture du fichier
                break
            }
        } elseif (-not $classFound) {
            # Avant la classe, garder tout
            $newLines += $line
        }
        # Après la classe, ignorer tout (fonctions en dehors)
    }
    
    $newContent = $newLines -join "`n"
    Set-Content $file $newContent -Encoding UTF8
    Write-Host "Fichier nettoyé!" -ForegroundColor Green
}

Write-Host "Terminé!" -ForegroundColor Green
