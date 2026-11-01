@echo off
REM capturar_tela.cmd [EQ01] [descricao] - captura a tela para o pendrive depois de 3 segundos
set "PSModuleAnalysisCachePath=NUL"
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PSEXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
set "EQ=%~1"
if "%EQ%"=="" set /p "EQ=Equipamento (ex.: EQ01): "
set "DS=%~2"
if "%DS%"=="" set /p "DS=Descricao curta (ex.: apps_fabricanteA): "
"%PSEXE%" -NoLogo -NoProfile -ExecutionPolicy Bypass -File "%~dp0capturar_tela.ps1" -Equip "%EQ%" -Descricao "%DS%"
pause
