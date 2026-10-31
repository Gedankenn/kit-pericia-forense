@echo off
setlocal EnableExtensions
REM ==========================================================================
REM  rodar_coleta_v1.3.cmd - lancador da coleta v1.3 (pericia, SOMENTE LEITURA)
REM  Uso: clicar com o botao direito > "Executar como administrador".
REM  Tudo e gravado no proprio pendrive (pasta coleta\ ao lado deste arquivo).
REM  v1.3: ao final imprime e grava 00_RESUMO.txt (veredito/indicadores/sugestoes).
REM ==========================================================================
set "KIT=%~dp0"
set "SCRIPT=%KIT%coleta_inventario_software_v1.3.ps1"

REM PowerShell 64 bits mesmo se este .cmd for aberto por um processo 32 bits
set "PSEXE=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "PSEXE=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"

REM Impede o PowerShell de gravar o cache de modulos no perfil do usuario da maquina vistoriada
set "PSModuleAnalysisCachePath=NUL"
set "PSDisableModuleAnalysisCacheCleanup=1"

if not exist "%SCRIPT%" (
  echo ERRO: nao encontrei "%SCRIPT%"
  pause
  exit /b 1
)

REM Aviso se nao estiver como administrador (a coleta roda, mas fica parcial)
net session >nul 2>&1
if errorlevel 1 (
  echo.
  echo  ATENCAO: NAO esta como administrador. Prefetch, Defender e perfis de
  echo  outros usuarios serao pulados. Feche e use "Executar como administrador"
  echo  ou pressione uma tecla para seguir assim mesmo.
  pause
)

echo.
set "EQ="
set /p "EQ=Identificador do equipamento (ex.: EQ01, igual a etiqueta/foto): "
if "%EQ%"=="" set "EQ=EQ_SEM_ID"

"%PSEXE%" -NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -File "%SCRIPT%" -Equip "%EQ%" -CapturaTela
set "RC=%ERRORLEVEL%"
echo.
echo Codigo de saida: %RC%  (0 = ok; 2 = destino recusado; 3/4 = erro de pasta)
echo Fotografe a tela com o RESUMO e o hash do manifesto antes de fechar.
pause
endlocal
