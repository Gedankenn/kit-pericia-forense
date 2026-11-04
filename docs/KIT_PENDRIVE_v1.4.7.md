# Kit do pendrive para a vistoria de software (v1.4.7)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.7 (04/11/2026):**

- Manifesto SHA-256 e `INDICE_COLETAS.txt` gravados **sempre** (try/finally + trap), mesmo se a coleta abortar.
- Copias que falham **nao** entram no manifesto; falha registrada em `19_falhas_copia.csv` e no log.
- Copia obrigatoria de `.lic`/`.dat` NLM/FlexLM referidos em registro, env (`LM_LICENSE_FILE`, `*_LICENSE_FILE`) e pastas FLEXnet/NLM (inclui `licenses.lic` / `licpath.lic`) -> `licencas_referenciadas\` + `07b_`.
- Relogio no **inicio e no fim**: hora local/UTC, fuso, `w32tm /query /status` e offset via `/stripchart` (somente leitura; **nunca** `/resync`).
- SHA-256 dos binarios citados em regras de firewall e nas exclusoes do Defender (quando forem arquivo).
- Prefetch: `RunCount` + ultimas execucoes (versoes 17/23/26/30; MAM descompactado via `RtlDecompressBufferEx` / ntdll; temp so no pendrive).
- `NTUSER.DAT` + `UsrClass.dat` de **todos** os perfis (FileShare, `reg save`, fallback VSS documentado).
- Ordem de coleta com timestamps + nome do operador (`-Operador` / prompt do `.cmd`); captura de tela no **inicio e no fim**.
- Menos FP de nome: `AdskRcDispatch`, `AsmPreloader` / preloader Autodesk, scripts Dynamo `*.Patch.dyn` / `CloseCracks.dyn`.
- Mantem v1.4.6: FP InventorySvc/LicenseManager; SEM_EVENTOS/Public nao contam como erro; hive da sessao ativa `COPIADO_SESSAO_ATIVA`.

## Estrutura do pendrive

```
E:\
|-- rodar_coleta_v1.4.7.cmd
|-- coleta_inventario_software_v1.4.7.ps1
|-- perfis\exemplo_generico.psd1
|-- capturar_tela.cmd / capturar_tela.ps1
|-- coleta_minima_v1.2.cmd
|-- KIT_SHA256.txt
|-- CHECKLIST_CAMPO_v1.4.md
\-- coleta\
```

## Codigos de saida

0 ok | 2 destino recusado | 3/4 pasta | 5 perfil | 6 ID EQ invalido

## Operador

O lancador pergunta o nome do operador/perito (ou use `-Operador` / `set KIT_OPERADOR=`). Fica em `00b_ordem_coleta.csv` e no cabecalho do manifesto.

## Hives (padrao ligado)

1. Todos os perfis: tenta `NTUSER.DAT` + `UsrClass.dat` para o pendrive.
2. Logado: evidencia sem `reg load` (FileShare / `reg save` / VSS).
3. Deslogados: copia + `reg load` **so da copia**.
4. `reg unload` no `finally` (antes do manifesto).

Desliga com `-SemHivesOffline` ou `set KIT_HIVES=0`.

## Copia de suspeitos

Igual v1.4.6: automatica para FORTES (nao FP); `> 500 MB` pergunta S/N. Falha de copia -> log + `19_falhas_copia.csv`, sem entrada fantasma no manifesto.

## Changelog

Ver `docs/CHANGELOG_v1.4.7.md`.
