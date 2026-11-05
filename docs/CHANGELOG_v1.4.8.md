# Changelog — kit pericia forense v1.4.8

Data: 2026-11-04 (America/Sao_Paulo)  
Base: v1.4.7  
Arquivos novos (originais preservados):

- `scripts/coleta_inventario_software_v1.4.8.ps1`
- `scripts/rodar_coleta_v1.4.8.cmd`
- `docs/KIT_PENDRIVE_v1.4.8.md`
- `docs/CHANGELOG_v1.4.8.md` (este)

Nenhuma informacao de processo/partes neste documento.

## Alteracoes

1. **Descoberta de rede/servidores (somente leitura)** — mapeamentos SMB (`Get-SmbMapping`/`Get-SmbConnection`/`net use`), UNC no registro (Network, MountPoints2, RecentDocs, TypedPaths, RunMRU, Map Network Drive MRU), alvos UNC de `.lnk` Recent, servidores de licenca `porta@host` (`LM_LICENSE_FILE` / `*_LICENSE_FILE`), ARP/`Get-NetNeighbor`, DNS cache (filtros), TCP estabelecidos em portas de arquivo/licenca, dominio/DC (`nltest`).
2. **Deduplicacao** — ID estavel `Hostname[+IPs][+MAC]`; antes de escanear consulta pastas `SRV_*`, `servidores_escaneados.csv` e `INDICE_SERVIDORES.txt` em coletas anteriores no pendrive. Se ja escaneado: nao varre de novo; registra em `acesso_pc_servidor.csv` apontando a coleta origem.
3. **Scan de servidor novo** — pasta `SRV_<id>/` com shares, varredura limitada (profundidade/tempo), mesmas heuristicas de software/crack, tentativa opcional de Uninstall remoto via `OpenRemoteBaseKey` (nao inicia servico). Host local nao e tratado como SRV (ja coberto pelo EQ).
4. **Inventario de formatos** — `formatos_arquivos.csv` (caminho, extensao, tamanho, criado/modificado/acessado, `VersaoCabecalho` barata para DWG/PDF/OLE) e `formatos_resumo.csv` (contagem, bytes, min/max datas por escopo+extensao). **Sem** cronologia mensal. Metadados apenas; nao copia os arquivos de projeto. Lista configuravel (`-ExtensoesFormato`).
5. **Controles** — `-SemRede` / `KIT_REDE=0`; `-SegundosPorServidor` (90); `-SegundosTotalServidores` (300); `-ProfundidadeServidor` (4); `-SemCabecalhoFormato`.
6. **Saidas novas no manifesto/INDICE** — `servidores_descobertos.csv`, `acesso_pc_servidor.csv`, `servidores_escaneados.csv`, `formatos_*.csv`, pastas `SRV_*`, `INDICE_SERVIDORES.txt` na raiz `coleta\`.

## Herdado da v1.4.7 (inalterado)

Manifesto+INDICE sempre; falhas de copia; .lic NLM; relogio/NTP; hashes firewall/Defender; Prefetch RunCount; hives de todos os perfis (VSS fallback permanece); operador/ordem; FPs AdskRcDispatch/AsmPreloader/Dynamo.

## Limitacoes

- Scan usa credenciais da sessao atual; sem prompt de senha; shares inacessiveis so sao documentados.
- Open Finance/terceiros nao se aplicam; isto e SMB/UNC local da rede vistoriada.
- Cabecalho Revit/Inventor completo (versao salva) nao e parseado alem da assinatura OLE (custo); DWG usa assinatura AC10xx.
- Varredura de formatos em disco local e limitada por tempo/profundidade; pode ficar parcial em discos grandes.
- ARP/DNS/TCP so documentam vizinhos; scan so roda com evidencia de share/UNC/licenca/DC (`PULADO_SO_VIZINHO`). Multicast/broadcast/link-local filtrados.
- Hostname nomeado vira ID estavel sem sufixo IP/MAC (evita forks).
- Captura de tela em SSH puro continua falhando (esperado).
- Nao faz commit/push automatico.
