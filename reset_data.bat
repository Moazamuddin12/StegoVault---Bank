@echo off
rem Clears ALL depositor data (users.dat, requests.dat, Vault_Images\*.bmp) so only
rem accounts you create from now on exist. cashier.dat (your cashier login) is kept.
echo This deletes every depositor account and vault image in this folder.
choice /m "Continue"
if errorlevel 2 goto :eof
if exist users.dat del /q users.dat
if exist requests.dat del /q requests.dat
if exist Vault_Images\*.bmp del /q Vault_Images\*.bmp
echo Done. Start main.exe and register new depositors.
