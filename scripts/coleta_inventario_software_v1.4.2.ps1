<#
  coleta_inventario_software_v1.4.2.ps1 - Pericia judicial (vistoria de software)
  Perito: Fabio Slika Stella - CREA/PR PR-224755/D
  Versao 1.4 (01/11/2026) - baseada na v1.3 (originais preservados ao lado)
  v1.4.2: -LerHivesOffline DESLIGADO por padrao (opt-in; use -LerHivesOffline para carregar
        copia de NTUSER.DAT no pendrive). Reduz risco de reg load no hive em uso.
  v1.4.1: script 100% ASCII + UTF-8 BOM (PS 5.1/cp1252 nao quebra mais em em-dash);
        ID do equipamento obrigatorio no formato EQ## (rejeita texto livre; aceita 1/EQ1).
  v1.4: hives offline via copia no pendrive (-LerHivesOffline); fallback Defender via registro;
        hash+Authenticode de suspeitos + -CopiarSuspeitos; menos FP crack/keygen (11f_);
        IDs EQ## padronizados; -Perfil (psd1/json) com listas externas; checklist capturas manuais.
  v1.3: resumo minimo GENERICO (00_RESUMO.txt) impresso na tela e gravado ANTES do manifesto;
        irregularidades/pirataria de QUALQUER fabricante; -Destacar (opcional) so destaca no topo.
  v1.2: nomes que casam com -ExclusaoIndicios (padrao ^SSH-KEYGEN, ferramenta legitima do OpenSSH)
        nao contam como indicio de crack; vao para 11e_indicios_excluidos.csv (nada fica oculto).

  O QUE FAZ
    Coleta SOMENTE LEITURA: nao instala, nao altera, nao apaga e nao abre arquivos de
    trabalho da maquina vistoriada. Todos os resultados vao para a pasta do pendrive
    (por padrao <pasta do script>\coleta). Ao final gera manifesto SHA-256 de todos os
    arquivos produzidos.

  COMO USAR (recomendado: pelo lancador rodar_coleta_v1.4.2.cmd, clicando com o botao direito
  em "Executar como administrador"). Linha de comando equivalente:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File E:\coleta_inventario_software_v1.4.2.ps1 -Equip EQ01 -CapturaTela

  PARAMETROS PRINCIPAIS
    -Equip                 identificador EQ## (aceita 1/EQ1/EQ01; rejeita texto livre; codigo 6 se invalido)
    -Destino               pasta de saida (padrao: <pasta do script>\coleta). Recusa o disco do sistema.
    -Perfil                arquivo .psd1/.json com Fabricantes, indicios, pastas etc. (opcional)
    -CapturaTela           salva PNG da tela no inicio da coleta
    -HashArquivosProjeto   calcula SHA-256 dos arquivos .dwg/.cdr/... encontrados (DESLIGADO por padrao)
    -CopiarLicencas        copia para o pendrive os arquivos de licenca pequenos (<= 5 MB)
    -CopiarSuspeitos       copia binarios suspeitos (NotSigned/HashMismatch) para o pendrive
    -LerHivesOffline       (padrao: DESLIGADO; opt-in) copia NTUSER.DAT para o pendrive e carrega A COPIA
    -ResolverAtalhos       le o destino dos atalhos .lnk da pasta Recent
    -MRUCompleto           lista TODOS os itens recentes (padrao: so os relacionados)
    -Destacar              (opcional) fabricantes a DESTACAR no topo do resumo. Nunca oculta o resto.
    -ModoTeste             permite gravar no disco do sistema (SO PARA TESTE NO PC DO PERITO)

  OBS. TECNICAS
 - Nao usa Win32_Product (dispara verificacao/reparo MSI). Inventario vem do registro (Uninstall),
      lido via .NET em modo somente leitura, nas visoes 64 e 32 bits (WOW6432Node) e em HKEY_USERS.
 - Hives de usuarios deslogados (v1.4+): so se -LerHivesOffline (opt-in desde v1.4.2); copia NTUSER.DAT para o pendrive e
      faz reg load SOMENTE da copia (HKU\PericiaTmp_*). O original no disco vistoriado nao e escrito.
 - Nao compila codigo (sem Add-Type -TypeDefinition, que gravaria em %TEMP%).
 - Varreduras de disco sao limitadas por profundidade, tempo e quantidade, e nao seguem
      junctions/links simbolicos.
 - Inevitavel: o proprio Windows registra a conexao do pendrive e a execucao do PowerShell
      (Prefetch, logs de eventos, registro USBSTOR). Isso deve constar do laudo como efeito da diligencia.
#>
[CmdletBinding()]
param(
  [string]$Equip = '',
  [string]$Destino = '',
  [string]$Perfil = '',
  [string]$Fabricantes = 'Autodesk|AutoCAD|Inventor|Revit|3ds ?Max|\bMaya\b|Civil ?3D|Navisworks|Fusion ?360|Corel|PHOTO-PAINT|PaintShop|VideoStudio|Pinnacle Studio|WinZip|Parallels|MindManager|Alludo|Roxio|WinDVD|Adobe|Photoshop|Illustrator',
  [string]$IndiciosFortes = '(key[-_ .]?gen|\bkg[-_ ]|crack|x[-_ ]?force|xf-?adsk|\bxf-[a-z]{2,8}|amtlib|amtemu|solidsquad|\bssq\b|ativador|crackead|universal[-_ ]?patch|(adsk|autodesk|autocad|acad).*patch|corel.*(patch|fix|\bkg\b)|kmspico|kmsauto|\bkms\b|kms.?activator|microsoft.?toolkit|re-?loader|aesofthome|midas.?office|office.?kms|adobe.*(crack|keygen|patch|amtlib)|\.torrent$)',
  [string]$ExclusaoIndicios = '^SSH-KEYGEN',
  [string]$IndiciosFracos = '(\bpatch(er)?\b|\bloader\b|activator|\bserials?\b|\.nfo$|portable|repack|license[-_ ]?(fix|bypass|gen)|como[-_ ]?ativar|how[-_ ]?to[-_ ]?(activate|crack))',
  [string]$Extensoes = '.dwg,.dwt,.dxf,.dws,.dwf,.dwfx,.dwl,.dwl2,.sv$,.bak,.rvt,.rfa,.rte,.rft,.ifc,.nwd,.nwc,.nwf,.ipt,.iam,.idw,.ipn,.ide,.max,.3ds,.fbx,.ma,.mb,.f3d,.cdr,.cdt,.cmx,.cpt,.des,.csl,.ai,.eps,.prt,.dcu,.dfm,.dpk',
  [int]$DiasEventos = 1095,
  [int]$MaxEventos = 5000,
  [int]$SegundosPorRaiz = 60,
  [int]$SegundosTotalArquivos = 240,
  [int]$SegundosFabricante = 60,
  [int]$SegundosAssinaturas = 90,
  [int]$SegundosHash = 120,
  [int]$ProfundidadePerfil = 12,
  [int]$ProfundidadeDisco = 6,
  [int]$MaxAchados = 200000,
  [long]$HashMaxBytes = 524288000,
  [long]$CopiaSuspeitoMaxBytes = 52428800,
  [switch]$HashArquivosProjeto,
  [switch]$CapturaTela,
  [switch]$CopiarLicencas,
  [switch]$CopiarSuspeitos,
  [switch]$LerHivesOffline,
  [switch]$SemHivesOffline,
  [switch]$ResolverAtalhos,
  [switch]$MRUCompleto,
  [string[]]$Destacar = @(),
  [switch]$ModoTeste
)

# ---------------------------------------------------------------------------------------------
# 0. Reexecuta em PowerShell 64 bits se foi aberto o PowerShell 32 bits num Windows 64 bits
#    (no 32 bits HKLM\SOFTWARE e Program Files sao redirecionados e a coleta ficaria incompleta)
# ---------------------------------------------------------------------------------------------
if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
  $ps64 = Join-Path $env:SystemRoot 'Sysnative\WindowsPowerShell\v1.0\powershell.exe'
  if (Test-Path -LiteralPath $ps64) {
    $argsRelanc = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $PSCommandPath)
    foreach ($kv in $PSBoundParameters.GetEnumerator()) {
      if ($kv.Value -is [System.Management.Automation.SwitchParameter]) {
        if ($kv.Value.IsPresent) { $argsRelanc += ('-' + $kv.Key) }
      } else {
        $argsRelanc += ('-' + $kv.Key); $argsRelanc += ([string]$kv.Value).TrimEnd('\')
      }
    }
    Write-Host 'PowerShell 32 bits detectado: reexecutando em 64 bits...'
    & $ps64 @argsRelanc
    exit $LASTEXITCODE
  }
}

$ErrorActionPreference = 'SilentlyContinue'   # erros sao contados e registrados no log por secao
$env:PSModuleAnalysisCachePath = 'NUL'         # nao gravar cache de modulos no perfil da maquina vistoriada (v1.1 testes em VM)
$ProgressPreference    = 'SilentlyContinue'
$VersaoScript = '1.4.2'
# -Destacar opcional: Corel,Autodesk ou varios -Destacar Corel -Destacar Autodesk. Vazio = generico.
if ($null -eq $Destacar) { $Destacar = @() }
elseif ($Destacar.Count -eq 1 -and ([string]$Destacar[0]) -match '[,;]') {
  $Destacar = @(([string]$Destacar[0] -split '[,;]+') | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}
$Destacar = @($Destacar | ForEach-Object { ([string]$_).Trim() } | Where-Object { $_ })

# --- v1.4: carrega perfil externo (-Perfil) e normaliza Equip para EQ## ---
$script:PerfilMeta = [pscustomobject]@{ Arquivo = ''; Nome = '(defaults embutidos)'; Carregado = $false }
$script:PastasPrograma = @('Autodesk','Corel','Alludo','WinZip','Parallels')
$script:RaizesRegistroLicenca = @('Autodesk','Corel','Alludo','Parallels','Nico Mak Computing','WinZip Computing','FLEXlm License Manager','Macrovision','Flexera Software')
$script:PrefetchPrefixes = '^(ACAD|ACCORECONSOLE|ADSK|ADODIS|ADLM|AUTODESK|INVENTOR|REVIT|3DSMAX|MAYA|NAVISWORKS|ROAMER|FUSION360|LMU|LMGRD|ODIS|CORELDRW|CORELPP|CORELPS|CDGS|DESIGNER|PAINTSHOP|WINZIP|PRL_|PARALLELS|MSIEXEC|SETUP|INSTALL|UNINSTALL|UNINS)'
$script:LicencaProgramData = @('Autodesk\CLM','Autodesk\AdskLicensingService','Autodesk\AdskLicensing','Autodesk\ODIS','FLEXnet','Macrovision','Corel','Alludo')
$script:CandidatosLicencaRx = '^(adlmint|adlmutil|adlmact|adlmPIT|adskflex|AdskLicensing[^\\]*|AdskIdentityManager|AdSSO|LMU|acad|accoreconsole|Inventor|Revit|3dsmax|maya|Navisworks|roamer|CorelDRW|CorelPP|CorelPS|Designer|PASMUTILITY|PSIKey[^\\]*|CrlLicense[^\\]*|iPMClient|ClientServices|WINZIP64|WINZIP32|prl_[^\\]*)\.(dll|exe)$'
$script:HivesCarregadosTmp = New-Object System.Collections.ArrayList
$script:ProvavelFp = New-Object System.Collections.ArrayList

function Import-PerfilColeta {
  param([string]$Caminho)
  if ([string]::IsNullOrWhiteSpace($Caminho)) { return $null }
  $p = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Caminho)
  if (-not (Test-Path -LiteralPath $p)) { throw ("Perfil nao encontrado: " + $p) }
  $ext = [System.IO.Path]::GetExtension($p).ToLowerInvariant()
  $obj = $null
  if ($ext -eq '.json') {
    $raw = [System.IO.File]::ReadAllText($p)
    $obj = $raw | ConvertFrom-Json
  } elseif ($ext -eq '.psd1') {
    $obj = Import-PowerShellDataFile -LiteralPath $p
  } else {
    throw 'Perfil deve ser .psd1 ou .json'
  }
  return @{ Path = $p; Data = $obj }
}

if (-not [string]::IsNullOrWhiteSpace($Perfil)) {
  try {
    $imp = Import-PerfilColeta -Caminho $Perfil
    $d = $imp.Data
    if ($d.Fabricantes) { $Fabricantes = [string]$d.Fabricantes }
    if ($d.IndiciosFortes) { $IndiciosFortes = [string]$d.IndiciosFortes }
    if ($d.IndiciosFracos) { $IndiciosFracos = [string]$d.IndiciosFracos }
    if ($null -ne $d.ExclusaoIndicios) { $ExclusaoIndicios = [string]$d.ExclusaoIndicios }
    if ($d.Extensoes) { $Extensoes = [string]$d.Extensoes }
    if ($d.PastasPrograma) { $script:PastasPrograma = @($d.PastasPrograma) }
    if ($d.RaizesRegistroLicenca) { $script:RaizesRegistroLicenca = @($d.RaizesRegistroLicenca) }
    if ($d.PrefetchPrefixes) { $script:PrefetchPrefixes = [string]$d.PrefetchPrefixes }
    if ($d.LicencaProgramData) { $script:LicencaProgramData = @($d.LicencaProgramData) }
    if ($d.CandidatosLicenca) { $script:CandidatosLicencaRx = [string]$d.CandidatosLicenca }
    if ($d.DestacarPadrao -and $Destacar.Count -eq 0) { $Destacar = @($d.DestacarPadrao) }
    $nomeP = [string]$d.Nome; if (-not $nomeP) { $nomeP = [System.IO.Path]::GetFileNameWithoutExtension($imp.Path) }
    $script:PerfilMeta = [pscustomobject]@{ Arquivo = $imp.Path; Nome = $nomeP; Carregado = $true }
  } catch {
    Write-Host ("ABORTADO: falha ao carregar -Perfil: " + $_.Exception.Message) -ForegroundColor Red
    exit 5
  }
}

function Normalize-EquipId([string]$Raw) {
  # Aceita: 1, 01, EQ1, EQ01, eq_01 -> EQ01. Rejeita texto livre (ex.: mamae2).
  if ([string]::IsNullOrWhiteSpace($Raw)) { return $null }
  $s = $Raw.Trim()
  if ($s -match '^(?i)EQ[_-]?0*(\d{1,3})$') {
    $n = [int]$Matches[1]
    if ($n -lt 1 -or $n -gt 999) { return $null }
    return ('EQ{0:D2}' -f $n)
  }
  if ($s -match '^(\d{1,3})$') {
    $n = [int]$Matches[1]
    if ($n -lt 1 -or $n -gt 999) { return $null }
    return ('EQ{0:D2}' -f $n)
  }
  return $null
}

function Get-EquipIdValidado([string]$Inicial) {
  $tentativas = 0
  $cand = $Inicial
  while ($true) {
    $norm = Normalize-EquipId $cand
    if ($norm) { return $norm }
    $tentativas++
    if ($tentativas -gt 8) {
      Write-Host 'ID invalido demais vezes. Use EQ01, EQ02... (ou so o numero). Abortando.' -ForegroundColor Red
      exit 6
    }
    if (-not [string]::IsNullOrWhiteSpace($cand)) {
      Write-Host ("Identificador invalido: '{0}'. Use EQ01 / EQ02 ou so o numero (ex.: 1)." -f $cand) -ForegroundColor Yellow
    }
    try { $cand = Read-Host 'Identificador do equipamento (ex.: EQ01)' } catch { $cand = '' }
    if ([string]::IsNullOrWhiteSpace($cand)) {
      Write-Host 'ID vazio. Abortando (codigo 6).' -ForegroundColor Red
      exit 6
    }
  }
}

$script:Utf8Bom = New-Object System.Text.UTF8Encoding $true
$script:Inicio = Get-Date
$script:InicioUtc = $script:Inicio.ToUniversalTime()
$script:BufferLog = New-Object System.Collections.ArrayList
$script:LogPath = $null
$script:Arquivos = New-Object System.Collections.ArrayList
$script:Secoes = New-Object System.Collections.ArrayList
$script:HostsFabLinhas = New-Object System.Collections.ArrayList
$script:ServicosFab = New-Object System.Collections.ArrayList
$script:RemocoesMsiFab = New-Object System.Collections.ArrayList
$script:VolumesTodos = New-Object System.Collections.ArrayList
$script:LerHivesOfflineAuto = $false
$script:HiveAlias = @{}

function Write-Registro {
  param([string]$Msg, [string]$Nivel = 'INFO')
  $agora = Get-Date
  $linha = '{0} | UTC {1} | {2,-5} | {3}' -f $agora.ToString('yyyy-MM-dd HH:mm:ss'), $agora.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'), $Nivel, $Msg
  if ($script:LogPath) {
    try { [System.IO.File]::AppendAllText($script:LogPath, $linha + "`r`n", $script:Utf8Bom) } catch { }
  } else { [void]$script:BufferLog.Add($linha) }
  $cor = 'Gray'
  if ($Nivel -eq 'AVISO') { $cor = 'Yellow' } elseif ($Nivel -eq 'ERRO') { $cor = 'Red' }
  Write-Host $linha -ForegroundColor $cor
}

function Format-Data($d) {
  if ($null -eq $d -or [string]$d -eq '') { return '' }
  try { return ([datetime]$d).ToString('yyyy-MM-dd HH:mm:ss') } catch { return [string]$d }
}
function Format-DataUtc($d) {
  if ($null -eq $d -or [string]$d -eq '') { return '' }
  try { return ([datetime]$d).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss') } catch { return '' }
}

# Executa um bloco em runspace separado com tempo limite (evita travar em WMI/firewall/Defender).
function Invoke-ComLimite {
  param([scriptblock]$Bloco, [int]$Segundos = 60, [object[]]$Argumentos = @())
  $ps = [System.Management.Automation.PowerShell]::Create()
  [void]$ps.AddScript($Bloco.ToString())
  foreach ($a in $Argumentos) { [void]$ps.AddArgument($a) }
  $h = $ps.BeginInvoke()
  if ($h.AsyncWaitHandle.WaitOne($Segundos * 1000)) {
    $r = $null; $falha = $null
    try { $r = $ps.EndInvoke($h) } catch { $falha = $_.Exception.Message }
    foreach ($er in $ps.Streams.Error) { Write-Registro ("  erro interno: " + $er.ToString()) 'AVISO' }
    $ps.Dispose()
    if ($null -ne $falha) { throw ("FALHA: " + $falha) }
    return $r
  }
  try { [void]$ps.BeginStop($null, $null) } catch { }
  throw ("TEMPO LIMITE de {0}s excedido" -f $Segundos)
}

# ---------------------------------------------------------------------------------------------
# 1. Identificador, administrador, destino (somente pendrive)
# ---------------------------------------------------------------------------------------------
# ID obrigatorio no formato EQ## (1 / EQ1 / EQ01 -> EQ01). Texto livre e rejeitado.
$Equip = Get-EquipIdValidado $Equip
# -LerHivesOffline: padrao DESLIGADO (opt-in). -SemHivesOffline forca desligado.
# Risco residual: reg load da COPIA ainda toca HKU no PC vistoriado enquanto a coleta roda.
if ($SemHivesOffline) { $LerHivesOffline = $false }
$script:LerHivesOfflineAuto = $false

$idAtual = [System.Security.Principal.WindowsIdentity]::GetCurrent()
$script:IsAdmin = (New-Object System.Security.Principal.WindowsPrincipal $idAtual).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $PSScriptRoot) { Write-Host 'Execute com -File (PSScriptRoot vazio).' -ForegroundColor Red; exit 3 }
if ([string]::IsNullOrWhiteSpace($Destino)) { $Destino = Join-Path $PSScriptRoot 'coleta' }
$Destino = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Destino).TrimEnd('\')
$raizDestino = [System.IO.Path]::GetPathRoot($Destino)
$raizSistema = [System.IO.Path]::GetPathRoot($env:SystemRoot)
$raizScript  = [System.IO.Path]::GetPathRoot($PSScriptRoot)
$tipoDestino = 'Desconhecido'; $barramento = ''
try { $tipoDestino = [string](New-Object System.IO.DriveInfo $raizDestino).DriveType } catch { }
$destinoOk = $true; $motivoDestino = ''
if ($raizDestino -ieq $raizSistema) {
  $destinoOk = $false; $motivoDestino = "destino esta no disco do sistema ($raizSistema)"
} elseif ($tipoDestino -eq 'Removable') {
  $destinoOk = $true
} elseif ($tipoDestino -eq 'Fixed') {
  try {
    $letra = $raizDestino.Substring(0, 1)
    $r = Invoke-ComLimite -Segundos 20 -Argumentos @($letra) -Bloco {
      param($l) (Get-Partition -DriveLetter $l -ErrorAction Stop | Get-Disk -ErrorAction Stop).BusType
    }
    $barramento = [string](@($r) -join ',')
  } catch { }
  if ($barramento -match 'USB') { $destinoOk = $true }
  elseif ($raizDestino -ieq $raizScript) { $destinoOk = $true; $motivoDestino = "disco fixo (barramento '$barramento'), aceito por ser a mesma unidade do kit" }
  else { $destinoOk = $false; $motivoDestino = "destino em disco fixo nao-USB (barramento '$barramento')" }
} else {
  $destinoOk = $false; $motivoDestino = "tipo de unidade de destino: $tipoDestino"
}
if (-not $destinoOk) {
  if ($ModoTeste) { Write-Host "MODO TESTE: $motivoDestino - prosseguindo." -ForegroundColor Yellow }
  else {
    Write-Host "ABORTADO: $motivoDestino. A saida deve ficar no pendrive do perito." -ForegroundColor Red
    Write-Host 'Nada foi gravado. Use -Destino apontando para o pendrive (ou -ModoTeste no PC do perito).' -ForegroundColor Red
    exit 2
  }
}

$script:Out = Join-Path $Destino ('{0}_{1}_{2}' -f $Equip, $env:COMPUTERNAME, $script:Inicio.ToString('yyyyMMdd_HHmmss'))
try { [void][System.IO.Directory]::CreateDirectory($script:Out) } catch {
  Write-Host "Nao foi possivel criar a pasta de saida $($script:Out): $($_.Exception.Message)" -ForegroundColor Red; exit 4
}
$script:LogPath = Join-Path $script:Out '00_log_execucao.txt'
foreach ($l in $script:BufferLog) { [System.IO.File]::AppendAllText($script:LogPath, $l + "`r`n", $script:Utf8Bom) }

Write-Registro ("Coleta v{0} iniciada. Equip={1} Host={2}" -f $VersaoScript, $Equip, $env:COMPUTERNAME)
Write-Registro ("Inicio local: {0} ({1}) | Inicio UTC: {2}" -f $script:Inicio.ToString('yyyy-MM-dd HH:mm:ss'), [System.TimeZoneInfo]::Local.Id, $script:InicioUtc.ToString('yyyy-MM-dd HH:mm:ss'))
Write-Registro ("Usuario: {0} | Administrador: {1} | PowerShell: {2} ({3}) | Processo 64 bits: {4} | LanguageMode: {5}" -f $idAtual.Name, $script:IsAdmin, $PSVersionTable.PSVersion, $PSVersionTable.PSEdition, [Environment]::Is64BitProcess, $ExecutionContext.SessionState.LanguageMode)
Write-Registro ("Script: {0} | Destino: {1} (tipo {2} {3}) {4}" -f $PSCommandPath, $script:Out, $tipoDestino, $barramento, $motivoDestino)
if ([string]$ExecutionContext.SessionState.LanguageMode -ne 'FullLanguage') { Write-Registro 'PowerShell em modo restrito (AppLocker/WDAC). Varias secoes falharao; usar o plano B (coleta_minima.cmd).' 'AVISO' }
if (-not [string]::IsNullOrWhiteSpace($ExclusaoIndicios)) { Write-Registro ("Exclusao de indicios ativa: nomes que casam com '{0}' NAO contam como indicio de crack (ssh-keygen.exe do OpenSSH, legitimo, casaria com 'keygen'). Ocorrencias vao para 11e_indicios_excluidos.csv." -f $ExclusaoIndicios) }
if ($Destacar.Count -gt 0) { Write-Registro ("Destacar no resumo (opcional): {0}" -f ($Destacar -join ', ')) } else { Write-Registro 'Resumo generico (sem -Destacar): todas as irregularidades' }
# (v1.4.2) sem auto-enable de hives offline
if (-not $script:IsAdmin) { Write-Registro 'Executando SEM administrador: Prefetch, Defender e perfis de outros usuarios serao pulados ou parciais.' 'AVISO' }
if ($LerHivesOffline -and -not $script:IsAdmin) {
  Write-Registro ' -LerHivesOffline pedido sem admin: nao e possivel reg load; desligando.' 'AVISO'
  $LerHivesOffline = $false
}
if ($script:PerfilMeta.Carregado) { Write-Registro ("Perfil carregado: {0} ({1})" -f $script:PerfilMeta.Nome, $script:PerfilMeta.Arquivo) }
else { Write-Registro 'Perfil: defaults embutidos (use -Perfil para listas externas)' }
if ($LerHivesOffline) { Write-Registro 'Hives offline: LIGADO (copia NTUSER.DAT para o pendrive e reg load so da copia)' }
else { Write-Registro 'Hives offline: desligado (perfis deslogados sem Uninstall/MRU de registro)' }
if ($CopiarSuspeitos) { Write-Registro 'CopiarSuspeitos: LIGADO (binarios suspeitos serao copiados ao pendrive)' }
try { $hs = Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256; Write-Registro ("SHA-256 deste script: {0}" -f $hs.Hash) } catch { }

function Save-Csv {
  param([string]$Nome, $Dados, [string]$Descricao = '')
  $p = Join-Path $script:Out $Nome
  $arr = @($Dados | Where-Object { $null -ne $_ })
  try {
    if ($arr.Count -gt 0) { $arr | Export-Csv -LiteralPath $p -NoTypeInformation -Encoding UTF8 -Delimiter ';' }
    else { [System.IO.File]::WriteAllText($p, "`"Info`"`r`n`"sem registros`"`r`n", $script:Utf8Bom) }
    Write-Registro ("  gravado {0}: {1} registro(s)" -f $Nome, $arr.Count)
  } catch { Write-Registro ("  falha ao gravar {0}: {1}" -f $Nome, $_.Exception.Message) 'ERRO' }
  [void]$script:Arquivos.Add([pscustomobject]@{ Arquivo = $Nome; Registros = $arr.Count; Descricao = $Descricao })
}

function Invoke-Secao {
  param([string]$Nome, [scriptblock]$Bloco, [switch]$RequerAdmin)
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  if ($RequerAdmin -and -not $script:IsAdmin) {
    Write-Registro "[$Nome] PULADA: requer administrador" 'AVISO'
    [void]$script:Secoes.Add([pscustomobject]@{ Secao = $Nome; Status = 'PULADA_SEM_ADMIN'; Segundos = 0; ErrosIgnorados = 0; Observacao = 'requer administrador' })
    return
  }
  Write-Registro "[$Nome] inicio"
  $status = 'OK'; $obs = ''
  $script:SecaoParcial = New-Object System.Collections.ArrayList
  $Error.Clear()
  try { & $Bloco } catch { $status = 'ERRO'; $obs = ($_.Exception.Message -replace '\s+', ' '); Write-Registro "[$Nome] ERRO: $obs" 'ERRO' }
  if ($status -eq 'OK' -and $script:SecaoParcial.Count -gt 0) { $status = 'OK_PARCIAL'; $obs = ($script:SecaoParcial -join ' ; ') }
  $nErr = $Error.Count
  if ($nErr -gt 0) {
    $amostra = @($Error | Select-Object -First 3 | ForEach-Object { ($_.ToString() -replace '\s+', ' ') })
    Write-Registro ("[$Nome] {0} erro(s) nao fatais ignorados (ex.: acesso negado). Amostra: {1}" -f $nErr, ($amostra -join ' || ')) 'AVISO'
  }
  $sw.Stop()
  Write-Registro ("[$Nome] fim ({0:N1}s)" -f $sw.Elapsed.TotalSeconds)
  [void]$script:Secoes.Add([pscustomobject]@{ Secao = $Nome; Status = $status; Segundos = [math]::Round($sw.Elapsed.TotalSeconds, 1); ErrosIgnorados = $nErr; Observacao = $obs })
}

# ---------------------------------------------------------------------------------------------
# Utilitarios: registro (.NET, somente leitura), regex, perfis
# ---------------------------------------------------------------------------------------------
$rxOpt = [System.Text.RegularExpressions.RegexOptions]::IgnoreCase -bor [System.Text.RegularExpressions.RegexOptions]::Compiled
$script:RxFab    = New-Object System.Text.RegularExpressions.Regex ($Fabricantes, $rxOpt)
$script:RxForte  = New-Object System.Text.RegularExpressions.Regex ($IndiciosFortes, $rxOpt)
$script:RxExclusao = $null
if (-not [string]::IsNullOrWhiteSpace($ExclusaoIndicios)) { $script:RxExclusao = New-Object System.Text.RegularExpressions.Regex ($ExclusaoIndicios, $rxOpt) }
$script:Excluidos = New-Object System.Collections.ArrayList
# Indicio forte pelo nome, exceto exclusoes explicitas e provaveis FP (imagens/PDF/site-packages/crackfortran).
$script:RxExtFp = New-Object System.Text.RegularExpressions.Regex('\.(png|jpe?g|gif|bmp|webp|tiff?|psd|xcf|dds|tga|ico|svg|pdf|md|txt|html?|css|woff2?|ttf|otf)$', $rxOpt)
$script:RxPathFp = New-Object System.Text.RegularExpressions.Regex('(\\site-packages\\|/site-packages/|\\Lib\\numpy|\\numpy\\|\\textures?\\|/textures?/|\\Materials\\|\\Maps\\|\\__pycache__\\|\\node_modules\\)', $rxOpt)
$script:RxNomeFp = New-Object System.Text.RegularExpressions.Regex('crackfortran|crack[_-]?detection|anti[-_]?crack|uncracked', $rxOpt)
function Test-ProvavelFalsoPositivo([string]$Nome, [string]$Caminho) {
  if ($script:RxNomeFp.IsMatch($Nome)) { return 'nome conhecido (crackfortran/anti-crack)' }
  if ($script:RxExtFp.IsMatch($Nome)) { return 'extensao de imagem/documento (nao binario)' }
  if ($Caminho -and $script:RxPathFp.IsMatch($Caminho)) { return 'caminho tipico de biblioteca/textura/site-packages' }
  # "crack" sozinho em nome de textura/mapa sem keygen/kms/ativador
  if ($Nome -match '(?i)crack' -and $Nome -notmatch '(?i)keygen|kms|ativador|activator|amtlib|xf-|patch' -and $Caminho -match '(?i)(texture|material|map|asset|sprite|skin)') {
    return 'crack em contexto de textura/asset grafico'
  }
  return $null
}
function Test-IndicioForte([string]$Nome, [string]$Fonte, [string]$Caminho) {
  if (-not $script:RxForte.IsMatch($Nome)) { return $false }
  if ($null -ne $script:RxExclusao -and $script:RxExclusao.IsMatch($Nome)) {
    [void]$script:Excluidos.Add([pscustomobject]@{ Fonte = $Fonte; Nome = $Nome; Caminho = $Caminho; PadraoExclusao = $ExclusaoIndicios; Motivo = 'falso positivo conhecido (ex.: ssh-keygen.exe do OpenSSH casa com o padrao keygen)' })
    return $false
  }
  $motivoFp = Test-ProvavelFalsoPositivo $Nome $Caminho
  if ($motivoFp) {
    [void]$script:ProvavelFp.Add([pscustomobject]@{ Fonte = $Fonte; Nome = $Nome; Caminho = $Caminho; Classificacao = 'PROVAVEL_FALSO_POSITIVO'; Motivo = $motivoFp })
    return $false
  }
  return $true
}
$script:RxFraco  = New-Object System.Text.RegularExpressions.Regex ($IndiciosFracos, $rxOpt)
$script:RxInstalador = New-Object System.Text.RegularExpressions.Regex ('\.(exe|msi|iso|img|zip|rar|7z)$', $rxOpt)
$script:RxLicServ = New-Object System.Text.RegularExpressions.Regex (($Fabricantes + '|FlexNet|FLEXlm|lmgrd|adskflex|AdskLicensing|Licens|GenuineService|AdAppMgr|ODIS|AdskAccess|Desktop ?Connect'), $rxOpt)
$script:ExtSet = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
foreach ($e in ($Extensoes -split '[,; ]+')) { if ($e) { if (-not $e.StartsWith('.')) { $e = '.' + $e }; [void]$script:ExtSet.Add($e) } }

$script:Views = @()
if ([Environment]::Is64BitOperatingSystem) {
  $script:Views = @(@{ View = [Microsoft.Win32.RegistryView]::Registry64; Rot = '64' }, @{ View = [Microsoft.Win32.RegistryView]::Registry32; Rot = '32' })
} else { $script:Views = @(@{ View = [Microsoft.Win32.RegistryView]::Default; Rot = '32' }) }

function Open-Base([Microsoft.Win32.RegistryHive]$Hive, [Microsoft.Win32.RegistryView]$View) {
  try { return [Microsoft.Win32.RegistryKey]::OpenBaseKey($Hive, $View) } catch { return $null }
}
function Open-Key($Base, [string]$Path) {
  if ($null -eq $Base) { return $null }
  try { return $Base.OpenSubKey($Path, $false) } catch { return $null }   # $false = somente leitura
}
function Format-RV($v) {
  if ($null -eq $v) { return '' }
  if ($v -is [byte[]]) {
    if ($v.Length -eq 0) { return 'hex:' }
    $n = [math]::Min($v.Length, 128)
    $hex = [System.BitConverter]::ToString($v, 0, $n).Replace('-', '')
    if ($v.Length -gt $n) { $hex += ('...(' + $v.Length + ' bytes)') }
    return ('hex:' + $hex)
  }
  if ($v -is [string[]]) { return ($v -join ' | ') }
  return [string]$v
}
function Get-RV($Key, [string]$Name) {
  if ($null -eq $Key) { return '' }
  try { return (Format-RV ($Key.GetValue($Name, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames))) } catch { return '' }
}

# Percorre uma arvore do registro com limites de profundidade/tempo/linhas.
function Read-RegTree {
  param($Base, [string]$Path, [string]$Rotulo, $RxNome, $RxChave, [int]$MaxProf, [int]$Segundos, [int]$MaxLinhas, $Saida)
  $k0 = Open-Key $Base $Path
  if ($null -eq $k0) { return 'INEXISTENTE_OU_NEGADO' }
  $k0.Close()
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $pilha = New-Object 'System.Collections.Generic.Stack[object]'
  $pilha.Push(@($Path, 0))
  while ($pilha.Count -gt 0) {
    if ($sw.Elapsed.TotalSeconds -ge $Segundos) { return 'TEMPO_ESGOTADO' }
    if ($Saida.Count -ge $MaxLinhas) { return 'LIMITE_LINHAS' }
    $it = $pilha.Pop(); $p = [string]$it[0]; $prof = [int]$it[1]
    $k = Open-Key $Base $p
    if ($null -eq $k) { continue }
    try {
      $chaveCasa = ($null -ne $RxChave) -and $RxChave.IsMatch($p)
      foreach ($vn in $k.GetValueNames()) {
        $casa = $chaveCasa -or (($null -ne $RxNome) -and $RxNome.IsMatch($vn))
        if ($casa) {
          $tipo = ''
          try { $tipo = [string]$k.GetValueKind($vn) } catch { }
          $nomeV = $vn; if ($vn -eq '') { $nomeV = '(Padrao)' }
          [void]$Saida.Add([pscustomobject]@{ Chave = ($Rotulo + '\' + $p); Valor = $nomeV; Tipo = $tipo; Dado = (Get-RV $k $vn) })
        }
      }
      if ($prof -lt $MaxProf) { foreach ($sk in $k.GetSubKeyNames()) { $pilha.Push(@(($p + '\' + $sk), ($prof + 1))) } }
    } catch { }
    $k.Close()
  }
  return 'COMPLETO'
}

$script:HKLM = @{}
foreach ($v in $script:Views) { $script:HKLM[$v.Rot] = Open-Base ([Microsoft.Win32.RegistryHive]::LocalMachine) $v.View }
$script:HKU = Open-Base ([Microsoft.Win32.RegistryHive]::Users) ([Microsoft.Win32.RegistryView]::Default)
$hklmN = $script:HKLM[$script:Views[0].Rot]   # visao nativa

# Perfis de usuario: ProfileList (local, sem consulta ao dominio) + pastas em <SystemDrive>\Users
$script:SidsCarregados = @()
if ($script:HKU) { $script:SidsCarregados = @($script:HKU.GetSubKeyNames() | Where-Object { $_ -notmatch '_Classes$' }) }
$script:Perfis = New-Object System.Collections.ArrayList
$vistosPerfil = @{}
$pl = Open-Key $hklmN 'SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList'
if ($pl) {
  foreach ($sid in $pl.GetSubKeyNames()) {
    $k = $pl.OpenSubKey($sid, $false)
    if ($null -eq $k) { continue }
    $cam = [Environment]::ExpandEnvironmentVariables([string]$k.GetValue('ProfileImagePath'))
    $k.Close()
    if ($sid -match '^S-1-5-(18|19|20)$') { continue }
    if ($cam -and -not $vistosPerfil.ContainsKey($cam.ToLower())) {
      $vistosPerfil[$cam.ToLower()] = 1
      [void]$script:Perfis.Add([pscustomobject]@{ SID = $sid; Caminho = $cam; Usuario = (Split-Path $cam -Leaf); HiveCarregado = ($script:SidsCarregados -contains $sid) })
    }
  }
  $pl.Close()
}
$dirUsers = Join-Path $raizSistema 'Users'
try {
  foreach ($d in [System.IO.Directory]::GetDirectories($dirUsers)) {
    $attr = [System.IO.File]::GetAttributes($d)
    if (($attr -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) { continue }
    if (-not $vistosPerfil.ContainsKey($d.ToLower())) {
      $vistosPerfil[$d.ToLower()] = 1
      [void]$script:Perfis.Add([pscustomobject]@{ SID = ''; Caminho = $d; Usuario = (Split-Path $d -Leaf); HiveCarregado = $false })
    }
  }
} catch { }
function Get-UsuarioPorSid([string]$sid) {
  if ([string]::IsNullOrEmpty($sid)) { return '' }
  foreach ($p in $script:Perfis) {
    if ($p.SID -eq $sid) { return $p.Usuario }
    if ($p.PSObject.Properties['HiveChaveTemp'] -and $p.HiveChaveTemp -eq $sid) { return $p.Usuario }
  }
  return ''
}

$script:PF64  = $env:ProgramW6432;       if (-not $script:PF64)  { $script:PF64 = $env:ProgramFiles }
$script:PF86  = ${env:ProgramFiles(x86)}
$script:CPF64 = $env:CommonProgramW6432; if (-not $script:CPF64) { $script:CPF64 = $env:CommonProgramFiles }
$script:CPF86 = ${env:CommonProgramFiles(x86)}
$script:PD    = $env:ProgramData
$script:DesdeEventos = (Get-Date).AddDays(-$DiasEventos)
$script:Programas = New-Object System.Collections.ArrayList
$script:NaoAssinados = 0

# ---------------------------------------------------------------------------------------------
# Motor de varredura de arquivos: pilha manual, sem seguir reparse points, com limites.
# Modos: projeto | lixeira | fabricante | licenca.  So le a listagem de diretorios (nomes,
# tamanhos, datas); nao abre arquivos (excecao: os pequenos $I da Lixeira, lidos sem alterar).
# ---------------------------------------------------------------------------------------------
$script:Achados = @{}
foreach ($n in 'Projeto', 'Forte', 'Fraco', 'Instalador', 'Licenca', 'Candidato', 'DllSistema', 'Lixeira') { $script:Achados[$n] = New-Object System.Collections.ArrayList }
$script:Visitados = @{}
$script:RaizesStatus = New-Object System.Collections.ArrayList
$script:SwArquivos = New-Object System.Diagnostics.Stopwatch
$script:DllsSistema = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase)
foreach ($n in 'version.dll', 'winmm.dll', 'netapi32.dll', 'winhttp.dll', 'dwmapi.dll', 'msimg32.dll', 'iphlpapi.dll', 'uxtheme.dll', 'wtsapi32.dll', 'userenv.dll', 'cryptbase.dll', 'dinput8.dll', 'wininet.dll', 'secur32.dll') { [void]$script:DllsSistema.Add($n) }
$script:RxCandidato = New-Object System.Text.RegularExpressions.Regex ($script:CandidatosLicencaRx, $rxOpt)

function ConvertTo-LinhaArquivo($e, [string]$Rotulo, [string]$Categoria) {
  $tam = $null; try { $tam = $e.Length } catch { }
  return [pscustomobject]@{
    Categoria = $Categoria; Nome = $e.Name; Extensao = $e.Extension; Caminho = $e.FullName; TamanhoBytes = $tam
    Criado = (Format-Data $e.CreationTime); Modificado = (Format-Data $e.LastWriteTime); Acessado = (Format-Data $e.LastAccessTime)
    CriadoUTC = (Format-DataUtc $e.CreationTime); ModificadoUTC = (Format-DataUtc $e.LastWriteTime); Atributos = [string]$e.Attributes; Raiz = $Rotulo
  }
}

# Le o registro $I da Lixeira (v1 = Vista/7/8, v2 = Win10/11): versao, tamanho, data de exclusao, caminho original
function Read-RecycleI([string]$Caminho) {
  $b = [System.IO.File]::ReadAllBytes($Caminho)
  if ($b.Length -lt 24) { return $null }
  $ver = [System.BitConverter]::ToInt64($b, 0)
  $tam = [System.BitConverter]::ToInt64($b, 8)
  $ft  = [System.BitConverter]::ToInt64($b, 16)
  $orig = ''
  if ($ver -eq 2 -and $b.Length -ge 28) {
    $len = [System.BitConverter]::ToInt32($b, 24)
    $orig = [System.Text.Encoding]::Unicode.GetString($b, 28, [math]::Min($len * 2, $b.Length - 28))
  } else {
    $orig = [System.Text.Encoding]::Unicode.GetString($b, 24, [math]::Min(520, $b.Length - 24))
  }
  $i = $orig.IndexOf([char]0); if ($i -ge 0) { $orig = $orig.Substring(0, $i) }
  $exc = $null; try { $exc = [DateTime]::FromFileTimeUtc($ft) } catch { }
  return @($ver, $tam, $exc, $orig)
}

function Invoke-Varredura {
  param([string]$Raiz, [string]$Modo, [int]$ProfMax, [int]$Segundos, [string]$Rotulo, $RxExcluirDir = $null, [switch]$ContaNoTotal)
  $st = [ordered]@{ Rotulo = $Rotulo; Raiz = $Raiz; Modo = $Modo; Status = 'COMPLETO'; Pastas = 0; Arquivos = 0; Achados = 0; AcessoNegado = 0; PontosReparseIgnorados = 0; CaminhoLongo = 0; OutrosErros = 0; Segundos = 0 }
  if ([string]::IsNullOrEmpty($Raiz) -or -not [System.IO.Directory]::Exists($Raiz)) {
    $st.Status = 'INEXISTENTE_OU_NEGADO'; [void]$script:RaizesStatus.Add([pscustomobject]$st); return
  }
  if (-not $script:Visitados.ContainsKey($Modo)) { $script:Visitados[$Modo] = New-Object 'System.Collections.Generic.HashSet[string]' ([System.StringComparer]::OrdinalIgnoreCase) }
  $vis = $script:Visitados[$Modo]
  $sw = [System.Diagnostics.Stopwatch]::StartNew()
  $antes = 0; foreach ($l in $script:Achados.Values) { $antes += $l.Count }
  $pilha = New-Object 'System.Collections.Generic.Stack[object]'
  $pilha.Push(@($Raiz, 0))
  $flagDir = [System.IO.FileAttributes]::Directory
  $flagRep = [System.IO.FileAttributes]::ReparsePoint
  while ($pilha.Count -gt 0) {
    if ($sw.Elapsed.TotalSeconds -ge $Segundos) { $st.Status = 'TEMPO_ESGOTADO'; break }
    if ($ContaNoTotal -and $script:SwArquivos.Elapsed.TotalSeconds -ge $SegundosTotalArquivos) { $st.Status = 'TEMPO_TOTAL_ESGOTADO'; break }
    if ($script:Achados['Projeto'].Count -ge $MaxAchados) { $st.Status = 'LIMITE_ACHADOS'; break }
    $it = $pilha.Pop(); $dir = [string]$it[0]; $prof = [int]$it[1]
    if (-not $vis.Add($dir)) { continue }
    $st.Pastas++
    try {
      $di = New-Object System.IO.DirectoryInfo $dir
      foreach ($e in $di.EnumerateFileSystemInfos()) {
        try {
          $attr = $e.Attributes
          if (($attr -band $flagDir) -ne 0) {
            if (($attr -band $flagRep) -ne 0) { $st.PontosReparseIgnorados++; continue }
            if ($prof -lt $ProfMax) {
              $fn = $e.FullName
              if ($null -ne $RxExcluirDir -and $RxExcluirDir.IsMatch($fn)) { continue }
              $pilha.Push(@($fn, ($prof + 1)))
            }
            continue
          }
          $st.Arquivos++
          $nome = $e.Name
          if ($Modo -eq 'licenca') {
            [void]$script:Achados['Licenca'].Add((ConvertTo-LinhaArquivo $e $Rotulo 'ARQUIVO_LICENCA'))
            continue
          }
          if ($Modo -eq 'fabricante') {
            if (Test-IndicioForte $nome 'pasta_programa' $e.FullName) { [void]$script:Achados['Forte'].Add((ConvertTo-LinhaArquivo $e $Rotulo 'INDICIO_FORTE_NOME_PASTA_PROGRAMA')) }
            if ($script:DllsSistema.Contains($nome)) { [void]$script:Achados['DllSistema'].Add((ConvertTo-LinhaArquivo $e $Rotulo 'DLL_DE_SISTEMA_NA_PASTA_DO_PROGRAMA')) }
            if ($script:RxCandidato.IsMatch($nome)) { [void]$script:Achados['Candidato'].Add($e.FullName) }
            continue
          }
          # modos projeto / lixeira
          if ($script:ExtSet.Contains($e.Extension) -and -not ($Modo -eq 'lixeira' -and $nome.StartsWith('$I'))) {
            $catP = 'ARQUIVO_PROJETO'; if ($Modo -eq 'lixeira') { $catP = 'ARQUIVO_PROJETO_NA_LIXEIRA' }
            [void]$script:Achados['Projeto'].Add((ConvertTo-LinhaArquivo $e $Rotulo $catP))
          }
          if (Test-IndicioForte $nome ('varredura:' + $Rotulo) $e.FullName) { [void]$script:Achados['Forte'].Add((ConvertTo-LinhaArquivo $e $Rotulo 'INDICIO_FORTE_NOME')) }
          elseif ($script:RxFraco.IsMatch($nome) -and ($nome.EndsWith('.nfo', [System.StringComparison]::OrdinalIgnoreCase) -or $script:RxFab.IsMatch($e.FullName) -or $nome -match '(?i)activat|\bkms|toolkit|keygen|crack|patch')) {
            [void]$script:Achados['Fraco'].Add((ConvertTo-LinhaArquivo $e $Rotulo 'INDICIO_FRACO_NOME'))
          }
          if ($script:RxInstalador.IsMatch($nome) -and $script:RxFab.IsMatch($nome)) { [void]$script:Achados['Instalador'].Add((ConvertTo-LinhaArquivo $e $Rotulo 'INSTALADOR_OU_PACOTE_FABRICANTE')) }
          if ($Modo -eq 'lixeira' -and $nome.StartsWith('$I') -and $e.Length -le 8192) {
            $r = Read-RecycleI $e.FullName
            if ($null -ne $r) {
              $orig = [string]$r[3]
              $rel = $script:ExtSet.Contains([System.IO.Path]::GetExtension($orig)) -or $script:RxFab.IsMatch($orig) -or $script:RxForte.IsMatch($orig)
              $sidL = ''; if ($e.FullName -match '[\\/]\$Recycle\.Bin[\\/](S-[0-9-]+)[\\/]') { $sidL = $Matches[1] }
              $excLocal = $null; if ($null -ne $r[2]) { $excLocal = ([datetime]$r[2]).ToLocalTime() }
              [void]$script:Achados['Lixeira'].Add([pscustomobject]@{
                Relevante = $rel; CaminhoOriginal = $orig; TamanhoOriginal = $r[1]; ExcluidoEmLocal = (Format-Data $excLocal); ExcluidoEmUTC = (Format-Data $r[2])
                SID = $sidL; Usuario = (Get-UsuarioPorSid $sidL); ArquivoI = $e.FullName
                ConteudoAindaNaLixeira = (Test-Path -LiteralPath ($e.FullName.Substring(0, $e.FullName.Length - $nome.Length) + '$R' + $nome.Substring(2))); VersaoFormato = $r[0]
              })
            }
          }
        } catch [System.IO.PathTooLongException] { $st.CaminhoLongo++ } catch { $st.OutrosErros++ }
      }
    } catch [System.UnauthorizedAccessException] { $st.AcessoNegado++ }
      catch [System.IO.PathTooLongException] { $st.CaminhoLongo++ }
      catch [System.Security.SecurityException] { $st.AcessoNegado++ }
      catch { $st.OutrosErros++ }
  }
  $sw.Stop()
  $depois = 0; foreach ($l in $script:Achados.Values) { $depois += $l.Count }
  $st.Achados = $depois - $antes
  $st.Segundos = [math]::Round($sw.Elapsed.TotalSeconds, 1)
  if ($st.Status -eq 'COMPLETO' -and $pilha.Count -gt 0) { $st.Status = 'INCOMPLETO' }
  [void]$script:RaizesStatus.Add([pscustomobject]$st)
  Write-Registro ("  varredura {0} [{1}]: {2} ({3} pastas, {4} arquivos, {5} achados, {6} negados, {7}s)" -f $Rotulo, $Modo, $st.Status, $st.Pastas, $st.Arquivos, $st.Achados, $st.AcessoNegado, $st.Segundos)
}

# =============================================================================================
# SECOES DE COLETA (ordem: o que o proprio PowerShell pode alterar e coletado primeiro)
# =============================================================================================

Invoke-Secao 'Identificacao do equipamento' {
  $cs = Get-CimInstance Win32_ComputerSystem -OperationTimeoutSec 60
  $bios = Get-CimInstance Win32_BIOS -OperationTimeoutSec 60
  $os = Get-CimInstance Win32_OperatingSystem -OperationTimeoutSec 60
  $csp = Get-CimInstance Win32_ComputerSystemProduct -OperationTimeoutSec 60
  $tz = [System.TimeZoneInfo]::Local
  Save-Csv '01_identificacao.csv' ([pscustomobject]@{
    Equip = $Equip; Hostname = $env:COMPUTERNAME; Dominio = $cs.Domain; Fabricante = $cs.Manufacturer; Modelo = $cs.Model
    SerieBIOS = $bios.SerialNumber; UUID = $csp.UUID; SO = $os.Caption; VersaoSO = $os.Version; Build = $os.BuildNumber; Arquitetura = $os.OSArchitecture
    InstalacaoSO = (Format-Data $os.InstallDate); UltimoBoot = (Format-Data $os.LastBootUpTime); UsuarioLogadoConsole = $cs.UserName
    UsuarioExecutando = $idAtual.Name; Administrador = $script:IsAdmin; PowerShell = [string]$PSVersionTable.PSVersion
    RelogioMaquinaLocal = $script:Inicio.ToString('yyyy-MM-dd HH:mm:ss'); RelogioMaquinaUTC = $script:InicioUtc.ToString('yyyy-MM-dd HH:mm:ss')
    FusoHorario = $tz.Id; OffsetUTC = [string]$tz.GetUtcOffset($script:Inicio); NomeRegistradoSO = $os.RegisteredUser; OrganizacaoSO = $os.Organization
  }) 'Identificacao do equipamento e relogio'
  Save-Csv '01b_discos.csv' (Get-CimInstance Win32_DiskDrive -OperationTimeoutSec 60 | ForEach-Object { [pscustomobject]@{ Modelo = $_.Model; Serie = ([string]$_.SerialNumber).Trim(); Interface = $_.InterfaceType; TamanhoGB = [math]::Round(($_.Size / 1GB), 1); Particoes = $_.Partitions } }) 'Discos fisicos'
  $vols = foreach ($d in [System.IO.DriveInfo]::GetDrives()) {
    $o = [ordered]@{ Unidade = $d.Name; Tipo = [string]$d.DriveType; Pronto = $d.IsReady; Rotulo = ''; Formato = ''; TamanhoGB = ''; LivreGB = '' }
    if ($d.IsReady) { try { $o.Rotulo = $d.VolumeLabel; $o.Formato = $d.DriveFormat; $o.TamanhoGB = [math]::Round($d.TotalSize / 1GB, 1); $o.LivreGB = [math]::Round($d.AvailableFreeSpace / 1GB, 1) } catch { } }
    $obj = [pscustomobject]$o
    [void]$script:VolumesTodos.Add($obj)
    $obj
  }
  Save-Csv '01c_volumes.csv' $vols 'Volumes'
  Save-Csv '01d_perfis_usuario.csv' $script:Perfis 'Perfis de usuario (ProfileList + pasta Users)'
  Save-Csv '02_rede.csv' (Get-CimInstance Win32_NetworkAdapterConfiguration -OperationTimeoutSec 60 | Where-Object { $_.IPEnabled } |
    ForEach-Object { [pscustomobject]@{ Descricao = $_.Description; MAC = $_.MACAddress; IP = ($_.IPAddress -join ';'); Gateway = ($_.DefaultIPGateway -join ';'); DNS = ($_.DNSServerSearchOrder -join ';'); DominioDNS = $_.DNSDomain } }) 'Adaptadores de rede'
}

if ($CapturaTela) {
  Invoke-Secao 'Captura de tela' {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Add-Type -AssemblyName System.Drawing -ErrorAction Stop
    $b = [System.Windows.Forms.SystemInformation]::VirtualScreen
    $bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
    $p = Join-Path $script:Out '01e_captura_tela_inicio.png'
    $bmp.Save($p, [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Registro ("  captura salva ({0}x{1})" -f $b.Width, $b.Height)
  }
}

# Prefetch primeiro: a propria execucao do PowerShell gera/atualiza POWERSHELL.EXE-*.pf poucos segundos depois.
Invoke-Secao 'Prefetch (programas executados)' -RequerAdmin {
  $dir = Join-Path $env:SystemRoot 'Prefetch'
  $rxPf = New-Object System.Text.RegularExpressions.Regex (($script:PrefetchPrefixes + '|' + $IndiciosFortes), $rxOpt)
  $lin = New-Object System.Collections.ArrayList
  $di = New-Object System.IO.DirectoryInfo $dir
  foreach ($f in $di.EnumerateFiles('*.pf')) {
    $exe = ($f.Name -replace '-[0-9A-F]{8}\.pf$', '')
    $relPf = ($rxPf.IsMatch($exe) -or $script:RxFab.IsMatch($exe))
    if ($relPf -and $null -ne $script:RxExclusao -and $script:RxExclusao.IsMatch($exe)) {
      $relPf = $false
      [void]$script:Excluidos.Add([pscustomobject]@{ Fonte = 'prefetch'; Nome = $exe; Caminho = $f.FullName; PadraoExclusao = $ExclusaoIndicios; Motivo = 'falso positivo conhecido (ex.: ssh-keygen.exe do OpenSSH casa com o padrao keygen)' })
    }
    [void]$lin.Add([pscustomobject]@{ Executavel = $exe; Relevante = $relPf; ArquivoPf = $f.Name
      CriadoPrimeiraExec = (Format-Data $f.CreationTime); ModificadoUltimaExec = (Format-Data $f.LastWriteTime); ModificadoUTC = (Format-DataUtc $f.LastWriteTime); TamanhoBytes = $f.Length })
  }
  Save-Csv '13_prefetch.csv' ($lin | Sort-Object ModificadoUltimaExec -Descending) 'Prefetch: nome e datas (sem abrir os .pf). POWERSHELL/CMD/CONHOST podem refletir esta coleta.'
}

Invoke-Secao 'Arquivos recentes (Recent .lnk e Jump Lists)' {
  $lin = New-Object System.Collections.ArrayList
  $jl = New-Object System.Collections.ArrayList
  $total = 0
  $sh = $null
  if ($ResolverAtalhos) { try { $sh = New-Object -ComObject WScript.Shell } catch { Write-Registro '  WScript.Shell indisponivel; destinos nao resolvidos' 'AVISO' } }
  foreach ($p in $script:Perfis) {
    $rec = Join-Path $p.Caminho 'AppData\Roaming\Microsoft\Windows\Recent'
    try {
      $di = New-Object System.IO.DirectoryInfo $rec
      foreach ($f in $di.EnumerateFiles('*.lnk')) {
        $total++
        $base = $f.Name.Substring(0, $f.Name.Length - 4)
        $rel = $script:ExtSet.Contains([System.IO.Path]::GetExtension($base)) -or $script:RxFab.IsMatch($base) -or (Test-IndicioForte $base 'recent_lnk' $f.FullName)
        if (-not ($rel -or $MRUCompleto)) { continue }
        $alvo = ''
        if ($sh) { try { $alvo = $sh.CreateShortcut($f.FullName).TargetPath } catch { } }
        [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; Relevante = $rel; Atalho = $f.Name; Alvo = $alvo; CriadoPrimeiroAcesso = (Format-Data $f.CreationTime); ModificadoUltimoAcesso = (Format-Data $f.LastWriteTime); ModificadoUTC = (Format-DataUtc $f.LastWriteTime); Caminho = $f.FullName })
      }
    } catch { Write-Registro ("  Recent de {0}: sem acesso ou inexistente" -f $p.Usuario) }
    foreach ($sub in 'AutomaticDestinations', 'CustomDestinations') {
      try {
        $di = New-Object System.IO.DirectoryInfo (Join-Path $rec $sub)
        foreach ($f in $di.EnumerateFiles()) { [void]$jl.Add([pscustomobject]@{ Usuario = $p.Usuario; Tipo = $sub; Arquivo = $f.Name; Criado = (Format-Data $f.CreationTime); Modificado = (Format-Data $f.LastWriteTime); TamanhoBytes = $f.Length }) }
      } catch { }
    }
  }
  $modoTxt = 'so relacionados'; if ($MRUCompleto) { $modoTxt = 'todos' }
  Write-Registro ("  {0} atalhos .lnk no total; {1} listados ({2})" -f $total, $lin.Count, $modoTxt)
  Save-Csv '15_recentes_lnk.csv' $lin 'Atalhos da pasta Recent (padrao: so os relacionados a extensoes/fabricantes/indicios)'
  Save-Csv '15b_jumplists_lista.csv' $jl 'Jump Lists: so nome e datas (nao interpretados)'
}

# =============================================================================================
# v1.4: carrega hives de usuarios deslogados a partir de COPIA no pendrive (somente leitura no original)
# =============================================================================================
Invoke-Secao 'Hives offline (copia NTUSER.DAT no pendrive)' {
  if (-not $LerHivesOffline) {
    Write-Registro '  -LerHivesOffline desligado; pulando carga de hives deslogados'
    [void]$script:SecaoParcial.Add('desligado por parametro')
    return
  }
  if (-not $script:IsAdmin) {
    Write-Registro '  reg load de hives exige administrador' 'AVISO'
    return
  }
  $dirHives = Join-Path $script:Out 'hives_offline'
  [void][System.IO.Directory]::CreateDirectory($dirHives)
  $lin = New-Object System.Collections.ArrayList
  foreach ($p in $script:Perfis) {
    if ($p.HiveCarregado) {
      [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; SID = $p.SID; Status = 'JA_CARREGADO_SESSAO'; Copia = ''; ChaveTemp = '' })
      continue
    }
    $nt = Join-Path $p.Caminho 'NTUSER.DAT'
    if (-not (Test-Path -LiteralPath $nt)) {
      [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; SID = $p.SID; Status = 'NTUSER_AUSENTE'; Copia = ''; ChaveTemp = '' })
      continue
    }
    $sidSafe = if ($p.SID) { ($p.SID -replace '[^A-Za-z0-9-]', '_') } else { ($p.Usuario -replace '[^A-Za-z0-9_-]', '_') }
    $chave = 'PericiaTmp_' + $sidSafe
    # Recusa path que nao seja claramente uma copia sob o destino (pendrive)
    $dst = Join-Path $dirHives ($sidSafe + '_NTUSER.DAT')
    try {
      [System.IO.File]::Copy($nt, $dst, $true)
      foreach ($suf in ('.LOG', '.LOG1', '.LOG2', '.blf', '.regtrans-ms')) {
        $srcL = $nt + $suf
        if (Test-Path -LiteralPath $srcL) {
          try { [System.IO.File]::Copy($srcL, ($dst + $suf), $true) } catch { }
        }
      }
    } catch {
      [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; SID = $p.SID; Status = ('COPIA_FALHOU: ' + ($_.Exception.Message -replace '\s+', ' ')); Copia = ''; ChaveTemp = '' })
      continue
    }
    # Sanity: destino deve estar sob $script:Out (pendrive), nunca sob C:\Users
    if ($dst.StartsWith($raizSistema, [System.StringComparison]::OrdinalIgnoreCase)) {
      Write-Registro '  ABORTADO interno: destino da copia nao pode ficar no disco do sistema' 'ERRO'
      [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; SID = $p.SID; Status = 'RECUSADO_PATH_SISTEMA'; Copia = $dst; ChaveTemp = '' })
      continue
    }
    $outLoad = & reg.exe load ("HKU\" + $chave) $dst 2>&1 | Out-String
    if ($LASTEXITCODE -ne 0) {
      [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; SID = $p.SID; Status = ('REG_LOAD_FALHOU: ' + ($outLoad -replace '\s+', ' ').Trim()); Copia = $dst; ChaveTemp = $chave })
      continue
    }
    [void]$script:HivesCarregadosTmp.Add($chave)
    # Marca perfil como carregado via copia e inclui SID na lista de leitura
    $p.HiveCarregado = $true
    $p | Add-Member -NotePropertyName HiveCarregadoViaCopia -NotePropertyValue $true -Force
    $p | Add-Member -NotePropertyName HiveChaveTemp -NotePropertyValue $chave -Force
    if ($p.SID -and ($script:SidsCarregados -notcontains $p.SID)) {
      # Mapeia SID real -> chave temp para Open-Key via alias? reg load usa nome, nao SID.
      # Guardamos mapa SID->chave temp
    }
    if (-not $p.SID) {
      # Perfil so de pasta: usa a chave temp como "SID" logico para leituras
      $p.SID = $chave
    }
    # Adiciona ao mapa de resolucao: quando SID real difere da chave temp
    if (-not $script:HiveAlias) { $script:HiveAlias = @{} }
    $script:HiveAlias[$chave] = $chave
    if ($p.SID -and $p.SID -ne $chave) { $script:HiveAlias[$p.SID] = $chave }
    if ($script:SidsCarregados -notcontains $chave) {
      $script:SidsCarregados = @($script:SidsCarregados) + @($chave)
    }
    [void]$lin.Add([pscustomobject]@{ Usuario = $p.Usuario; SID = $p.SID; Status = 'CARREGADO_VIA_COPIA'; Copia = $dst; ChaveTemp = $chave })
    Write-Registro ("  hive offline carregado: {0} -> HKU\\{1}" -f $p.Usuario, $chave)
  }
  Save-Csv '01f_hives_offline.csv' $lin 'Hives de usuarios deslogados: copia no pendrive + reg load da copia (original nao escrito)'
}

Invoke-Secao 'MRU do registro (usuarios com hive carregado)' {
  $lin = New-Object System.Collections.ArrayList
  $rxMru = New-Object System.Text.RegularExpressions.Regex ('recent|mru|history|lastfile|filelist|openfile', $rxOpt)
  foreach ($sid in $script:SidsCarregados) {
    $chaveLeitura = $sid
    if ($script:HiveAlias -and $script:HiveAlias.ContainsKey($sid)) { $chaveLeitura = $script:HiveAlias[$sid] }
    $u = Get-UsuarioPorSid $sid
    if (-not $u) { $u = Get-UsuarioPorSid $chaveLeitura }
    $sid = $chaveLeitura
    # 1) Explorer RecentDocs por extensao
    $rd = Open-Key $script:HKU "$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
    if ($rd) {
      foreach ($sub in $rd.GetSubKeyNames()) {
        if (-not $script:ExtSet.Contains($sub)) { continue }
        $k = $rd.OpenSubKey($sub, $false); if (-not $k) { continue }
        foreach ($vn in $k.GetValueNames()) {
          if ($vn -eq 'MRUListEx') { continue }
          $b = $k.GetValue($vn)
          if ($b -is [byte[]] -and $b.Length -gt 2) {
            $s = [System.Text.Encoding]::Unicode.GetString($b); $i = $s.IndexOf([char]0); if ($i -gt 0) { $s = $s.Substring(0, $i) }
            [void]$lin.Add([pscustomobject]@{ Usuario = $u; SID = $sid; Fonte = "Explorer RecentDocs\$sub"; Item = $vn; Valor = $s })
          }
        }
        $k.Close()
      }
      $rd.Close()
    }
    # 2) Dialogos Abrir/Salvar (OpenSavePidlMRU) - extrai nomes de arquivo do PIDL binario
    $os2 = Open-Key $script:HKU "$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\ComDlg32\OpenSavePidlMRU"
    if ($os2) {
      foreach ($sub in $os2.GetSubKeyNames()) {
        if (-not $script:ExtSet.Contains('.' + $sub)) { continue }
        $k = $os2.OpenSubKey($sub, $false); if (-not $k) { continue }
        $rxN = New-Object System.Text.RegularExpressions.Regex (('(?:(?![\\/:*?"<>|])[\u0020-\u007E\u00A0-\u024F]){1,200}\.' + [regex]::Escape($sub) + '(?![A-Za-z0-9])'), $rxOpt)
        foreach ($vn in $k.GetValueNames()) {
          if ($vn -eq 'MRUListEx') { continue }
          $b = $k.GetValue($vn)
          if (-not ($b -is [byte[]])) { continue }
          $nomes = New-Object System.Collections.Generic.List[string]
          foreach ($desl in 0, 1) {
            if ($b.Length -le $desl + 2) { continue }
            $s = [System.Text.Encoding]::Unicode.GetString($b, $desl, $b.Length - $desl)
            foreach ($m in $rxN.Matches($s)) { if (-not $nomes.Contains($m.Value)) { $nomes.Add($m.Value) } }
          }
          [void]$lin.Add([pscustomobject]@{ Usuario = $u; SID = $sid; Fonte = "ComDlg32 OpenSavePidlMRU\$sub"; Item = $vn; Valor = ($nomes -join ' | ') })
        }
        $k.Close()
      }
      $os2.Close()
    }
    # 3) MRU dos produtos Autodesk / Corel (chaves com Recent/MRU/History)
    foreach ($fab in $script:RaizesRegistroLicenca) {
      $tmp = New-Object System.Collections.ArrayList
      $res = Read-RegTree -Base $script:HKU -Path "$sid\Software\$fab" -Rotulo 'HKU' -RxNome $null -RxChave $rxMru -MaxProf 10 -Segundos 30 -MaxLinhas 10000 -Saida $tmp
      foreach ($t in $tmp) { [void]$lin.Add([pscustomobject]@{ Usuario = $u; SID = $sid; Fonte = $t.Chave; Item = $t.Valor; Valor = $t.Dado }) }
      if ($res -ne 'COMPLETO' -and $res -ne 'INEXISTENTE_OU_NEGADO') { Write-Registro "  MRU $fab de ${sid}: $res" 'AVISO' }
    }
    # 4) Office File MRU (padrao: so itens relacionados)
    $off = Open-Key $script:HKU "$sid\Software\Microsoft\Office"
    if ($off) {
      foreach ($ver in $off.GetSubKeyNames()) {
        if ($ver -notmatch '^\d+\.\d+$') { continue }
        $kv = $off.OpenSubKey($ver, $false); if (-not $kv) { continue }
        foreach ($app in $kv.GetSubKeyNames()) {
          $caminhos = New-Object System.Collections.Generic.List[string]
          $caminhos.Add("$app\File MRU")
          $um = $kv.OpenSubKey("$app\User MRU", $false)
          if ($um) { foreach ($idm in $um.GetSubKeyNames()) { $caminhos.Add("$app\User MRU\$idm\File MRU") }; $um.Close() }
          foreach ($c in $caminhos) {
            $k = $kv.OpenSubKey($c, $false); if (-not $k) { continue }
            foreach ($vn in $k.GetValueNames()) {
              if ($vn -notmatch '^Item') { continue }
              $val = [string]$k.GetValue($vn)
              $cam = $val; $ix = $val.IndexOf('*'); if ($ix -ge 0) { $cam = $val.Substring($ix + 1) }
              $extC = ''; try { $extC = [System.IO.Path]::GetExtension($cam) } catch { }
              $rel = $script:ExtSet.Contains($extC) -or $script:RxFab.IsMatch($cam) -or $script:RxForte.IsMatch($cam)
              if ($rel -or $MRUCompleto) { [void]$lin.Add([pscustomobject]@{ Usuario = $u; SID = $sid; Fonte = "Office $ver\$c"; Item = $vn; Valor = $val }) }
            }
            $k.Close()
          }
        }
        $kv.Close()
      }
      $off.Close()
    }
  }
  Save-Csv '16_mru_registro.csv' $lin 'Listas de recentes no registro (RecentDocs, Abrir/Salvar, Autodesk/Corel, Office filtrado)'
}


Invoke-Secao 'Programas instalados (Uninstall 64/32 bits + HKEY_USERS)' {
  function Read-Uninstall($Base, [string]$Path, [string]$Rotulo, [string]$Escopo) {
    $k = Open-Key $Base $Path
    if ($null -eq $k) { return }
    foreach ($n in $k.GetSubKeyNames()) {
      $s = $null
      try { $s = $k.OpenSubKey($n, $false) } catch { continue }
      if ($null -eq $s) { continue }
      $dn = Get-RV $s 'DisplayName'
      if (-not [string]::IsNullOrEmpty($dn)) {
        [void]$script:Programas.Add([pscustomobject]@{
          Escopo = $Escopo; DisplayName = $dn; DisplayVersion = (Get-RV $s 'DisplayVersion'); Publisher = (Get-RV $s 'Publisher'); InstallDate = (Get-RV $s 'InstallDate')
          InstallLocation = (Get-RV $s 'InstallLocation'); InstallSource = (Get-RV $s 'InstallSource'); UninstallString = (Get-RV $s 'UninstallString')
          EstimatedSizeKB = (Get-RV $s 'EstimatedSize'); SystemComponent = (Get-RV $s 'SystemComponent'); WindowsInstaller = (Get-RV $s 'WindowsInstaller')
          ParentDisplayName = (Get-RV $s 'ParentDisplayName'); RegOwner = (Get-RV $s 'RegOwner'); RegCompany = (Get-RV $s 'RegCompany'); ProductID = (Get-RV $s 'ProductID')
          Comments = (Get-RV $s 'Comments'); Chave = ($Rotulo + '\' + $n)
        })
      }
      $s.Close()
    }
    $k.Close()
  }
  foreach ($v in $script:Views) {
    Read-Uninstall $script:HKLM[$v.Rot] 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall' ("HKLM(" + $v.Rot + ")\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall") ('Maquina ' + $v.Rot + ' bits')
  }
  foreach ($sid in $script:SidsCarregados) {
    $chaveLeitura = $sid
    if ($script:HiveAlias -and $script:HiveAlias.ContainsKey($sid)) { $chaveLeitura = $script:HiveAlias[$sid] }
    $antes = $script:Programas.Count
    $uNome = Get-UsuarioPorSid $sid
    if (-not $uNome) { $uNome = Get-UsuarioPorSid $chaveLeitura }
    Read-Uninstall $script:HKU "$chaveLeitura\Software\Microsoft\Windows\CurrentVersion\Uninstall" "HKU\$chaveLeitura\Software\Microsoft\Windows\CurrentVersion\Uninstall" ("Usuario " + $uNome + " " + $chaveLeitura)
    Read-Uninstall $script:HKU "$chaveLeitura\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" "HKU\$chaveLeitura\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall" ("Usuario " + $uNome + " " + $chaveLeitura + " 32b")
    Write-Registro ("  HKU\{0}: {1} programa(s)" -f $chaveLeitura, ($script:Programas.Count - $antes))
  }
  $naoCarregados = @($script:Perfis | Where-Object { -not $_.HiveCarregado } | ForEach-Object { $_.Usuario })
  if ($naoCarregados.Count -gt 0) { Write-Registro ("  Perfis sem hive carregado (programas instalados 'so para o usuario' NAO lidos): " + ($naoCarregados -join ', ')) 'AVISO' }
  Save-Csv '03_programas_todos.csv' ($script:Programas | Sort-Object DisplayName) 'Todos os programas (registro Uninstall)'
  Save-Csv '04_programas_fabricantes.csv' ($script:Programas | Where-Object { $script:RxFab.IsMatch($_.DisplayName) -or $script:RxFab.IsMatch($_.Publisher) } | Sort-Object DisplayName) 'Programas das autoras (Autodesk / Corel-Alludo-Parallels)'
}

Invoke-Secao 'Registro dos fabricantes: licenca/serial/produto' {
  $lin = New-Object System.Collections.ArrayList
  $rxNome = New-Object System.Text.RegularExpressions.Regex ('serial|productkey|product ?key|prodkey|licen|activ|regist|sku|edition|subscri|trial|server|productcode|productname|product ?id|release|version|install(date|path|dir|location)|language|\bpid\b|lic_|flex|owner|company|user ?name|email', $rxOpt)
  $rxChave = New-Object System.Text.RegularExpressions.Regex ('licen|regist|serial|\\adlm|\\clm|activation|FLEXlm', $rxOpt)
  $raizes = $script:RaizesRegistroLicenca
  foreach ($v in $script:Views) {
    foreach ($r in $raizes) {
      $res = Read-RegTree -Base $script:HKLM[$v.Rot] -Path "SOFTWARE\$r" -Rotulo ("HKLM(" + $v.Rot + ")") -RxNome $rxNome -RxChave $rxChave -MaxProf 12 -Segundos 45 -MaxLinhas 40000 -Saida $lin
      if ($res -ne 'INEXISTENTE_OU_NEGADO') { Write-Registro ("  HKLM({0})\SOFTWARE\{1}: {2}" -f $v.Rot, $r, $res) }
    }
  }
  foreach ($sid in $script:SidsCarregados) {
    foreach ($r in $raizes) {
      $res = Read-RegTree -Base $script:HKU -Path "$sid\Software\$r" -Rotulo 'HKU' -RxNome $rxNome -RxChave $rxChave -MaxProf 12 -Segundos 30 -MaxLinhas 60000 -Saida $lin
      if ($res -ne 'INEXISTENTE_OU_NEGADO') { Write-Registro ("  HKU\{0}\Software\{1}: {2}" -f $sid, $r, $res) }
    }
  }
  Save-Csv '05_registro_licencas.csv' $lin 'Valores de registro relacionados a licenca/serial/produto (somente leitura)'
  $env2 = New-Object System.Collections.ArrayList
  foreach ($esc in 'Machine', 'User', 'Process') {
    try {
      $vars = [Environment]::GetEnvironmentVariables([System.EnvironmentVariableTarget]$esc)
      foreach ($k in $vars.Keys) { if ([string]$k -match 'LICEN|FLEX|ADSK|LM_|COREL|AUTODESK') { [void]$env2.Add([pscustomobject]@{ Escopo = $esc; Nome = $k; Valor = $vars[$k] }) } }
    } catch { }
  }
  Save-Csv '05b_variaveis_ambiente_licenca.csv' $env2 'Variaveis de ambiente de licenciamento (ex.: ADSKFLEX_LICENSE_FILE = servidor de rede)'
}

Invoke-Secao 'Servicos, processos e portas' {
  $svcLin = @(Get-CimInstance Win32_Service -OperationTimeoutSec 60 | Where-Object { $script:RxLicServ.IsMatch([string]$_.Name + ' ' + [string]$_.DisplayName + ' ' + [string]$_.PathName) -or $script:RxForte.IsMatch([string]$_.PathName) } |
    ForEach-Object { [pscustomobject]@{ Nome = $_.Name; NomeExibicao = $_.DisplayName; Estado = $_.State; Inicializacao = $_.StartMode; Executavel = $_.PathName; Conta = $_.StartName } })
  foreach ($sv in $svcLin) { [void]$script:ServicosFab.Add($sv) }
  Save-Csv '06_servicos.csv' $svcLin 'Servicos de licenciamento/fabricantes'
  Save-Csv '06b_processos.csv' (Get-CimInstance Win32_Process -OperationTimeoutSec 60 | Where-Object { $script:RxLicServ.IsMatch([string]$_.Name + ' ' + [string]$_.ExecutablePath) -or $script:RxForte.IsMatch([string]$_.Name + ' ' + [string]$_.ExecutablePath) } |
    ForEach-Object { [pscustomobject]@{ PID = $_.ProcessId; Nome = $_.Name; Executavel = $_.ExecutablePath; LinhaComando = $_.CommandLine; Inicio = (Format-Data $_.CreationDate) } }) 'Processos em execucao relacionados'
  $portas = $null
  try {
    $portas = Invoke-ComLimite -Segundos 30 -Bloco {
      Get-NetTCPConnection -State Listen -ErrorAction Stop | ForEach-Object {
        $pn = ''; try { $pn = (Get-Process -Id $_.OwningProcess -ErrorAction Stop).ProcessName } catch { }
        [pscustomobject]@{ Endereco = [string]$_.LocalAddress; Porta = $_.LocalPort; PID = $_.OwningProcess; Processo = $pn; PossivelFlexLM = (($_.LocalPort -ge 27000 -and $_.LocalPort -le 27009) -or $_.LocalPort -eq 2080) }
      }
    }
  } catch { Write-Registro ("  Get-NetTCPConnection: " + $_.Exception.Message) 'AVISO' }
  if ($null -ne $portas -and @($portas).Count -gt 0) { Save-Csv '09c_portas_escuta.csv' $portas 'Portas TCP em escuta' }
  else {
    $txt = (& "$env:SystemRoot\System32\netstat.exe" -ano 2>$null) -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $script:Out '09c_portas_escuta_netstat.txt'), $txt, $script:Utf8Bom)
    Write-Registro '  portas: usado netstat -ano (fallback)'
  }
}

Invoke-Secao 'Hosts e firewall (bloqueio de ativacao)' {
  $dbp = Get-RV (Open-Key $hklmN 'SYSTEM\CurrentControlSet\Services\Tcpip\Parameters') 'DataBasePath'
  if (-not $dbp) { $dbp = '%SystemRoot%\System32\drivers\etc' }
  $dbp = [Environment]::ExpandEnvironmentVariables($dbp)
  $hostsPath = Join-Path $dbp 'hosts'
  Write-Registro "  DataBasePath: $dbp"
  if ([System.IO.File]::Exists($hostsPath)) {
    $bytes = [System.IO.File]::ReadAllBytes($hostsPath)
    [System.IO.File]::WriteAllBytes((Join-Path $script:Out '08_hosts_copia_integral.txt'), $bytes)
    $fi = New-Object System.IO.FileInfo $hostsPath
    Write-Registro ("  hosts: {0} bytes, criado {1}, modificado {2}" -f $fi.Length, (Format-Data $fi.CreationTime), (Format-Data $fi.LastWriteTime))
    $rxDom = New-Object System.Text.RegularExpressions.Regex ('autodesk|adsk|corel|alludo|parallels|winzip|flexnet|flexera|macrovision|revenera|cdgs|adobe|creativecloud|microsoft|office365|office\.com|activation\.sls|kms|licen[cs]e|genuine', $rxOpt)
    $n = 0; $lin = New-Object System.Collections.ArrayList
    foreach ($l in ([System.Text.Encoding]::UTF8.GetString($bytes) -split "`r?`n")) {
      $n++
      $t = $l.Trim()
      if ($t -eq '' -or $t.StartsWith('#')) { continue }
      if ($rxDom.IsMatch($t)) {
        $hl = [pscustomobject]@{ Linha = $n; Conteudo = $t; Arquivo = $hostsPath; HostsModificado = (Format-Data $fi.LastWriteTime) }
        [void]$lin.Add($hl)
        [void]$script:HostsFabLinhas.Add($hl)
      }
    }
    Save-Csv '08b_hosts_linhas_fabricantes.csv' $lin 'Linhas ativas do hosts com dominios dos fabricantes (bloqueio de validacao)'
  } else { Write-Registro "  hosts nao encontrado em $hostsPath" 'AVISO' }

  # Firewall pelo registro (rapido, sem modulos): regras locais e de GPO
  $fw = New-Object System.Collections.ArrayList
  $rxFwTxt = New-Object System.Text.RegularExpressions.Regex (($Fabricantes + '|adsk|acad\.exe|corel|cdgs|flex|lmgrd|licens|' + $IndiciosFortes), $rxOpt)
  foreach ($loc in @(@('SYSTEM\CurrentControlSet\Services\SharedAccess\Parameters\FirewallPolicy\FirewallRules', 'Local'), @('SOFTWARE\Policies\Microsoft\WindowsFirewall\FirewallRules', 'GPO'))) {
    $k = Open-Key $hklmN $loc[0]
    if ($null -eq $k) { continue }
    foreach ($vn in $k.GetValueNames()) {
      $d = [string]$k.GetValue($vn)
      if (-not $rxFwTxt.IsMatch($d)) { continue }
      $campos = @{}
      foreach ($par in $d.Split('|')) { $ix = $par.IndexOf('='); if ($ix -gt 0) { $campos[$par.Substring(0, $ix)] = $par.Substring($ix + 1) } }
      [void]$fw.Add([pscustomobject]@{ Origem = $loc[1]; Acao = $campos['Action']; Ativa = $campos['Active']; Direcao = $campos['Dir']; Programa = $campos['App']; Nome = $campos['Name']; Descricao = $campos['Desc']; IdRegra = $vn; Bruto = $d })
    }
    $k.Close()
  }
  Save-Csv '09_firewall_regras_registro.csv' $fw 'Regras de firewall que citam programas dos fabricantes (Acao=Block indica bloqueio de validacao)'
  # Conferencia cruzada com o cmdlet (pode ser lento: tempo limite); fallback netsh
  try {
    $r = Invoke-ComLimite -Segundos 60 -Argumentos @($rxFwTxt.ToString()) -Bloco {
      param($rx)
      $apps = @{}
      Get-NetFirewallApplicationFilter -All -ErrorAction Stop | ForEach-Object { $apps[$_.InstanceID] = $_.Program }
      Get-NetFirewallRule -All -ErrorAction Stop | ForEach-Object {
        $prog = [string]$apps[$_.InstanceID]
        if (($prog + ' ' + $_.DisplayName) -match $rx) {
          [pscustomobject]@{ Nome = $_.DisplayName; Direcao = [string]$_.Direction; Acao = [string]$_.Action; Habilitada = [string]$_.Enabled; Perfil = [string]$_.Profile; Programa = $prog; Origem = [string]$_.PolicyStoreSourceType; Id = $_.InstanceID }
        }
      }
    }
    Save-Csv '09b_firewall_regras_cmdlet.csv' $r 'Regras de firewall (Get-NetFirewallRule) que citam os fabricantes'
  } catch {
    Write-Registro ("  Get-NetFirewallRule falhou ({0}); usando netsh" -f $_.Exception.Message) 'AVISO'
    $txt = (& "$env:SystemRoot\System32\netsh.exe" advfirewall firewall show rule name=all verbose 2>$null) -join "`r`n"
    [System.IO.File]::WriteAllText((Join-Path $script:Out '09b_firewall_netsh_completo.txt'), $txt, $script:Utf8Bom)
  }
}

# Le eventos sem deixar uma falha (log negado, filtro invalido) derrubar a secao inteira.
# Status: OK | SEM_EVENTOS | NEGADO | ERRO: <msg>. Nao depende do idioma do Windows (usa o tipo/FQID da excecao).
function Get-EventosSeguro {
  param([hashtable]$Filtro, [int]$Max = 1000, [string]$Rotulo = '')
  $r = [pscustomobject]@{ Eventos = @(); Status = 'OK' }
  try { $r.Eventos = @(Get-WinEvent -FilterHashtable $Filtro -MaxEvents $Max -ErrorAction Stop) }
  catch {
    $ex = $_.Exception; while ($ex.InnerException) { if ($ex -is [System.UnauthorizedAccessException]) { break }; $ex = $ex.InnerException }
    if ([string]$_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { $r.Status = 'SEM_EVENTOS' }
    elseif ($_.Exception -is [System.UnauthorizedAccessException] -or $ex -is [System.UnauthorizedAccessException] -or $_.CategoryInfo.Category -eq 'PermissionDenied') { $r.Status = 'NEGADO' }
    else { $r.Status = 'ERRO: ' + ($_.Exception.Message -replace '\s+', ' ') }
  }
  if ($r.Status -eq 'NEGADO' -or $r.Status -like 'ERRO*') {
    [void]$script:SecaoParcial.Add(('{0}: {1}' -f $Rotulo, $r.Status))
    Write-Registro ("  {0}: {1}" -f $Rotulo, $r.Status) 'AVISO'
  }
  return $r
}

Invoke-Secao 'Eventos: instalacoes/remocoes MSI, limpeza de logs, servicos' {
  $tipos = @{ 1033 = 'Instalacao (status)'; 1034 = 'REMOCAO'; 1035 = 'Reconfiguracao'; 1036 = 'Atualizacao'; 11707 = 'Instalacao concluida'; 11708 = 'Instalacao falhou'; 11724 = 'REMOCAO concluida'; 11725 = 'Remocao falhou'; 11728 = 'Configuracao concluida' }
  $q = Get-EventosSeguro -Filtro @{ LogName = 'Application'; ProviderName = 'MsiInstaller'; Id = 1033, 1034, 1035, 1036, 11707, 11708, 11724, 11725, 11728; StartTime = $script:DesdeEventos } -Max $MaxEventos -Rotulo 'Application/MsiInstaller'
  $ev = $q.Eventos
  $lin = foreach ($e in $ev) {
    $msg = $e.Message
    if ([string]::IsNullOrEmpty($msg)) { $msg = (@($e.Properties | ForEach-Object { [string]$_.Value }) -join ' | ') }
    $msg = ($msg -replace '\s+', ' ')
    $usr = ''; if ($e.UserId) { $usr = $e.UserId.Value }
    [pscustomobject]@{ DataLocal = (Format-Data $e.TimeCreated); DataUTC = (Format-DataUtc $e.TimeCreated); Id = $e.Id; Tipo = $tipos[[int]$e.Id]; Fabricante = $script:RxFab.IsMatch($msg); SID = $usr; Usuario = (Get-UsuarioPorSid $usr); Mensagem = $msg.Substring(0, [math]::Min(1500, $msg.Length)) }
  }
  Write-Registro ("  {0} eventos MsiInstaller na janela de {1} dias (limite {2}) - leitura: {3}" -f @($ev).Count, $DiasEventos, $MaxEventos, $q.Status)
  Save-Csv '12_eventos_msi_todos.csv' $lin ('Eventos MsiInstaller (instalacao/remocao) na janela - leitura do log: ' + $q.Status)
  $linFab = @($lin | Where-Object { $_.Fabricante })
  foreach ($evf in $linFab) {
    if ([string]$evf.Tipo -match 'REMOCAO') { [void]$script:RemocoesMsiFab.Add($evf) }
  }
  Save-Csv '12a_eventos_msi_fabricantes.csv' $linFab 'Eventos MsiInstaller dos produtos das autoras'

  # Cobertura: cada log em try/catch proprio (sem admin, Security sempre falha; via logon de rede, todos falham)
  $logs = New-Object System.Collections.ArrayList
  foreach ($ln in 'Application', 'System', 'Security', 'Setup', 'Microsoft-Windows-Windows Defender/Operational') {
    $info = $null; $old = $null; $obsL = ''
    try { $info = Get-WinEvent -ListLog $ln -ErrorAction Stop } catch { $obsL = 'config: ' + ($_.Exception.Message -replace '\s+', ' ') }
    try { $old = Get-WinEvent -LogName $ln -Oldest -MaxEvents 1 -ErrorAction Stop }
    catch {
      if ([string]$_.FullyQualifiedErrorId -like 'NoMatchingEventsFound*') { $obsL = ($obsL + ' log vazio').Trim() }
      elseif ($ln -eq 'Security' -and -not $script:IsAdmin) { $obsL = 'indisponivel sem admin' }
      else { $obsL = ($obsL + ' leitura: ' + ($_.Exception.Message -replace '\s+', ' ')).Trim(); [void]$script:SecaoParcial.Add("cobertura ${ln}: sem acesso") }
    }
    $rc = $null; $fs = $null; $mx = $null; $md = ''; $lw = ''
    if ($info) { $rc = $info.RecordCount; $fs = $info.FileSize; $mx = $info.MaximumSizeInBytes; $md = [string]$info.LogMode; $lw = (Format-Data $info.LastWriteTime) }
    $tOld = ''; if ($old) { $tOld = (Format-Data $old.TimeCreated) }
    [void]$logs.Add([pscustomobject]@{ Log = $ln; Acessivel = ($null -ne $old); Registros = $rc; TamanhoBytes = $fs; MaximoBytes = $mx; Modo = $md; EventoMaisAntigo = $tOld; UltimaGravacao = $lw; Observacao = $obsL })
  }
  Save-Csv '12b_logs_eventos_cobertura.csv' $logs 'Cobertura dos logs (evento mais antigo indica ate onde ha historico)'

  $limp = New-Object System.Collections.ArrayList
  $q = Get-EventosSeguro -Filtro @{ LogName = 'System'; Id = 104; StartTime = $script:DesdeEventos } -Max 500 -Rotulo 'System/104'
  foreach ($e in $q.Eventos) { [void]$limp.Add([pscustomobject]@{ DataLocal = (Format-Data $e.TimeCreated); Log = 'System'; Id = 104; Mensagem = ($e.Message -replace '\s+', ' ') }) }
  if ($script:IsAdmin) {
    $q = Get-EventosSeguro -Filtro @{ LogName = 'Security'; ProviderName = 'Microsoft-Windows-Eventlog'; Id = 1102; StartTime = $script:DesdeEventos } -Max 500 -Rotulo 'Security/1102'
    foreach ($e in $q.Eventos) { [void]$limp.Add([pscustomobject]@{ DataLocal = (Format-Data $e.TimeCreated); Log = 'Security'; Id = 1102; Mensagem = ($e.Message -replace '\s+', ' ') }) }
  } else { Write-Registro '  Security 1102 (limpeza do log de seguranca) nao lido: requer administrador' 'AVISO' }
  Save-Csv '12c_eventos_limpeza_logs.csv' $limp 'Eventos de limpeza de log (System 104 / Security 1102)'
  $q = Get-EventosSeguro -Filtro @{ LogName = 'System'; Id = 7045; StartTime = $script:DesdeEventos } -Max 2000 -Rotulo 'System/7045'
  $svc = foreach ($e in $q.Eventos) {
    $m = ($e.Message -replace '\s+', ' ')
    if ($script:RxLicServ.IsMatch($m) -or $script:RxForte.IsMatch($m)) { [pscustomobject]@{ DataLocal = (Format-Data $e.TimeCreated); Id = 7045; Mensagem = $m } }
  }
  Save-Csv '12d_eventos_servicos_instalados.csv' $svc 'Servicos instalados (7045) relacionados a fabricantes/licenciamento'
}

Invoke-Secao 'Windows Defender: deteccoes e exclusoes' {
  $lin = New-Object System.Collections.ArrayList
  $qd = Get-EventosSeguro -Filtro @{ LogName = 'Microsoft-Windows-Windows Defender/Operational'; Id = 1006, 1007, 1116, 1117, 1118, 1119, 5001, 5007; StartTime = $script:DesdeEventos } -Max 3000 -Rotulo 'Defender/Operational'
  foreach ($e in $qd.Eventos) {
    $m = ($e.Message -replace '\s+', ' ')
    if ($e.Id -eq 5007 -and $m -notmatch 'Exclusion') { continue }
    [void]$lin.Add([pscustomobject]@{ DataLocal = (Format-Data $e.TimeCreated); DataUTC = (Format-DataUtc $e.TimeCreated); Id = $e.Id; Relacionado = ($script:RxFab.IsMatch($m) -or $script:RxForte.IsMatch($m) -or $m -match 'HackTool|Keygen|Crack|Patch'); Mensagem = $m.Substring(0, [math]::Min(2000, $m.Length)) })
  }
  Save-Csv '17_defender_eventos.csv' $lin 'Defender: deteccoes (1116/1117...), protecao desligada (5001), exclusoes adicionadas (5007)'
  $cmdletsOk = $false
  if ($script:IsAdmin) {
    try {
      $r = Invoke-ComLimite -Segundos 45 -Bloco {
        $nomes = @{}; Get-MpThreat -ErrorAction SilentlyContinue | ForEach-Object { $nomes[[string]$_.ThreatID] = $_.ThreatName }
        Get-MpThreatDetection -ErrorAction Stop | ForEach-Object { [pscustomobject]@{ Ameaca = $nomes[[string]$_.ThreatID]; ThreatID = $_.ThreatID; Deteccao = $_.InitialDetectionTime; UltimaAcao = $_.LastThreatStatusChangeTime; Processo = $_.ProcessName; Usuario = $_.DomainUser; Recursos = (@($_.Resources) -join ' | '); AcaoOk = $_.ActionSuccess } }
      }
      Save-Csv '17b_defender_historico.csv' $r 'Historico de deteccoes do Defender (Get-MpThreatDetection)'
      $pref = Invoke-ComLimite -Segundos 30 -Bloco { $p = Get-MpPreference -ErrorAction Stop; [pscustomobject]@{ Fonte = 'Cmdlet_Get-MpPreference'; ExclusaoCaminhos = (@($p.ExclusionPath) -join ' | '); ExclusaoProcessos = (@($p.ExclusionProcess) -join ' | '); ExclusaoExtensoes = (@($p.ExclusionExtension) -join ' | '); TempoRealDesligado = $p.DisableRealtimeMonitoring } }
      Save-Csv '17c_defender_exclusoes.csv' $pref 'Exclusoes configuradas no Defender (cracks costumam pedir exclusao)'
      $cmdletsOk = $true
    } catch {
      Write-Registro ("  Defender (cmdlets): " + $_.Exception.Message + " - tentando fallback via registro") 'AVISO'
      [void]$script:SecaoParcial.Add('cmdlets Defender falharam; usando registro')
    }
  } else { Write-Registro '  Historico Defender via cmdlet: requer administrador (pulado)' 'AVISO' }

  # v1.4 fallback: exclusoes e status no registro (cobre 0x800106ba / servico parado)
  if (-not $cmdletsOk) {
    $excLin = New-Object System.Collections.ArrayList
    $paths = New-Object System.Collections.ArrayList
    $procs = New-Object System.Collections.ArrayList
    $exts = New-Object System.Collections.ArrayList
    foreach ($v in $script:Views) {
      $base = $script:HKLM[$v.Rot]
      foreach ($raizExc in @(
        'SOFTWARE\Microsoft\Windows Defender\Exclusions',
        'SOFTWARE\Policies\Microsoft\Windows Defender\Exclusions'
      )) {
        foreach ($sub in 'Paths', 'Processes', 'Extensions', 'TemporaryPaths') {
          $k = Open-Key $base ($raizExc + '\' + $sub)
          if ($null -eq $k) { continue }
          foreach ($vn in $k.GetValueNames()) {
            $val = Get-RV $k $vn
            $item = if ($val) { $val } else { $vn }
            if ($sub -match 'Path') { [void]$paths.Add($item) }
            elseif ($sub -match 'Process') { [void]$procs.Add($item) }
            else { [void]$exts.Add($item) }
            [void]$excLin.Add([pscustomobject]@{ Fonte = 'REGISTRO_FALLBACK'; Visao = $v.Rot; Chave = ($raizExc + '\' + $sub); Nome = $vn; Valor = $val })
          }
          $k.Close()
        }
      }
    }
    $rtp = ''
    $dis = ''
    foreach ($v in $script:Views) {
      $k = Open-Key $script:HKLM[$v.Rot] 'SOFTWARE\Microsoft\Windows Defender\Real-Time Protection'
      if ($k) { $rtp = Get-RV $k 'DisableRealtimeMonitoring'; $k.Close(); if ($rtp -ne '') { break } }
      $k2 = Open-Key $script:HKLM[$v.Rot] 'SOFTWARE\Policies\Microsoft\Windows Defender'
      if ($k2) { $dis = Get-RV $k2 'DisableAntiSpyware'; $k2.Close() }
    }
    $resumo = [pscustomobject]@{
      Fonte = 'REGISTRO_FALLBACK'
      ExclusaoCaminhos = (@($paths | Select-Object -Unique) -join ' | ')
      ExclusaoProcessos = (@($procs | Select-Object -Unique) -join ' | ')
      ExclusaoExtensoes = (@($exts | Select-Object -Unique) -join ' | ')
      TempoRealDesligado = $rtp
      DisableAntiSpyware = $dis
      ItensRegistro = $excLin.Count
    }
    Save-Csv '17c_defender_exclusoes.csv' $resumo 'Exclusoes Defender via REGISTRO (fallback quando Get-MpPreference falha, ex. 0x800106ba)'
    Save-Csv '17d_defender_exclusoes_registro_detalhe.csv' $excLin 'Detalhe das exclusoes lidas do registro (fallback)'
    Write-Registro ("  fallback registro: {0} valor(es) de exclusao; DisableRealtime={1}" -f $excLin.Count, $rtp)
  }
}


Invoke-Secao 'Arquivos de licenca e pastas dos fabricantes' {
  $lic = New-Object System.Collections.ArrayList
  foreach ($rel in $script:LicencaProgramData) {
    [void]$lic.Add(@((Join-Path $script:PD $rel), ('ProgramData\' + $rel)))
  }
  if ($script:CPF86) { [void]$lic.Add(@((Join-Path $script:CPF86 'Macrovision Shared\FlexNet Publisher'), 'CommonFiles(x86)\Macrovision Shared\FlexNet Publisher')) }
  foreach ($p in $script:Perfis) {
    foreach ($rel in $script:LicencaProgramData) {
      $leaf = ($rel -split '[\\/]')[0]
      if ($leaf) {
        [void]$lic.Add(@((Join-Path $p.Caminho ('AppData\Local\' + $leaf)), ('perfil:' + $p.Usuario + '\Local\' + $leaf)))
        [void]$lic.Add(@((Join-Path $p.Caminho ('AppData\Roaming\' + $leaf)), ('perfil:' + $p.Usuario + '\Roaming\' + $leaf)))
      }
    }
  }
  $swL = [System.Diagnostics.Stopwatch]::StartNew()
  foreach ($x in $lic) {
    if ($swL.Elapsed.TotalSeconds -ge 90) { Write-Registro '  tempo da listagem de licencas esgotado' 'AVISO'; break }
    Invoke-Varredura -Raiz $x[0] -Modo 'licenca' -ProfMax 6 -Segundos 30 -Rotulo $x[1]
    if ($script:Achados['Licenca'].Count -ge 20000) { Write-Registro '  limite de 20000 arquivos de licenca' 'AVISO'; break }
  }
  # SHA-256 (<= 5 MB), previa de texto de LGS.data / *.lic, copia opcional para o pendrive
  $dirCopia = Join-Path $script:Out 'licencas_copias'
  $i = 0
  foreach ($r in $script:Achados['Licenca']) {
    $i++
    $r | Add-Member -NotePropertyName SHA256 -NotePropertyValue '' -Force
    $r | Add-Member -NotePropertyName Previa -NotePropertyValue '' -Force
    $r | Add-Member -NotePropertyName CopiaNoPendrive -NotePropertyValue '' -Force
    if ($swL.Elapsed.TotalSeconds -ge 150) { $r.SHA256 = 'NAO_CALCULADO_TEMPO'; continue }
    if ($null -ne $r.TamanhoBytes -and $r.TamanhoBytes -le 5MB) {
      try { $r.SHA256 = (Get-FileHash -LiteralPath $r.Caminho -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $r.SHA256 = 'ERRO_LEITURA' }
      if ($r.Nome -match '^(LGS\.data|.*\.lic|.*\.licx)$' -and $r.TamanhoBytes -le 16384) {
        try { $txt = (([System.IO.File]::ReadAllText($r.Caminho)) -replace '[^\x20-\x7E\r\n\t]', '.' -replace '\s+', ' '); $r.Previa = $txt.Substring(0, [math]::Min(1000, $txt.Length)) } catch { }
      }
      if ($CopiarLicencas) {
        try {
          [void][System.IO.Directory]::CreateDirectory($dirCopia)
          $dst = Join-Path $dirCopia ('{0:D5}_{1}' -f $i, $r.Nome)
          [System.IO.File]::Copy($r.Caminho, $dst, $false)
          $r.CopiaNoPendrive = (Split-Path $dst -Leaf)
        } catch { $r.CopiaNoPendrive = 'ERRO' }
      }
    } else { $r.SHA256 = 'NAO_CALCULADO_TAMANHO' }
  }
  Save-Csv '07_arquivos_licenca.csv' $script:Achados['Licenca'] 'Arquivos em pastas de licenciamento (metadados + SHA-256; conteudo nao alterado)'

  # Pastas dos fabricantes (instalacao atual ou residuos de desinstalacao)
  $pastas = New-Object System.Collections.ArrayList
  $bases = New-Object System.Collections.Generic.List[string]
  foreach ($b in @($script:PF64, $script:PF86, $script:CPF64, $script:CPF86, $script:PD)) { if ($b -and -not $bases.Contains($b)) { $bases.Add($b) } }
  foreach ($p in $script:Perfis) { $bases.Add((Join-Path $p.Caminho 'AppData\Roaming')); $bases.Add((Join-Path $p.Caminho 'AppData\Local')) }
  foreach ($b in $bases) {
    try {
      foreach ($d in (New-Object System.IO.DirectoryInfo $b).EnumerateDirectories()) {
        if (-not $script:RxFab.IsMatch($d.Name) -and $d.Name -notmatch 'Autodesk Shared|FLEXnet|Macrovision') { continue }
        [void]$pastas.Add([pscustomobject]@{ Nivel = 1; Caminho = $d.FullName; Criada = (Format-Data $d.CreationTime); Modificada = (Format-Data $d.LastWriteTime); Reparse = (($d.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) })
        try { foreach ($s in $d.EnumerateDirectories()) { [void]$pastas.Add([pscustomobject]@{ Nivel = 2; Caminho = $s.FullName; Criada = (Format-Data $s.CreationTime); Modificada = (Format-Data $s.LastWriteTime); Reparse = (($s.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) }) } } catch { }
      }
    } catch { }
  }
  Save-Csv '18_pastas_fabricantes.csv' $pastas 'Pastas dos fabricantes (comparar com 04_programas: pasta sem programa = possivel residuo de desinstalacao)'
}

Invoke-Secao 'Indicios de crack nas pastas dos programas (nomes, DLLs, assinaturas)' {
  $raizes = New-Object System.Collections.Generic.List[string]
  foreach ($b in @($script:PF64, $script:PF86)) { if ($b) { foreach ($n in $script:PastasPrograma) { $raizes.Add((Join-Path $b $n)) } } }
  foreach ($b in @($script:CPF64, $script:CPF86)) { if ($b) { foreach ($n in $script:PastasPrograma) { $raizes.Add((Join-Path $b ($n + ' Shared'))); $raizes.Add((Join-Path $b $n)) } } }
  foreach ($pr in $script:Programas) {
    if ($pr.InstallLocation -and ($script:RxFab.IsMatch($pr.DisplayName) -or $script:RxFab.IsMatch($pr.Publisher))) {
      $loc = [Environment]::ExpandEnvironmentVariables($pr.InstallLocation.Trim().Trim('"')).TrimEnd('\')
      if ($loc.Length -gt 3 -and -not $raizes.Contains($loc)) { $raizes.Add($loc) }
    }
  }
  $swF = [System.Diagnostics.Stopwatch]::StartNew()
  foreach ($r in $raizes) {
    $rest = $SegundosFabricante - [int]$swF.Elapsed.TotalSeconds
    if ($rest -le 0) {
      Write-Registro "  tempo esgotado; nao varrida: $r" 'AVISO'
      [void]$script:RaizesStatus.Add([pscustomobject]([ordered]@{ Rotulo = 'programa'; Raiz = $r; Modo = 'fabricante'; Status = 'NAO_VARRIDA_TEMPO'; Pastas = 0; Arquivos = 0; Achados = 0; AcessoNegado = 0; PontosReparseIgnorados = 0; CaminhoLongo = 0; OutrosErros = 0; Segundos = 0 }))
      continue
    }
    Invoke-Varredura -Raiz $r -Modo 'fabricante' -ProfMax 8 -Segundos ([math]::Min(45, $rest)) -Rotulo 'programa'
  }
  Save-Csv '11c_dlls_sistema_em_pasta_programa.csv' $script:Achados['DllSistema'] 'DLLs com nome de DLL do Windows dentro da pasta do programa (tecnica comum de loader/crack; conferir assinatura)'
  # Assinatura digital (Authenticode) + SHA-256 dos candidatos de licenca, DLLs loader e indicios FORTES binarios (v1.4)
  $sig = New-Object System.Collections.ArrayList
  $cands = New-Object System.Collections.Generic.List[string]
  foreach ($c in $script:Achados['Candidato']) { if (-not $cands.Contains($c)) { $cands.Add($c) } }
  foreach ($d in $script:Achados['DllSistema']) { if (-not $cands.Contains($d.Caminho)) { $cands.Add($d.Caminho) } }
  foreach ($f in $script:Achados['Forte']) {
    if ($f.Nome -match '(?i)\.(exe|dll|sys|ocx|scr)$' -and -not $cands.Contains($f.Caminho)) { $cands.Add($f.Caminho) }
  }
  $dirSus = Join-Path $script:Out 'suspeitos_copias'
  $swS = [System.Diagnostics.Stopwatch]::StartNew()
  $iCopia = 0
  foreach ($c in $cands) {
    if ($swS.Elapsed.TotalSeconds -ge $SegundosAssinaturas -or $sig.Count -ge 500) { Write-Registro ("  limite de verificacao de assinaturas atingido ({0} de {1})" -f $sig.Count, $cands.Count) 'AVISO'; break }
    if (-not (Test-Path -LiteralPath $c)) { continue }
    $s = Get-AuthenticodeSignature -LiteralPath $c -ErrorAction SilentlyContinue
    $vi = $null; try { $vi = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($c) } catch { }
    $fi = New-Object System.IO.FileInfo $c
    $sub = ''; $iss = ''; if ($s -and $s.SignerCertificate) { $sub = $s.SignerCertificate.Subject; $iss = $s.SignerCertificate.Issuer }
    $fv = ''; $pn = ''; $cn = ''; $on = ''; if ($vi) { $fv = $vi.FileVersion; $pn = $vi.ProductName; $cn = $vi.CompanyName; $on = $vi.OriginalFilename }
    $sha = ''
    if ($fi.Length -le $HashMaxBytes -and $swS.Elapsed.TotalSeconds -lt ($SegundosAssinaturas + $SegundosHash)) {
      try { $sha = (Get-FileHash -LiteralPath $c -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $sha = 'ERRO_LEITURA' }
    } else { $sha = 'NAO_CALCULADO' }
    $st = [string]$s.Status
    $suspeito = ($st -ne 'Valid')
    $copia = ''
    if ($CopiarSuspeitos -and $suspeito -and $fi.Length -gt 0 -and $fi.Length -le $CopiaSuspeitoMaxBytes) {
      try {
        [void][System.IO.Directory]::CreateDirectory($dirSus)
        $iCopia++
        $dst = Join-Path $dirSus ('{0:D4}_{1}' -f $iCopia, $fi.Name)
        [System.IO.File]::Copy($c, $dst, $false)
        $copia = (Split-Path $dst -Leaf)
      } catch { $copia = 'ERRO' }
    }
    [void]$sig.Add([pscustomobject]@{
      Arquivo = $c; SHA256 = $sha; StatusAssinatura = $st; Suspeito = $suspeito; Signatario = $sub; Emissor = $iss
      Versao = $fv; Produto = $pn; Empresa = $cn; NomeOriginal = $on; TamanhoBytes = $fi.Length
      Criado = (Format-Data $fi.CreationTime); Modificado = (Format-Data $fi.LastWriteTime); CopiaNoPendrive = $copia
    })
  }
  $script:NaoAssinados = @($sig | Where-Object { $_.Suspeito }).Count
  Save-Csv '11d_assinaturas_binarios.csv' $sig 'SHA-256 + Authenticode (licenciamento, DLLs loader e indicios FORTES binarios); -CopiarSuspeitos copia os suspeitos'
}


Invoke-Secao 'Arquivos de projeto, indicios e instaladores (varredura limitada)' {
  $script:SwArquivos.Start()
  $rxExclPerfil = New-Object System.Text.RegularExpressions.Regex ('\\AppData\\Local\\(Microsoft|Packages|Google|Mozilla|BraveSoftware|Comms|D3DSCache|CrashDumps|NVIDIA|Steam)(\\|$)|\\AppData\\Roaming\\(Mozilla|Microsoft\\Windows\\Recent|Code|npm)(\\|$)|\\(node_modules|\.git|\.vs|__pycache__)(\\|$)', $rxOpt)
  # 1) Pastas prioritarias de cada perfil (inclui pastas redirecionadas lidas do hive, se carregado)
  foreach ($p in $script:Perfis) {
    $prior = New-Object System.Collections.Generic.List[string]
    foreach ($n in 'Desktop', 'Documents', 'Downloads') { $prior.Add((Join-Path $p.Caminho $n)) }
    try { foreach ($od in [System.IO.Directory]::GetDirectories($p.Caminho, 'OneDrive*')) { $prior.Add($od) } } catch { }
    if ($p.HiveCarregado -and $p.SID) {
      $usf = Open-Key $script:HKU ($p.SID + '\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders')
      if ($usf) {
        foreach ($vn in 'Desktop', 'Personal', '{374DE290-123F-4565-9164-39C4925E467B}') {
          $v = [string]$usf.GetValue($vn, $null, [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
          if ($v) { $v = $v -replace '%USERPROFILE%', $p.Caminho.Replace('$', '$$'); $v = [Environment]::ExpandEnvironmentVariables($v); if (-not $prior.Contains($v)) { $prior.Add($v) } }
        }
        $usf.Close()
      }
    }
    foreach ($d in $prior) { if ([System.IO.Directory]::Exists($d)) { Invoke-Varredura -Raiz $d -Modo 'projeto' -ProfMax $ProfundidadePerfil -Segundos $SegundosPorRaiz -Rotulo ('perfil:' + $p.Usuario + ':' + (Split-Path $d -Leaf)) -RxExcluirDir $rxExclPerfil -ContaNoTotal } }
  }
  # 2) Restante de cada perfil (pastas ja varridas nao sao repetidas)
  foreach ($p in $script:Perfis) { Invoke-Varredura -Raiz $p.Caminho -Modo 'projeto' -ProfMax $ProfundidadePerfil -Segundos $SegundosPorRaiz -Rotulo ('perfil:' + $p.Usuario) -RxExcluirDir $rxExclPerfil -ContaNoTotal }
  # 3) Unidades fixas (exceto a do pendrive), a partir da raiz com profundidade limitada
  $unidades = @([System.IO.DriveInfo]::GetDrives() | Where-Object { $_.DriveType -eq [System.IO.DriveType]::Fixed -and $_.IsReady -and ($_.RootDirectory.FullName -ine $raizDestino) -and ($_.RootDirectory.FullName -ine $raizScript) })
  foreach ($u in $unidades) {
    $raiz = $u.RootDirectory.FullName
    $lst = 'Windows|Program Files|Program Files \(x86\)|ProgramData|System Volume Information|\$Recycle\.Bin|\$WinREAgent|\$Windows\.~BT|\$Windows\.~WS|\$SysReset|Recovery|Config\.Msi|MSOCache|PerfLogs|OneDriveTemp'
    if ($raiz -ieq $raizSistema) { $lst += '|Users' }
    $rxEx = New-Object System.Text.RegularExpressions.Regex (('^[A-Za-z]:\\(' + $lst + ')(\\|$)|^[A-Za-z]:\\Windows\.old\\(Windows|Program Files[^\\]*|ProgramData)(\\|$)'), $rxOpt)
    Invoke-Varredura -Raiz $raiz -Modo 'projeto' -ProfMax $ProfundidadeDisco -Segundos $SegundosPorRaiz -Rotulo ('disco:' + $raiz) -RxExcluirDir $rxEx -ContaNoTotal
  }
  # 4) Lixeira de cada unidade fixa (itens excluidos e ainda nao esvaziados)
  foreach ($u in $unidades) { Invoke-Varredura -Raiz (Join-Path $u.RootDirectory.FullName '$Recycle.Bin') -Modo 'lixeira' -ProfMax 6 -Segundos 30 -Rotulo ('lixeira:' + $u.Name) }
  $script:SwArquivos.Stop()
  Write-Registro ("  tempo de varredura de perfis/discos: {0:N0}s (limite {1}s)" -f $script:SwArquivos.Elapsed.TotalSeconds, $SegundosTotalArquivos)

  if ($HashArquivosProjeto) {
    Write-Registro '  -HashArquivosProjeto ativo: le o conteudo dos arquivos (pode atualizar a data de ultimo acesso)' 'AVISO'
    $swH = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($r in $script:Achados['Projeto']) {
      $r | Add-Member -NotePropertyName SHA256 -NotePropertyValue '' -Force
      if ($swH.Elapsed.TotalSeconds -ge $SegundosHash) { $r.SHA256 = 'NAO_CALCULADO_TEMPO'; continue }
      if ($null -eq $r.TamanhoBytes -or $r.TamanhoBytes -gt $HashMaxBytes) { $r.SHA256 = 'NAO_CALCULADO_TAMANHO'; continue }
      try { $r.SHA256 = (Get-FileHash -LiteralPath $r.Caminho -Algorithm SHA256 -ErrorAction Stop).Hash } catch { $r.SHA256 = 'ERRO_LEITURA' }
    }
  }
  Save-Csv '10_arquivos_projeto.csv' $script:Achados['Projeto'] 'Arquivos pelas extensoes (so metadados; nenhum arquivo aberto, salvo -HashArquivosProjeto)'
  $cont = foreach ($g in ($script:Achados['Projeto'] | Group-Object Extensao | Sort-Object Count -Descending)) {
    [pscustomobject]@{ Extensao = $g.Name; Quantidade = $g.Count; ModificadoMaisRecente = (($g.Group | Sort-Object Modificado -Descending | Select-Object -First 1).Modificado); TamanhoTotalMB = [math]::Round((($g.Group | Measure-Object TamanhoBytes -Sum).Sum / 1MB), 1) }
  }
  Save-Csv '10b_contagem_extensoes.csv' $cont 'Contagem por extensao'
  Save-Csv '11_indicios_nomes_arquivos.csv' (@($script:Achados['Forte']) + @($script:Achados['Fraco'])) 'Nomes de arquivo sugestivos de crack/keygen/patch (FORTE/FRACO; nada foi aberto ou executado)'
  Save-Csv '11b_instaladores_fabricantes.csv' $script:Achados['Instalador'] 'Instaladores/pacotes com nome dos fabricantes'
  Save-Csv '14_lixeira.csv' $script:Achados['Lixeira'] 'Lixeira: itens excluidos (caminho original e data de exclusao, lidos do $I)'
}
Save-Csv '11e_indicios_excluidos.csv' $script:Excluidos ('Ocorrencias que casaram com indicio forte mas foram excluidas por -ExclusaoIndicios (' + $ExclusaoIndicios + '); listadas para transparencia')
Save-Csv '11f_indicios_provavel_fp.csv' $script:ProvavelFp 'Indicios que casaram com padrao forte mas classificados como PROVAVEL_FALSO_POSITIVO (imagens/PDF/site-packages/crackfortran/texturas) - v1.4'
Save-Csv '10c_varredura_raizes.csv' $script:RaizesStatus 'Cobertura de cada varredura (COMPLETO / TEMPO_ESGOTADO / INEXISTENTE_OU_NEGADO)'

# ---------------------------------------------------------------------------------------------
# Resumo minimo GENERICO (v1.3): irregularidades de qualquer fabricante; -Destacar so destaca
# ---------------------------------------------------------------------------------------------
function Get-ExtensoesDoFabricante([string]$Fab) {
  $f = $Fab.ToLowerInvariant()
  if ($f -match 'corel|alludo|photo-?paint|paintshop|videostudio|pinnacle|roxio|windvd|winzip') {
    return @('.cdr', '.cdt', '.cmx', '.cpt', '.des', '.csl')
  }
  if ($f -match 'autodesk|autocad|inventor|revit|maya|navisworks|fusion|civil') {
    return @('.dwg', '.dwt', '.dxf', '.dws', '.dwf', '.dwfx', '.dwl', '.dwl2', '.rvt', '.rfa', '.rte', '.rft', '.ifc', '.nwd', '.nwc', '.nwf', '.ipt', '.iam', '.idw', '.ipn', '.ide', '.max', '.3ds', '.fbx', '.ma', '.mb', '.f3d')
  }
  if ($f -match 'adobe') { return @('.ai', '.psd', '.indd', '.aep', '.prproj') }
  if ($f -match 'microsoft|office') { return @('.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx') }
  return @()
}
function Test-NomeDoFabricante([string]$Texto, [string]$Fab) {
  if ([string]::IsNullOrWhiteSpace($Texto)) { return $false }
  $f = $Fab.ToLowerInvariant()
  $tx = $Texto.ToLowerInvariant()
  if ($f -match 'corel') { return ($tx -match 'corel|alludo|photo-?paint|paintshop|videostudio|pinnacle|roxio|windvd|winzip|parallels|mindmanager') }
  if ($f -match 'autodesk') { return ($tx -match 'autodesk|autocad|\bacad\b|inventor|revit|3ds ?max|\bmaya\b|navisworks|fusion ?360|civil ?3d|adsk') }
  if ($f -match 'adobe') { return ($tx -match 'adobe|photoshop|illustrator|indesign|premiere|after ?effects|acrobat|creative ?cloud|\bamtlib\b') }
  if ($f -match 'microsoft|office') { return ($tx -match 'microsoft|office|windows.?10|windows.?11|\bkms\b|kmspico|kmsauto|microsoft.?toolkit') }
  return ($tx -match [regex]::Escape($f))
}
function Get-VendorGuess([string]$Texto) {
  $tx = [string]$Texto
  if ($tx -match '(?i)autodesk|autocad|\bacad\b|inventor|revit|adsk|xf-?adsk') { return 'Autodesk' }
  if ($tx -match '(?i)corel|alludo|cdgs|photo-?paint') { return 'Corel' }
  if ($tx -match '(?i)adobe|photoshop|illustrator|amtlib|creative.?cloud') { return 'Adobe' }
  if ($tx -match '(?i)kms|kmspico|kmsauto|microsoft.?toolkit|re-?loader|office.?20\d\d|windows.?1[01]') { return 'Microsoft' }
  if ($tx -match '(?i)winzip') { return 'WinZip' }
  if ($tx -match '(?i)parallels') { return 'Parallels' }
  if ($tx -match '(?i)solid.?squad|\bssq\b') { return 'SolidSquad/Autodesk' }
  return 'Outro/indefinido'
}

function Write-ResumoMinimo {
  $linhas = New-Object System.Collections.ArrayList
  $agora = Get-Date
  $tz = [System.TimeZoneInfo]::Local
  $sugestoes = New-Object System.Collections.ArrayList
  [void]$linhas.Add('================================================================')
  [void]$linhas.Add(' RESUMO MINIMO DA COLETA  v' + $VersaoScript + '  (GENERICO)')
  [void]$linhas.Add((' Equip: {0}   Host: {1}' -f $Equip, $env:COMPUTERNAME))
  [void]$linhas.Add((' Local: {0} ({1}, offset {2})' -f $agora.ToString('yyyy-MM-dd HH:mm:ss'), $tz.Id, $tz.GetUtcOffset($agora)))
  [void]$linhas.Add((' UTC:   {0}' -f $agora.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')))
  [void]$linhas.Add((' Usuario: {0}   Admin: {1}   Duracao: {2:N0}s' -f $idAtual.Name, $script:IsAdmin, ($agora - $script:Inicio).TotalSeconds))
  if ($Destacar.Count -gt 0) {
    [void]$linhas.Add((' Destacar (opcional): {0}' -f ($Destacar -join ', ')))
  } else {
    [void]$linhas.Add(' Destacar: (nenhum - relatorio generico completo)')
  }
  [void]$linhas.Add('================================================================')
  [void]$linhas.Add('')

  $fortes = @($script:Achados['Forte'])
  $fracos = @($script:Achados['Fraco'])
  $excl = @($script:Excluidos)
  $instAll = @($script:Achados['Instalador'])
  $dllsN = @($script:Achados['DllSistema']).Count

  # --- (1) DESTAQUE opcional ---
  if ($Destacar.Count -gt 0) {
    [void]$linhas.Add('--- 1. DESTAQUE (fabricantes de interesse; NAO oculta o restante) ---')
    foreach ($fabAlvo in $Destacar) {
      $progs = @($script:Programas | Where-Object { (Test-NomeDoFabricante $_.DisplayName $fabAlvo) -or (Test-NomeDoFabricante $_.Publisher $fabAlvo) } | Sort-Object DisplayName)
      $exts = Get-ExtensoesDoFabricante $fabAlvo
      $projetos = @()
      if ($exts.Count -gt 0) { $projetos = @($script:Achados['Projeto'] | Where-Object { $exts -contains ([string]$_.Extensao).ToLowerInvariant() }) }
      $inds = @(@($fortes) + @($fracos) | Where-Object { (Test-NomeDoFabricante $_.Nome $fabAlvo) -or (Test-NomeDoFabricante $_.Caminho $fabAlvo) -or ((Get-VendorGuess ($_.Nome + ' ' + $_.Caminho)) -match ('(?i)' + [regex]::Escape($fabAlvo))) })
      $hostsD = @($script:HostsFabLinhas | Where-Object { Test-NomeDoFabricante $_.Conteudo $fabAlvo })
      $svcD = @($script:ServicosFab | Where-Object { (Test-NomeDoFabricante $_.Nome $fabAlvo) -or (Test-NomeDoFabricante $_.NomeExibicao $fabAlvo) -or (Test-NomeDoFabricante $_.Executavel $fabAlvo) })
      $instD = @($instAll | Where-Object { (Test-NomeDoFabricante $_.Nome $fabAlvo) -or (Test-NomeDoFabricante $_.Caminho $fabAlvo) })
      [void]$linhas.Add('')
      [void]$linhas.Add((' [{0}]' -f $fabAlvo.ToUpperInvariant()))
      if ($progs.Count -gt 0) {
        [void]$linhas.Add(('   Instalado (Uninstall): {0}' -f $progs.Count))
        foreach ($pr in ($progs | Select-Object -First 8)) {
          [void]$linhas.Add((' - {0} | v{1} | {2}' -f $pr.DisplayName, $pr.DisplayVersion, $pr.Escopo))
          if ($pr.InstallLocation) { [void]$linhas.Add(('       em: {0}' -f $pr.InstallLocation)) }
        }
      } else {
        [void]$linhas.Add('   Instalado (Uninstall): nenhum')
      }
      if ($inds.Count -gt 0) {
        [void]$linhas.Add(('   Indicios (crack/keygen/ativador) ligados: {0}' -f $inds.Count))
        foreach ($x in ($inds | Select-Object -First 6)) { [void]$linhas.Add((' - {0}' -f $x.Caminho)) }
      }
      if ($hostsD.Count -gt 0) {
        [void]$linhas.Add(('   Hosts bloqueando dominio: {0}' -f $hostsD.Count))
        foreach ($h in $hostsD) { [void]$linhas.Add((' - {0}' -f $h.Conteudo)) }
      }
      if ($svcD.Count -gt 0) {
        [void]$linhas.Add(('   Servicos: {0}' -f $svcD.Count))
        foreach ($s in ($svcD | Select-Object -First 5)) { [void]$linhas.Add((' - {0} ({1})' -f $s.NomeExibicao, $s.Estado)) }
      }
      if ($instD.Count -gt 0) { [void]$linhas.Add(('   Instaladores soltos: {0}' -f $instD.Count)) }
      if ($projetos.Count -gt 0) {
        $porExt = $projetos | Group-Object Extensao | Sort-Object Count -Descending
        $resumoExt = ($porExt | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }) -join ', '
        [void]$linhas.Add(('   Arquivos de projeto: {0} ({1})' -f $projetos.Count, $resumoExt))
        if ($progs.Count -eq 0) {
          $extTxt = ($exts | Select-Object -First 4) -join '/'
          [void]$sugestoes.Add(('{0}: arquivos {1} sem programa instalado - procurar versao portatil / outro usuario / outro disco' -f $fabAlvo, $extTxt))
        }
      } else {
        [void]$linhas.Add('   Arquivos de projeto: nenhum nesta varredura')
      }
    }
    [void]$linhas.Add('')
  } else {
    [void]$linhas.Add('--- 1. DESTAQUE ---')
    [void]$linhas.Add(' (omitido - rode com -Destacar FabricanteA,FabricanteB se quiser priorizar no topo)')
    [void]$linhas.Add('')
  }

  # --- (2) IRREGULARIDADES GENERICAS (sempre tudo) ---
  [void]$linhas.Add('--- 2. IRREGULARIDADES / INDICIOS DE PIRATARIA (todos os fabricantes) ---')
  [void]$linhas.Add('')

  # 2a Keygen/crack agrupado por vendor guess
  if ($fortes.Count -gt 0) {
    [void]$linhas.Add((' A) Keygen / crack / patch / ativador (FORTES): {0}' -f $fortes.Count))
    $porVend = $fortes | ForEach-Object {
      $_ | Add-Member -NotePropertyName _Vend -NotePropertyValue (Get-VendorGuess ($_.Nome + ' ' + $_.Caminho)) -Force -PassThru
    } | Group-Object _Vend | Sort-Object Name
    foreach ($g in $porVend) {
      [void]$linhas.Add(('   [{0}] ({1})' -f $g.Name, $g.Count))
      foreach ($x in ($g.Group | Select-Object -First 8)) {
        [void]$linhas.Add((' - {0}' -f $x.Caminho))
      }
      if ($g.Count -gt 8) { [void]$linhas.Add(('     ... +{0}' -f ($g.Count - 8))) }
    }
    [void]$sugestoes.Add('Conferir manualmente os arquivos listados como indicios FORTES (nao executar).')
  } else {
    [void]$linhas.Add(' A) Keygen / crack / patch / ativador (FORTES): nenhum')
  }

  if ($fracos.Count -gt 0) {
    [void]$linhas.Add((' B) Indicios FRACOS (patch/loader/serial/nfo/portable): {0}' -f $fracos.Count))
    foreach ($x in ($fracos | Select-Object -First 8)) {
      [void]$linhas.Add((' - [{0}] {1}' -f (Get-VendorGuess ($x.Nome + ' ' + $x.Caminho)), $x.Caminho))
    }
    if ($fracos.Count -gt 8) { [void]$linhas.Add(('   ... +{0}' -f ($fracos.Count - 8))) }
  } else {
    [void]$linhas.Add(' B) Indicios FRACOS: nenhum')
  }
  if ($excl.Count -gt 0) {
    [void]$linhas.Add(('    (excluidos por -ExclusaoIndicios, ex. ssh-keygen: {0} - ver 11e_)' -f $excl.Count))
  }

  # 2c Hosts
  if ($script:HostsFabLinhas.Count -gt 0) {
    [void]$linhas.Add((' C) Hosts bloqueando ativacao/validacao: {0} linha(s)' -f $script:HostsFabLinhas.Count))
    $porH = $script:HostsFabLinhas | ForEach-Object {
      $_ | Add-Member -NotePropertyName _Vend -NotePropertyValue (Get-VendorGuess $_.Conteudo) -Force -PassThru
    } | Group-Object _Vend | Sort-Object Name
    foreach ($g in $porH) {
      [void]$linhas.Add(('   [{0}]' -f $g.Name))
      foreach ($h in $g.Group) { [void]$linhas.Add((' - L{0}: {1}' -f $h.Linha, $h.Conteudo)) }
    }
    [void]$sugestoes.Add('hosts alterado com bloqueio de dominio - fotografar e anotar na ata')
  } else {
    [void]$linhas.Add(' C) Hosts bloqueando ativacao/validacao: nenhum')
  }

  # 2d Servicos
  if ($script:ServicosFab.Count -gt 0) {
    [void]$linhas.Add((' D) Servicos de licenca / fabricante: {0}' -f $script:ServicosFab.Count))
    foreach ($s in ($script:ServicosFab | Select-Object -First 10)) {
      [void]$linhas.Add((' - [{0}] {1} | {2} | {3}' -f (Get-VendorGuess ($s.Nome + ' ' + $s.NomeExibicao + ' ' + $s.Executavel)), $s.NomeExibicao, $s.Estado, $s.Inicializacao))
    }
  } else {
    [void]$linhas.Add(' D) Servicos de licenca / fabricante: nenhum')
  }

  # 2e Instaladores
  if ($instAll.Count -gt 0) {
    [void]$linhas.Add((' E) Instaladores/pacotes soltos (nome fabricante): {0}' -f $instAll.Count))
    foreach ($i in ($instAll | Select-Object -First 8)) {
      [void]$linhas.Add((' - [{0}] {1}' -f (Get-VendorGuess ($i.Nome + ' ' + $i.Caminho)), $i.Caminho))
    }
    [void]$sugestoes.Add('Instaladores soltos presentes - verificar midia/instalacao pendente')
  } else {
    [void]$linhas.Add(' E) Instaladores/pacotes soltos: nenhum')
  }

  # 2f Remocoes MSI
  if ($script:RemocoesMsiFab.Count -gt 0) {
    [void]$linhas.Add((' F) Desinstalacoes MSI recentes (produtos das autoras da coleta): {0}' -f $script:RemocoesMsiFab.Count))
    foreach ($r in ($script:RemocoesMsiFab | Select-Object -First 6)) {
      $msg = [string]$r.Mensagem
      if ($msg.Length -gt 110) { $msg = $msg.Substring(0, 110) + '...' }
      [void]$linhas.Add((' - {0} | Id {1} | {2}' -f $r.DataLocal, $r.Id, $msg))
    }
    [void]$sugestoes.Add('Houve remocao MSI relevante - checar residuos em Program Files/ProgramData e Lixeira')
  } else {
    [void]$linhas.Add(' F) Desinstalacoes MSI recentes (autoras da coleta): nenhuma na janela')
  }

  # 2g Assinaturas / DLLs
  if ($script:NaoAssinados -gt 0) {
    [void]$linhas.Add((' G) Binarios de licenciamento sem assinatura valida: {0} (ver 11d_)' -f $script:NaoAssinados))
    [void]$sugestoes.Add('Binarios de licenciamento sem assinatura valida - conferir 11d_assinaturas_binarios.csv')
  } else {
    [void]$linhas.Add(' G) Binarios de licenciamento sem assinatura valida: 0')
  }
  if ($dllsN -gt 0) {
    [void]$linhas.Add((' H) DLLs de sistema em pasta de programa (loader?): {0} (ver 11c_)' -f $dllsN))
  } else {
    [void]$linhas.Add(' H) DLLs de sistema em pasta de programa: 0')
  }

  # 2i Discos nao varridos
  $raizDest = [System.IO.Path]::GetPathRoot($script:Out)
  $naoVarridos = New-Object System.Collections.ArrayList
  foreach ($v in $script:VolumesTodos) {
    $u = [string]$v.Unidade
    if (-not $v.Pronto) { [void]$naoVarridos.Add(('{0} ({1}, rotulo={2}) - nao pronto' -f $u, $v.Tipo, $v.Rotulo)); continue }
    if ($u -ieq $raizDest) { continue }
    if ($v.Tipo -eq 'Removable' -or $v.Tipo -eq 'CDRom' -or $v.Tipo -eq 'Network') {
      [void]$naoVarridos.Add(('{0} ({1}, rotulo={2}) - tipo nao varrido pela coleta de arquivos' -f $u, $v.Tipo, $v.Rotulo))
    }
  }
  foreach ($r in $script:RaizesStatus) {
    if ($r.Status -match 'TEMPO|LIMITE|INCOMPLETO|NAO_VARRIDA') {
      [void]$naoVarridos.Add(('cobertura parcial: {0} ({1}) [{2}]' -f $r.Rotulo, $r.Raiz, $r.Status))
    }
  }
  if ($naoVarridos.Count -gt 0) {
    [void]$linhas.Add((' I) Outros discos/particoes/USB ou cobertura parcial: {0}' -f $naoVarridos.Count))
    foreach ($n in ($naoVarridos | Select-Object -First 10)) {
      [void]$linhas.Add((' - {0}' -f $n))
      if ($n -match 'Removable|nao varrido|nao pronto') {
        $sug = ($n -replace '\s+-\s.*$', '') + ' nao varrido - se for relevante, varrer manualmente antes de sair'
        if ($sugestoes -notcontains $sug) { [void]$sugestoes.Add($sug) }
      }
    }
  } else {
    [void]$linhas.Add(' I) Outros discos/particoes/USB nao varridos: nenhum sinalizado')
  }

  # 2j Provaveis FP
  $nFp = @($script:ProvavelFp).Count
  if ($nFp -gt 0) {
    [void]$linhas.Add((' J) Provaveis falsos positivos (nao contam como FORTE): {0} (ver 11f_)' -f $nFp))
  } else {
    [void]$linhas.Add(' J) Provaveis falsos positivos: 0')
  }

  # --- (3) SUGESTOES ---
  [void]$linhas.Add('')
  [void]$linhas.Add("--- 3. SUGESTOES 'vale pesquisar mais neste PC' ---")
  if (-not $script:IsAdmin) {
    [void]$sugestoes.Insert(0, 'Rodou SEM administrador: Prefetch/Defender/outros perfis parciais - se houver credencial, repetir como admin')
  }
  foreach ($s in @($script:Secoes | Where-Object { $_.Status -match 'ERRO|PULADA' })) {
    [void]$sugestoes.Add(('Secao {0}: {1} {2}' -f $s.Secao, $s.Status, $s.Observacao))
  }
  $vistos = @{}; $finalSug = New-Object System.Collections.ArrayList
  foreach ($s in $sugestoes) {
    $k = ([string]$s).ToLowerInvariant()
    if ($vistos.ContainsKey($k)) { continue }
    $vistos[$k] = 1
    [void]$finalSug.Add($s)
  }
  if ($finalSug.Count -eq 0) {
    [void]$linhas.Add(' (nenhuma sugestao extra - cobertura tipica ok)')
  } else {
    $i = 0
    foreach ($s in ($finalSug | Select-Object -First 12)) {
      $i++
      [void]$linhas.Add((' {0}. {1}' -f $i, $s))
    }
  }

  # --- (4) CONTAGENS ---
  $fabN = @($script:Programas | Where-Object { $script:RxFab.IsMatch($_.DisplayName) -or $script:RxFab.IsMatch($_.Publisher) }).Count
  $lixRel = @($script:Achados['Lixeira'] | Where-Object { $_.Relevante }).Count
  # --- (3b) CAPTURAS MANUAIS (checklist de campo) ---
  [void]$linhas.Add('')
  [void]$linhas.Add('--- 3b. CAPTURAS MANUAIS PENDENTES (checklist) ---')
  [void]$linhas.Add('  [ ] Foto do equipamento + etiqueta EQ + relogio Windows vs referencia')
  [void]$linhas.Add('  [ ] Tela Programas e Recursos / Configuracoes > Aplicativos (filtro por fabricante de interesse)')
  [void]$linhas.Add('  [ ] Tela Sobre do produto (somente se autorizada na ata; por ultimo)')
  [void]$linhas.Add('  [ ] Foto do 00_RESUMO + SHA-256 do manifesto nesta tela')
  [void]$linhas.Add('  Use capturar_tela.cmd EQ## descricao  (ex.: EQ01 apps_fabricanteA)')

  [void]$linhas.Add('')
  [void]$linhas.Add('--- 4. CONTAGENS-CHAVE ---')
  if ($script:PerfilMeta.Carregado) {
    [void]$linhas.Add((' Perfil: {0}' -f $script:PerfilMeta.Nome))
  }
  [void]$linhas.Add((' Hives offline: {0} | Provaveis FP: {1}' -f $(if ($LerHivesOffline) {'ligado'} else {'desligado'}), @($script:ProvavelFp).Count))
  [void]$linhas.Add((' Programas (Uninstall total): {0} | regex coleta (-Fabricantes): {1}' -f $script:Programas.Count, $fabN))
  [void]$linhas.Add((' Arquivos de projeto: {0} | indicios fortes: {1} | fracos: {2} | instaladores: {3}' -f $script:Achados['Projeto'].Count, $fortes.Count, $fracos.Count, $instAll.Count))
  [void]$linhas.Add((' Lixeira relevantes: {0} | hosts: {1} | servicos: {2} | remocoes MSI: {3}' -f $lixRel, $script:HostsFabLinhas.Count, $script:ServicosFab.Count, $script:RemocoesMsiFab.Count))
  [void]$linhas.Add((' Assinatura invalida/ausente: {0} | DLLs sistema em pasta prog: {1}' -f $script:NaoAssinados, $dllsN))
  $ok = @($script:Secoes | Where-Object { $_.Status -eq 'OK' }).Count
  $parcial = @($script:Secoes | Where-Object { $_.Status -eq 'OK_PARCIAL' }).Count
  $outras = @($script:Secoes | Where-Object { $_.Status -ne 'OK' -and $_.Status -ne 'OK_PARCIAL' }).Count
  [void]$linhas.Add((' Secoes: OK={0} OK_PARCIAL={1} outras={2} (ver 00_resumo_secoes.csv)' -f $ok, $parcial, $outras))
  [void]$linhas.Add('')
  [void]$linhas.Add((' Pasta da coleta: {0}' -f $script:Out))
  [void]$linhas.Add(' (Somente leitura na maquina vistoriada. Este resumo entra no manifesto SHA-256.)')
  [void]$linhas.Add('================================================================')

  $texto = ($linhas -join "`r`n") + "`r`n"
  $pathResumo = Join-Path $script:Out '00_RESUMO.txt'
  [System.IO.File]::WriteAllText($pathResumo, $texto, $script:Utf8Bom)
  [void]$script:Arquivos.Add([pscustomobject]@{ Arquivo = '00_RESUMO.txt'; Registros = $linhas.Count; Descricao = 'Resumo minimo generico (irregularidades + destaque opcional + checklist capturas) - v1.4' })
  Write-Registro ("Resumo minimo gravado: {0} ({1} linhas)" -f $pathResumo, $linhas.Count)
  Write-Host ''
  Write-Host $texto -ForegroundColor White
  return $pathResumo
}

# ---------------------------------------------------------------------------------------------
# Encerramento: resumo minimo, log final, manifesto (nada e gravado na pasta depois do manifesto)
# ---------------------------------------------------------------------------------------------
$fab = @($script:Programas | Where-Object { $script:RxFab.IsMatch($_.DisplayName) -or $script:RxFab.IsMatch($_.Publisher) })
$lixRel = @($script:Achados['Lixeira'] | Where-Object { $_.Relevante }).Count
$fim = Get-Date
Save-Csv '00_resumo_secoes.csv' $script:Secoes 'Status de cada secao (OK / ERRO / PULADA_SEM_ADMIN)'
Write-Registro ("RESUMO: programas das autoras={0} | arquivos de projeto={1} | indicios fortes={2} | indicios fracos={3} | instaladores={4} | lixeira relevantes={5} | binarios com assinatura invalida/ausente={6} | DLLs de sistema em pasta de programa={7}" -f $fab.Count, $script:Achados['Projeto'].Count, $script:Achados['Forte'].Count, $script:Achados['Fraco'].Count, $script:Achados['Instalador'].Count, $lixRel, $script:NaoAssinados, $script:Achados['DllSistema'].Count)
foreach ($s in $script:Secoes) { if ($s.Status -ne 'OK') { Write-Registro ("  secao '{0}': {1} {2}" -f $s.Secao, $s.Status, $s.Observacao) 'AVISO' } }
foreach ($r in $script:RaizesStatus) { if ($r.Status -match 'TEMPO|LIMITE|INCOMPLETO') { Write-Registro ("  cobertura parcial: {0} ({1}) {2}" -f $r.Rotulo, $r.Raiz, $r.Status) 'AVISO' } }
Write-Registro ("Fim local: {0} | Fim UTC: {1} | Duracao: {2:N0}s" -f $fim.ToString('yyyy-MM-dd HH:mm:ss'), $fim.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'), ($fim - $script:Inicio).TotalSeconds)
# v1.4: descarrega hives temporarios ANTES do resumo/manifesto (copias ficam no pendrive)
if ($script:HivesCarregadosTmp.Count -gt 0) {
  Write-Registro ("Descarregando {0} hive(s) temporario(s)..." -f $script:HivesCarregadosTmp.Count)
  foreach ($ch in @($script:HivesCarregadosTmp)) {
    try {
      $o = & reg.exe unload ("HKU\" + $ch) 2>&1 | Out-String
      if ($LASTEXITCODE -eq 0) { Write-Registro ("  unload HKU\{0}: OK" -f $ch) }
      else { Write-Registro ("  unload HKU\{0}: FALHA {1}" -f $ch, ($o -replace '\s+', ' ').Trim()) 'AVISO' }
    } catch { Write-Registro ("  unload HKU\{0}: {1}" -f $ch, $_.Exception.Message) 'AVISO' }
  }
  $script:HivesCarregadosTmp.Clear()
  # Fecha handle HKU e reabre limpo (evita lock na copia)
  try { if ($script:HKU) { $script:HKU.Close() } } catch { }
  $script:HKU = Open-Base ([Microsoft.Win32.RegistryHive]::Users) ([Microsoft.Win32.RegistryView]::Default)
}

# v1.4: resumo minimo ANTES do manifesto (entra na cadeia de custodia)
[void](Write-ResumoMinimo)
Save-Csv '00_indice_arquivos.csv' $script:Arquivos 'Indice dos arquivos gerados (inclui 00_RESUMO.txt)'
Write-Registro 'Gerando manifesto SHA-256 (nada mais sera gravado nesta pasta depois dele).'

$manif = Join-Path $script:Out 'MANIFESTO_SHA256.txt'
$linhas = New-Object System.Collections.ArrayList
[void]$linhas.Add(('# Manifesto SHA-256 - Equip={0} Host={1} Pasta={2} GeradoUTC={3}' -f $Equip, $env:COMPUTERNAME, (Split-Path $script:Out -Leaf), (Get-Date).ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss')))
$baseLen = $script:Out.TrimEnd('\').Length + 1
foreach ($f in (Get-ChildItem -LiteralPath $script:Out -File -Recurse -Force | Where-Object { $_.FullName -ne $manif } | Sort-Object FullName)) {
  $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLower()
  [void]$linhas.Add(('{0}  {1}' -f $h, $f.FullName.Substring($baseLen).Replace('\', '/')))
}
[System.IO.File]::WriteAllLines($manif, [string[]]$linhas.ToArray([string]), (New-Object System.Text.UTF8Encoding $false))
$hm = (Get-FileHash -LiteralPath $manif -Algorithm SHA256).Hash
try { [System.IO.File]::WriteAllText(($manif + '.sha256'), (('{0}  MANIFESTO_SHA256.txt' -f $hm.ToLower()) + "`r`n"), (New-Object System.Text.UTF8Encoding $false)) } catch { }
try { [System.IO.File]::AppendAllText((Join-Path $Destino 'INDICE_COLETAS.txt'), (('{0} | {1} | {2} | {3} | manifesto SHA-256 {4}' -f $fim.ToString('yyyy-MM-dd HH:mm:ss'), $Equip, $env:COMPUTERNAME, (Split-Path $script:Out -Leaf), $hm) + "`r`n"), $script:Utf8Bom) } catch { }

Write-Host ''
Write-Host '==================================================================' -ForegroundColor Cyan
Write-Host (' COLETA CONCLUIDA  Equip {0}  Host {1}' -f $Equip, $env:COMPUTERNAME) -ForegroundColor Cyan
Write-Host (' Pasta: {0}' -f $script:Out)
Write-Host (' Administrador: {0}   Duracao: {1:N0}s' -f $script:IsAdmin, ($fim - $script:Inicio).TotalSeconds)
Write-Host (' Programas das autoras: {0}   Arquivos de projeto: {1}   Indicios fortes: {2}' -f $fab.Count, $script:Achados['Projeto'].Count, $script:Achados['Forte'].Count)
$puladas = @($script:Secoes | Where-Object { $_.Status -ne 'OK' }).Count
if ($puladas -gt 0) { Write-Host (' Secoes com ERRO ou PULADAS: {0} (ver 00_resumo_secoes.csv)' -f $puladas) -ForegroundColor Yellow }
Write-Host ' Resumo minimo: 00_RESUMO.txt (ja impresso acima; incluso no manifesto).' -ForegroundColor Cyan
Write-Host (' SHA-256 do manifesto: {0}' -f $hm) -ForegroundColor Yellow
Write-Host ' Fotografe esta tela (resumo + hash) e anote na planilha de campo.'
Write-Host '==================================================================' -ForegroundColor Cyan
exit 0
