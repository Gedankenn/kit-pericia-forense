# Kit do pendrive para a vistoria de software (v1.4)

Processo sigiloso: o pendrive e os arquivos de saída ficam só com o perito. Não coloque nomes das partes no rótulo do pendrive nem nos nomes de pasta. Use só os identificadores **EQ01**, **EQ02** etc. (o script normaliza `1`/`EQ1` → `EQ01`).

## 1. Estrutura do pendrive

```
E:\                                   (pendrive do perito, NTFS ou exFAT, >= 16 GB)
├── rodar_coleta_v1.4.cmd             <- lançador (botão direito > Executar como administrador)
├── coleta_inventario_software_v1.4.ps1
├── perfis\
│   └── exemplo_generico.psd1         <- listas de fabricantes/indícios (troque pelo perfil do caso)
├── capturar_tela.cmd / capturar_tela.ps1
├── coleta_minima_v1.2.cmd            <- PLANO B (PowerShell bloqueado; sem 00_RESUMO)
├── KIT_SHA256.txt
├── CHECKLIST_CAMPO_v1.4.md
└── coleta\
    ├── EQ01_<HOST>_<data_hora>\
    │   ├── 00_RESUMO.txt
    │   ├── hives_offline\            <- cópias NTUSER.DAT (se -LerHivesOffline)
    │   ├── suspeitos_copias\         <- se -CopiarSuspeitos
    │   ├── *.csv / *.txt
    │   └── MANIFESTO_SHA256.txt
    └── INDICE_COLETAS.txt
```

No pendrive da diligência leve **apenas** os arquivos v1.4 (+ plano B e capturar_tela). Versões antigas ficam arquivadas.

## 2. O lançador `rodar_coleta_v1.4.cmd`

- PowerShell 5.1 64 bits com `-NoProfile -ExecutionPolicy Bypass -File`.
- `PSModuleAnalysisCachePath=NUL`.
- Pede o identificador e roda com `-CapturaTela` e `-Perfil perfis\exemplo_generico.psd1` (se existir).
- Equivalente:
  `powershell -NoProfile -ExecutionPolicy Bypass -File E:\coleta_inventario_software_v1.4.ps1 -Equip EQ01 -CapturaTela -Perfil E:\perfis\exemplo_generico.psd1`

### Parâmetros novos / relevantes (v1.4)

| Parâmetro | Função |
|---|---|
| `-Perfil` | Carrega `.psd1`/`.json` com Fabricantes, indícios, pastas etc. Código 5 se inválido. |
| `-LerHivesOffline` | Padrão **ligado** se admin. Copia `NTUSER.DAT` para o pendrive e faz `reg load` **só da cópia**. |
| `-SemHivesOffline` | Desliga a carga de hives deslogados. |
| `-CopiarSuspeitos` | Copia binários com assinatura inválida/ausente para `suspeitos_copias\` (≤ 50 MB). |
| `-Destacar` | Só prioriza fabricantes no topo do resumo (nunca oculta o resto). |
| `-ModoTeste` | Permite gravar no disco do sistema (PC do perito). |

## 3. Passo a passo

Ver também `CHECKLIST_CAMPO_v1.4.md`.

1. Fotos prévias (equipamento, tela, relógios). Não fazer logoff.
2. Plugar pendrive; recusar “verificar e corrigir”.
3. `rodar_coleta_v1.4.cmd` como administrador.
4. Digitar EQ (ex. `EQ01`). Aguardar.
5. Ler/fotografar `00_RESUMO.txt` + hash do manifesto.
6. **Capturas manuais:** Programas e Recursos / Aplicativos; Sobre só se autorizado (por último).
7. Ejetar. Se PowerShell bloqueado → `coleta_minima_v1.2.cmd`.

### Arquivos CSV novos / alterados na v1.4

| Arquivo | Conteúdo |
|---|---|
| `01f_hives_offline.csv` | Status da cópia/carga de NTUSER.DAT de perfis deslogados |
| `11d_assinaturas_binarios.csv` | Agora com **SHA-256** + Authenticode também de indícios FORTES binários |
| `11f_indicios_provavel_fp.csv` | Casos classificados como provável falso positivo (não contam como FORTE) |
| `17c_defender_exclusoes.csv` | Se cmdlets falharem (ex. 0x800106ba): preenchido via **registro** (`Fonte=REGISTRO_FALLBACK`) |
| `17d_defender_exclusoes_registro_detalhe.csv` | Detalhe do fallback |
| `suspeitos_copias\` | Cópias opcionais (`-CopiarSuspeitos`), cobertas pelo manifesto |
| `hives_offline\` | Cópias dos hives (pendrive); original no disco vistoriado não é escrito |

## 4. Somente leitura — hives offline

A v1.3 **não** carregava hives deslogados (risco de alterar `NTUSER.DAT`).  
A v1.4, com `-LerHivesOffline` (padrão admin):

1. Copia `NTUSER.DAT` (+ logs se existirem) para `coleta\...\hives_offline\` no **pendrive**.
2. Executa `reg load HKU\PericiaTmp_*` apontando para a **cópia**.
3. Lê Uninstall / MRU / User Shell Folders.
4. `reg unload` antes do manifesto.

O arquivo original em `C:\Users\...\NTUSER.DAT` não é aberto em escrita pelo script. Efeitos inevitáveis do Windows (Prefetch, USBSTOR, possível last-access) continuam a ser declarados no laudo.

## 5. Efeitos inevitáveis na máquina

Iguais à v1.3: USBSTOR/MountedDevices; Prefetch/eventos do PowerShell; `StartupProfileData-NonInteractive`; last-access NTFS se ativo. Nenhum arquivo de usuário é alterado ou apagado pelo script.

## 6. Checklist pré-voo (PC do perito)

- [ ] Formatar pendrive; copiar só o kit v1.4.
- [ ] Conferir `KIT_SHA256.txt`.
- [ ] Rodar com `-ModoTeste` como admin e como usuário comum.
- [ ] Plantar: `keygen.exe`, `texture_crack.png`, `crackfortran.py` em site-packages, PDF com “crack”, perfil deslogado com Uninstall.
- [ ] Conferir: fortes reais em `11_`; FP em `11f_`; hive em `01f_` + programas do perfil; Defender fallback se cmdlets falharem; IDs `EQ##`; manifesto íntegro; C: sem escrita do script.

## 7. Limitações conhecidas (v1.4)

- Data de última gravação de chave de registro ainda não coletada.
- Seriais Autodesk recentes em geral não ficam no registro.
- Captura de tela pode ficar parcial em DPI alto / multi-monitor.
- Plano B (`coleta_minima_v1.2.cmd`) não gera `00_RESUMO.txt`.
- Hive offline exige admin e falha se `NTUSER.DAT` estiver locked (registrado em `01f_`).
- Relaunch 32→64 / AppLocker restrito: validar no PC real da diligência.
- Campo anterior usou v1.2; esta v1.4 incorpora as correções sugeridas pós-campo.

## Changelog v1.4 (01/11/2026)

**Arquivos novos:** `coleta_inventario_software_v1.4.ps1`, `rodar_coleta_v1.4.cmd`, `KIT_PENDRIVE_v1.4.md`, `CHECKLIST_CAMPO_v1.4.md`, `PLANO_v1.4.md`, `perfis/exemplo_generico.psd1`. Hashes appendados em `KIT_SHA256.txt`.

- Hives de usuários deslogados via cópia no pendrive (`-LerHivesOffline`).
- Fallback Defender por registro quando `Get-Mp*` falha (0x800106ba).
- SHA-256 + Authenticode de suspeitos; `-CopiarSuspeitos`.
- Classificação de prováveis FP (`11f_`); exclusões explícitas seguem em `11e_`.
- IDs de pasta padronizados `EQ##`.
- `-Perfil` externo (psd1/json); exemplo neutro no repo; perfil de caso fora do git.
- Checklist de capturas manuais no `00_RESUMO` e em `CHECKLIST_CAMPO_v1.4.md`.

## Changelog v1.3 / v1.2 / v1.1

Ver `KIT_PENDRIVE_v1.3.md` e `KIT_PENDRIVE_v1.2.md`.
