@echo off
TITLE Installing Apps, Features and PowerShell Modules...
echo Your computer might restart, please save your work before continuing!
echo After restart, you can restart this script to finish installation
pause
powershell -executionpolicy bypass -noprofile -file "%~dp0install_apps.ps1" -All
echo Logging is available in %Temp%\Install.log
echo Press any to update installed apps or CTRL-C to exit and then reboot your system manually
pause
winget upgrade --all --silent --force
echo. 
echo Done updating, press any key to quit and reboot your system manually
pause