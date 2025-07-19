# Script pour corriger les enums avec l'ancienne syntaxe
Write-Host "Correction des enums..." -ForegroundColor Green

$enumFile = "lib\core\enums\app_enums.dart"
$content = Get-Content $enumFile -Raw

# Supprimer les lignes avec juste ";"
$content = $content -replace "\s+;\s*\n", "`n"

# Supprimer les déclarations de propriétés finales dans les enums
$content = $content -replace "\s+final String value;\s*\n", ""
$content = $content -replace "\s+final String displayName;\s*\n", ""
$content = $content -replace "\s+final String icon;\s*\n", ""
$content = $content -replace "\s+final bool isRequired;\s*\n", ""
$content = $content -replace "\s+final bool isFinal;\s*\n", ""
$content = $content -replace "\s+final int hierarchyLevel;\s*\n", ""

# Remplacer les enums avec paramètres par des enums simples
$content = $content -replace "(\w+)\([^)]+\),", "`$1,"
$content = $content -replace "(\w+)\([^)]+\);", "`$1;"

# Nettoyer les lignes vides excessives
$content = $content -replace "\n\n\n+", "`n`n"

Set-Content -Path $enumFile -Value $content -NoNewline
Write-Host "Enums corriges!" -ForegroundColor Yellow
