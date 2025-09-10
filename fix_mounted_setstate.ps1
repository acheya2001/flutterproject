# Script pour corriger tous les "if (mounted) setState" sans accolades
Write-Host "Correction des setState avec mounted..." -ForegroundColor Yellow

$file = "lib\conducteur\widgets\croquis_interactif_widget.dart"

if (Test-Path $file) {
    $content = Get-Content $file -Raw -Encoding UTF8
    
    # Remplacer tous les patterns "if (mounted) setState(" par "if (mounted) { setState("
    $content = $content -replace 'if \(mounted\) setState\(', 'if (mounted) { setState('
    
    # Maintenant nous devons ajouter les accolades fermantes
    # Nous allons traiter ligne par ligne pour être plus précis
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
                $newLines += "                  }"
                $needsClosingBrace = $false
            }
        } else {
            $newLines += $line
        }
    }
    
    $newContent = $newLines -join "`n"
    Set-Content $file $newContent -Encoding UTF8
    Write-Host "Fichier corrigé!" -ForegroundColor Green
}

Write-Host "Terminé!" -ForegroundColor Green
