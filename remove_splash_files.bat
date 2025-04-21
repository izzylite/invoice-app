@echo off
REM Remove Android splash screen files
del /q android\app\src\main\res\drawable-hdpi\android12splash.png
del /q android\app\src\main\res\drawable-hdpi\splash.png
del /q android\app\src\main\res\drawable-mdpi\android12splash.png
del /q android\app\src\main\res\drawable-mdpi\splash.png
del /q android\app\src\main\res\drawable-night-hdpi\android12splash.png
del /q android\app\src\main\res\drawable-night-mdpi\android12splash.png
del /q android\app\src\main\res\drawable-night-xhdpi\android12splash.png
del /q android\app\src\main\res\drawable-night-xxhdpi\android12splash.png
del /q android\app\src\main\res\drawable-night-xxxhdpi\android12splash.png
del /q android\app\src\main\res\drawable-xhdpi\android12splash.png
del /q android\app\src\main\res\drawable-xhdpi\splash.png
del /q android\app\src\main\res\drawable-xxhdpi\android12splash.png
del /q android\app\src\main\res\drawable-xxhdpi\splash.png
del /q android\app\src\main\res\drawable-xxxhdpi\android12splash.png
del /q android\app\src\main\res\drawable-xxxhdpi\splash.png

REM Remove any background and branding images
del /q android\app\src\main\res\drawable\background.png
del /q android\app\src\main\res\drawable\branding.png
del /q android\app\src\main\res\drawable-night\background.png
del /q android\app\src\main\res\drawable-night\branding.png

echo Splash screen files removed
