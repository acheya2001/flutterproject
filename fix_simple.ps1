# Script simple pour corriger les erreurs principales
Write-Host "Correction des erreurs withOpacity..." -ForegroundColor Green

$filesFixed = 0

Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $modified = $false

    # Corriger withOpacity
    if ($content -match "\.withOpacity\(") {
        $content = $content -replace "\.withOpacity\(([^)]+)\)", ".withValues(alpha: `$1)"
        $modified = $true
    }

    # Corriger doubles point-virgules
    if ($content -match ";;") {
        $content = $content -replace ";;", ";"
        $modified = $true
    }

    # Corriger erreurs const simples
    if ($content -match "(?<!const\s)Text\(") {
        $content = $content -replace "(?<!const\s)Text\(", "const Text("
        $modified = $true
    }

    if ($content -match "(?<!const\s)Icon\(") {
        $content = $content -replace "(?<!const\s)Icon\(", "const Icon("
        $modified = $true
    }

    if ($content -match "(?<!const\s)SizedBox\(") {
        $content = $content -replace "(?<!const\s)SizedBox\(", "const SizedBox("
        $modified = $true
    }

    # Corriger erreurs de syntaxe
    if ($content -match "Selectableconst") {
        $content = $content -replace "Selectableconst", "SelectableText(const"
        $modified = $true
    }

    if ($content -match "adminData:") {
        $content = $content -replace "adminData:", "data:"
        $modified = $true
    }

    if ($modified) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
        $filesFixed++
        Write-Host "Corrige: $($_.Name)" -ForegroundColor Yellow
    }
}

Write-Host "Termine! $filesFixed fichiers corriges" -ForegroundColor Green
