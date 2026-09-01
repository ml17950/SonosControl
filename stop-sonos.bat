@echo off

SonosControl.exe RINCON_5CAAFD4D269401400 PAUSE
SonosControl.exe RINCON_B8E93733EF4001400 PAUSE

echo %DATE% %TIME% > "%~dp0sonos.stopped"

rem SchTasks /Create /F /RU SYSTEM /TN "Sonos Stop" /TR "%~dp0stop-sonos.bat" /SC DAILY /ST 18:00
rem SchTasks /Delete /F /TN "Sonos Stop"
