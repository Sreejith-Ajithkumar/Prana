param(
    [string]$RepoRoot = "D:\Development\Projects\Prana",
    [string]$Tag,
    [switch]$BuildAll,
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$mobileRelativePath = "apps\mobile"
$distDir = Join-Path $RepoRoot "dist"
$tempRoot = Join-Path $env:TEMP "prana_release_builds"

function Invoke-Step {
    param(
        [string]$Message,
        [scriptblock]$Action
    )

    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
    & $Action
}

if (-not (Test-Path (Join-Path $RepoRoot ".git"))) {
    throw "No Git repository found at: $RepoRoot"
}

Invoke-Step "Checking repository state" {
    Push-Location $RepoRoot
    try {
        $status = git status --porcelain
        if ($status) {
            throw "Your working tree has uncommitted changes. Commit or stash them before building releases."
        }
    }
    finally {
        Pop-Location
    }
}

Invoke-Step "Creating output folders" {
    New-Item -ItemType Directory -Force -Path $distDir | Out-Null
    New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null
}

Push-Location $RepoRoot

try {
    $tags = @()

    if ($BuildAll) {
        $tags = git tag --sort=version:refname
    }
    elseif ($Tag) {
        $tags = @($Tag)
    }
    else {
        $latestTag = git tag --sort=-version:refname | Select-Object -First 1

        if (-not $latestTag) {
            throw "No Git tags were found."
        }

        $tags = @($latestTag)
    }

    foreach ($currentTag in $tags) {
        if (-not (git tag --list $currentTag)) {
            Write-Warning "Tag $currentTag does not exist. Skipping."
            continue
        }

        $destinationApk = Join-Path $distDir "Prana-$currentTag.apk"

        if ((Test-Path $destinationApk) -and -not $Force) {
            Write-Host ""
            Write-Host "Skipping $currentTag because this APK already exists:" -ForegroundColor Yellow
            Write-Host $destinationApk
            continue
        }

        $worktreeDir = Join-Path $tempRoot $currentTag

        if (Test-Path $worktreeDir) {
            Remove-Item -Recurse -Force $worktreeDir
        }

        try {
            Invoke-Step "Creating temporary worktree for $currentTag" {
                git worktree add --detach $worktreeDir $currentTag
            }

            $mobileDir = Join-Path $worktreeDir $mobileRelativePath

            if (-not (Test-Path (Join-Path $mobileDir "pubspec.yaml"))) {
                throw "Flutter project not found for $currentTag at $mobileDir"
            }

            Push-Location $mobileDir

            try {
                Invoke-Step "Getting dependencies for $currentTag" {
                    flutter pub get
                }

                Invoke-Step "Analyzing $currentTag" {
                    flutter analyze
                }

                Invoke-Step "Running tests for $currentTag" {
                    flutter test
                }

                Invoke-Step "Building release APK for $currentTag" {
                    flutter build apk --release
                }

                $sourceApk = Join-Path $mobileDir "build\app\outputs\flutter-apk\app-release.apk"

                if (-not (Test-Path $sourceApk)) {
                    throw "APK was not created for $currentTag."
                }

                Invoke-Step "Copying APK to dist" {
                    Copy-Item -Force $sourceApk $destinationApk
                }

                $hash = Get-FileHash -Algorithm SHA256 $destinationApk
                $hashFile = Join-Path $distDir "Prana-$currentTag.sha256.txt"

                "$($hash.Hash)  Prana-$currentTag.apk" |
                    Set-Content -Encoding UTF8 $hashFile

                Write-Host ""
                Write-Host "Built successfully:" -ForegroundColor Green
                Write-Host $destinationApk
                Write-Host $hashFile
            }
            finally {
                Pop-Location
            }
        }
        finally {
            if (Test-Path $worktreeDir) {
                Invoke-Step "Removing temporary worktree for $currentTag" {
                    git worktree remove --force $worktreeDir
                }
            }

            git worktree prune
        }
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "Release build completed." -ForegroundColor Green
Write-Host "Output folder: $distDir" -ForegroundColor Green
