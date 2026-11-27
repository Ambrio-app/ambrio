import 'package:ambrio/core/utils/percent_input_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final formatter = PercentInputFormatter();

  String type(String previous, String next) =>
      formatter.formatEditUpdate(TextEditingValue(text: previous), TextEditingValue(text: next)).text;

  test('digitar anda pelas casas decimais', () {
    expect(type('', '2'), '0,02 %');
    expect(type('0,02 %', '0,025 %'), '0,25 %');
    expect(type('0,25 %', '0,250 %'), '2,50 %');
    expect(type('2,50 %', '2,501 %'), '25,01 %');
  });

  test('apagar volta pelas casas até esvaziar', () {
    expect(type('2,50 %', '2,5 %'), '0,25 %');
    expect(type('0,02 %', '0,0 %'), '');
  });

  test('não passa de 99,99 %', () {
    expect(type('99,99 %', '99,999 %'), '99,99 %');
  });

  test('parse devolve centésimos de ponto e vazio vale 0', () {
    expect(PercentInputFormatter.parse('2,50 %'), 250);
    expect(PercentInputFormatter.parse('19,99 %'), 1999);
    expect(PercentInputFormatter.parse(''), 0);
  });

  test('format e label', () {
    expect(PercentInputFormatter.format(250), '2,50 %');
    expect(PercentInputFormatter.format(5), '0,05 %');
    expect(PercentInputFormatter.format(0), '');
    expect(PercentInputFormatter.label(1999), '19,99');
  });
}
