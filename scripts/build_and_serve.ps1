# build_and_serve.ps1 - Loki Mode Fallback
Write-Host "🔄 Loki Mode: Starting Static Build Strategy..." -ForegroundColor Cyan

# 1. Cleanup
Stop-Process -Name "dart", "flutter" -ErrorAction SilentlyContinue -Force

# 2. Build Web
Write-Host "🏗️ Building Flutter Web (Release Mode)..." -ForegroundColor Yellow
Set-Location "c:\Users\tonne\SITES\mediare_mgcf\frontend"
flutter build web --release

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build Successful." -ForegroundColor Green
}
else {
    Write-Host "❌ Build Failed." -ForegroundColor Red
    exit 1
}

# 3. Serve via Python
Write-Host "🚀 Serving Static Files on Port 5005..." -ForegroundColor Cyan
Set-Location "build\web"
python -m http.server 5005 --bind 127.0.0.1
