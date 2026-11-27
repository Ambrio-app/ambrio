import 'dart:convert';

import 'package:ambrio/core/database/app_database.dart';
import 'package:ambrio/core/utils/year_month.dart';
import 'package:ambrio/features/accounts/domain/account_kind.dart';
import 'package:ambrio/features/entries/data/month_report_pdf.dart';
import 'package:ambrio/features/entries/domain/entry_type.dart';
import 'package:ambrio/features/entries/domain/entry_with_account.dart';
import 'package:ambrio/features/entries/domain/month_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  final created = DateTime(2025);
  final bank = Account(id: 1, name: 'Bradesco', kind: AccountKind.checking, closingDayInCurrent: false, createdAt: created);

  EntryWithAccount row(int id, EntryType type, int cents, String description) => EntryWithAccount(
    Entry(
      id: id,
      accountId: 1,
      type: type,
      description: description,
      amountCents: cents,
      date: DateTime(2026, 11, 1 + id % 28),
      competence: 202611,
      createdAt: created,
    ),
    bank,
  );

  MonthReport report(List<EntryWithAccount> rows, {bool lines = false}) =>
      MonthReport.from(month: YearMonth(2026, 11), generatedAt: DateTime(2026, 11, 25), rows: rows, includeLines: lines);

  test('o nome do arquivo leva o mês', () {
    expect(monthReportFileName(report(const [])), 'ambrio-relatorio-2026-11.pdf');
  });

  test('gera um PDF de verdade (cabeçalho %PDF e fim %%EOF)', () async {
    final bytes = await buildMonthReportPdf(
      report([row(1, EntryType.income, 500000, 'Salário'), row(2, EntryType.expense, 12345, 'Mercado')]),
    );
    expect(bytes.length, greaterThan(500));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
    expect(ascii.decode(bytes.sublist(bytes.length - 6)).trim(), '%%EOF');
  });

  test('mês sem lançamentos também gera o PDF', () async {
    final bytes = await buildMonthReportPdf(report(const [], lines: true));
    expect(ascii.decode(bytes.sublist(0, 5)), '%PDF-');
  });

  test('muitos lançamentos viram várias páginas, e emoji e acento não quebram', () async {
    final rows = [
      for (var i = 1; i <= 220; i++) row(i, EntryType.expense, 1000 + i, i % 7 == 0 ? 'Pizza 🍕 açaí' : 'Compra número $i'),
    ];
    final small = await buildMonthReportPdf(report(rows.take(3).toList(), lines: true));
    final big = await buildMonthReportPdf(report(rows, lines: true));
    expect(ascii.decode(big.sublist(0, 5)), '%PDF-');
    expect(big.length, greaterThan(small.length * 3), reason: 'a lista maior ocupa mais páginas');
  });
}
