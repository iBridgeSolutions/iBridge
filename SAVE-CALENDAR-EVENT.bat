@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0save-calendar-event.ps1" %*
