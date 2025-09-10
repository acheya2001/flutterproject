$filePath = "lib/conducteur/screens/modern_single_accident_info_screen.dart"
$content = Get-Content $filePath -Raw

Write-Host "Nettoyage des SnackBar cassés..."

# Remplacer tous les blocs SnackBar cassés par des commentaires simples
$content = $content -replace '// SNACKBAR_REMOVED: ScaffoldMessenger\.of\(context\)\.showSnackBar\([^}]*\}\s*\)\s*;\s*\)', '// SnackBar supprimé pour éviter les erreurs'

# Nettoyer les blocs SnackBar restants qui causent des erreurs de syntaxe
$content = $content -replace '// SNACKBAR_REMOVED: ScaffoldMessenger\.of\(context\)\.showSnackBar\([^;]*;[^}]*\}[^;]*;[^}]*\}[^;]*;', '// SnackBar supprimé'

# Supprimer les lignes orphelines qui causent des erreurs
$content = $content -replace '\s*\),\s*\n\s*\),\s*\n\s*\);', ');'
$content = $content -replace '\s*\),\s*\n\s*\);', ');'

$content | Set-Content $filePath -Encoding UTF8

Write-Host "Nettoyage terminé !"
