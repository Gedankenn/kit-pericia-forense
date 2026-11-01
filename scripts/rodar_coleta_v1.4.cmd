@echo off
setlocal EnableExtensions
REM ==========================================================================
REM  rodar_coleta_v1.4.cmd - lancador da coleta v1.4 (pericia, SOMENTE LEITURA)
REM  Uso: clicar com o botao direito > "Executar como administrador".
REM  Tudo e gravado no proprio pendrive (pasta coleta\ ao lado deste arquivo).
REM  v1.4: hives offline, fallback Defender, hash/assinatura de suspeitos,
REM        menos FP, IDs EQ##, -Perfil opcional (perfis\exemplo_generico.psd1).
REM ==========================================================================
set "KIT=%~dp0"
set "SCRIPT=%KIT%coleta_inventario_software_v1.4.ps1"
set "PERFIL=%KIT%perfis\exemplo_generico.psd1"

set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PSEXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

set "PSModuleAnalysisCachePath=NUL"
set "PSDisableModuleAnalysisCacheCleanup=1"

if not exist "%SCRIPT%" (
  echo ERRO: nao encontrei "%SCRIPT%"
  pause
  exit /b 1
)

net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  ATENCAO: NAO esta como administrador. Prefetch, Defender, hives offline e
  echo  perfis de outros usuarios serao pulados. Feche e use "Executar como
  echo  administrador" ou pressione uma tecla para seguir assim mesmo.
  pause
)

echo.
set "EQ="
set /p "EQ=Identificador do equipamento (ex.: EQ01, igual a etiqueta/foto): "
if "%EQ%"=="" set "EQ=EQ_SEM_ID"

if exist "%PERFIL%" (
  "%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "%EQ%" -CapturaTela -Perfil "%PERFIL%"
) else (
  "%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "%EQ%" -CapturaTela
)
set "RC=%ERRORLEVEL%"
echo.
echo Codigo de saida: %RC%  (0 = ok; 2 = destino recusado; 3/4 = erro de pasta; 5 = perfil invalido)
echo Fotografe a tela com o RESUMO e o hash do manifesto antes de fechar.
echo Checklist: capturas manuais de Programas e Recursos / Sobre (ver KIT_PENDRIVE_v1.4.md).
pause
endlocal
