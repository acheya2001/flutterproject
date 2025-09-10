# Script ultra-rapide pour corriger TOUTES les erreurs
Write-Host "CORRECTION ULTRA-RAPIDE EN COURS..." -ForegroundColor Red

$files = @(
    "lib\features\conducteur\screens\conducteur_dashboard_complete.dart"
)

foreach ($file in $files) {
    if (Test-Path $file) {
        Write-Host "Correction: $file" -ForegroundColor Yellow
        
        $content = Get-Content $file -Raw -Encoding UTF8
        
        # Rechercher les fonctions en dehors de la classe et les supprimer
        # Pattern pour détecter les fonctions problématiques
        $lines = $content -split "`n"
        $newLines = @()
        $inClass = $false
        $braceCount = 0
        
        for ($i = 0; $i -lt $lines.Length; $i++) {
            $line = $lines[$i]
            
            # Détecter le début de la classe
            if ($line -match "class _.*State.*\{") {
                $inClass = $true
                $braceCount = 1
                $newLines += $line
                continue
            }
            
            # Compter les accolades si on est dans la classe
            if ($inClass) {
                $openBraces = ($line -split '\{').Length - 1
                $closeBraces = ($line -split '\}').Length - 1
                $braceCount += $openBraces - $closeBraces
                
                # Si on sort de la classe
                if ($braceCount -eq 0) {
                    $newLines += $line
                    $inClass = $false
                    break
                }
            }
            
            # Ajouter la ligne si on est dans la classe ou avant la classe
            if ($inClass -or -not ($line -match "^\s*(void|Future|Widget|String|int|bool|double).*\(.*\).*\{")) {
                $newLines += $line
            }
        }
        
        $newContent = $newLines -join "`n"
        Set-Content $file $newContent -Encoding UTF8
        Write-Host "OK: $file" -ForegroundColor Green
    }
}

Write-Host "CORRECTION TERMINEE!" -ForegroundColor Green
