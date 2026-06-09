@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ================================================
echo   NeYesem Mobil Uygulama (Chrome) baslatiliyor
echo   ONCE AI backend acik olmali (SUNUM_1).
echo   Ilk derleme ~1 dakika surer, Chrome otomatik acilir.
echo   Bu pencereyi KAPATMA.
echo ================================================
flutter run -d chrome
echo.
echo Uygulama durdu. Bir tusa bas...
pause >nul
