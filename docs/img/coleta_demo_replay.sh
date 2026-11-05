#!/usr/bin/env bash
# Replay curado da coleta REAL v1.4.8 na VM de teste (EQ99 / PeritoTeste).
# Fonte: transcript D:\coleta\_eq99_demo_transcript.txt (2026-11-05).
# Sem dados de caso. Para o GIF do README (charmbracelet/vhs).
set -euo pipefail
export LANG=C.UTF-8

A=$'\033[38;5;214m'
D=$'\033[38;5;178m'
C=$'\033[38;5;81m'
G=$'\033[38;5;114m'
W=$'\033[97m'
R=$'\033[0m'
B=$'\033[1m'

pause() { sleep "${1:-0.12}"; }
say() { printf '%b\n' "$1"; pause "${2:-0.10}"; }
info() { say "${D}$1${R}" "${2:-0.11}"; }

clear
say "${A}${B}+------------------------------------------------------------------------------+" 0.05
say "|  >_ KIT PERICIA FORENSE                                      [READ-ONLY]     |" 0.05
say "|  __________________________________________________________________________  |" 0.05
say "|  | Coleta de inventario de software  |  PowerShell 5.1  |  v1.4.8          | |" 0.05
say "|  | Somente leitura + rede/servidores |  Saida no pendrive |  EQ##          | |" 0.05
say "|  |____[ SHA-256 manifesto ]__________|__[ sem telemetria ]|________________| |" 0.05
say "+------------------------------------------------------------------------------+${R}" 0.30

say "" 0.05
printf '%b' "${W}Identificador do equipamento (ex.: EQ01, ou so o numero): ${R}"
read -r EQ
say "${D}Usando identificador: ${C}${EQ}${R}" 0.20
printf '%b' "${W}Nome do operador/perito (Enter=NAO_INFORMADO): ${R}"
read -r OP
[[ -z "${OP}" ]] && OP='NAO_INFORMADO'
say "${D}Operador: ${C}${OP}${R}" 0.22
say "" 0.05
say "${A}>>> rodar_coleta_v1.4.8.cmd  (replay da execucao real na VM)${R}" 0.25
say "" 0.05

info "2026-11-05 13:20:16 | INFO  | Coleta v1.4.8 iniciada. Equip=${EQ} Host=PERITOW-USIRIDF"
info "2026-11-05 13:20:17 | INFO  | Hives offline: LIGADO (NTUSER.DAT via FileShare/reg save/VSS)"
info "2026-11-05 13:20:18 | INFO  | SHA-256 deste script: 6D57FD443DBDB759E1CFABC5FA02C05925C294AAC2..."
info "2026-11-05 13:20:19 | INFO  | Operador: ${OP}"
info "2026-11-05 13:20:34 | INFO  | [Identificacao do equipamento] inicio"
info "2026-11-05 13:20:41 | INFO  |   gravado 01_identificacao.csv: 1 registro(s)"
info "2026-11-05 13:20:45 | INFO  | [Identificacao do equipamento] fim (11.5s)"
info "2026-11-05 13:20:45 | INFO  | [Prefetch (programas executados)] inicio"
say "${D}… Prefetch …${R}" 0.18
info "2026-11-05 13:24:12 | INFO  |   gravado 13_prefetch.csv: 153 registro(s)"
info "2026-11-05 13:24:13 | INFO  | [Prefetch (programas executados)] fim (207.2s)"
info "2026-11-05 13:24:15 | INFO  | [Rede e servidores (descoberta, dedup, scan somente leitura)] inicio"
info "2026-11-05 13:24:48 | INFO  |   servidores unicos: 3; ja escaneados em coletas anteriores: 13"
info "2026-11-05 13:24:49 | INFO  |   PULADO (ja escaneado em EQ90_…): so documenta acesso deste EQ"
info "2026-11-05 13:24:50 | INFO  | [Rede e servidores] fim"
info "2026-11-05 13:24:50 | INFO  | [Inventario de formatos (discos locais, metadados)] inicio"
info "2026-11-05 13:25:16 | INFO  |   gravado formatos_resumo.csv / formatos_arquivos.csv"
info "2026-11-05 13:25:16 | INFO  | [Inventario de formatos] fim (26.5s)"
say "${D}… hives / programas / firewall / defender / suspeitos …${R}" 0.20
info "2026-11-05 13:27:31 | INFO  |   gravado 00b_ordem_coleta.csv: 18 registro(s)"
info "2026-11-05 13:27:32 | INFO  |   atualizado INDICE_COLETAS.txt + INDICE_SERVIDORES.txt"
info "2026-11-05 13:27:36 | INFO  | Manifesto gerado (93 arquivos, motivo=normal)."
info "2026-11-05 13:27:36 | INFO  | SHA-256=1192618BBD97EA7D703B811085CE12FC8A2BDF125DF01E4F3ED949CEE852BE67"

say "" 0.05
say "${C}${B}==================================================================${R}" 0.08
say "${C}${B} COLETA CONCLUIDA  Equip ${EQ}  Host PERITOW-USIRIDF  Op ${OP}${R}" 0.12
say "${W} Pasta: D:/coleta/EQ99_PERITOW-USIRIDF_20261105_132015${R}" 0.10
say "${W} Administrador: True   Duracao: 421s${R}" 0.10
say "${W} Programas das autoras: 3   Arquivos de projeto: 5   Indicios fortes: 8${R}" 0.10
say "${W} Copias de suspeitos: 8 (ver 11g_ e pasta suspeitos_copias\\)${R}" 0.10
say "${C} SHA-256 do manifesto: 1192618BBD97EA7D703B811085CE12FC8A2BDF125DF01E4F3ED949CEE852BE67${R}" 0.14
say "${C}${B}==================================================================${R}" 0.10
say "" 0.05
say "${G}${B}END code=0 2026-11-05T13:27:37${R}" 0.10
pause 1.2
