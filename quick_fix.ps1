Write-Host "Correction rapide..." -ForegroundColor Yellow

$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw -Encoding UTF8
    $changed = $false
    
    if ($content -match "safeInit") {
        $content = $content -replace "safeInit\(\(\)\s*\{", "WidgetsBinding.instance.addPostFrameCallback((_) {"
        $changed = $true
    }
    
    if ($content -match "safeSetState") {
        $content = $content -replace "safeSetState\(", "if (mounted) setState("
        $changed = $true
    }
    
    if ($changed) {
        Set-Content $file.FullName $content -Encoding UTF8
        Write-Host "OK: $($file.Name)" -ForegroundColor Green
    }
}

Write-Host "Termine!" -ForegroundColor Green
