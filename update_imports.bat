@echo off
echo Updating imports from invoice_app to elakkaitrack...

for /r lib %%f in (*.dart) do (
    echo Processing %%f
    powershell -Command "(Get-Content '%%f') -replace 'package:invoice_app/', 'package:elakkaitrack/' | Set-Content '%%f'"
)

echo Done!
