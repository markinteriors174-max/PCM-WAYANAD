$srcPath = "lib\screens\home\pcm_ai_designer_screen.dart"
$tmpPath = "lib\screens\home\pcm_ai_designer_screen_tmp.dart"

$lines = Get-Content $srcPath -Encoding UTF8
# Keep only up to and including line 1567 (index 1566)
$trimmed = $lines[0..1566]

# Write to a temp file first
Set-Content -Path $tmpPath -Value $trimmed -Encoding UTF8

Write-Host "Temp file written with $($trimmed.Count) lines."
Write-Host "Now replacing original..."

# Copy temp over original
Copy-Item -Path $tmpPath -Destination $srcPath -Force
Remove-Item -Path $tmpPath

Write-Host "Done! Final line count: $((Get-Content $srcPath).Count)"
