# Kit do pendrive para a vistoria de software (v1.4.6)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.6 (03/11/2026):**

- Menos falsos positivos de servicos: `InventorySvc` / `LicenseManager` da Microsoft nao entram mais como Autodesk/licenca de fabricante (`\bInventor\b`, sem `|Licens` generico).
- Avisos de `SEM_EVENTOS` (log sem MSI/104/7045) e caminhos inexistentes de `Public`/`Default` **nao contam** como erro nao-fatal.
- Perfis `Public` / `Default` / `Default User`: pulados em Recent e AppData de fabricante; aviso "sem hive" vira INFO esperado.
- Usuario **logado**: exporta hive para `hives_offline\` **sem** `reg load` (FileShare ou `reg save HKU\SID`; status `COPIADO_SESSAO_ATIVA`); leitura live via `HKU\<SID>`.
- Herda v1.4.5: lancador `.cmd` valida `EQ##` em batch puro (aceita `eq01`).

## Estrutura do pendrive

```
E:\
|-- rodar_coleta_v1.4.6.cmd
|-- coleta_inventario_software_v1.4.6.ps1
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

1. Usuario logado: evidencia no pendrive (`COPIADO_SESSAO_ATIVA`) via FileShare ou, se travado, `reg save HKU\<SID>` (sem `reg load`; original intacto).
2. Usuarios deslogados: copia + `reg load HKU\PericiaTmp_*` **so da copia**.
3. `reg unload` no `finally` (antes do manifesto).

Desliga com `-SemHivesOffline` ou `set KIT_HIVES=0` no lancador.

## Copia de suspeitos

- Automatica para indicios FORTES e DLLs/EXEs de licenciamento com Authenticode != Valid.
- Nao copia `11f_` (provavel FP) nem `11e_` (exclusao explicita).
- `> 500 MB`: prompt S/N; em teste `-RespostaCopiaGrande S|N` ou `set KIT_COPIA_GRANDE=S`.
- Destino: `suspeitos_copias\<caminho-relativo>`; CSV `11g_copias_suspeitos.csv`.

## Changelog

### v1.4.6 (03/11/2026)
- FP servicos: `\bInventor\b`, remove `|Licens` generico, ignora InventorySvc/LicenseManager/sppsvc/ClipSVC.
- Contagem de erros: filtra NoMatchingEventsFound e DirectoryNotFound; Test-Path antes de Enumerate*.
- Perfis especiais silenciosos em Recent/AppData; aviso "sem hive" so para usuarios reais.
- Copia/exporta hive da sessao ativa para o pendrive (FileShare ou reg save; COPIADO_SESSAO_ATIVA), hasheado no manifesto.

### v1.4.5 (03/11/2026)
- Corrige o lancador: validacao EQ## 100% batch; aceita `eq01`.

### v1.4.4 (02/11/2026)
- Banner ASCII; fallback FileShare na copia de NTUSER.DAT travado.

### v1.4.3 (02/11/2026)
- Hives offline ligados por padrao; copia automatica de suspeitos; prompt >500 MB; ID EQ##.

### v1.4.1 (01/11/2026)
- Script 100% ASCII + UTF-8 BOM (corrige ParserError PS 5.1/cp1252).
