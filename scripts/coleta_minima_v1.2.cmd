@echo off
setlocal EnableExtensions EnableDelayedExpansion
REM ==========================================================================
REM  coleta_minima_v1.2.cmd - PLANO B (usar so se o PowerShell estiver bloqueado ou
REM  em modo restrito). Somente comandos nativos do Windows, SOMENTE LEITURA na
REM  maquina; tudo vai para o pendrive. Menos completo que o script v1.1.
REM  v1.2: C:\Users e listado UMA vez com "robocopy /L /XJ" (so lista, nao copia;
REM  nao entra em juncoes/links simbolicos, entao nao entra em laco mesmo com
REM  SeBackupPrivilege ativo). O "dir /s" das v1.0/v1.1 podia entrar em laco.
REM ==========================================================================
set "KIT=%~dp0"
if /i "%~d0"=="%SystemDrive%" ( echo ABORTADO: o kit esta no disco do sistema. & pause & exit /b 2 )
set "EQ="
set /p "EQ=Identificador do equipamento (ex.: EQ01): "
REM v1.2: tira espacos no inicio e no fim do identificador.
for /f "tokens=* delims= " %%a in ("%EQ%") do set "EQ=%%a"
:trimEQ
if defined EQ if "%EQ:~-1%"==" " ( set "EQ=%EQ:~0,-1%" & goto trimEQ )
if "%EQ%"=="" set "EQ=EQ_SEM_ID"
for /f "tokens=1-3 delims=/:. " %%a in ("%TIME: =0%") do set "HH=%%a%%b%%c"
set "OUT=%KIT%coleta\%EQ%_%COMPUTERNAME%_minima_%RANDOM%%HH%"
mkdir "%OUT%" || ( echo nao criou "%OUT%" & pause & exit /b 4 )
echo Inicio: %DATE% %TIME% > "%OUT%\00_execucao.txt"
whoami /all >> "%OUT%\00_execucao.txt" 2>&1
systeminfo > "%OUT%\01_systeminfo.txt" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /reg:64 > "%OUT%\03_uninstall_64.txt" 2>&1
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" /s /reg:32 > "%OUT%\03_uninstall_32.txt" 2>&1
reg query "HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall" /s > "%OUT%\03_uninstall_hkcu.txt" 2>&1
for %%K in (Autodesk Corel Alludo "FLEXlm License Manager") do (
  reg query "HKLM\SOFTWARE\%%~K" /s /reg:64 > "%OUT%\05_reg_HKLM64_%%~K.txt" 2>&1
  reg query "HKLM\SOFTWARE\%%~K" /s /reg:32 > "%OUT%\05_reg_HKLM32_%%~K.txt" 2>&1
  reg query "HKCU\Software\%%~K" /s > "%OUT%\05_reg_HKCU_%%~K.txt" 2>&1
)
copy /b "%SystemRoot%\System32\drivers\etc\hosts" "%OUT%\08_hosts_copia.txt" >nul 2>&1
netsh advfirewall firewall show rule name=all verbose > "%OUT%\09_firewall_netsh.txt" 2>&1
sc query type= service state= all > "%OUT%\06_servicos.txt" 2>&1
tasklist /v > "%OUT%\06b_processos.txt" 2>&1
wevtutil qe Application /q:"*[System[Provider[@Name='MsiInstaller'] and (EventID=1033 or EventID=1034 or EventID=11707 or EventID=11724)]]" /c:3000 /rd:true /f:text > "%OUT%\12_eventos_msi.txt" 2>&1
dir /a /o:-d "%SystemRoot%\Prefetch" > "%OUT%\13_prefetch.txt" 2>&1
dir /s /a:-d /t:w "%ProgramData%\Autodesk\CLM" "%ProgramData%\FLEXnet" "%ProgramData%\Autodesk\AdskLicensingService" "%ProgramData%\Corel" > "%OUT%\07_arquivos_licenca.txt" 2>&1
echo Listando arquivos em %SystemDrive%\Users (pode demorar)...
REM v1.2: uma unica listagem de C:\Users com robocopy em modo /L (somente lista, nada e copiado;
REM o destino nao e criado). /XJ = nao segue juncoes nem links simbolicos (evita o laco
REM "All Users\Application Data\Application Data\..."); /R:0 /W:0 = sem novas tentativas.
REM Cada arquivo aparece uma vez; os filtros abaixo so separam por nome.
robocopy "%SystemDrive%\Users" "%OUT%\_robocopy_L_destino_nao_criado" *.* /L /S /XJ /FP /NS /NC /NDL /NJH /R:0 /W:0 > "%OUT%\_listagem_users.tmp" 2>&1
echo robocopy /L codigo de saida: %ERRORLEVEL% (0-7 = ok; 8 ou mais = pastas nao lidas, ver 10b) >> "%OUT%\00_execucao.txt"
setlocal DisableDelayedExpansion
(for /f "usebackq tokens=*" %%L in ("%OUT%\_listagem_users.tmp") do echo %%L) > "%OUT%\_listagem_users2.tmp"
endlocal
findstr /i /r /c:"^[A-Z]:\\.*\.dwg$" /c:"^[A-Z]:\\.*\.dxf$" /c:"^[A-Z]:\\.*\.dwt$" /c:"^[A-Z]:\\.*\.rvt$" /c:"^[A-Z]:\\.*\.rfa$" /c:"^[A-Z]:\\.*\.ipt$" /c:"^[A-Z]:\\.*\.iam$" /c:"^[A-Z]:\\.*\.cdr$" /c:"^[A-Z]:\\.*\.cdt$" /c:"^[A-Z]:\\.*\.cmx$" "%OUT%\_listagem_users2.tmp" > "%OUT%\10_arquivos_projeto_usuarios.txt"
REM 10b: o que a listagem NAO viu. O robocopy so detalha erro da pasta raiz; pastas internas sem
REM acesso aparecem apenas na coluna FAILED da linha "Dirs" do resumo. Por isso o 10b traz o resumo,
REM eventuais linhas de erro e as pastas de perfil sem acesso.
(
  echo Resumo da listagem robocopy /L de %SystemDrive%\Users. Modo so-lista: "Copied" = listado; nada foi copiado.
  echo Coluna FAILED da linha Dirs = pastas que nao puderam ser lidas; o conteudo delas NAO esta em 10/11.
  findstr /i /r /v /c:"^[A-Z]:\\." "%OUT%\_listagem_users2.tmp"
  echo.
  echo Pastas de perfil sem acesso para este usuario:
) > "%OUT%\10b_listagem_resumo.txt"
setlocal DisableDelayedExpansion
(for /d %%P in ("%SystemDrive%\Users\*") do dir /a "%%P" >nul 2>&1 || echo   SEM ACESSO: %%P) >> "%OUT%\10b_listagem_resumo.txt"
endlocal
REM Indicios por nome. Exclusao: ssh-keygen*.exe (OpenSSH, legitimo) casaria com "keygen"; vai para 11b_indicios_excluidos.txt, nao some.
findstr /i /r /c:"^[A-Z]:\\.*keygen[^\\]*$" /c:"^[A-Z]:\\.*crack[^\\]*$" /c:"^[A-Z]:\\.*xf-adsk[^\\]*$" /c:"^[A-Z]:\\.*x-force[^\\]*$" /c:"^[A-Z]:\\.*\.nfo$" "%OUT%\_listagem_users2.tmp" > "%OUT%\11_tmp_indicios.tmp"
findstr /i /v /r /c:"\\ssh-keygen[^\\]*$" "%OUT%\11_tmp_indicios.tmp" > "%OUT%\11_indicios_nomes.txt"
findstr /i /r /c:"\\ssh-keygen[^\\]*$" "%OUT%\11_tmp_indicios.tmp" > "%OUT%\11b_indicios_excluidos.txt"
del "%OUT%\11_tmp_indicios.tmp" "%OUT%\_listagem_users.tmp" "%OUT%\_listagem_users2.tmp" >nul 2>&1
echo Fim: %DATE% %TIME% >> "%OUT%\00_execucao.txt"
echo Gerando manifesto SHA-256...
REM v1.2: certutil falha em arquivo vazio (0 bytes) e o arquivo sumia do manifesto; agora entra com o
REM SHA-256 padrao de conteudo vazio (e3b0c442...b855).
(for %%F in ("%OUT%\*.txt") do (
  if "%%~zF"=="0" (echo e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855  %%~nxF) else (
  for /f "skip=1 delims=" %%H in ('certutil -hashfile "%%F" SHA256 ^| findstr /v /c:"CertUtil"') do echo %%H  %%~nxF)
)) > "%OUT%\MANIFESTO_SHA256.lst"
certutil -hashfile "%OUT%\MANIFESTO_SHA256.lst" SHA256
echo.
echo Pasta: %OUT%
echo Fotografe o hash acima.
pause
endlocal
