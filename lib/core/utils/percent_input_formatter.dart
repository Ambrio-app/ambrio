import 'package:flutter/services.dart';

/// Campo de taxa em que se digita só números e o valor "anda" pelas casas decimais,
/// como o campo de dinheiro: `25` → 0,25 % · `250` → 2,50 % · `1999` → 19,99 %.
///
/// A taxa vive como **centésimos de ponto percentual** (2,5 % = 250), inteiro, sem `double`.
/// Leia com [PercentInputFormatter.parse].
class PercentInputFormatter extends TextInputFormatter {
  /// Até 99,99 %: acima disso é quase certamente erro de digitação.
  static const int maxDigits = 4;

  /// A taxa em centésimos de ponto (2,5 % = 250) do texto do campo. Vazio vale 0.
  static int parse(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }

  /// "2,50 %" para 250; campo vazio para 0.
  static String format(int bps) => bps == 0 ? '' : '${label(bps)} %';

  /// "2,50" para 250 (sem o símbolo; use em frases como "2,50% de R$ 1.000,00").
  static String label(int bps) => '${bps ~/ 100},${(bps % 100).toString().padLeft(2, '0')}';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) return oldValue;
    final text = format(parse(digits));
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}
