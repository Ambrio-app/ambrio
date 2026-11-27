import '../../../core/utils/year_month.dart';
import 'entry_type.dart';
import 'entry_with_account.dart';
import 'month_situation.dart';
import 'month_summary.dart';

/// Uma linha da lista de lançamentos do relatório.
class ReportLine {
  const ReportLine({
    required this.date,
    required this.type,
    required this.description,
    required this.account,
    required this.cents,
    this.note,
  });

  final DateTime date;
  final String type;
  final String description;

  /// "Bradesco" ou "Bradesco → fatura Amazon" (fluxo de dinheiro).
  final String account;

  /// Com sinal: entrada positiva, saída negativa. Transferência e pagamento de fatura são
  /// movimentos entre contas suas e saem com o valor sem sinal (não entram nos totais).
  final int cents;
  final String? note;
}

/// O relatório de um mês (feat 0030): só junta números que o app já calcula
/// ([MonthSummary], [MonthSituation]) numa forma pronta para desenhar. Sem Flutter, sem PDF.
///
/// Por padrão leva **só os totais**. A lista de lançamentos e os saldos só entram se a pessoa pedir.
class MonthReport {
  const MonthReport({
    required this.month,
    required this.generatedAt,
    required this.incomeCents,
    required this.debitExpenseCents,
    required this.cards,
    this.balances,
    this.openCards,
    this.lines,
  });

  factory MonthReport.from({
    required YearMonth month,
    required DateTime generatedAt,
    required List<EntryWithAccount> rows,
    MonthSituation? situation,
    bool includeLines = false,
  }) {
    final summary = MonthSummary.from(rows);
    return MonthReport(
      month: month,
      generatedAt: generatedAt,
      incomeCents: summary.incomeCents,
      debitExpenseCents: summary.debitExpenseCents,
      cards: [for (final c in summary.cards) (name: c.card.name, cents: c.cents)],
      balances: situation == null
          ? null
          : [for (final b in situation.accountBalances) (name: b.account.name, cents: b.cents)],
      openCards: situation == null
          ? null
          : [for (final c in situation.openCards) (name: c.card.name, cents: c.openCents)],
      lines: includeLines ? _lines(rows) : null,
    );
  }

  final YearMonth month;
  final DateTime generatedAt;
  final int incomeCents;
  final int debitExpenseCents;

  /// Só os cartões com gasto no mês, em ordem alfabética.
  final List<({String name, int cents})> cards;

  /// Saldo de hoje de cada conta corrente; nulo se a pessoa não pediu os saldos.
  final List<({String name, int cents})>? balances;

  /// O que está em aberto em cada cartão hoje; nulo se a pessoa não pediu os saldos.
  final List<({String name, int cents})>? openCards;

  /// Lançamentos do mês, do mais antigo ao mais novo; nulo se a pessoa não pediu a lista.
  final List<ReportLine>? lines;

  int get cardsCents => cards.fold(0, (sum, c) => sum + c.cents);

  /// Tudo o que se gastou no mês (débito mais cartões).
  int get spentCents => debitExpenseCents + cardsCents;

  /// O que entrou menos o que se gastou (pode ser negativo).
  int get resultCents => incomeCents - spentCents;

  bool get isEmpty => incomeCents == 0 && debitExpenseCents == 0 && cards.isEmpty;
}

List<ReportLine> _lines(List<EntryWithAccount> rows) {
  final sorted = [...rows]
    ..sort((a, b) {
      final byDate = a.entry.date.compareTo(b.entry.date);
      return byDate != 0 ? byDate : a.entry.id.compareTo(b.entry.id);
    });
  return [
    for (final EntryWithAccount(:entry, :account, :toAccount) in sorted)
      ReportLine(
        date: entry.date,
        type: entry.type.label,
        description: entry.description,
        account: switch (entry.type) {
          EntryType.transfer => '${account.name} → ${toAccount?.name ?? '?'}',
          EntryType.billPayment => '${account.name} → fatura ${toAccount?.name ?? '?'}',
          _ => account.name,
        },
        cents: switch (entry.type) {
          EntryType.income || EntryType.adjustmentIncrease => entry.amountCents,
          EntryType.expense || EntryType.adjustmentDecrease => -entry.amountCents,
          _ => entry.amountCents,
        },
        note: entry.note,
      ),
  ];
}

/// Texto seguro para o PDF: a fonte padrão cobre só Latin-1 (acentos do português, `·`, `ª`).
/// O que passa disso (emoji, `→`, aspas curvas) vira `?`; quebra de linha vira espaço.
String pdfSafe(String text) {
  final out = StringBuffer();
  for (final rune in text.runes) {
    if (rune == 0x0A || rune == 0x0D || rune == 0x09) {
      out.write(' ');
    } else if (rune < 0x20 || (rune > 0x7E && rune < 0xA0) || rune > 0xFF) {
      out.write('?');
    } else {
      out.writeCharCode(rune);
    }
  }
  return out.toString();
}
