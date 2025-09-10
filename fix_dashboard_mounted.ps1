# Script pour corriger tous les "if (mounted) setState" dans le dashboard
Write-Host "Correction du dashboard conducteur..." -ForegroundColor Yellow

$file = "lib\features\conducteur\screens\conducteur_dashboard_complete_original.dart"

if (Test-Path $file) {
    $content = Get-Content $file -Raw -Encoding UTF8
    
    # Remplacer tous les patterns problématiques
    $content = $content -replace 'if \(mounted\) setState\(', 'if (mounted) { setState('
    
    # Traiter ligne par ligne pour ajouter les accolades fermantes
    $lines = $content -split "`n"
    $newLines = @()
    $needsClosingBrace = $false
    $braceCount = 0
    
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        
        # Si on trouve une ligne avec "if (mounted) { setState("
        if ($line -match 'if \(mounted\) \{ setState\(') {
            $newLines += $line
            $needsClosingBrace = $true
            $braceCount = 1
            continue
        }
        
        if ($needsClosingBrace) {
            # Compter les accolades
            $openBraces = ($line -split '\{').Length - 1
            $closeBraces = ($line -split '\}').Length - 1
            $braceCount += $openBraces - $closeBraces
            
            $newLines += $line
            
            # Si on ferme toutes les accolades du setState
            if ($braceCount -eq 0) {
                # Ajouter l'accolade fermante pour le if
                $indentation = ""
                if ($line -match '^(\s+)') {
                    $indentation = $matches[1]
                }
                $newLines += "$indentation}"
                $needsClosingBrace = $false
            }
        } else {
            $newLines += $line
        }
    }
    
    $newContent = $newLines -join "`n"
    Set-Content $file $newContent -Encoding UTF8
    Write-Host "Dashboard corrigé!" -ForegroundColor Green
}

Write-Host "Terminé!" -ForegroundColor Green
