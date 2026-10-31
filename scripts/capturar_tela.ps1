<#
  capturar_tela.ps1 - captura manual da tela para o pendrive somente leitura na maquina.
  Uso: capturar_tela.cmd [EQ01] [descricao]. Salva PNG em <pendrive>\coleta\capturas e registra SHA-256.
#>
param([string]$Equip = 'EQ', [string]$Descricao = 'tela', [int]$Atraso = 3)
$Equip = ($Equip -replace '[^A-Za-z0-9_-]', '_'); $Descricao = ($Descricao -replace '[^A-Za-z0-9_-]', '_')
$raizSistema = [System.IO.Path]::GetPathRoot($env:SystemRoot)
if ([System.IO.Path]::GetPathRoot($PSScriptRoot) -ieq $raizSistema) { Write-Host 'ABORTADO: o kit esta no disco do sistema.' -ForegroundColor Red; exit 2 }
$dir = Join-Path $PSScriptRoot 'coleta\capturas'
[void][System.IO.Directory]::CreateDirectory($dir)
Write-Host ("Capturando em {0}s... (deixe a janela desejada em primeiro plano)" -f $Atraso)
Start-Sleep -Seconds $Atraso
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
$b = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = New-Object System.Drawing.Bitmap $b.Width, $b.Height
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($b.Location, [System.Drawing.Point]::Empty, $b.Size)
$agora = Get-Date
$arq = Join-Path $dir ('{0}_{1}_{2}_{3}.png' -f $Equip, $env:COMPUTERNAME, $agora.ToString('yyyyMMdd_HHmmss'), $Descricao)
$bmp.Save($arq, [System.Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $bmp.Dispose()
$h = (Get-FileHash -LiteralPath $arq -Algorithm SHA256).Hash
[System.IO.File]::AppendAllText((Join-Path $dir 'HASHES_CAPTURAS.txt'), ('{0} | UTC {1} | {2} | {3}' -f $agora.ToString('yyyy-MM-dd HH:mm:ss'), $agora.ToUniversalTime().ToString('yyyy-MM-dd HH:mm:ss'), (Split-Path $arq -Leaf), $h) + "`r`n")
Write-Host ("Salvo: {0}`nSHA-256: {1}" -f $arq, $h) -ForegroundColor Yellow
