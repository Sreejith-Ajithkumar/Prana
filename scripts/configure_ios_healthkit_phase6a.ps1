$ErrorActionPreference = 'Stop'

$repoRoot = (Get-Location).Path
$projectPath = Join-Path $repoRoot 'apps\mobile\ios\Runner.xcodeproj\project.pbxproj'

if (-not (Test-Path $projectPath)) {
    throw "Could not find $projectPath. Run this script from the Prana repo root."
}

$text = [System.IO.File]::ReadAllText($projectPath)

# health 13.3.2 requires iOS 15.0+.
$text = $text -replace 'IPHONEOS_DEPLOYMENT_TARGET = 13\.0;', 'IPHONEOS_DEPLOYMENT_TARGET = 15.0;'

# Wire Runner build configurations to the HealthKit entitlements file.
$lines = $text -split "`r?`n"
$output = New-Object System.Collections.Generic.List[string]

foreach ($line in $lines) {
    if ($line -match '^(\s*)INFOPLIST_FILE = Runner/Info\.plist;\s*$') {
        $indent = $matches[1]
        $previous = if ($output.Count -gt 0) { $output[$output.Count - 1] } else { '' }

        if ($previous -notmatch 'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;') {
            $output.Add("${indent}CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements;")
        }
    }

    $output.Add($line)
}

$result = [string]::Join("`r`n", $output)

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($projectPath, $result, $utf8NoBom)

$deploymentCount = ([regex]::Matches(
    $result,
    'IPHONEOS_DEPLOYMENT_TARGET = 15\.0;'
)).Count

$entitlementsCount = ([regex]::Matches(
    $result,
    'CODE_SIGN_ENTITLEMENTS = Runner/Runner\.entitlements;'
)).Count

Write-Host "Updated iOS project configuration."
Write-Host "iOS 15 deployment target entries: $deploymentCount"
Write-Host "Runner entitlements build settings: $entitlementsCount"

if ($entitlementsCount -lt 3) {
    Write-Warning "Expected Runner entitlements in Debug/Profile/Release. Inspect project.pbxproj before committing."
}
