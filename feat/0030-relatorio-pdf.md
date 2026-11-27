# 0030 — Relatório do mês em PDF

**Data:** 2026-11-25 · **Status:** ✅ concluído

## O que mudou

- Em **Configurações › Dados**, nova seção "Relatório do mês": escolher o mês (o corrente e os 23 anteriores), ligar ou não "Incluir a lista de lançamentos" e "Incluir os saldos" e tocar em **Gerar relatório em PDF**.
  O arquivo é feito no aparelho e salvo pelo seletor de arquivos (o mesmo caminho do backup): `ambrio-relatorio-AAAA-MM.pdf`. Nada vai para a rede.
- **Por padrão só os totais:** entradas, gastos no débito, gasto em cada cartão, total gasto e "entrou menos o que gastou". A lista (data, tipo, descrição, conta e valor, do mais antigo ao mais novo) e os saldos de hoje (contas e o em aberto dos cartões) só entram se a pessoa ligar.
- Os números são os que o app já calcula ([`MonthSummary`](../lib/features/entries/domain/month_summary.dart) e `MonthSituation`): transferências, pagamento de fatura e ajustes não entram nos totais (a nota no rodapé do PDF diz isso).
- O PDF usa a fonte padrão, que cobre os acentos do português; emoji e símbolos fora disso saem como `?` ([`pdfSafe`](../lib/features/entries/domain/month_report.dart)).
- Dependência nova: `pdf` (Dart puro, sem rede), que traz `barcode`, `bidi`, `path_parsing` e `qr` (licenças livres: Apache-2.0, BSD e MIT).
- `PRIVACIDADE.md` e a tela de privacidade ganharam a linha do relatório (o arquivo fica sem senha; não sobe a versão do texto porque nada é enviado a terceiros).

## Por quê

O autor pediu um relatório para ler no celular e mandar a quem ajuda com as contas. Ficou em **PDF** (e não Markdown) porque nem todo mundo sabe abrir `.md`.

## Limites conhecidos

- Só a fonte padrão: descrições com emoji aparecem com `?`.
- PDF é bom de ler e ruim de processar por código; se um agente de análise precisar, Markdown ou CSV entram como segunda opção.
- O selecionar-arquivo é do sistema: a geração do PDF foi testada por testes (bytes `%PDF`, várias páginas), e o salvar real fica para o emulador e o celular.

## Como verificar

`flutter test test/features/entries/month_report_test.dart test/features/entries/month_report_pdf_test.dart test/features/settings/report_section_test.dart test/features/settings/privacy_test.dart`.
