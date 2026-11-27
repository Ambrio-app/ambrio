import 'package:ambrio/core/database/app_database.dart';
import 'package:ambrio/core/utils/year_month.dart';
import 'package:ambrio/features/accounts/domain/account_kind.dart';
import 'package:ambrio/features/entries/domain/entry_type.dart';
import 'package:ambrio/features/entries/domain/entry_with_account.dart';
import 'package:ambrio/features/entries/domain/month_report.dart';
import 'package:ambrio/features/entries/domain/month_situation.dart';
import 'package:ambrio/features/entries/domain/month_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final created = DateTime(2025);
  Account account(int id, String name, AccountKind kind) =>
      Account(id: id, name: name, kind: kind, closingDayInCurrent: false, createdAt: created);

  final bank = account(1, 'Bradesco', AccountKind.checking);
  final savings = account(2, 'Poupança', AccountKind.checking);
  final amazon = account(3, 'Amazon', AccountKind.creditCard);

  var id = 0;
  EntryWithAccount row(
    Account a,
    EntryType type,
    int cents, {
    DateTime? date,
    String description = 'x',
    Account? to,
    String? note,
  }) => EntryWithAccount(
    Entry(
      id: id++,
      accountId: a.id,
      toAccountId: to?.id,
      type: type,
      description: description,
      amountCents: cents,
      date: date ?? DateTime(2026, 11, 10),
      note: note,
      competence: 202611,
      createdAt: created,
    ),
    a,
    toAccount: to,
  );

  final november = YearMonth(2026, 11);
  final now = DateTime(2026, 11, 25);

  final rows = [
    row(bank, EntryType.income, 500000, date: DateTime(2026, 11, 5), description: 'Salário'),
    row(bank, EntryType.expense, 50000, date: DateTime(2026, 11, 8), description: 'Mercado'),
    row(amazon, EntryType.expense, 13999, date: DateTime(2026, 11, 2), description: 'Mouse', note: 'parcela 1/3'),
    row(bank, EntryType.transfer, 10000, date: DateTime(2026, 11, 9), description: 'Transferência', to: savings),
    row(bank, EntryType.billPayment, 20000, date: DateTime(2026, 11, 20), description: 'Pagamento', to: amazon),
  ];

  test('os totais batem com o MonthSummary: transferência e pagamento de fatura ficam de fora', () {
    final report = MonthReport.from(month: november, generatedAt: now, rows: rows);
    final summary = MonthSummary.from(rows);

    expect(report.incomeCents, summary.incomeCents);
    expect(report.debitExpenseCents, summary.debitExpenseCents);
    expect(report.cards.map((c) => (c.name, c.cents)), [('Amazon', 13999)]);
    expect(report.cardsCents, 13999);
    expect(report.spentCents, 50000 + 13999);
    expect(report.resultCents, 500000 - 63999);
  });

  test('por padrão leva só os totais: sem lista e sem saldos', () {
    final report = MonthReport.from(month: november, generatedAt: now, rows: rows);
    expect(report.lines, isNull);
    expect(report.balances, isNull);
    expect(report.openCards, isNull);
  });

  test('com a lista ligada, os lançamentos saem do mais antigo ao mais novo, com sinal e o fluxo de dinheiro', () {
    final report = MonthReport.from(month: november, generatedAt: now, rows: rows, includeLines: true);
    final lines = report.lines!;

    expect(lines.map((l) => l.description), ['Mouse', 'Salário', 'Mercado', 'Transferência', 'Pagamento']);
    expect(lines.firstWhere((l) => l.description == 'Salário').cents, 500000);
    expect(lines.firstWhere((l) => l.description == 'Mercado').cents, -50000);
    expect(lines.firstWhere((l) => l.description == 'Transferência').account, 'Bradesco → Poupança');
    expect(lines.firstWhere((l) => l.description == 'Pagamento').account, 'Bradesco → fatura Amazon');
    expect(lines.firstWhere((l) => l.description == 'Mouse').note, 'parcela 1/3');
  });

  test('com os saldos ligados, leva o saldo das contas e o em aberto dos cartões', () {
    final situation = MonthSituation.from(
      accounts: [bank, savings, amazon],
      balances: {1: 300000, 2: 50000, 3: -13999},
    );
    final report = MonthReport.from(month: november, generatedAt: now, rows: rows, situation: situation);

    expect(report.balances!.map((b) => (b.name, b.cents)), [('Bradesco', 300000), ('Poupança', 50000)]);
    expect(report.openCards!.map((c) => (c.name, c.cents)), [('Amazon', 13999)]);
  });

  test('mês sem lançamentos', () {
    final report = MonthReport.from(month: november, generatedAt: now, rows: const [], includeLines: true);
    expect(report.isEmpty, isTrue);
    expect(report.lines, isEmpty);
    expect(report.resultCents, 0);
  });

  group('pdfSafe', () {
    test('mantém acentos do português e o ponto médio', () {
      expect(pdfSafe('Açaí · Café da Mãe'), 'Açaí · Café da Mãe');
    });

    test('troca o que a fonte padrão não tem (emoji, seta, aspas curvas) por ?', () {
      expect(pdfSafe('Pizza 🍕'), 'Pizza ?');
      expect(pdfSafe('A → B'), 'A ? B');
      expect(pdfSafe('“oi”'), '?oi?');
    });

    test('quebra de linha e tabulação viram espaço', () {
      expect(pdfSafe('a\nb\tc'), 'a b c');
    });
  });
}
