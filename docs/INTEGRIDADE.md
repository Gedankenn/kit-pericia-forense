# Verificação de integridade

## 1. Conferir o kit antes de usar

No Windows (PowerShell), a partir da pasta do repositório/pendrive:

```powershell
Get-Content .\KIT_SHA256.txt | Where-Object { $_ -match '^[a-f0-9]{64}\s' } | ForEach-Object {
  $hash, $path = $_ -split '\s+', 2
  if (Test-Path $path) {
    $atual = (Get-FileHash $path -Algorithm SHA256).Hash.ToLower()
    if ($atual -eq $hash) { "OK  $path" } else { "DIVERGE  $path`n  esperado $hash`n  atual    $atual" }
  } else { "AUSENTE  $path" }
}
```

Ou com `certutil`:

```bat
certutil -hashfile scripts\coleta_inventario_software_v1.3.ps1 SHA256
```

## 2. Manifesto gerado pela coleta

Ao final de cada execução, o script grava `MANIFESTO_SHA256.txt` (e um `.sha256` do próprio manifesto) na pasta da máquina. O `00_RESUMO.txt` é escrito **antes** do manifesto, então também é coberto.

Fotografe o hash do manifesto na tela e anote na ata / planilha de campo.

## 3. O que NÃO versionar

Pastas `coleta\` com evidências reais **nunca** devem ir para o Git. O `.gitignore` já bloqueia.
