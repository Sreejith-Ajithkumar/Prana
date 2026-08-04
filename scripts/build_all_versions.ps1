param(
    [string[]]$Tags = @("v0.1.0", "v0.2.0", "v0.3.0"),
    [string]$RepoRoot = "D:\Development\Projects\Prana"
)

$ErrorActionPreference = "Stop"

function Invoke-Step {
    param(
        [string]$Message,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
    & $Action
}

$mobileDir = Join-Path $RepoRoot "apps\mobile"
$releaseDir = Join-Path $RepoRoot "releases"

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "No Git repository found at: $RepoRoot"
}

if (-not (Test-Path (Join-Path $mobileDir "pubspec.yaml"))) {
    throw "No Flutter project found at: $mobileDir"
}

Invoke-Step "Checking for uncommitted changes" {
    Push-Location $RepoRoot
    try {
        $status = git status --porcelain
        if ($status) {
            throw "Your working tree has uncommitted changes. Commit or stash them before building tagged versions."
        }
    }
    finally {
        Pop-Location
    }
}

Invoke-Step "Creating releases folder" {
    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
}

Push-Location $RepoRoot

try {
    $originalBranch = git branch --show-current

    if ([string]::IsNullOrWhiteSpace($originalBranch)) {
        $originalBranch = "main"
    }

    foreach ($tag in $Tags) {
        Write-Host ""
        Write-Host "----------------------------------------" -ForegroundColor DarkGray
        Write-Host "Building $tag" -ForegroundColor Green
        Write-Host "----------------------------------------" -ForegroundColor DarkGray

        $tagExists = git tag --list $tag

        if (-not $tagExists) {
            Write-Warning "Tag $tag does not exist. Skipping."
            continue
        }

        Invoke-Step "Checking out $tag" {
            git checkout --force $tag
        }

        Push-Location $mobileDir

        try {
            Invoke-Step "Cleaning Flutter build for $tag" {
                flutter clean
            }

            Invoke-Step "Getting dependencies for $tag" {
                flutter pub get
            }

            Invoke-Step "Analyzing $tag" {
                flutter analyze
            }

            Invoke-Step "Building release APK for $tag" {
                flutter build apk --release
            }

            $sourceApk = Join-Path $mobileDir "build\app\outputs\flutter-apk\app-release.apk"

            if (-not (Test-Path $sourceApk)) {
                throw "APK was not created for $tag."
            }

            $destinationApk = Join-Path $releaseDir "Prana-$tag.apk"

            Invoke-Step "Copying APK to $destinationApk" {
                Copy-Item -Force $sourceApk $destinationApk
            }

            Write-Host ""
            Write-Host "Built successfully: $destinationApk" -ForegroundColor Green
        }
        finally {
            Pop-Location
        }
    }
}
finally {
    Invoke-Step "Returning to branch $originalBranch" {
        git switch $originalBranch
    }

    Pop-Location
}

Write-Host ""
Write-Host "All requested versions are complete." -ForegroundColor Green
Write-Host "APK files are in: $releaseDir" -ForegroundColor Green
