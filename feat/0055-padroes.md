# 0055 — Padrões de texto e símbolos

**Data:** 2026-11-24 · **Status:** ✅ concluído

## O que mudou

- **Sem travessão (—) nas mensagens da tela** (cerca de 20, quase todas do importador: "… — ignorada.", "Chave … não configurada — rebuilde…", e duas de Configurações). Viraram ponto, dois-pontos ou ponto e vírgula.
  As instruções que vão para a IA (`llm_table_locator.dart`) ficam como estão: não aparecem na tela e mexer nelas mudaria a avaliação do importador.
- **Plural de verdade, sem "(s)":** "1 lançamento" / "3 lançamentos" (filtro da tela inicial, prévia e fim da importação, notas da importação, filtro de contas). `Formatters.count`.
- **Ícone do cartão sempre em contorno** (`credit_card_outlined`); cheio fica só para selecionado ou concluído.
- **Regras escritas** em [`docs/PADROES.md`](../docs/PADROES.md) (travessão, emoji, plural, reticências, dinheiro, datas, separador `·`, seta `→`, ícones, três jeitos de nomear o cartão).
- **Trava:** `test/core/texts_test.dart` reprova travessão, emoji e "(s)" em texto de tela novo.

## Por quê

O autor perguntou se símbolos, emojis e siglas seguiam um padrão único. A varredura mostrou que sim, quase: nenhum emoji, `·` como separador, `→` só para fluxo de dinheiro. Sobraram poucos pontos fora, arrumados aqui antes do parcelamento (0031), para o formulário novo já nascer no padrão.

## Como verificar

`flutter test test/core/texts_test.dart` e os testes do importador e da tela inicial.
