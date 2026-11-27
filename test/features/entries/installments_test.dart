import 'package:ambrio/features/entries/domain/installments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  int sum(List<InstallmentSlice> s) => s.fold(0, (a, b) => a + b.amountCents);

  group('planInstallments', () {
    test('divide o total e o resto de centavos vai para a parcela 1', () {
      final p = planInstallments(totalCents: 60001, count: 3, date: DateTime(2026, 11, 17));
      expect(p.map((s) => s.amountCents), [20001, 20000, 20000]);
      expect(sum(p), 60001);
      expect(p.map((s) => s.label), ['1/3', '2/3', '3/3']);
    });

    test('as datas caem um mês depois da outra, no mesmo dia', () {
      final p = planInstallments(totalCents: 30000, count: 3, date: DateTime(2026, 11, 17));
      expect(p.map((s) => s.date), [DateTime(2026, 11, 17), DateTime(2026, 12, 17), DateTime(2027, 1, 17)]);
    });

    test('dia 31 cai no último dia do mês quando ele não existe (e em ano bissexto)', () {
      final p = planInstallments(totalCents: 40000, count: 4, date: DateTime(2027, 1, 31));
      expect(p.map((s) => s.date), [
        DateTime(2027, 1, 31),
        DateTime(2027, 2, 28),
        DateTime(2027, 3, 31),
        DateTime(2027, 4, 30),
      ]);
      final leap = planInstallments(totalCents: 20000, count: 2, date: DateTime(2028, 1, 31));
      expect(leap.last.date, DateTime(2028, 2, 29));
    });

    test('começar na parcela 3 de 6 cria 4 parcelas numeradas 3/6 a 6/6 e nada anterior', () {
      final p = planInstallments(
        totalCents: 60001,
        count: 6,
        current: 3,
        date: DateTime(2026, 11, 17),
      );
      expect(p.map((s) => s.label), ['3/6', '4/6', '5/6', '6/6']);
      expect(p.first.date, DateTime(2026, 11, 17), reason: 'a data informada é a da parcela atual');
      expect(p.last.date, DateTime(2027, 2, 17));
      expect(p.every((s) => s.amountCents == 10000), isTrue, reason: 'o resto ficou com a parcela 1, que já passou');
    });

    test('parcela atual igual à última cria uma só', () {
      final p = planInstallments(totalCents: 30000, count: 3, current: 3, date: DateTime(2026, 11, 17));
      expect(p, hasLength(1));
      expect(p.single.label, '3/3');
    });

    test('a soma das parcelas é sempre o total, para qualquer divisão', () {
      for (final total in [100, 101, 9999, 123457, 600001]) {
        for (final n in [2, 3, 7, 12, 48]) {
          if (total < n) continue;
          expect(sum(planInstallments(totalCents: total, count: n, date: DateTime(2026, 1, 1))), total);
        }
      }
    });

    test('limites: de 2 a $kMaxInstallments parcelas, parcela atual válida e pelo menos 1 centavo cada', () {
      final d = DateTime(2026, 1, 1);
      expect(() => planInstallments(totalCents: 1000, count: 1, date: d), throwsArgumentError);
      expect(() => planInstallments(totalCents: 100000, count: kMaxInstallments + 1, date: d), throwsArgumentError);
      expect(() => planInstallments(totalCents: 1000, count: 3, current: 0, date: d), throwsArgumentError);
      expect(() => planInstallments(totalCents: 1000, count: 3, current: 4, date: d), throwsArgumentError);
      expect(() => planInstallments(totalCents: 2, count: 3, date: d), throwsArgumentError);
      expect(planInstallments(totalCents: kMaxInstallments, count: kMaxInstallments, date: d), hasLength(kMaxInstallments));
    });
  });

  test('addMonthsKeepingDay atravessa o ano', () {
    expect(addMonthsKeepingDay(DateTime(2026, 11, 30), 3), DateTime(2027, 2, 28));
    expect(addMonthsKeepingDay(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
  });
}
