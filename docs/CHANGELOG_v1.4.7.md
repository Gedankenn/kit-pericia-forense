# Changelog — kit pericia forense v1.4.7

Data: 2026-11-04 (America/Sao_Paulo)  
Base: v1.4.6  
Arquivos novos (originais preservados):

- `scripts/coleta_inventario_software_v1.4.7.ps1`
- `scripts/rodar_coleta_v1.4.7.cmd`
- `docs/KIT_PENDRIVE_v1.4.7.md`
- `docs/CHANGELOG_v1.4.7.md` (este)

Nenhuma informacao de processo/partes neste documento.

## Alteracoes

1. **Manifesto + INDICE sempre** — `Write-ManifestoEIndice` em try/catch/finally e `trap`; atualiza `INDICE_COLETAS.txt` mesmo em abort.
2. **Copias falhas** — destino parcial removido; registro em `19_falhas_copia.csv`; manifesto so lista arquivos existentes (exclui `_kit_tmp`).
3. **Licencas NLM/FlexLM** — varre registro, env `LM_LICENSE_FILE` / `*_LICENSE_FILE` e pastas NLM/FLEXnet; copia `licenses.lic`, `licpath.lic` e `.dat` referidos para `licencas_referenciadas\` (`07b_licencas_referenciadas.csv`).
4. **Relogio** — `01g_relogio_inicio.csv` / `01g_relogio_fim.csv` com hora, fuso, `w32tm /query /status` e offset `/stripchart` (somente leitura).
5. **Hash de firewall/Defender** — coluna `SHA256Programa` nas regras; `17e_defender_exclusoes_hash.csv` para exclusoes que sao arquivo.
6. **Prefetch parseado** — colunas `PrefetchVersao`, `RunCount`, `UltimasExecucoes` (v17/23/26/30; MAM via ntdll; TEMP no pendrive). RunCount: v17@0x98, v23/26@0xD0, v30@0xC8.
7. **Hives completos** — `UsrClass.dat` de todos os perfis (`01h_usrclass.csv`); fallback VSS documentado apos FileShare/`reg save`.
8. **Operador + ordem + captura final** — prompt/`-Operador`; `00b_ordem_coleta.csv`; PNG de tela no inicio e no fim.
9. **Falsos positivos de nome** — `AdskRcDispatch`, `AsmPreloader`/preloader Autodesk, Dynamo `*.Patch.dyn` / `CloseCracks.dyn` (e json de geometria relacionados) vao para `11f_`.

## Verificado como ainda valido (herdado da v1.4.6)

1. FP de servicos `InventorySvc` / `LicenseManager` (e afins) nao entram como fabricante.
2. Avisos esperados (`SEM_EVENTOS`, pastas Public/Default inexistentes) nao inflama a contagem de erros do resumo.
3. Hive do usuario logado continua sendo exportado (`COPIADO_SESSAO_ATIVA`), agora no conjunto de todos os perfis.

## Limitacoes

- Captura de tela exige sessao interativa (SSH puro: `CopyFromScreen` falha — esperado).
- Fallback VSS cria/remove shadow temporario (documentado no log; nao e puramente passivo).
- Prefetch MAM depende de `ntdll!RtlDecompressBufferEx`; se indisponivel, mantem metadados de filesystem sem RunCount.
- Offset NTP depende de rede ate o peer; sem rede o campo fica vazio e o status w32tm local permanece.
- Nao faz commit/push automatico: revisao humana antes de uso em campo.
