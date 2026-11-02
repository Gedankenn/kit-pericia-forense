# Kit do pendrive para a vistoria de software (v1.4.3)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.3 (02/11/2026):**

- `-LerHivesOffline` **LIGADO por padrao** (admin). Desliga com `-SemHivesOffline` ou `set KIT_HIVES=0` no lancador.
- **Copia automatica** de arquivos suspeitos (indicios FORTES + binarios de licenciamento sem assinatura valida) para `suspeitos_copias\` no pendrive, com caminho relativo, SHA-256 origem/destino e CSV `11g_copias_suspeitos.csv`.
- Arquivos **> 500 MB**: pergunta S/N ao operador antes de copiar. Em teste: `-RespostaCopiaGrande S|N` ou `set KIT_COPIA_GRANDE=S`.
- Falsos positivos (`11f_`) e exclusoes (`11e_`) **nao** sao copiados.
- Checagem de espaco livre no pendrive antes de cada copia.
- Leitura da origem em modo somente leitura (timestamps da origem verificados).
- Unload dos hives temporarios em `finally` antes do manifesto.

Herda v1.4.1 (ASCII + UTF-8 BOM; ID EQ## obrigatorio).

## Estrutura do pendrive

```
E:\
├── rodar_coleta_v1.4.3.cmd
├── coleta_inventario_software_v1.4.3.ps1
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

1. Copia `NTUSER.DAT` para `coleta\...\hives_offline\` no pendrive.
2. `reg load HKU\PericiaTmp_*` **so da copia**.
3. Le Uninstall/MRU; `reg unload` no `finally` (antes do manifesto).

O original em `C:\Users\...\NTUSER.DAT` nao e aberto em escrita pelo script. O load/unload deixa rastros temporarios em HKU enquanto roda.

## Copia de suspeitos

- Automatica para indicios FORTES e DLLs/EXEs de licenciamento com Authenticode != Valid.
- Nao copia `11f_` (provavel FP) nem `11e_` (exclusao explicita, ex. SSH-KEYGEN).
- `> 500 MB`: prompt S/N; decisao registrada em `11g_copias_suspeitos.csv`.
- Destino: `suspeitos_copias\<caminho-relativo>` (ex.: `C\Users\Public\Downloads\KMSpico_setup.exe`).

## Changelog

### v1.4.3 (02/11/2026)
- Hives offline ligados por padrao; `-SemHivesOffline` / `KIT_HIVES=0`.
- Copia automatica de suspeitos + prompt >500 MB + `11g_` + espaco livre + hash origem/destino.
- Lancador rejeita ID invalido e pergunta de novo (ex.: mamae2).

### v1.4.2 (02/11/2026)
- Hives opt-in (revertido na 1.4.3).

### v1.4.1 (01/11/2026)
- Script 100% ASCII + UTF-8 BOM (corrige ParserError PS 5.1/cp1252 com em-dash).
- ID EQ## obrigatorio (codigo 6).

### v1.4
Ver `KIT_PENDRIVE_v1.4.md`.
