# Script pour corriger les StateNotifiers
Write-Host "Correction des StateNotifiers..." -ForegroundColor Green

$filesFixed = 0

Get-ChildItem -Path "lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    $modified = $false
    
    # Corriger les StateNotifier sans état initial
    if ($content -match "StateNotifier<(\w+)>\s*\{\s*\w+\(\)\s*:\s*super\(\);") {
        # SuperAdminState
        $content = $content -replace "StateNotifier<SuperAdminState>\s*\{\s*(\w+)\(\)\s*:\s*super\(\);", "StateNotifier<SuperAdminState> {`n  `$1() : super(const SuperAdminState());"
        
        # AuthState
        $content = $content -replace "StateNotifier<AuthState>\s*\{\s*(\w+)\(\)\s*:\s*super\(\);", "StateNotifier<AuthState> {`n  `$1() : super(const AuthState());"
        
        # AccountRequestState
        $content = $content -replace "StateNotifier<AccountRequestState>\s*\{\s*(\w+)\(\)\s*:\s*super\(\);", "StateNotifier<AccountRequestState> {`n  `$1() : super(const AccountRequestState());"
        
        # CompagnieAgenceState
        $content = $content -replace "StateNotifier<CompagnieAgenceState>\s*\{\s*(\w+)\(\)\s*:\s*super\(\);", "StateNotifier<CompagnieAgenceState> {`n  `$1() : super(const CompagnieAgenceState());"
        
        # OnboardingState
        $content = $content -replace "StateNotifier<OnboardingState>\s*\{\s*(\w+)\(\)\s*:\s*super\(\);", "StateNotifier<OnboardingState> {`n  `$1() : super(const OnboardingState());"
        
        # SplashState
        $content = $content -replace "StateNotifier<SplashState>\s*\{\s*(\w+)\(\)\s*:\s*super\(\);", "StateNotifier<SplashState> {`n  `$1() : super(const SplashState());"
        
        $modified = $true
    }
    
    # Corriger les constructeurs super() vides
    if ($content -match ":\s*super\(\)\s*;") {
        $content = $content -replace ":\s*super\(\)\s*;", ": super(const Object());"
        $modified = $true
    }
    
    if ($modified) {
        Set-Content -Path $_.FullName -Value $content -NoNewline
        $filesFixed++
        Write-Host "Corrige: $($_.Name)" -ForegroundColor Yellow
    }
}

Write-Host "Termine! $filesFixed fichiers corriges" -ForegroundColor Green
