```
+------------------------------------------------------------------------------+
|  >_ KIT PERICIA FORENSE                                      [READ-ONLY]     |
|  __________________________________________________________________________  |
|   _  __ ___ _____   ____  _____ ____  ___ ____ ___    _                      |
|  | |/ /|_ _|_   _| |  _ \| ____|  _ \|_ _/ ___|_ _|  / \                     |
|  | ' /  | |  | |   | |_) |  _| | |_) || | |    | |  / _ \                    |
|  | . \  | |  | |   |  __/| |___|  _ < | | |___ | | / ___ \                   |
|  |_|\_\|___| |_|   |_|   |_____|_| \_\___\____|___/_/   \_\                  |
|  __________________________________________________________________________  |
|  | Coleta de inventario de software  |  PowerShell 5.1  |  v1.4.5          | |
|  | Somente leitura na maquina        |  Saida no pendrive |  EQ##          | |
|  |____[ SHA-256 manifesto ]__________|__[ sem telemetria ]|________________| |
+------------------------------------------------------------------------------+
```

# Kit Pericia Forense

![versao](https://img.shields.io/badge/versao-v1.4.5-FFB000?style=flat-square&labelColor=1a1200)
![ps](https://img.shields.io/badge/PowerShell-5.1-4472C4?style=flat-square&labelColor=1a1200)
![win](https://img.shields.io/badge/Windows-10%20%2F%2011-00A4EF?style=flat-square&labelColor=1a1200)
![licenca](https://img.shields.io/badge/licenca-MIT-22c55e?style=flat-square&labelColor=1a1200)
![telemetria](https://img.shields.io/badge/telemetria-nenhuma-111827?style=flat-square&labelColor=1a1200)
![metrics](https://img.shields.io/badge/metrics-off-111827?style=flat-square&labelColor=1a1200)

**Coleta somente-leitura de inventario de software para vistoria / pericia judicial.**  
Roda no pendrive, grava so no pendrive, fecha com manifesto SHA-256. Sem telemetria, sem phone-home, sem nuvem.

> Autor: **Fabio Slika Stella** — CREA/PR PR-224755/D  
> Script atual: [`scripts/coleta_inventario_software_v1.4.5.ps1`](scripts/coleta_inventario_software_v1.4.5.ps1) · Lancador: [`scripts/rodar_coleta_v1.4.5.cmd`](scripts/rodar_coleta_v1.4.5.cmd)  
> Oficial anterior (v1.3): [`scripts/coleta_inventario_software_v1.3.ps1`](scripts/coleta_inventario_software_v1.3.ps1) · [`scripts/rodar_coleta_v1.3.cmd`](scripts/rodar_coleta_v1.3.cmd)

---

## Galeria — fluxo na VM de teste

Sequencia real do console (estilo amber HUD). Hostnames e caminhos de exemplo sao genericos.

| # | Cena | Preview |
|---|------|---------|
| 01 | Banner no inicio da execucao | ![01 banner](img/01_banner_inicio.png) |
| 02 | Prompt do ID `EQ##` (rejeita texto livre) | ![02 EQ](img/02_prompt_EQ.png) |
| 03 | Prompt de arquivo suspeito **> 500 MB** | ![03 500MB](img/03_prompt_500MB.png) |
| 04 | Progresso das secoes | ![04 secoes](img/04_progresso_secoes.png) |
| 05 | `00_RESUMO.txt` (com banner no topo) | ![05 resumo](img/05_00_RESUMO.png) |
| 06 | Verificacao do manifesto SHA-256 | ![06 manifesto](img/06_manifesto_verify.png) |
| 07 | Tela final **COLETA CONCLUIDA** | ![07 fim](img/07_coleta_concluida.png) |

---

## O que e

Kit de campo para **inventario forense de software** em Windows. O perito leva o pendrive, executa o lancador como administrador, informa o identificador do equipamento (`EQ01`, `EQ02`…) e leva embora so o que foi gravado na pasta `coleta\` do proprio pendrive.

Pensado para ata / laudo: saida estruturada (CSV + TXT), resumo minimo legivel na tela, e cadeia de custodia via `MANIFESTO_SHA256.txt`.

---

## Garantias (read-only)

| Garantia | Como |
|----------|------|
| Nao instala / nao desinstala / nao repara MSI | Nao usa `Win32_Product`; le Uninstall via .NET somente leitura |
| Nao altera arquivos da maquina vistoriada | Leituras com share de leitura; timestamps da origem conferidos nas copias |
| Saida so no pendrive | Recusa gravar no disco do sistema (salvo `-ModoTeste` no PC do perito) |
| Hives de usuarios deslogados | Copia `NTUSER.DAT` **para o pendrive** e faz `reg load` so da copia; `unload` no `finally` |
| Sem telemetria | Sem rede propria do kit, sem metrics, sem update check |
| Integridade | Todo arquivo gerado entra no manifesto SHA-256 (incluindo o `00_RESUMO.txt`) |

Inevitavel (efeito da diligencia, anotar na ata): o Windows registra a conexao do pendrive e a execucao do PowerShell (Prefetch, USBSTOR, logs).

---

## O que coleta

- Identificacao do host, discos, volumes, perfis
- Programas (Uninstall 64/32 + `HKEY_USERS`)
- Prefetch, Recent/Jump Lists, MRU (quando hive disponivel)
- Hosts e regras de firewall ligadas a licenciamento/ativacao
- Eventos MSI, limpeza de logs, servicos
- Defender: deteccoes/exclusoes (cmdlet com **fallback via registro**)
- Arquivos de projeto (extensoes configuraveis) e indicios de crack/keygen/ativador
- Authenticode + SHA-256 de binarios de licenciamento / indicios fortes
- **Copia automatica** dos suspeitos para `suspeitos_copias\` (CSV `11g_`; FP em `11f_` nao sao copiados)
- Resumo generico `00_RESUMO.txt` + manifesto

Listas de fabricantes/indicios podem ir num `-Perfil` externo (`.psd1` / `.json`) para nao hardcodar o caso no script publicado.

---

## Versoes neste repositorio

So duas linhas de script ficam na arvore (intermediarias quebradas/fora de uso foram removidas; o historico git preserva tudo):

| Versao | Papel |
|--------|-------|
| **v1.4.5** | **Atual** — use esta em campo. Lancador `.cmd` com EQ## em batch puro (aceita `eq01`); banner ASCII HUD; hives ON; copia automatica de suspeitos (prompt **> 500 MB**); ASCII + UTF-8 BOM |
| **v1.3** | **Oficial estavel** anterior (pre-1.4) — `00_RESUMO` generico + `-Destacar`; plano B `coleta_minima_v1.2.cmd` |

Arquivos novos de versao **nunca sobrescrevem** os anteriores; o que nao esta mais na arvore continua no historico do git.

---

## Uso rapido (pendrive)

1. Copie para a raiz do pendrive:
   - `scripts/coleta_inventario_software_v1.4.5.ps1`
   - `scripts/rodar_coleta_v1.4.5.cmd`
   - `perfis/exemplo_generico.psd1` (opcional)
   - `KIT_SHA256.txt` + docs do pendrive (opcional)
2. No PC vistoriado: botao direito em `rodar_coleta_v1.4.5.cmd` → **Executar como administrador**.
3. Informe o ID (`EQ01` ou so `1`). Texto livre e **rejeitado** (codigo de saida `6`).
4. Se aparecer arquivo **> 500 MB**, responda `S` ou `N` (a decisao vai para `11g_copias_suspeitos.csv`).
5. Fotografe o resumo + hash do manifesto; siga o checklist de capturas manuais.

Codigos de saida: `0` ok · `2` destino recusado · `3`/`4` pasta · `5` perfil · `6` ID invalido.

---

## Parametros principais

| Parametro | Padrao | Efeito |
|-----------|--------|--------|
| `-Equip` | (obrigatorio) | `EQ##` — aceita `1` / `EQ1` / `EQ01` |
| `-Destino` | `.\coleta` | Pasta de saida (deve ficar no pendrive) |
| `-Perfil` | — | `.psd1` / `.json` com listas externas |
| `-CapturaTela` | off | PNG da tela no inicio (precisa sessao interativa) |
| `-SemHivesOffline` | — | Desliga carga de hives deslogados |
| `-SemCopiarSuspeitos` | — | Desliga copia automatica |
| `-RespostaCopiaGrande S\|N` | pergunta | Resposta automatica ao limiar >500 MB (teste/CI) |
| `-LimitePerguntaCopiaMB` | `500` | Limiar do prompt |
| `-Destacar` | vazio | Destaca fabricantes no topo do resumo (**nunca oculta** o resto) |
| `-ModoTeste` | off | Permite gravar fora do pendrive (so no PC do perito) |

Atalhos do `.cmd`: `set KIT_HIVES=0` desliga hives; `set KIT_COPIA_GRANDE=S` (ou `N`) responde o prompt grande.

---

## Saida, manifesto e integridade

Estrutura tipica apos uma coleta:

```
D:\coleta\EQ01_HOSTNAME_yyyyMMdd_HHmmss\
├── 00_RESUMO.txt              ← banner + irregularidades + checklist
├── 00_log_execucao.txt
├── 00_resumo_secoes.csv
├── 11_indicios_*.csv / 11f_ / 11g_
├── suspeitos_copias\...       ← copias com caminho relativo
├── hives_offline\...          ← copias de NTUSER.DAT (se hives ligados)
├── MANIFESTO_SHA256.txt
└── MANIFESTO_SHA256.txt.sha256
```

Conferir o kit no pendrive:

```bash
sha256sum -c KIT_SHA256.txt --ignore-missing
```

Hashes oficiais: [`KIT_SHA256.txt`](KIT_SHA256.txt) · Guia do pendrive: [`docs/KIT_PENDRIVE_v1.4.5.md`](docs/KIT_PENDRIVE_v1.4.5.md) · Exemplo de resumo: [`exemplos/exemplo_00_RESUMO_v1.4.5.txt`](exemplos/exemplo_00_RESUMO_v1.4.5.txt)

---

## Cenarios testados (laboratorio)

VM Windows 10 Enterprise Eval, PowerShell 5.1, QEMU TCG (sem KVM), pendrive simulado.

| Cenario | Versao | Resultado |
|---------|--------|-----------|
| Admin via `.\rodar_coleta_v1.4.5.cmd`, ID **`eq01`** (minusculas) | 1.4.5 | OK; normalizou para `EQ01`; coleta ~146 s sob TCG; manifesto confere |
| Admin, resposta **N** ao arquivo >500 MB | 1.4.4 | OK (~4 min sob TCG); decisao `PULADO_OPERADOR_N`; FPs nao copiados; manifesto confere |
| Admin, resposta **S** ao arquivo >500 MB | 1.4.4 | OK; banner no console e no resumo; hive offline via copia; `COPIADO_APOS_SIM` com HashOk; unload no finally |
| Usuario padrao (sem admin) | 1.4.4 | OK; hives desligados automaticamente; copia de suspeitos acessiveis segue |

Ainda a validar em campo: relaunch 32→64 sob AppLocker restrito; PC lento / AV corporativo agressivo; captura de tela exige console interativo (SSH puro falha no `CopyFromScreen`).

---

## Uso em campo (referencia)

Pericia judicial de inventario de software (Brasil, out/2026) — **sem identificar partes, processo ou fabricantes da acao**:

- 9 PCs Windows (7 Win10 Pro, 2 Win11 Pro), todos como Administrador
- Tempo medio ~**67 s**/PC (min 27, max 163); nenhuma varredura estourou 240 s
- **527** softwares inventariados (media ~59/PC)
- Manifesto SHA-256: **0 falhas** nas 9 coletas; saida so no pendrive
- Campo rodou **v1.2**; laboratorio validou a linha **v1.4.x** na VM

Achados tipicos (genericos): regras de firewall bloqueando licenciamento; DLL de licenca sem assinatura valida; keygens/ativadores; exclusoes do Defender; arquivos de projeto sem o produto instalado; falsos positivos do matcher (texturas com "crack" no nome, etc. — agora separados em `11f_`).

---

## Roadmap

- [ ] Carregar hive deslogado ainda mais robusto / documentar workaround de campo
- [ ] Menos FP no matcher (alem de `11f_`)
- [ ] Hash/assinatura automaticos ja feitos na 1.4 — expandir candidatos
- [ ] Teste ponta a ponta: usuario no console fisico; AppLocker; AV corporativo
- [ ] Plano B (`coleta_minima`) gerar resumo minimo compativel

---

## Changelog resumido

- **v1.4.5** *(atual)* — Corrige lancador (`.cmd` sem PowerShell inline; `eq01` -> `EQ01`); herda banner HUD, FileShare hive, hives ON, copia automatica + prompt >500 MB, ASCII/BOM, Defender fallback, FP, `-Perfil`  
- **v1.3** *(oficial anterior)* — `00_RESUMO` generico + `-Destacar`  
- **v1.2** — Exclusao de indicios (ex.: SSH-KEYGEN); plano B `coleta_minima`  

Detalhes atuais: [`docs/KIT_PENDRIVE_v1.4.5.md`](docs/KIT_PENDRIVE_v1.4.5.md) · Oficial anterior: [`docs/KIT_PENDRIVE_v1.3.md`](docs/KIT_PENDRIVE_v1.3.md)

---

## Licenca e autor

[MIT](LICENSE) © 2026 Fabio Slika Stella (CREA/PR PR-224755/D).

Uso pericial / forense bem-vindo. **Nao publique dados de casos reais neste repositorio.** Sem telemetria.
