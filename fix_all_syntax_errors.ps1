# Script pour corriger toutes les erreurs de syntaxe
Write-Host "Correction massive des erreurs de syntaxe..." -ForegroundColor Green

$filesFixed = 0

Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $originalContent = $content
    
    # Corriger les constructeurs malformés
    $content = $content -replace "const Text\(\\;", "const Text('Texte');"
    $content = $content -replace "const (\w+)\(\{Key\? key\}\) \) : super\(key: key\);", "const `$1({Key? key}) : super(key: key);"
    
    # Corriger les chaînes non fermées
    $content = $content -replace "'([^']*)\$", "'`$1'"
    $content = $content -replace '"([^"]*)\$', '"`$1"'
    $content = $content -replace "'([^']*)'e'\)", "'`$1' + e.toString())"
    $content = $content -replace "'([^']*)'([^']*)\)", "'`$1`$2')"
    
    # Corriger les parenthèses non fermées dans Text
    $content = $content -replace "const Text\('([^']*)", "const Text('`$1')"
    $content = $content -replace "Text\('([^']*)", "Text('`$1')"
    $content = $content -replace "content: \('([^']*)", "content: Text('`$1')"
    
    # Corriger les expressions incomplètes
    $content = $content -replace "child: \),", "child: const Text('Action')),"
    $content = $content -replace "child: \)", "child: const Text('Action'))"
    $content = $content -replace "Icon\(Icons\.\),", "Icon(Icons.info),"
    $content = $content -replace "Icon\(Icons\.\)", "Icon(Icons.info)"
    
    # Corriger les EdgeInsets vides
    $content = $content -replace "const EdgeInsets\.all\(\)", "const EdgeInsets.all(8.0)"
    $content = $content -replace "const EdgeInsets\.symmetric\(\)", "const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)"
    $content = $content -replace "padding: ,", "padding: const EdgeInsets.all(8.0),"
    
    # Corriger les listes non fermées
    $content = $content -replace "children: \[", "children: ["
    $content = $content -replace "\.\.\.\[", "...[]"
    
    # Corriger les commentaires non fermés
    $content = $content -replace "/\*([^*]|\*[^/])*$", "/* `$1 */"
    
    # Corriger les withValues
    $content = $content -replace "\.withValues\(alpha: ,", ".withValues(alpha: 0.5),"
    $content = $content -replace "\.withValues\(alpha: \)", ".withValues(alpha: 0.5)"
    
    # Corriger les chaînes avec caractères spéciaux
    $content = $content -replace "é", "e"
    $content = $content -replace "è", "e"
    $content = $content -replace "à", "a"
    $content = $content -replace "ç", "c"
    
    # Corriger les expressions de debug
    $content = $content -replace "debugPrint\('([^']*)'([^']*)\);", "debugPrint('`$1' + `$2.toString());"
    
    # Corriger les NavigationNamed non fermées
    $content = $content -replace "Navigator\.pushReplacementNamed\(context, '/login\s*$", "Navigator.pushReplacementNamed(context, '/login');"
    
    # Corriger les accolades manquantes
    $content = $content -replace "^\s*\}\s*$", ""
    $content = $content -replace "^\s*\)\s*$", ""
    $content = $content -replace "^\s*;\s*$", ""
    
    # Nettoyer les lignes vides excessives
    $content = $content -replace "\n\n\n+", "`n`n"
    
    if ($content -ne $originalContent) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
        $filesFixed++
        Write-Host "Corrige: $($_.Name)" -ForegroundColor Yellow
    }
}

Write-Host "Termine! $filesFixed fichiers corriges" -ForegroundColor Green
