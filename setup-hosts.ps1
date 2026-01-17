# PowerShell script to add easyshop.devopsdock.site to hosts file
# Run as Administrator

$hostsPath = "C:\Windows\System32\drivers\etc\hosts"
$domain = "easyshop.devopsdock.site"
$ip = "127.0.0.1"
$entry = "$ip`t$domain"

# Check if entry already exists
$hostsContent = Get-Content $hostsPath
if ($hostsContent -notcontains $entry) {
    Write-Host "Adding $domain to hosts file..." -ForegroundColor Green
    Add-Content -Path $hostsPath -Value "`n$entry"
    Write-Host "✓ Successfully added $domain" -ForegroundColor Green
} else {
    Write-Host "✓ $domain already exists in hosts file" -ForegroundColor Yellow
}

Write-Host "`nHosts file updated. You can now access your app at:" -ForegroundColor Cyan
Write-Host "http://$domain" -ForegroundColor Cyan
