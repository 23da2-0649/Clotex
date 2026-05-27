# fix_paths.ps1
# This script moves the Flutter SDK and the project to paths without spaces to fix the "is not recognized" error.

# 1. Stop any remaining dart/flutter processes
Write-Host "Stopping background processes..." -ForegroundColor Cyan
taskkill /F /IM dart.exe /T 2>$null
taskkill /F /IM flutter.exe /T 2>$null

$oldSdk = "C:\Users\RS COMPUTERS\Downloads\flutter_windows_3.41.6-stable\flutter"
$newSdk = "C:\flutter"
$oldProject = "C:\Users\RS COMPUTERS\Downloads\clotex\clotex"
$newProject = "C:\src\clotex"

# 2. Move Flutter SDK
Write-Host "Moving Flutter SDK..." -ForegroundColor Cyan
if (Test-Path $oldSdk) {
    if (!(Test-Path $newSdk)) {
        Move-Item -Path $oldSdk -Destination $newSdk -Force
        Write-Host "SDK moved to $newSdk" -ForegroundColor Green
    } else {
        Write-Host "Destination $newSdk already exists. Skipping move." -ForegroundColor Yellow
    }
} else {
    Write-Host "SDK not found at $oldSdk (maybe it's already moved?)" -ForegroundColor Yellow
}

# 3. Move Project
Write-Host "Moving Project..." -ForegroundColor Cyan
if (Test-Path $oldProject) {
    if (!(Test-Path "C:\src")) { 
        New-Item -ItemType Directory -Path "C:\src" > $null
    }
    if (!(Test-Path $newProject)) {
        # Note: If this script is running from the project folder, this might fail.
        # But we will tell the user to run it and then it will handle what it can.
        try {
            Move-Item -Path $oldProject -Destination $newProject -Force
            Write-Host "Project moved to $newProject" -ForegroundColor Green
        } catch {
            Write-Host "Could not move project automatically (it might be in use). Please move it manually to $newProject." -ForegroundColor Red
        }
    } else {
        Write-Host "Destination $newProject already exists. Skipping move." -ForegroundColor Yellow
    }
} else {
    Write-Host "Project not found at $oldProject" -ForegroundColor Yellow
}

# 4. Update PATH variable
Write-Host "Updating PATH variable..." -ForegroundColor Cyan
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPathEntry = "$newSdk\bin"
$oldPathEntry = "$oldSdk\bin"

if ($userPath -notlike "*$newPathEntry*") {
    # Remove old entry if it exists and add new one at the beginning
    $cleanPath = $userPath.Replace($oldPathEntry, "").Replace(";;", ";").Trim(";")
    $updatedPath = "$newPathEntry;" + $cleanPath
    [Environment]::SetEnvironmentVariable("Path", $updatedPath, "User")
    Write-Host "PATH updated successfully." -ForegroundColor Green
    Write-Host "IMPORTANT: You MUST restart your terminal/IDE for changes to take effect." -ForegroundColor Yellow
} else {
    Write-Host "PATH already contains $newPathEntry." -ForegroundColor Green
}

Write-Host "`nFix complete! Next steps:" -ForegroundColor Cyan
Write-Host "1. Close this terminal."
Write-Host "2. Open a NEW terminal."
Write-Host "3. Go to $newProject"
Write-Host "4. Run 'flutter doctor' to verify."
