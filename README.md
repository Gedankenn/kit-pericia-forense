<p align="center">
  <img src="img/banner.jpg" alt="kit-pericia-forense" width="100%">
</p>

# kit-pericia-forense

**Coleta forense somente-leitura** de inventário de software em Windows. Feito para vistoria em campo: roda do pendrive, não grava no disco vistoriado, imprime um resumo na tela e fecha com manifesto SHA-256.

> PowerShell 5.1 nativo · saída só no pendrive · `00_RESUMO.txt` genérico · parâmetro opcional `-Destacar`

[![versão](https://img.shields.io/badge/versão-1.3-f5a623?style=flat-square)](#)
[![somente%20leitura](https://img.shields.io/badge/disco%20vistoriado-READ--ONLY-2ecc71?style=flat-square)](#garantias-somente-leitura)
[![licença](https://img.shields.io/badge/licença-MIT-blue?style=flat-square)](LICENSE)

---

## O que é

Script de perícia / vistoria de software que monta, em minutos, um pacote de evidências **somente por leitura**:

- programas instalados (registro Uninstall 64/32 bits + HKCU/HKU);
- indícios por nome (keygen, crack, KMS, patch, ativador…);
- hosts e firewall que bloqueiam ativação;
- metadados de arquivos de projeto (`.dwg`, `.cdr`, `.rvt`…);
- Prefetch, eventos MSI, Lixeira, Defender (quando há admin);
- **`00_RESUMO.txt`** — veredito curto em português, impresso na tela e coberto pelo manifesto.

Não substitui imagem forense (FTK/E01). É o kit leve de **campo**, para ler na frente da máquina e anexar ao laudo.

<p align="center">
  <img src="img/fluxo_coleta.png" alt="Fluxo da coleta" width="100%">
</p>

---

## Garantias (somente leitura)

| Promessa | Como |
|---|---|
| Nada é gravado no disco vistoriado | Saída só no pendrive; destino em `C:\` é **recusado** (código 2) |
| Política de execução intacta | `-ExecutionPolicy Bypass -File` só naquela sessão |
| Sem cache de módulo no perfil | `PSModuleAnalysisCachePath=NUL` |
| Sem `Win32_Product` | Inventário via registro .NET (read-only) — não dispara repair MSI |
| Sem carregar hive deslogado | Evita alterar `NTUSER.DAT` |
| Sem compilar C# | Nada em `%TEMP%` via `Add-Type` |
| Resumo no manifesto | `00_RESUMO.txt` é escrito **antes** do SHA-256 |

**Efeitos inevitáveis do Windows** (declarar no laudo): USBSTOR / MountedDevices ao plugar o pendrive; Prefetch e eventos do PowerShell; possível atualização de *last-access* NTFS nas pastas listadas.

---

## O que coleta (visão rápida)

| Grupo | Arquivos típicos |
|---|---|
| Resumo e log | `00_RESUMO.txt`, `00_log_execucao.txt`, `00_resumo_secoes.csv` |
| Identificação | host, discos, perfis, rede, captura de tela opcional |
| Programas | Uninstall completo + filtro por fabricantes (`-Fabricantes`) |
| Licença | chaves de registro, FlexLM, arquivos de licença (+ SHA-256) |
| Indícios | keygen/crack/KMS, hosts, firewall, assinatura digital |
| Projetos | metadados `.dwg` / `.cdr` / `.rvt`… com timeout por raiz |
| Histórico | MSI install/remove, Prefetch, Lixeira, Defender |

Detalhamento completo: [`docs/KIT_PENDRIVE_v1.3.md`](docs/KIT_PENDRIVE_v1.3.md).

---

## Uso no pendrive

```
E:\                                      (NTFS ou exFAT, ≥ 16 GB)
├── rodar_coleta_v1.3.cmd                ← botão direito → Executar como administrador
├── coleta_inventario_software_v1.3.ps1
├── coleta_minima_v1.2.cmd               ← plano B (PowerShell bloqueado)
├── capturar_tela.cmd / .ps1
├── KIT_SHA256.txt
└── coleta\                              ← criada na hora
    └── EQ01_<HOST>_<data_hora>\
        ├── 00_RESUMO.txt
        ├── *.csv / *.txt
        └── MANIFESTO_SHA256.txt
```

1. Foto do equipamento + etiqueta `EQ01` + relógio do Windows vs. referência.
2. Plugar o pendrive (**recusar** “verificar e corrigir”).
3. Botão direito em `rodar_coleta_v1.3.cmd` → **Executar como administrador**.
4. Digitar o identificador (`EQ01`). Esperar ~3–10 min.
5. Ler / fotografar o `00_RESUMO.txt` e o hash do manifesto.
6. Ejetar com segurança.

Equivalente manual:

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File E:\coleta_inventario_software_v1.3.ps1 -Equip EQ01 -CapturaTela
```

Teste no seu PC (permite gravar em `C:\`):

```bat
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\coleta_inventario_software_v1.3.ps1 -Equip TESTE -ModoTeste
```

---

## Admin vs. usuário padrão

| | Administrador | Usuário padrão |
|---|---|---|
| Uninstall HKLM + HKCU | ✓ | ✓ (HKCU do usuário atual) |
| Prefetch | ✓ | pulado |
| Defender (ameaças / exclusões) | ✓ | pulado |
| Perfis de outros usuários | parcial (arquivos); hive só se logado | só o próprio |
| Registro no log | seções `OK` | seções `PULADA` / aviso no resumo |

**Recomendação:** sempre “Executar como administrador”. Sem admin a coleta **roda**, mas a cobertura fica parcial — e isso fica escrito no `00_RESUMO.txt` e em `00_resumo_secoes.csv`.

---

## `-Destacar` (opcional)

Por padrão o resumo é **genérico**: irregularidades de qualquer fabricante.

```powershell
# só prioriza no topo; NUNCA oculta o restante
... -Destacar Corel,Autodesk
```

- Não altera a regex de coleta (`-Fabricantes`).
- Sem o parâmetro = relatório completo, sem seção “DESTAQUE”.

<p align="center">
  <img src="img/exemplo_00_RESUMO_v1.3.png" alt="Exemplo de 00_RESUMO.txt (VM de teste)" width="720">
</p>

<p align="center"><sub>Exemplo gerado em VM de laboratório com artefatos plantados — não é coleta real.</sub></p>

Texto completo: [`exemplos/exemplo_00_RESUMO_v1.3.txt`](exemplos/exemplo_00_RESUMO_v1.3.txt) (com `-Destacar`) e [`exemplos/exemplo_00_RESUMO_v1.3_sem_destacar.txt`](exemplos/exemplo_00_RESUMO_v1.3_sem_destacar.txt).

---

## Saída e manifesto SHA-256

1. Script grava todos os CSVs/TXTs na pasta `coleta\EQ_HOST_datahora\`.
2. Escreve `00_RESUMO.txt`.
3. Calcula SHA-256 de **cada** arquivo → `MANIFESTO_SHA256.txt`.
4. Calcula o hash do próprio manifesto e mostra na tela.

Verificação do kit (antes de sair): [`docs/INTEGRIDADE.md`](docs/INTEGRIDADE.md) e `KIT_SHA256.txt`.

---

## Limitações / não testado

- Hive de usuário **deslogado** não é carregado (decisão técnica).
- Data de última gravação de chave de registro não é coletada.
- Captura de tela pode ficar parcial em DPI alto / multi-monitor.
- Seriais Autodesk recentes em geral **não** ficam no registro.
- Plano B (`coleta_minima_v1.2.cmd`) **não** gera `00_RESUMO.txt`.
- **Não testado de ponta a ponta:** usuário padrão no console físico (sem SSH); relaunch 32→64 bits em AppLocker restrito; tempo em PC real lento / antivírus corporativo agressivo.
- Testado em VM Windows 10 (PowerShell 5.1) com artefatos plantados. Checklist pré-voo em PC real continua obrigatório (ver doc do pendrive).

---

## Estrutura do repositório

```
kit-pericia-forense/
├── README.md
├── LICENSE                          MIT
├── KIT_SHA256.txt                   hashes dos scripts/docs
├── .gitignore
├── scripts/
│   ├── coleta_inventario_software_v1.3.ps1
│   ├── rodar_coleta_v1.3.cmd
│   ├── coleta_minima_v1.2.cmd
│   ├── capturar_tela.cmd
│   └── capturar_tela.ps1
├── docs/
│   ├── KIT_PENDRIVE_v1.3.md         guia de campo
│   └── INTEGRIDADE.md
├── exemplos/
│   ├── exemplo_00_RESUMO_v1.3.txt
│   └── exemplo_00_RESUMO_v1.3_sem_destacar.txt
└── img/
    ├── banner.jpg
    ├── fluxo_coleta.png
    └── exemplo_00_RESUMO_v1.3.png
```

---

## Aviso

Ferramenta de apoio a perícia / auditoria legítima. Use só com autorização (mandado, alvará, consentimento do titular ou política interna). O autor não se responsabiliza por uso indevido. Este repositório **não** contém evidências de nenhum caso concreto.

---

## Autor

**Fabio Slika Stella** — CREA/PR PR-224755/D  
[Gedankenn](https://github.com/Gedankenn) · [site](https://gedankenn.github.io/Gedankenn/)

`measure before assuming.`
