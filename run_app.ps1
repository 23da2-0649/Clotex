# This script fixes the path and runs the app from the new location.
$env:Path = "C:\flutter\bin;" + $env:Path
Write-Host "Switching to new project location: E:\src\clotex" -ForegroundColor Cyan
Set-Location "E:\src\clotex"
flutter run
