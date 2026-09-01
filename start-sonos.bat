@echo off

SonosControl.exe 192.168.151.1 SCAN

SonosControl.exe RINCON_5CAAFD4D269401400 PLAY
SonosControl.exe RINCON_B8E93733EF4001400 PLAY

echo %DATE% %TIME% > "%~dp0sonos.started"

rem SchTasks /Create /F /RU SYSTEM /TN "Sonos Start" /TR "%~dp0start-sonos.bat" /SC DAILY /ST 09:00
rem SchTasks /Delete /F /TN "Sonos Start"