# Kit do pendrive para a vistoria de software (v1.3)

Boas práticas: o pendrive e os arquivos de saída ficam sob custódia do perito. Não coloque nomes de partes, empresas ou pessoas no rótulo do pendrive nem nos nomes de pasta. Use só identificadores genéricos (EQ01, EQ02 etc.).

## 1. Estrutura do pendrive

```
E:\                                   (pendrive do perito, NTFS ou exFAT, de preferência >= 16 GB)
├── rodar_coleta_v1.3.cmd             <- lançador principal (botão direito > Executar como administrador)
├── coleta_inventario_software_v1.3.ps1
├── capturar_tela.cmd / capturar_tela.ps1   <- captura manual de tela 
├── coleta_minima_v1.2.cmd            <- PLANO B, se o PowerShell estiver bloqueado (sem mudança na v1.3)
├── KIT_SHA256.txt                    <- hashes do próprio kit (conferir antes de cada uso)
├── ferramentas\                      <- opcional, só ferramentas assinadas (ver item 4)
│   └── sysinternals\ (sigcheck64.exe, autorunsc64.exe)
└── coleta\                           <- criada automaticamente; uma subpasta por máquina
    ├── EQ01_<HOST>_<data_hora>\
    │   ├── 00_RESUMO.txt             <- NOVO v1.3: veredito/indicadores/sugestões (ler na frente da máquina)
    │   ├── 00_log_execucao.txt, CSVs...
    │   └── MANIFESTO_SHA256.txt (+ .sha256)  <- inclui o 00_RESUMO.txt
    ├── capturas\ (PNGs + HASHES_CAPTURAS.txt)
    └── INDICE_COLETAS.txt            <- uma linha por máquina, com o hash do manifesto
```

Não leve versões antigas (`coleta_inventario_software.ps1`, `_v1.1`, `_v1.2`) para a diligência. Elas ficam arquivadas só como histórico. **No pendrive, leve apenas os arquivos v1.3** (+ `coleta_minima_v1.2.cmd` como plano B e `capturar_tela.*`).

## 2. O lançador `rodar_coleta_v1.3.cmd`

- Chama o PowerShell 5.1 de 64 bits do próprio Windows com `-NoProfile -ExecutionPolicy Bypass -File`. Assim a política de execução não bloqueia, e nada é alterado na política da máquina.
- Define `PSModuleAnalysisCachePath=NUL` para o PowerShell não gravar cache de módulos no perfil do usuário da máquina.
- Avisa se não estiver como administrador, pede o identificador (EQ01...) e roda com `-CapturaTela`.
- Linha equivalente, se for preciso digitar à mão:
  `powershell -NoProfile -ExecutionPolicy Bypass -File E:\coleta_inventario_software_v1.3.ps1 -Equip EQ01 -CapturaTela`
- Opções úteis:
  - `-Destacar Corel,Autodesk` (**opcional**) — só **destaca** esses fabricantes no topo do `00_RESUMO.txt`. Sem o parâmetro, o resumo é **genérico** (todas as irregularidades de qualquer fabricante). Nunca oculta o restante. Não altera a regex de coleta (`-Fabricantes`).
  - `-CopiarLicencas` copia para o pendrive os arquivos de licença de até 5 MB.
  - `-ResolverAtalhos` lê o destino dos `.lnk` recentes.
  - `-MRUCompleto` lista todos os recentes, não só os relacionados.
  - `-HashArquivosProjeto` calcula o SHA-256 dos .dwg/.cdr. Fica **desligado** por padrão porque ler o conteúdo pode atualizar a "data de último acesso".
- O script **se recusa** a gravar no disco do sistema (código 2). Para testar no seu PC, use `-ModoTeste`.

## 3. Passo a passo em cada máquina (5 a 10 min)

1. **Antes de tocar:** foto do equipamento com a etiqueta EQxx, da tela como está e do relógio do Windows ao lado de um relógio de referência (celular). A diferença de horário entra no laudo.
2. Anote quem está logado. **Não** faça logoff nem troque de usuário: os hives de quem está logado são lidos. Os de quem não está logado **não** são carregados, por decisão técnica, porque carregar poderia alterar o NTUSER.DAT.
3. Plugue o pendrive. Se o Windows oferecer "verificar e corrigir", **recuse**. Anote a letra da unidade.
4. Abra o pendrive pelo Explorer. Botão direito em `rodar_coleta_v1.3.cmd` > **Executar como administrador**. A senha de administrador deve ser fornecida pela empresa, e isso deve constar da ata. Sem admin a coleta roda, mas pula Prefetch, Defender e perfis de outros usuários (isso fica registrado em `00_resumo_secoes.csv` e no `00_RESUMO.txt`).
5. Digite o identificador (EQ01). Aguarde, sem mexer na máquina. Os limites de tempo internos somam em torno de 6 a 9 min no pior caso.
6. Na tela final: leia o **`00_RESUMO.txt`** (também impresso na tela), **fotografe** o quadro com o resumo e o SHA-256 do manifesto, e anote-os na planilha de campo e na ata.
7. Para o captura manual da instalação (quando o caso exigir), abra **Configurações > Aplicativos** (ou Painel de Controle > Programas), filtre por "Autodesk" e depois por "Corel", e rode `capturar_tela.cmd EQ01 apps_autodesk`. Evite abrir AutoCAD ou CorelDRAW: isso altera arquivos de perfil e pode disparar validação online. Se for indispensável (tela "Sobre" com o serial), faça por último, registre na ata e capture.
8. Feche a janela e use "Ejetar" no pendrive. Anote o horário de término.
9. Se o PowerShell estiver bloqueado (mensagem de política, AppLocker ou "modo de linguagem restrito" no log), use `coleta_minima_v1.2.cmd` (plano B, menos completo; **não** gera o `00_RESUMO.txt`).

### O que o script coleta (arquivos CSV com `;` e UTF-8, que abrem direto no Excel)

| Arquivo | Conteúdo |
|---|---|
| **00_RESUMO.txt** | **NOVO v1.3.** Relatório **genérico** de irregularidades/pirataria (qualquer fabricante), agrupado; `-Destacar` opcional só prioriza no topo. Sugestões + contagens. Impresso na tela e incluso no manifesto. |
| 00_log_execucao.txt, 00_resumo_secoes.csv | início e fim (local e UTC), host, usuário, admin, versão do PS, seções OK/ERRO/PULADA  |
| 01*_ / 02_ | identificação, discos, volumes, perfis, rede; 01e = captura de tela |
| 03 / 04 | todos os programas / programas dos fabricantes de interesse (versão, editor, data de instalação)  |
| 05 / 05b / 07 | valores de licença/serial no registro, variáveis FLEXlm, arquivos de licença com SHA-256  |
| 06 / 06b / 09c | serviços, processos e portas de licenciamento (servidor de rede FlexLM) |
| 08 / 08b / 09 / 09b | hosts (cópia integral e linhas que bloqueiam domínios dos fabricantes de interesse) e regras de firewall  |
| 11 / 11b / 11c / 11d / 11e | nomes de crack/keygen, instaladores, DLLs "loader", assinatura digital, indícios excluídos (ssh-keygen)  |
| 10 / 10b / 10c | arquivos .dwg/.dxf/.rvt/.cdr etc. (só metadados), contagem e cobertura de cada varredura  |
| 12* / 13 / 14 / 18 | eventos de instalação e remoção MSI, limpeza de logs, Prefetch, Lixeira, pastas remanescentes  |
| 15 / 16 / 17* | atalhos recentes, MRU, Defender |

Leitura: `10c_varredura_raizes.csv` mostra se alguma pasta ficou com `TEMPO_ESGOTADO`. Nesse caso, a lista de arquivos daquela pasta é parcial, e isso deve ser dito no laudo (e aparece nas sugestões do resumo).

## 4. Ferramentas portáteis complementares (opcionais)

O script v1.3 já cobre o necessário só com recursos nativos do Windows. Ferramentas extras aumentam o risco de alerta do antivírus na frente da Oficial de Justiça.

- **Evitar:** NirSoft ProduKey, "Magical Jelly Bean Keyfinder", "LicenseCrawler" e similares.
- **Risco baixo (assinadas pela Microsoft), se quiser conferência cruzada:** Sysinternals `sigcheck64.exe` e `autorunsc64.exe`. Atenção: `-accepteula` grava uma chave em HKCU\Software\Sysinternals — mencionar na ata, ou não use.
- **FTK Imager Lite:** só se o juízo autorizar imagem forense.
- Antes de levar qualquer .exe: confira a assinatura e registre o SHA-256 no `KIT_SHA256.txt`.

## 5. Efeitos inevitáveis na máquina (declarar no laudo)

O script não grava nada no disco vistoriado. O próprio Windows, porém, registra:

- a conexão do pendrive (USBSTOR, MountedDevices, logs de dispositivo);
- a execução de cmd/PowerShell (Prefetch `POWERSHELL.EXE-*.pf`, eventos PowerShell 400/600/4104);
- por estar na sessão de PowerShell 5.1, o arquivo `StartupProfileData-NonInteractive` em `%LOCALAPPDATA%\Microsoft\Windows\PowerShell`;
- as datas de último acesso de pastas listadas, quando essa atualização estiver ativa no NTFS.

Nenhum arquivo de usuário é aberto, alterado ou apagado. A coleta do Prefetch é feita logo no início, antes desses efeitos.

## 6. Checklist de domingo (pré-voo)

- [ ] Formatar o pendrive (NTFS ou exFAT) e copiar só os arquivos do item 1.
- [ ] Rodar `rodar_coleta_v1.3.cmd` num PC Windows 10/11 **seu**, duas vezes: (a) como administrador e (b) sem administrador. Para testar com o kit no próprio C:, use `powershell ... -File ... -Equip TESTE -ModoTeste`. Conferir:
  - [ ] que terminou em menos de 10 min e o tempo de cada seção em `00_resumo_secoes.csv`;
  - [ ] que o **`00_RESUMO.txt`** existe, está em português, traz irregularidades genéricas (+ destaque se usou `-Destacar`), sugestões e contagens, e aparece no `MANIFESTO_SHA256.txt`;
  - [ ] que nenhuma seção ficou em `ERRO` inesperado (o log `00_log_execucao.txt` traz a causa);
  - [ ] que os CSVs abrem no Excel com acentos corretos;
  - [ ] que o antivírus (Defender) não alertou;
  - [ ] o teste com uma pasta `Documentos\teste\x.dwg` e um arquivo `keygen_teste.txt`: precisam aparecer em `10_` e `11_` e no resumo.
- [ ] Testar também `capturar_tela.cmd` e, se possível, `coleta_minima_v1.2.cmd`.
- [ ] Apagar a pasta `coleta\` de teste do pendrive.
- [ ] Gerar os hashes do kit e salvar em `KIT_SHA256.txt`. Imprimir e levar uma cópia em papel para a ata.
- [ ] Pendrive com trava física de escrita: **não** use a trava (o script precisa gravar no pendrive).
- [ ] Levar: pendrive reserva, planilha de campo impressa, celular para fotos com data e hora, etiquetas EQ01...EQnn.
- [ ] Depois da diligência: copiar `coleta\` para dois locais, conferir os manifestos e só então trabalhar sobre as cópias.

## 7. Limitações conhecidas (v1.3)

- Herda as da v1.2 (hive de usuário deslogado não carregado; data de última gravação de chave de registro não coletada; captura parcial em DPI alto; seriais Autodesk recentes não ficam no registro).
- O `00_RESUMO.txt` é um **atalho de leitura em campo**. A prova continua sendo o conjunto de CSVs + manifesto. Em caso de dúvida, abra os CSVs.
- `-Destacar` só prioriza fabricantes no topo do resumo; a coleta ampla (`-Fabricantes` regex) e o restante do resumo permanecem iguais.
- Plano B (`coleta_minima_v1.2.cmd`) **não** gera `00_RESUMO.txt`.
- Testado em VM Windows 10 (PowerShell 5.1) com artefatos plantados. Checklist de domingo em PC real continua obrigatório.

## Changelog v1.3 (28/10/2026)

**Arquivos novos do kit v1.3:** `coleta_inventario_software_v1.3.ps1`, `rodar_coleta_v1.3.cmd`, `KIT_PENDRIVE_v1.3.md`. Hashes appendados em `KIT_SHA256.txt` (histórico preservado). `coleta_minima_v1.2.cmd` e `capturar_tela.*` sem mudança.

- **Resumo mínimo genérico (`00_RESUMO.txt`):** impresso na tela ao final e gravado **antes** do manifesto SHA-256. Em português, curto, serve a vistorias de **qualquer** objeto:
  1. **DESTAQUE** (só se `-Destacar` for informado): produtos/versão/local + indícios ligados aos fabricantes de interesse. **Nunca oculta** o restante.
  2. **IRREGULARIDADES / PIRATARIA (sempre completo):** keygen/crack/patch/ativador (inclui KMS), hosts bloqueando ativação, serviços/licença, instaladores soltos, desinstalações MSI, assinaturas inválidas, DLLs "loader", discos/USB não varridos — agrupados por fabricante quando dá para inferir. Exclusão `^SSH-KEYGEN` mantida.
  3. **SUGESTÕES** "vale pesquisar mais neste PC".
  4. Contagens-chave + hostname + data/hora local e UTC.
- Padrão sem `-Destacar` = relatório genérico. Mantém somente leitura; saída só no pendrive.

## Changelog v1.2 / v1.1

Ver `KIT_PENDRIVE_v1.2.md` (histórico completo: exclusão ssh-keygen, robocopy /XJ no plano B, Eventos OK_PARCIAL, PSModuleAnalysisCachePath=NUL, testes em VM).
