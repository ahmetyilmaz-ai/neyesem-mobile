@echo off
title NeYesem - Telefon Modu
cd /d "%~dp0"
echo ================================================================
echo  NeYesem - TELEFON MODU (Chrome ACMAZ, aga yayinlar)
echo  ONCE: AI (:8000) ve backend (:3000) ACIK olmali.
echo  Telefon ile bilgisayar AYNI Wi-Fi de olmali.
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ip=(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up'} | Select-Object -First 1).IPv4Address.IPAddress; if (-not $ip) { $ip=(Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -notlike '127.*' -and $_.IPAddress -notlike '169.254.*'} | Select-Object -First 1).IPAddress }; Write-Host ''; Write-Host ('   >>> TELEFONDA SU ADRESI AC:  http://' + $ip + ':8080') -ForegroundColor Green; Write-Host '   (Ilk acista Windows Guvenlik Duvari sorarsa: ERISIME IZIN VER)' -ForegroundColor Yellow; Write-Host ''"
echo Derleniyor ve yayinlaniyor (~1 dk)... Bu pencereyi KAPATMA.
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 8080
pause
