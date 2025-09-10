$filePath = "lib/conducteur/screens/modern_single_accident_info_screen.dart"
$content = Get-Content $filePath -Raw

Write-Host "Remplacement de tous les ScaffoldMessenger.of(context).showSnackBar..."

# Remplacer tous les ScaffoldMessenger.of(context).showSnackBar par des commentaires temporaires
$content = $content -replace 'ScaffoldMessenger\.of\(context\)\.showSnackBar\(', '// SNACKBAR_REMOVED: ScaffoldMessenger.of(context).showSnackBar('

$content | Set-Content $filePath -Encoding UTF8

Write-Host "Terminé ! Tous les SnackBar ont été commentés."
