# 🔧 Script PowerShell pour corriger les erreurs de compilation
Write-Host "🔧 Début de la correction des erreurs..." -ForegroundColor Green

# 1. Corriger withOpacity en withValues
Write-Host "📝 Correction des withOpacity..." -ForegroundColor Yellow
Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "\.withOpacity\(") {
        $content = $content -replace "\.withOpacity\(([^)]+)\)", ".withValues(alpha: `$1)"
        Set-Content -Path $_.FullName -Value $content -NoNewline
        Write-Host "  ✅ $($_.Name)" -ForegroundColor Green
    }
}

# 2. Corriger les constructeurs sans const
Write-Host "📝 Ajout de const aux constructeurs..." -ForegroundColor Yellow
Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $modified = $false
    
    # Remplacements courants
    $replacements = @{
        "(?<!const\s)Text\(" = "const Text("
        "(?<!const\s)Icon\(" = "const Icon("
        "(?<!const\s)SizedBox\(" = "const SizedBox("
        "(?<!const\s)EdgeInsets\." = "const EdgeInsets."
        "(?<!const\s)Padding\(" = "const Padding("
        "(?<!const\s)Center\(" = "const Center("
    }
    
    foreach ($pattern in $replacements.Keys) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, $replacements[$pattern]
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
        Write-Host "  ✅ $($_.Name)" -ForegroundColor Green
    }
}

# 3. Supprimer les imports inutilisés courants
Write-Host "📝 Suppression des imports inutilisés..." -ForegroundColor Yellow
$unusedImports = @(
    "import 'dart:typed_data';",
    "import '../../../core/widgets/custom_app_bar.dart';",
    "import '../../../core/widgets/empty_state.dart';",
    "import '../../../core/widgets/loading_state.dart';",
    "import '../../../core/services/email_service.dart';"
)

Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $modified = $false
    
    foreach ($import in $unusedImports) {
        if ($content -match [regex]::Escape($import)) {
            $content = $content -replace [regex]::Escape($import), ""
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
        Write-Host "  ✅ $($_.Name)" -ForegroundColor Green
    }
}

# 4. Corriger les super.key en Key? key
Write-Host "📝 Correction des constructeurs super.key..." -ForegroundColor Yellow
Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    if ($content -match "super\.key") {
        $content = $content -replace "super\.key", "Key? key"
        $content = $content -replace "\) : super\(key: key\);", ") : super(key: key);"
        Set-Content -Path $_.FullName -Value $content -NoNewline
        Write-Host "  ✅ $($_.Name)" -ForegroundColor Green
    }
}

Write-Host "✅ Correction terminée !" -ForegroundColor Green
Write-Host "🚀 Vous pouvez maintenant lancer: flutter run" -ForegroundColor Cyan
