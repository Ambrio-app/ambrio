# 0031 — Compra parcelada no cartão (1.1)

**Data:** 2026-11-24 · **Status:** ✅ concluído

## O que mudou

- **Formulário** (despesa nova no cartão): campo **Parcelas** (à vista ou de 2x a 48x). O "Valor" digitado é o **total** da compra. Com mais de uma parcela aparecem "Em qual parcela você está?"
  (para uma compra que já está andando) e a prévia: "3x de R$ 200,00 · Parcelas 1/3 a 3/3 · a última em janeiro de 2027". O aviso antigo ("Parcelamento ainda não existe") saiu.
- **Uma parcela por fatura:** cada parcela é um lançamento comum com a própria data (um mês depois da outra, mantendo o dia e caindo no último dia do mês quando ele não existe) e a própria competência
  pela regra do fechamento do cartão ([`installments.dart`](../lib/features/entries/domain/installments.dart)). O resto dos centavos fica na parcela 1.
- **Compra que já está na parcela 3 de 6:** cria só 3/6 a 6/6 (as anteriores já foram pagas e entrariam como dívida no cartão); a primeira criada recebe a observação "parcelas 1 a 2 anteriores ao uso do app".
- **Lista:** "parcela 2/3" na linha de apoio. **Excluir** uma parcela pergunta "Só esta parcela" ou "Todas as parcelas desta compra"; o Desfazer devolve o que saiu. **Editar** mexe só na parcela aberta.
- **Situação:** linha "Parcelas a vencer R$ X" (total e por cartão), com o olhinho. **O "em aberto" não mudou**: continua o saldo até hoje; as parcelas futuras ficam à parte.
- **Banco v10** ([`app_database.dart`](../lib/core/database/app_database.dart)): três colunas anuláveis em `entries` (`installment_group_id`, `installment_number`, `installment_count`). Lançamentos antigos ficam "não parcelados".
  Primeiro teste de migração **com dados** desde a v7 (`migration_v9_v10_test.dart`).
- Para caber no limite de 400 linhas, o repositório e o formulário ganharam arquivos `part` (`entries_repository_installments.dart`, `entry_form_screen_fields.dart`).

## Por quê

Era o limite mais visível do app: quem compra em 3x tinha de lançar o total de uma vez (júri 1.0.2). Duas linhas ligadas por colunas, e não uma tabela de grupo, reaproveitam competência, filtros, totais do mês, backup e a exclusão de conta sem mexer
na regra do saldo.

## Limites conhecidos

- O histórico das parcelas já pagas não é recriado (de propósito, para não inflar o "em aberto").
- Editar uma parcela não ajusta as outras. Para mudar a compra inteira, exclua todas e lance de novo.
- Só despesa em cartão. Parcelar a fatura (pagar menos e parcelar o resto) e conta corrente parcelada ficam de fora; a importação segue tratando as parcelas da planilha como linhas comuns.

## Como verificar

`flutter test test/features/entries/installments_test.dart test/features/entries/installments_repository_test.dart test/features/entries/installments_form_test.dart test/drift`. Roteiro do celular: `1.1-roteiro` no cofre.
