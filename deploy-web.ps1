# ==============================================================================
# PCM WAYANAD - Custom Web Portal Production Deploy Script
# ==============================================================================

Write-Host ">>> [1/2] Preparing Custom Web Portal Deployment..." -ForegroundColor Cyan
$deployDir = Join-Path $env:TEMP "pcm_portal_deploy"
if (Test-Path $deployDir) {
    Remove-Item -Path $deployDir -Recurse -Force
}
New-Item -ItemType Directory -Path $deployDir -Force | Out-Null

# Copy your custom web portal files from portal_web folder
Copy-Item -Path "portal_web\*" -Destination $deployDir -Recurse -Force

# Copy Vercel Configuration & API if they exist
if (Test-Path "api") {
    Copy-Item -Path "api" -Destination (Join-Path $deployDir "api") -Recurse -Force
}
if (Test-Path "vercel.json") {
    Copy-Item -Path "vercel.json" -Destination (Join-Path $deployDir "vercel.json") -Force
}

Write-Host ">>> [2/2] Deploying Custom Web Portal to Vercel Production..." -ForegroundColor Cyan
vercel deploy $deployDir --prod --yes

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Vercel deployment failed!" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host ">>> Successfully Deployed Your Custom Web Portal to Production!" -ForegroundColor Green
Write-Host "Live URL: https://pcm-wayanad-portal.vercel.app" -ForegroundColor Yellow
