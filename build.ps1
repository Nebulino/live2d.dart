Write-Host "Getting dependencies."
flutter pub get
Write-Host "Running static analysis."
flutter analyze
Write-Host "Running tests."
flutter test
Write-Host "Finished building."
