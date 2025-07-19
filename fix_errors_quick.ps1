# 🔧 Script PowerShell pour corriger rapidement les erreurs principales
Write-Host "🔧 Début de la correction automatique des erreurs..." -ForegroundColor Green

$filesFixed = 0
$totalErrors = 0

# Obtenir tous les fichiers Dart
$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
Write-Host "📁 $($dartFiles.Count) fichiers Dart trouvés" -ForegroundColor Yellow

foreach ($file in $dartFiles) {
    try {
        $content = Get-Content $file.FullName -Raw -ErrorAction Stop
        $originalContent = $content
        $fileErrors = 0
        
        # 1. CORRIGER LES ERREURS WITHOPACITY (CRITIQUE)
        if ($content -match "\.withOpacity\(") {
            $content = $content -replace "\.withOpacity\(([^)]+)\)", ".withValues(alpha: `$1)"
            $fileErrors++
        }
        
        # 2. CORRIGER LES DOUBLES POINT-VIRGULES
        if ($content -match ";;") {
            $content = $content -replace ";;", ";"
            $fileErrors++
        }
        
        # 3. CORRIGER LES ERREURS CONST SIMPLES
        $constReplacements = @{
            "(?<!const\s)Text\(" = "const Text("
            "(?<!const\s)Icon\(" = "const Icon("
            "(?<!const\s)SizedBox\(" = "const SizedBox("
            "(?<!const\s)EdgeInsets\." = "const EdgeInsets."
            "(?<!const\s)Padding\(" = "const Padding("
        }
        
        foreach ($pattern in $constReplacements.Keys) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $constReplacements[$pattern]
                $fileErrors++
            }
        }
        
        # 4. CORRIGER LES ERREURS DE SYNTAXE COMMUNES
        $syntaxFixes = @{
            "Selectableconst" = "SelectableText(const"
            "adminData:" = "data:"
            'Text\(\)' = 'Text("Texte")'
            'Text\("")' = 'Text("Texte")'
            "this\.createdData = \);" = "this.createdData = const [];"
            "this\.collectionsUsed = \);" = "this.collectionsUsed = const {};"
        }
        
        foreach ($pattern in $syntaxFixes.Keys) {
            if ($content -match $pattern) {
                $content = $content -replace $pattern, $syntaxFixes[$pattern]
                $fileErrors++
            }
        }
        
        # 5. CORRIGER LES ERREURS DE CONSTRUCTEURS
        if ($content -match "super\.key") {
            $content = $content -replace "const\s+([A-Z][a-zA-Z]*)\s*\(\s*\{\s*super\.key", "const `$1({Key? key"
            $content = $content -replace "\}\) : super\(key: key\);", "}) : super(key: key);"
            $fileErrors++
        }
        
        # 6. NETTOYER LES LIGNES VIDES EXCESSIVES
        if ($content -match "\n\n\n") {
            $content = $content -replace "\n\n\n+", "`n`n"
            $fileErrors++
        }
        
        # 7. CORRIGER LES IMPORTS INUTILISÉS COURANTS
        $unusedImports = @(
            "import 'dart:typed_data';",
            "import '../../../core/widgets/custom_app_bar.dart';",
            "import '../../../core/widgets/empty_state.dart';",
            "import '../../../core/widgets/loading_state.dart';",
            "import '../../../core/services/email_service.dart';",
            "import '../../../../test_firestore_screen.dart';"
        )
        
        foreach ($import in $unusedImports) {
            if ($content -match [regex]::Escape($import)) {
                $content = $content -replace [regex]::Escape($import), ""
                $fileErrors++
            }
        }
        
        # Sauvegarder si des changements ont été faits
        if ($content -ne $originalContent) {
            Set-Content -Path $file.FullName -Value $content -NoNewline -ErrorAction Stop
            $filesFixed++
            $totalErrors += $fileErrors
            
            if ($filesFixed % 10 == 0) {
                Write-Host "  📝 $filesFixed fichiers corrigés..." -ForegroundColor Cyan
            }
        }
        
    } catch {
        Write-Host "  ⚠️ Erreur avec $($file.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "✅ CORRECTION TERMINÉE !" -ForegroundColor Green
Write-Host "📁 $filesFixed fichiers corrigés" -ForegroundColor Yellow
Write-Host "🔧 ~$totalErrors erreurs réparées" -ForegroundColor Yellow
Write-Host ""
Write-Host "🚀 Testez maintenant avec: flutter analyze" -ForegroundColor Cyan
