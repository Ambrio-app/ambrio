import 'package:flutter/material.dart';

import '../../../core/utils/formatters.dart';
import '../domain/installments.dart';

/// "Parcelas" da compra no cartão (feat 0031): em quantas vezes e, se a compra já
/// está andando, em qual parcela a pessoa está. O valor digitado em "Valor" é o
/// **total** da compra; a prévia mostra quanto fica cada parcela e até quando vai.
///
/// Só desenha: o estado fica em `EntryFormScreen`. A conta de dividir mora em
/// [planInstallments], a mesma que o repositório usa para gravar.
class InstallmentsField extends StatelessWidget {
  const InstallmentsField({
    super.key,
    required this.count,
    required this.current,
    required this.totalCents,
    required this.date,
    required this.onCountChanged,
    required this.onCurrentChanged,
  });

  final int count;
  final int current;
  final int totalCents;

  /// A data da parcela em que a pessoa está (a data do formulário).
  final DateTime date;
  final ValueChanged<int> onCountChanged;
  final ValueChanged<int> onCurrentChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          // O valor muda por fora (ex.: "Salvar e novo" volta para 1): a chave refaz o campo.
          key: ValueKey('parcelas-$count'),
          initialValue: count,
          decoration: const InputDecoration(labelText: 'Parcelas'),
          items: [
            const DropdownMenuItem(value: 1, child: Text('À vista (1x)')),
            for (var n = 2; n <= kMaxInstallments; n++) DropdownMenuItem(value: n, child: Text('${n}x')),
          ],
          onChanged: (n) {
            if (n != null) onCountChanged(n);
          },
        ),
        if (count > 1) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            key: ValueKey('parcela-atual-$count-$current'),
            initialValue: current,
            decoration: const InputDecoration(labelText: 'Em qual parcela você está?'),
            items: [
              for (var k = 1; k <= count; k++) DropdownMenuItem(value: k, child: Text('$k de $count')),
            ],
            onChanged: (k) {
              if (k != null) onCurrentChanged(k);
            },
          ),
          _Preview(count: count, current: current, totalCents: totalCents, date: date, style: theme.textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.count,
    required this.current,
    required this.totalCents,
    required this.date,
    required this.style,
  });

  final int count;
  final int current;
  final int totalCents;
  final DateTime date;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    if (totalCents < count) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text('Informe o valor total da compra para ver as parcelas.', style: style),
      );
    }
    final slices = planInstallments(totalCents: totalCents, count: count, current: current, date: date);
    final base = totalCents ~/ count;
    final hasRest = slices.first.number == 1 && slices.first.amountCents != base;
    final value = hasRest
        ? '${Formatters.money(slices.first.amountCents)} na 1ª e ${count - 1}x de ${Formatters.money(base)}'
        : '${count}x de ${Formatters.money(base)}';
    final range = slices.length == 1 ? 'Parcela ${slices.first.label}' : 'Parcelas ${slices.first.label} a ${slices.last.label}';
    final before = current - 1;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        [
          value,
          '$range · a última em ${Formatters.monthYear(slices.last.date)}',
          if (before > 0)
            before == 1
                ? 'A parcela 1 não entra: já foi paga.'
                : 'As parcelas 1 a $before não entram: já foram pagas.',
        ].join('\n'),
        style: style,
      ),
    );
  }
}
