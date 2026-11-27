import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock.dart';
import '../../../core/utils/year_month.dart';
import '../../accounts/presentation/accounts_providers.dart';
import '../../entries/data/month_report_pdf.dart';
import '../../entries/domain/month_report.dart';
import '../../entries/domain/month_situation.dart';
import '../../entries/presentation/month_providers.dart';

/// "Relatório do mês" em Configurações › Dados (feat 0030): um PDF com os totais do mês,
/// para ler no celular ou mandar a quem ajuda com as contas. Por padrão leva **só os totais**;
/// a lista de lançamentos e os saldos só entram se a pessoa ligar. O arquivo é gerado no aparelho
/// e salvo onde ela escolher; nada é enviado.
class ReportSection extends ConsumerStatefulWidget {
  const ReportSection({super.key});

  @override
  ConsumerState<ReportSection> createState() => _ReportSectionState();
}

class _ReportSectionState extends ConsumerState<ReportSection> {
  YearMonth? _month;
  bool _lines = false;
  bool _balances = false;
  bool _busy = false;

  /// O mês corrente e os 23 anteriores.
  List<YearMonth> _options(YearMonth current) => [
    for (var i = 0, m = current; i < 24; i++, m = m.previous()) m,
  ];

  void _say(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _generate(YearMonth month) async {
    setState(() => _busy = true);
    try {
      final rows = await ref.read(monthEntriesProvider(month).future);
      MonthSituation? situation;
      if (_balances) {
        final accounts = await ref.read(accountsProvider.future);
        final balances = await ref.read(accountBalancesProvider.future);
        situation = MonthSituation.from(accounts: accounts, balances: balances);
      }
      final report = MonthReport.from(
        month: month,
        generatedAt: ref.read(clockProvider)(),
        rows: rows,
        situation: situation,
        includeLines: _lines,
      );
      final bytes = await buildMonthReportPdf(report);
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Salvar relatório',
        fileName: monthReportFileName(report),
        bytes: bytes,
      );
      if (saved != null && mounted) _say('Relatório salvo.');
    } catch (e) {
      if (mounted) _say('Não consegui gerar o relatório: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final current = YearMonth.of(ref.read(clockProvider)());
    final month = _month ?? current;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Relatório do mês', style: theme.textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Um PDF com o resumo do mês, para ler no celular ou mandar a quem ajuda com as suas contas. '
          'Ele é gerado aqui no aparelho e salvo onde você escolher.',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<YearMonth>(
          key: ValueKey('relatorio-${month.key}'),
          initialValue: month,
          decoration: const InputDecoration(labelText: 'Mês'),
          items: [for (final m in _options(current)) DropdownMenuItem(value: m, child: Text(m.title))],
          onChanged: _busy ? null : (m) => setState(() => _month = m),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Incluir a lista de lançamentos'),
          subtitle: const Text('Data, descrição, conta e valor de cada um.'),
          value: _lines,
          onChanged: _busy ? null : (v) => setState(() => _lines = v),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Incluir os saldos'),
          subtitle: const Text('Saldo das contas e o que está em aberto nos cartões, hoje.'),
          value: _balances,
          onChanged: _busy ? null : (v) => setState(() => _balances = v),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _busy ? null : () => _generate(month),
          icon: const Icon(Icons.picture_as_pdf_outlined),
          label: const Text('Gerar relatório em PDF'),
        ),
      ],
    );
  }
}
