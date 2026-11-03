# Kit do pendrive para a vistoria de software (v1.4.4)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.4 (02/11/2026):**

- Banner ASCII cyber/HUD (80 colunas) no inicio da execucao e no topo do `00_RESUMO.txt`.
- Fallback de copia de `NTUSER.DAT` com `FileShare.ReadWrite` quando o hive esta travado.
- Hives offline **ligados por padrao**; copia automatica de suspeitos; prompt se arquivo **> 500 MB**.

## Estrutura do pendrive

```
E:\
├── rodar_coleta_v1.4.4.cmd
├── coleta_inventario_software_v1.4.4.ps1
├── perfis\exemplo_generico.psd1
├── capturar_tela.cmd / capturar_tela.ps1
├── coleta_minima_v1.2.cmd
├── KIT_SHA256.txt
├── CHECKLIST_CAMPO_v1.4.md
└── coleta\
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

### v1.4.4 (02/11/2026) — versao atual neste repositorio
- Banner ASCII cyber/HUD (80 colunas) no inicio e no `00_RESUMO`.
- Fallback FileShare na copia de NTUSER.DAT travado.
- Inclui (da linha 1.4.x): hives offline ligados por padrao; copia automatica de suspeitos; prompt >500 MB; ID `EQ##`; script 100% ASCII + UTF-8 BOM.

A oficial estavel anterior permanece em `KIT_PENDRIVE_v1.3.md` / `coleta_inventario_software_v1.3.ps1`.
Intermediarias (v1.4 / 1.4.1 / 1.4.2 / 1.4.3) nao ficam mais na arvore — so no historico git.
