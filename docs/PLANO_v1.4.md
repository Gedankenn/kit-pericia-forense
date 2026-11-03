# Plano v1.4 — kit coleta inventário de software (somente leitura)

> **Status (2026-11-03):** a linha 1.4 culminou na **v1.4.4** (`coleta_inventario_software_v1.4.4.ps1` / `rodar_coleta_v1.4.4.cmd` / `KIT_PENDRIVE_v1.4.4.md`). Intermediárias (v1.4–v1.4.3) saíram da árvore do repo; o plano abaixo permanece como registro histórico do escopo.

**Data:** 2026-11-01 (America/Sao_Paulo)  
**Base:** `coleta_inventario_software_v1.3.ps1`  
**Regra:** arquivos novos `_v1.4`; versões antigas **nunca** sobrescritas.  
**Sigilo:** zero dados de processo/partes no repo público; perfis reais ficam só em `/workspace/pericia`.

## Objetivos (sugestões Peritoso + Fabio)

| # | Item | Abordagem | Risco | Critério de teste |
|---|---|---|---|---|
| 1 | Hives de usuário deslogado | Opcional `-LerHivesOffline` (padrão **ligado** se admin). Copia `NTUSER.DAT` (+ `.LOG*` se existirem) para o **pendrive** (`hives_offline\`), depois `reg load` **só da cópia** em `HKU\PericiaTmp_<SID>`, lê Uninstall + MRU + User Shell Folders, `reg unload` no `finally`. Original no disco vistoriado **não** é aberto em escrita. Se cópia falhar (arquivo locked), registra AVISO e segue. | Baixo se só a cópia for carregada; médio se alguém carregar o original por engano — código proíbe path sob `C:\Users`. | Admin: perfil órfão com Uninstall/MRU plantados no NTUSER.DAT → aparecem em `03_`/`16_` e `01d_` marca `HiveCarregadoViaCopia=True`. USN em C: sem escrita do script além do churn do SO. |
| 2 | Fallback Defender (0x800106ba) | Se `Get-MpPreference`/`Get-MpThreatDetection` falharem: ler exclusões em `HKLM\SOFTWARE\Microsoft\Windows Defender\Exclusions\*` e `...\Policies\Microsoft\Windows Defender\Exclusions\*`; status básico em `HKLM\SOFTWARE\Microsoft\Windows Defender\Real-Time Protection` / `DisableAntiSpyware`. Eventos 5007/1116… já coletados. | Nenhum (só leitura de registro). | Forçar falha do cmdlet (mock/serviço parado) → `17c_defender_exclusoes.csv` vem do registro com coluna `Fonte=REGISTRO_FALLBACK`; eventos ainda em `17_`. |
| 3 | Hash + Authenticode de suspeitos | Além dos candidatos de licenciamento: todo indicio FORTE `.exe/.dll/.sys` e DLLs “loader” → SHA-256 + `Get-AuthenticodeSignature` em `11d_`. Novo `-CopiarSuspeitos`: copia binários suspeitos (hash mismatch / NotSigned forte) para `suspeitos_copias\` no pendrive (≤ 50 MB/arquivo, limite de tempo). Entram no manifesto. | Leitura de conteúdo (last-access); cópia só no pendrive. | Plantar `keygen.exe` sem assinatura → hash + `NotSigned` em `11d_`; com `-CopiarSuspeitos` arquivo na pasta e no manifesto. |
| 4 | Menos falsos positivos crack/keygen | Extensões ignoradas (imagens/PDF/texturas); caminhos `site-packages`, `numpy`, `textures`, `Materials`, `Maps`; nome `crackfortran`. Coluna `Classificacao` = `FORTE` / `FRACO` / `PROVAVEL_FALSO_POSITIVO`. FP vão para `11f_indicios_provavel_fp.csv` e **não** entram na contagem de fortes do resumo. Mantém `11e_` (exclusões explícitas tipo ssh-keygen). | Falso negativo se crack real tiver nome genérico em pasta de textura — aceitável; fica em 11f para revisão. | Plantar `texture_crack.png`, `crackfortran.py` em site-packages, `documento_crack.pdf` → 11f, não em 11 fortes; `Corel_keygen.exe` continua FORTE. |
| 5 | IDs de pasta padronizados | Normaliza `-Equip`: `1`/`EQ1`/`eq04` → `EQ01`/`EQ04` (mín. 2 dígitos). Aceita `EQ01` já correto. Inválido → `EQ_SEM_ID` + AVISO. | Cosmético. | Entradas `eq1`, `EQ1`, `4` → pastas `EQ01_*`, `EQ04_*`. |
| 6 | Perfis externos | `-Perfil caminho.psd1` (ou `.json`) carrega: `Fabricantes`, `IndiciosFortes/Fracos`, `ExclusaoIndicios`, `Extensoes`, `PastasPrograma`, `RaizesRegistroLicenca`, `PrefetchPrefixes`, `VendorGuess`, `DestacarPadrao`. Sem `-Perfil`, usa defaults embutidos **neutros** (regex genérica de indícios + fabricantes comuns de exemplo). Repo público: `perfis/exemplo_generico.psd1`. Perfil real do caso: `/workspace/pericia/...` (não versionado). | Perfil malformado aborta com código 5 antes de coletar. | Rodar com exemplo → log mostra perfil carregado; sem perfil → defaults. |
| 7 | Checklist capturas manuais | `KIT_PENDRIVE_v1.4.4.md` + seção no `00_RESUMO` “CAPTURAS MANUAIS PENDENTES”: Programas e Recursos / Aplicativos; tela Sobre (se autorizada); foto etiqueta EQ. | Nenhum. | Texto presente no resumo e no doc. |

## Arquivos (entregue como v1.4.4)

- `coleta_inventario_software_v1.4.4.ps1` (linha 1.4; intermediárias removidas da árvore)
- `rodar_coleta_v1.4.4.cmd`
- `KIT_PENDRIVE_v1.4.4.md`
- `PLANO_v1.4.md` (este — histórico)
- `perfis/exemplo_generico.psd1` (público)
- `CHECKLIST_CAMPO_v1.4.md` (capturas manuais)
- Append em `KIT_SHA256.txt`

## Ordem de implementação

1. Plano (este arquivo).  
2. Perfil exemplo + schema.  
3. Script v1.4 (cópia v1.3 + patches).  
4. Launcher + docs.  
5. Testes VM (admin + usuário; fixtures FP + hive offline + Defender fallback).  
6. Hashes + push repo público (varredura `rg` anti-vazamento).

## Fora de escopo v1.4

- Data de última gravação de chave de registro.  
- Seriais Autodesk só-na-nuvem.  
- Plano B `coleta_minima` com `00_RESUMO` (fica para v1.5).  
- AppLocker / relaunch 32→64 em ambiente restrito real (tentar na VM; documentar se inviável).

## Critério de pronto

- [ ] Parse AST OK (PowerShell 5.1 / 7).  
- [ ] Admin e usuário: exit 0; manifesto íntegro; `00_RESUMO` antes do manifesto.  
- [ ] C: sem escrita do script (USN filtrado = só churn OS).  
- [ ] FP classificados; hives offline (admin); Defender fallback; IDs EQ##.  
- [ ] Repo público sem marcas/caso; perfil real fora do git.
