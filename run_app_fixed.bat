@echo off
cd %~dp0
echo Cleaning project...
flutter clean
echo Getting dependencies...
flutter pub get
echo Running app on device...
flutter run -d 9c2d165a
