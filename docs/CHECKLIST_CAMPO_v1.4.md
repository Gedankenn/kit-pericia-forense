# Checklist de campo — kit v1.4.4

Use uma folha por equipamento. Identificador sempre no formato **EQ01**, **EQ02**…

## Antes de plugar

- [ ] Foto do equipamento com a etiqueta EQxx
- [ ] Foto da tela como está (antes de qualquer clique)
- [ ] Foto do relógio do Windows ao lado de um relógio de referência (celular)
- [ ] Anotar quem está logado (não fazer logoff)

## Coleta automática

- [ ] Plugar pendrive; **recusar** “verificar e corrigir”
- [ ] Botão direito em `rodar_coleta_v1.4.4.cmd` → **Executar como administrador**
- [ ] Digitar o identificador (ex.: `EQ01` ou só `1` — o script normaliza)
- [ ] Aguardar o fim; ler o `00_RESUMO.txt` na tela
- [ ] Fotografar o quadro final (resumo + SHA-256 do manifesto)
- [ ] Anotar o hash do manifesto na planilha / ata

## Capturas manuais (obrigatórias no quesito de instalação)

- [ ] Abrir **Configurações → Aplicativos** (ou Painel de Controle → Programas e Recursos)
- [ ] Filtrar / rolar até os fabricantes de interesse; capturar com `capturar_tela.cmd EQ01 apps_lista`
- [ ] Se a ata autorizar tela **Sobre** do produto: abrir por último, capturar, registrar na ata (pode alterar perfil / disparar validação online)
- [ ] Não executar keygen/crack/ativador encontrados

## Depois

- [ ] Ejetar o pendrive com segurança
- [ ] Anotar horário de término e se rodou como admin
- [ ] No escritório: conferir `MANIFESTO_SHA256.txt` e trabalhar só sobre cópias
