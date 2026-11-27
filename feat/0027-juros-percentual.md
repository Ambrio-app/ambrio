# 0027 — Pagar fatura com juros em %

**Data:** 2026-11-25 · **Status:** ✅ concluído

## O que mudou

- Na tela de pagar fatura, o campo de juros e encargos ganhou um seletor **Juros em R$ | Juros em %** (o seletor só aparece quando há fatura em aberto).
- Em %, a pessoa digita a taxa que o banco informou (ex.: 2,50, que anda pela vírgula como o dinheiro, até 99,99%) e a tela mostra **ao vivo** o valor: "2,50% de R$ 1.000,00 em aberto = R$ 25,00. Vira um gasto no cartão.".
- A conta é só com inteiros, em [`interestFromRate`](../lib/features/entries/domain/payment_rules.dart): `(em aberto × taxa em centésimos + 5000) ÷ 10000`, meio centavo para cima. O resto (resumo, validação, o gasto "Juros e encargos da fatura" na mesma transação do pagamento) é o de sempre.
- Trocar de R$ para % (ou o contrário) limpa o campo, para um número não mudar de sentido sem a pessoa ver.
- Novo `PercentInputFormatter` ([`percent_input_formatter.dart`](../lib/core/utils/percent_input_formatter.dart)).

## Por quê

A fatura do banco costuma informar a taxa ("2,5% a.m."), não o valor em reais: quem pagava tinha de fazer a conta de cabeça (achado ao testar a 0025 no emulador).

## Sobre "sem taxa embutida" (0014)

A 0014 decidiu que o app não embute taxa nenhuma. Continua valendo: **a taxa vem de quem digita**, o app não sabe nem sugere nenhuma. A base é o **em aberto do cartão**, que é como o banco costuma anunciar.

## Como verificar

`flutter test test/core/percent_input_formatter_test.dart test/features/entries/payment_rules_test.dart test/features/entries/payment_validation_test.dart`.
