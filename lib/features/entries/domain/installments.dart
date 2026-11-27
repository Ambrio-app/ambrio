/// Compra parcelada no cartão (feat 0031): como o total vira parcelas.
///
/// Cada parcela é um lançamento comum com a própria data (e, por isso, a própria
/// fatura pela regra do fechamento). Aqui só mora a conta: valores e datas.
library;

/// Máximo de parcelas aceito (4 anos). Mais que isso é quase certamente erro de digitação.
const int kMaxInstallments = 48;

/// Uma parcela a gravar.
class InstallmentSlice {
  const InstallmentSlice({
    required this.number,
    required this.count,
    required this.amountCents,
    required this.date,
  });

  /// De 1 a [count].
  final int number;
  final int count;
  final int amountCents;
  final DateTime date;

  /// "2/6".
  String get label => '$number/$count';
}

/// As parcelas de [current] até [count] de uma compra de [totalCents].
///
/// * [totalCents] é o total da **compra** (não o que falta).
/// * [current] é a parcela em que a pessoa está: 1 para uma compra de hoje; 3 numa
///   compra de 6x que já pagou duas. As anteriores **não** são criadas (já foram
///   pagas e entrariam como dívida no cartão).
/// * [date] é a data da parcela [current]; as seguintes caem um mês depois da outra,
///   mantendo o dia, e no último dia do mês quando ele não existe (31/jan → 28/fev).
/// * O resto da divisão em centavos vai para a parcela 1 (só existe se [current] for 1);
///   as demais têm o mesmo valor. Somando as `count` parcelas, o total fecha sempre.
List<InstallmentSlice> planInstallments({
  required int totalCents,
  required int count,
  int current = 1,
  required DateTime date,
}) {
  if (count < 2 || count > kMaxInstallments) {
    throw ArgumentError('Parcelas: de 2 a $kMaxInstallments.');
  }
  if (current < 1 || current > count) {
    throw ArgumentError('A parcela atual vai de 1 a $count.');
  }
  if (totalCents < count) {
    throw ArgumentError('O total não dá nem 1 centavo por parcela.');
  }
  final base = totalCents ~/ count;
  final rest = totalCents - base * count;
  return [
    for (var k = current; k <= count; k++)
      InstallmentSlice(
        number: k,
        count: count,
        amountCents: k == 1 ? base + rest : base,
        date: addMonthsKeepingDay(date, k - current),
      ),
  ];
}

/// [date] daqui a [months] meses, no mesmo dia, ou no último dia do mês se ele não existir.
DateTime addMonthsKeepingDay(DateTime date, int months) {
  final first = DateTime(date.year, date.month + months);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, date.day > lastDay ? lastDay : date.day);
}
