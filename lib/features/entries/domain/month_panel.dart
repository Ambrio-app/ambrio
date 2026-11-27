import '../../../core/database/app_database.dart';
import 'due_info.dart';
import 'month_situation.dart';

/// O que o painel da tela inicial mostra (feat 0050): o mês em duas barras (entrou e
/// gastou, em percentual) e o vencimento de cartão mais próximo. Só junta números que
/// já existem em [MonthSituation] e [DueInfo]; nada de regra nova.
///
/// Feito para ser entendido **sem os valores em reais** (o olhinho os esconde): a forma
/// (as barras), o percentual e os dias não dependem deles.
class MonthPanel {
  const MonthPanel._({
    required this.totalCents,
    required this.incomeCents,
    required this.spentCents,
    required this.dueCards,
  });

  /// Quantos cartões o painel lista (o resto fica na tela Situação).
  static const int maxDueCards = 2;

  factory MonthPanel.from({
    required MonthSituation situation,
    required DateTime today,
  }) {
    final due = <({Account card, DueInfo due, int openCents, int order})>[];
    for (final c in situation.openCards) {
      if (c.openCents <= 0 || c.card.dueDay == null) continue;
      due.add((
        card: c.card,
        due: DueInfo.of(dueDay: c.card.dueDay, today: today),
        openCents: c.openCents,
        order: due.length,
      ));
    }
    // Em empate de dia, vale a ordem em que os cartões vieram (o sort do Dart não é estável).
    due.sort((a, b) {
      final byDay = a.due.daysUntil!.compareTo(b.due.daysUntil!);
      return byDay != 0 ? byDay : a.order.compareTo(b.order);
    });
    return MonthPanel._(
      totalCents: situation.totalCents,
      incomeCents: situation.incomeCents,
      spentCents: situation.spentCents,
      dueCards: [
        for (final d in due.take(maxDueCards))
          (card: d.card, due: d.due, openCents: d.openCents),
      ],
    );
  }

  /// Até [maxDueCards] cartões com algo em aberto e dia de vencimento, do que vence primeiro ao último,
  /// com o valor em aberto (nunca "fatura a pagar": em aberto é o saldo do cartão).
  final List<({Account card, DueInfo due, int openCents})> dueCards;

  /// "Em conta": a soma dos saldos das contas correntes.
  final int totalCents;
  final int incomeCents;
  final int spentCents;

  /// O cartão com algo em aberto que vence primeiro (e o texto do vencimento); nulo se nenhum tem dia de vencimento.
  ({Account card, DueInfo due})? get nextDue =>
      dueCards.isEmpty ? null : (card: dueCards.first.card, due: dueCards.first.due);

  bool get hasIncome => incomeCents > 0;

  /// O que se gastou em percentual do que entrou, arredondado; nulo sem entradas.
  int? get spentPercent =>
      hasIncome ? (spentCents * 100 / incomeCents).round() : null;

  /// Gastou mais do que entrou: a barra enche, ganha ícone e a palavra "acima".
  bool get overflow => hasIncome && spentCents > incomeCents;

  /// Largura da barra de gasto (0 a 1), sempre a partir do zero e na mesma escala da de entrada.
  double get spentFraction =>
      hasIncome ? (spentCents / incomeCents).clamp(0.0, 1.0) : 0;

  /// A frase que resume o mês (o leitor de tela fala o mesmo, com "acima do que entrou" quando passou).
  String get phrase {
    if (!hasIncome) {
      return spentCents == 0 ? 'Sem movimento neste mês' : 'Sem entradas neste mês';
    }
    final p = spentPercent!;
    return 'Gastou $p% do que entrou';
  }
}
