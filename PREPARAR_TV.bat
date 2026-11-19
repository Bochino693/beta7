@echo off
setlocal
cd /d "%~dp0"
title Olho no Lance - Preparar a TV Box
rem Prepara a TV Box pelo adb do PC, uma vez por TV Box: o jogo vira a tela
rem inicial (ligou, abre o jogo). So precisa se o jogo nao conseguiu se
rem preparar sozinho (TV Box sem root). Veja o LEIA-ME_TV_BOX.txt.
rem   PREPARAR_TV.bat -Ip 192.168.0.50
rem   PREPARAR_TV.bat -DevolverTv      (a tela inicial volta a ser a da TV)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0PREPARAR_TV.ps1" %*
echo.
pause
