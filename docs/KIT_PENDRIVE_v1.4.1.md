# Kit do pendrive para a vistoria de software (v1.4.1)

Processo sigiloso: o pendrive e os arquivos de saida ficam so com o perito. Nao coloque nomes das partes no rotulo do pendrive nem nos nomes de pasta. Use so os identificadores **EQ01**, **EQ02** etc.

**v1.4.1 (01/11/2026):** correcao critica de encoding para Windows PowerShell 5.1. O `.ps1` e 100% ASCII com **UTF-8 BOM**; o lancador `.cmd` e ASCII com CRLF. O ID do equipamento e obrigatorio no formato `EQ##` (aceita `1` / `EQ1` / `EQ01`; rejeita texto livre como `mamae2`, codigo de saida **6**).

A v1.4 permanece arquivada (nao sobrescrita). Em campo, prefira **v1.4.1**.

## 1. Estrutura do pendrive

```
E:\                                   (pendrive do perito, NTFS ou exFAT, >= 16 GB)
├── rodar_coleta_v1.4.1.cmd           <- lancador (botao direito > Executar como administrador)
├── coleta_inventario_software_v1.4.1.ps1
├── perfis\
│   └── exemplo_generico.psd1         <- listas de fabricantes/indicios (troque pelo perfil do caso)
├── capturar_tela.cmd / capturar_tela.ps1
├── coleta_minima_v1.2.cmd            <- PLANO B (PowerShell bloqueado; sem 00_RESUMO)
├── KIT_SHA256.txt
├── CHECKLIST_CAMPO_v1.4.md
└── coleta\
    ├── EQ01_<HOST>_<data_hora>\
    │   ├── 00_RESUMO.txt
    │   ├── hives_offline\            <- copias NTUSER.DAT (se -LerHivesOffline)
    │   ├── suspeitos_copias\         <- se -CopiarSuspeitos
    │   ├── *.csv / *.txt
    │   └── MANIFESTO_SHA256.txt
    └── INDICE_COLETAS.txt
```

No pendrive da diligencia leve **apenas** os arquivos v1.4.1 (+ plano B e capturar_tela). Versoes antigas ficam arquivadas.

## 2. O lancador `rodar_coleta_v1.4.1.cmd`

- PowerShell 5.1 64 bits com `-NoProfile -ExecutionPolicy Bypass -File`.
- `PSModuleAnalysisCachePath=NUL`.
- Pede o identificador, **valida EQ##** e roda com `-CapturaTela` e `-Perfil perfis\exemplo_generico.psd1` (se existir).
- Equivalente:
  `powershell -NoProfile -ExecutionPolicy Bypass -File E:\coleta_inventario_software_v1.4.1.ps1 -Equip EQ01 -CapturaTela -Perfil E:\perfis\exemplo_generico.psd1`

### Codigos de saida

| Codigo | Significado |
|---|---|
| 0 | ok |
| 2 | destino recusado (ex.: disco do sistema) |
| 3/4 | erro de pasta |
| 5 | perfil invalido |
| 6 | identificador EQ invalido |

### Parametros (herdados da v1.4)

| Parametro | Funcao |
|---|---|
| `-Perfil` | Carrega `.psd1`/`.json` com Fabricantes, indicios, pastas etc. Codigo 5 se invalido. |
| `-LerHivesOffline` | Padrao **ligado** se admin. Copia `NTUSER.DAT` para o pendrive e faz `reg load` **so da copia**. |
| `-SemHivesOffline` | Desliga a carga de hives deslogados. |
| `-CopiarSuspeitos` | Copia binarios com assinatura invalida/ausente para `suspeitos_copias\` (<= 50 MB). |
| `-Destacar` | So prioriza fabricantes no topo do resumo (nunca oculta o resto). |
| `-ModoTeste` | Permite gravar no disco do sistema (PC do perito). |

## 3. Passo a passo

Ver tambem `CHECKLIST_CAMPO_v1.4.md`.

1. Fotos previas (equipamento, tela, relogios). Nao fazer logoff.
2. Plugar pendrive; recusar "verificar e corrigir".
3. `rodar_coleta_v1.4.1.cmd` como administrador.
4. Digitar EQ (ex. `EQ01` ou `1`). Texto livre e rejeitado.
5. Ler/fotografar `00_RESUMO.txt` + hash do manifesto.
6. **Capturas manuais:** Programas e Recursos / Aplicativos; Sobre so se autorizado (por ultimo).
7. Ejetar. Se PowerShell bloqueado -> `coleta_minima_v1.2.cmd`.

Funcionalidade de coleta = v1.4 (hives offline, fallback Defender, hash/assinatura, FP, `-Perfil`). Ver `KIT_PENDRIVE_v1.4.md` para o detalhe dos CSVs.

## 4. Por que a v1.4.1 existe

No Windows PowerShell **5.1**, script `.ps1` salvo em UTF-8 **sem BOM** e interpretado com a pagina de codigo do sistema (tipicamente **cp1252** no Brasil). O byte `0x94` do em-dash UTF-8 (`—` = `E2 80 94`) vira aspas curvas `”` no meio de uma string, e o parser quebra (`ParserError` em cascata).

Correcao: corpo 100% ASCII + UTF-8 BOM; `.cmd` ASCII CRLF. Validado com `Parser::ParseFile` (0 erros) e reparse do corpo como cp1252 (0 erros).

## 5. Checklist pre-voo (PC do perito)

- [ ] Formatar pendrive; copiar so o kit v1.4.1.
- [ ] Conferir `KIT_SHA256.txt`.
- [ ] Confirmar que o `.ps1` abre no Notepad e a 1a linha nao mostra `ï»¿` quebrado de forma estranha (BOM e esperado; o restante ASCII).
- [ ] Rodar com `-ModoTeste` como admin: ID `mamae2` deve falhar (codigo 6); ID `1` deve virar `EQ01`.
- [ ] Conferir manifesto e que C: nao recebeu escrita do script.

## 6. Changelog v1.4.1 (01/11/2026)

**Arquivos novos:** `coleta_inventario_software_v1.4.1.ps1`, `rodar_coleta_v1.4.1.cmd`, `KIT_PENDRIVE_v1.4.1.md`. Hashes appendados em `KIT_SHA256.txt`. v1.4 nao foi sobrescrita.

- Script 100% ASCII + UTF-8 BOM (corrige ParserError do PS 5.1 / cp1252).
- Lancador `.cmd` ASCII + CRLF; valida EQ## antes de chamar o script.
- ID obrigatorio `EQ##` (aceita numero / EQ1 / EQ01); rejeita texto livre; codigo 6.

## Changelog v1.4 / v1.3 / ...

Ver `KIT_PENDRIVE_v1.4.md` e `KIT_PENDRIVE_v1.3.md`.
