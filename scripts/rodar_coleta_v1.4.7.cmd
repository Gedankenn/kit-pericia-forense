@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM ==========================================================================
REM  rodar_coleta_v1.4.7.cmd - lancador da coleta v1.4.7 (pericia, SOMENTE LEITURA)
REM  Uso: clicar com o botao direito > "Executar como administrador".
REM  Tudo e gravado no proprio pendrive (pasta coleta\ ao lado deste arquivo).
REM  v1.4.7: menos FP servicos; copia hive sessao ativa; filtra SEM_EVENTOS/Public;
REM          herda EQ## batch puro (aceita eq01); hives offline ON; copia suspeitos >500MB.
REM  v1.4.5: EQ## validado em batch puro (sem PowerShell inline); aceita eq01.
REM ==========================================================================
set "KIT=%~dp0"
set "SCRIPT=%KIT%coleta_inventario_software_v1.4.7.ps1"
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

REM ---------------------------------------------------------------------------
REM Normaliza/valida EQ## em batch puro (sem powershell inline).
REM Aceita: 1, 01, EQ1, EQ01, eq01, EQ_01, EQ-1. Rejeita texto livre.
REM ---------------------------------------------------------------------------
:ask_eq
set "EQOK="
set "RAW=!EQ!"
if not defined RAW goto eq_bad
REM trim leading spaces + CR/trailing spaces (echo/pipe pode deixar espaco no fim)
for /f "tokens=* delims= " %%A in ("!RAW!") do set "RAW=%%A"
if not defined RAW goto eq_bad
REM remove trailing CR and spaces
for /f "tokens=* delims= " %%A in ("!RAW!") do set "RAW=%%A"
:trim_trail
if "!RAW!"=="" goto eq_bad
if not "!RAW:~-1!"==" " if not "!RAW:~-1!"=="	" goto trim_done
set "RAW=!RAW:~0,-1!"
goto trim_trail
:trim_done
if not defined RAW goto eq_bad

set "NUM=!RAW!"
if /I "!NUM:~0,3!"=="EQ_" (
  set "NUM=!NUM:~3!"
  goto eq_have_num
)
if /I "!NUM:~0,3!"=="EQ-" (
  set "NUM=!NUM:~3!"
  goto eq_have_num
)
if /I "!NUM:~0,2!"=="EQ" (
  set "NUM=!NUM:~2!"
  goto eq_have_num
)
:eq_have_num
if not defined NUM goto eq_bad
REM only digits
echo(!NUM!| findstr /R /B /C:"^[0-9][0-9]*$" >nul
if errorlevel 1 goto eq_bad
REM at most 3 digits
if not "!NUM:~3!"=="" goto eq_bad
REM decimal value without octal trap (set /a treats 08 as octal)
set "PAD=000!NUM!"
set "PAD=!PAD:~-3!"
set /a N=1!PAD! - 1000
if !N! LSS 1 goto eq_bad
if !N! GTR 999 goto eq_bad
if !N! LSS 10 (
  set "EQOK=EQ0!N!"
) else (
  set "EQOK=EQ!N!"
)
goto eq_ok

:eq_bad
echo.
echo ERRO: identificador invalido "!EQ!". Use EQ01, EQ02 ou so o numero (ex.: 1).
set "EQ="
set /p "EQ=Identificador do equipamento (ex.: EQ01, ou so o numero): "
if not defined EQ (
  echo Codigo de saida: 6
  pause
  exit /b 6
)
goto ask_eq

:eq_ok
set "EQ=!EQOK!"
echo Usando identificador: !EQ!

set "OP="
set /p "OP=Nome do operador/perito (Enter=NAO_INFORMADO): "
if not defined OP set "OP=NAO_INFORMADO"
set "KIT_OPERADOR=!OP!"

REM Hives offline: LIGADO por padrao (v1.4.4+). Para desligar: set KIT_HIVES=0
set "HIVESARG="
if /I "%KIT_HIVES%"=="0" set "HIVESARG=-SemHivesOffline"

REM Resposta automatica a arquivos >500MB (teste): set KIT_COPIA_GRANDE=S ou N
set "GRANDEARG="
if /I "%KIT_COPIA_GRANDE%"=="S" set "GRANDEARG=-RespostaCopiaGrande S"
if /I "%KIT_COPIA_GRANDE%"=="N" set "GRANDEARG=-RespostaCopiaGrande N"

if exist "%PERFIL%" (
  "%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "!EQ!" -Operador "!OP!" -CapturaTela -Perfil "%PERFIL%" %HIVESARG% %GRANDEARG%
) else (
  "%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "!EQ!" -Operador "!OP!" -CapturaTela %HIVESARG% %GRANDEARG%
)
set "RC=%ERRORLEVEL%"
echo.
echo Codigo de saida: %RC%  (0 = ok; 2 = destino recusado; 3/4 = erro de pasta; 5 = perfil; 6 = ID invalido)
echo Fotografe a tela com o RESUMO e o hash do manifesto antes de fechar.
echo Checklist: capturas manuais de Programas e Recursos / Sobre (ver KIT_PENDRIVE_v1.4.7.md)..
pause
endlocal
