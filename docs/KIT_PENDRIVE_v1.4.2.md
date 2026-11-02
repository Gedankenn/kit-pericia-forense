# Kit do pendrive para a vistoria de software (v1.4.2)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.2 (02/11/2026):** `-LerHivesOffline` fica **DESLIGADO por padrao** (opt-in). Para ligar: passar `-LerHivesOffline` ou, no lancador, `set KIT_HIVES=1` antes de rodar. Motivo: `reg load` da copia ainda cria chave temporaria em HKU no PC vistoriado; melhor exigir escolha consciente do perito.

Herda a v1.4.1 (ASCII + UTF-8 BOM; ID EQ## obrigatorio).

## Estrutura do pendrive

```
E:\
├── rodar_coleta_v1.4.2.cmd
├── coleta_inventario_software_v1.4.2.ps1
├── perfis\exemplo_generico.psd1
├── capturar_tela.cmd / capturar_tela.ps1
├── coleta_minima_v1.2.cmd
├── KIT_SHA256.txt
├── CHECKLIST_CAMPO_v1.4.md
└── coleta\
```

## Codigos de saida

0 ok | 2 destino recusado | 3/4 pasta | 5 perfil | 6 ID EQ invalido

## Hives offline (risco e opt-in)

Com `-LerHivesOffline` (admin):

1. Copia `NTUSER.DAT` para `coleta\...\hives_offline\` no pendrive.
2. `reg load HKU\PericiaTmp_*` **so da copia**.
3. Le Uninstall/MRU; `reg unload` no fim.

O original em `C:\Users\...\NTUSER.DAT` nao e aberto em escrita pelo script. Ainda assim o load/unload deixa rastros em HKU enquanto roda — por isso o padrao e **desligado**.

## Changelog

### v1.4.2 (02/11/2026)
- `-LerHivesOffline` opt-in (desligado por padrao); `KIT_HIVES=1` no `.cmd`.
- Sem admin + flag: avisa e desliga.

### v1.4.1 (01/11/2026)
- Script 100% ASCII + UTF-8 BOM (corrige ParserError PS 5.1/cp1252 com em-dash).
- ID EQ## obrigatorio (codigo 6).

### v1.4
Ver `KIT_PENDRIVE_v1.4.md`.
