@echo off
cd C:\Users\izzy\Documents\Projects\invoice_app

REM Clean the project
flutter clean

REM Get dependencies
flutter pub get

REM Run the app on the device
flutter run -d 9c2d165a

@REM flutter build apk --release

@REM git checkout feature/contact-validation