# Script pour corriger le fichier users_management_screen.dart
Write-Host "Correction du fichier users_management_screen.dart..." -ForegroundColor Green

$file = "lib\features\admin\presentation\screens\users_management_screen.dart"
$content = Get-Content $file -Raw

# Corriger les erreurs communes
$content = $content -replace "const Text\(\\;", "const UsersManagementScreen({Key? key}) : super(key: key);"
$content = $content -replace "const Text\(\(", "const Text("
$content = $content -replace "const Text\('([^']*)'", "const Text('`$1')"
$content = $content -replace "const Text\(""([^""]*)""\)", "const Text('`$1')"

# Corriger les parenthèses manquantes
$content = $content -replace "Text\(\(", "Text("
$content = $content -replace "Text\('([^']*)", "Text('`$1')"

# Corriger les virgules manquantes
$content = $content -replace "Icon\(Icons\.([^,)]+)\)", "Icon(Icons.`$1)"

# Corriger les constructeurs vides
$content = $content -replace "const EdgeInsets\.all\(\)", "const EdgeInsets.all(8.0)"
$content = $content -replace "const EdgeInsets\.symmetric\(\)", "const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0)"

# Corriger les chaînes non fermées
$content = $content -replace "'([^']*)\$", "'`$1'"

# Corriger les expressions incomplètes
$content = $content -replace "child: \),", "child: const Text('Action')),"
$content = $content -replace "child: \)", "child: const Text('Action'))"

# Corriger les icônes manquantes
$content = $content -replace "Icon\(Icons\.\),", "Icon(Icons.info),"
$content = $content -replace "Icon\(Icons\.\)", "Icon(Icons.info)"

# Corriger les Text vides
$content = $content -replace "const Text\(\),", "const Text('Texte'),"
$content = $content -replace "const Text\(\)", "const Text('Texte')"

# Corriger les expressions avec des points orphelins
$content = $content -replace "^\s*\.\s*$", ""
$content = $content -replace "^\s*,\s*$", ""

# Nettoyer les lignes vides excessives
$content = $content -replace "\n\n\n+", "`n`n"

Set-Content -Path $file -Value $content -NoNewline
Write-Host "Fichier corrige!" -ForegroundColor Yellow
