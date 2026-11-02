@echo off
setlocal EnableExtensions
REM ==========================================================================
REM  rodar_coleta_v1.4.2.cmd - lancador da coleta v1.4.2 (pericia, SOMENTE LEITURA)
REM  Uso: clicar com o botao direito > "Executar como administrador".
REM  Tudo e gravado no proprio pendrive (pasta coleta\ ao lado deste arquivo).
REM  v1.4.2: script ASCII+UTF-8 BOM (PS 5.1); ID obrigatorio EQ##.
REM  v1.4: hives offline, fallback Defender, hash/assinatura de suspeitos,
REM        menos FP, IDs EQ##, -Perfil opcional (perfis\exemplo_generico.psd1).
REM ==========================================================================
set "KIT=%~dp0"
set "SCRIPT=%KIT%coleta_inventario_software_v1.4.2.ps1"
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
set /p "EQ=Identificador do equipamento (ex.: EQ01, ou so o numero): "

REM Normaliza/valida EQ## (aceita 1 / EQ1 / EQ01). Rejeita texto livre.
set "EQOK="
for /f "usebackq delims=" %%A in (`"%PSEXE%" -NoLogo -NoProfile -NonInteractive -Command "$e='%EQ%'; if ($e -match '^(?i)EQ[_-]?0*(\d{1,3})$') { 'EQ{0:D2}' -f [int]$Matches[1] } elseif ($e -match '^(\d{1,3})$') { 'EQ{0:D2}' -f [int]$Matches[1] }"`) do set "EQOK=%%A"

if "%EQOK%"=="" (
  echo.
  echo ERRO: identificador invalido "%EQ%". Use EQ01, EQ02 ou so o numero (ex.: 1).
  echo Codigo de saida: 6
  pause
  exit /b 6
)
set "EQ=%EQOK%"
echo Usando identificador: %EQ%

REM Hives offline: DESLIGADO por padrao (v1.4.2). Para ligar: set KIT_HIVES=1 antes de rodar.
set "HIVESARG="
if /I "%KIT_HIVES%"=="1" set "HIVESARG=-LerHivesOffline"

if exist "%PERFIL%" (
  "%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "%EQ%" -CapturaTela -Perfil "%PERFIL%" %HIVESARG%
) else (
  "%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "%EQ%" -CapturaTela %HIVESARG%
)
set "RC=%ERRORLEVEL%"
echo.
echo Codigo de saida: %RC%  (0 = ok; 2 = destino recusado; 3/4 = erro de pasta; 5 = perfil invalido; 6 = ID invalido)
echo Fotografe a tela com o RESUMO e o hash do manifesto antes de fechar.
echo Checklist: capturas manuais de Programas e Recursos / Sobre (ver KIT_PENDRIVE_v1.4.2.md).
pause
endlocal
