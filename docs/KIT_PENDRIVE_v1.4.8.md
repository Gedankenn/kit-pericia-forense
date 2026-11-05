# Kit do pendrive para a vistoria de software (v1.4.8)

Processo sigiloso: use so identificadores **EQ01**, **EQ02** etc. Sem nomes das partes no rotulo/pastas.

**v1.4.8 (04/11/2026):**

- Descoberta de rede/servidores (SMB, UNC no registro, Recent .lnk, licenca `porta@host`, ARP, DNS, TCP, DC).
- Dedup: se o servidor ja foi escaneado em coleta anterior no mesmo pendrive, so documenta o acesso deste EQ.
- Scan somente leitura de shares novos -> `SRV_<id>\` (timeouts; `-SemRede` / `set KIT_REDE=0` para pular).
- Vizinhos so de ARP/DNS/TCP (`PULADO_SO_VIZINHO`) nao sao escaneados sem evidencia de share/UNC/licenca/DC; multicast/broadcast filtrados.
- Inventario de formatos de projeto/desenho: `formatos_arquivos.csv` + `formatos_resumo.csv` (metadados; sem cronologia; cabecalho DWG/PDF opcional).
- Mantem v1.4.7: manifesto sempre, falhas de copia, .lic NLM, relogio/NTP, Prefetch RunCount, hives+VSS, operador, menos FP.

## Estrutura do pendrive

```
E:\
|-- rodar_coleta_v1.4.8.cmd
|-- coleta_inventario_software_v1.4.8.ps1
|-- perfis\exemplo_generico.psd1
|-- capturar_tela.cmd / capturar_tela.ps1
|-- coleta_minima_v1.2.cmd
|-- KIT_SHA256.txt
|-- CHECKLIST_CAMPO_v1.4.md
\-- coleta\
    |-- INDICE_COLETAS.txt
    |-- INDICE_SERVIDORES.txt
    \-- EQ##_HOST_timestamp\
        |-- servidores_*.csv
        |-- acesso_pc_servidor.csv
        |-- formatos_*.csv
        \-- SRV_<id>\
```

## Rede

Ligado por padrao. Desliga: `set KIT_REDE=0` antes do lancador, ou `-SemRede`.

## Formatos

Padrao: `.rvt,.rfa,.rte,.dwg,.dxf,.dwt,.dgn,.ipt,.iam,.idw,.nwd,.nwc,.skp,.3dm,.max,.ifc,.sldprt,.sldasm,.slddrw,.pln,.stp,.step,.pdf`  
Override: `-ExtensoesFormato`. Sem leitura de cabecalho: `-SemCabecalhoFormato`.

## Codigos de saida

0 ok | 2 destino recusado | 3/4 pasta | 5 perfil | 6 ID EQ invalido

## Changelog

Ver `docs/CHANGELOG_v1.4.8.md`.
