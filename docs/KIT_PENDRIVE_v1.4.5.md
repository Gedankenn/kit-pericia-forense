# Kit do pendrive para a vistoria de software (v1.4.5)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.5 (03/11/2026):**

- Lancador `.cmd` **sem PowerShell inline**: valida/normaliza `EQ##` em batch puro (corrige falha ao digitar `eq01` na v1.4.4).
- Aceita `1` / `EQ1` / `EQ01` / `eq01` / `EQ_01`; rejeita texto livre (codigo 6).
- Herda v1.4.4: banner ASCII; fallback FileShare no `NTUSER.DAT`; hives offline ON; copia automatica de suspeitos; prompt se **> 500 MB**.

## Estrutura do pendrive

```
E:\
|-- rodar_coleta_v1.4.5.cmd
|-- coleta_inventario_software_v1.4.5.ps1
|-- perfis\exemplo_generico.psd1
|-- capturar_tela.cmd / capturar_tela.ps1
|-- coleta_minima_v1.2.cmd
|-- KIT_SHA256.txt
|-- CHECKLIST_CAMPO_v1.4.md
\-- coleta\
```

## Codigos de saida

0 ok | 2 destino recusado | 3/4 pasta | 5 perfil | 6 ID EQ invalido

## Hives offline (padrao ligado)

Com admin (padrao):

1. Copia `NTUSER.DAT` para `coleta\...\hives_offline\` no pendrive (com fallback FileShare se travado).
2. `reg load HKU\PericiaTmp_*` **so da copia**.
3. Le Uninstall/MRU; `reg unload` no `finally` (antes do manifesto).

Desliga com `-SemHivesOffline` ou `set KIT_HIVES=0` no lancador.

## Copia de suspeitos

- Automatica para indicios FORTES e DLLs/EXEs de licenciamento com Authenticode != Valid.
- Nao copia `11f_` (provavel FP) nem `11e_` (exclusao explicita).
- `> 500 MB`: prompt S/N; em teste `-RespostaCopiaGrande S|N` ou `set KIT_COPIA_GRANDE=S`.
- Destino: `suspeitos_copias\<caminho-relativo>`; CSV `11g_copias_suspeitos.csv`.

## Changelog

### v1.4.5 (03/11/2026)
- Corrige o lancador: a v1.4.4 quebrava apos o prompt do EQ por causa de `for /f` + PowerShell inline (aspas/parenteses). Validacao agora e 100% batch.
- Aceita ID em minusculas (`eq01` -> `EQ01`).

### v1.4.4 (02/11/2026)
- Banner ASCII cyber/HUD (80 colunas) no inicio e no `00_RESUMO`.
- Fallback FileShare na copia de NTUSER.DAT travado.

### v1.4.3 (02/11/2026)
- Hives offline ligados por padrao; copia automatica de suspeitos; prompt >500 MB; ID EQ##.

### v1.4.1 (01/11/2026)
- Script 100% ASCII + UTF-8 BOM (corrige ParserError PS 5.1/cp1252).

