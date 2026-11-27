// Protótipos da tela inicial "resumo de tudo" (Brainstorm 008, 2026-11-24): três propostas
// desenhadas com widgets e dados FICTÍCIOS, como imagens para o "teste dos cinco segundos".
// Fora de `test/`, não roda no CI. Spike: sai do repositório se não virar entrega.
//
//     AUDIT_OUT=<pasta> flutter test tool/audit/prototipos_inicio_test.dart
//
// Gabarito: em conta R$ 4.230,10; Nubank R$ 1.240,00 em aberto, vence em 3 dias; Inter R$ 310,00,
// vence em 12 dias; entrou R$ 5.000,00 e gastou R$ 1.900,00 (38%): gastou MENOS do que entrou.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:ambrio/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../test/support/real_fonts.dart';

final out = Platform.environment['AUDIT_OUT'] ?? '${Directory.systemTemp.path}${Platform.pathSeparator}inicio';

Widget _row(IconData icon, String title, String sub, String value) => ListTile(
  dense: true,
  leading: Icon(icon),
  title: Text(title),
  subtitle: Text(sub),
  trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
);

Widget _entries() => Column(
  children: [
    _row(Icons.account_balance_outlined, 'Freela', '19/11 · Verde', '+ R\$ 850,00'),
    _row(Icons.account_balance_outlined, 'Internet', '18/11 · Azul', 'R\$ 99,90'),
    _row(Icons.credit_card, 'Jantar', '13/11 · Nubank · cartão', 'R\$ 187,00'),
    _row(Icons.credit_card, 'Livro de design', '12/11 · Inter · cartão', 'R\$ 89,90'),
    _row(Icons.account_balance_outlined, 'Mercado', '08/11 · Azul', 'R\$ 234,50'),
  ],
);

Widget _bar(BuildContext context, double frac) {
  final s = Theme.of(context).colorScheme;
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Container(
      height: 12,
      decoration: BoxDecoration(color: s.surfaceContainerHigh, border: Border.all(color: s.primary, width: 1.5)),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(widthFactor: frac, child: Container(color: AppTheme.amber)),
    ),
  );
}

Widget _dueLine(BuildContext c, String card, String value, String due) => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    children: [
      const Icon(Icons.credit_card, size: 18),
      const SizedBox(width: 8),
      Expanded(child: Text('$card · em aberto $value')),
      Text(due, style: Theme.of(c).textTheme.labelLarge),
    ],
  ),
);

/// A: o painel do mês ganha o saldo e as faturas (evolução do atual).
class ProposalA extends StatelessWidget {
  const ProposalA({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.menu),
        title: const Text('Novembro de 2026'),
        actions: const [Icon(Icons.visibility_outlined), SizedBox(width: 12), Icon(Icons.search), SizedBox(width: 12)],
      ),
      body: ListView(
        children: [
          Card(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Em conta', style: t.textTheme.labelLarge),
                  Text('R\$ 4.230,10', style: t.textTheme.headlineSmall),
                  const SizedBox(height: 10),
                  Text('Gastou 38% do que entrou', style: t.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  _bar(context, 0.38),
                  const SizedBox(height: 10),
                  _dueLine(context, 'Nubank', 'R\$ 1.240,00', 'vence em 3 dias'),
                  _dueLine(context, 'Inter', 'R\$ 310,00', 'vence em 12 dias'),
                ],
              ),
            ),
          ),
          _entries(),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}

/// B: tela Início de resumo + barra inferior (Início, Lançamentos, Cartões).
class ProposalB extends StatelessWidget {
  const ProposalB({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    Widget section(String title, Widget child) => Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: t.textTheme.labelLarge),
            const SizedBox(height: 6),
            child,
          ],
        ),
      ),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Início'), actions: const [Icon(Icons.visibility_outlined), SizedBox(width: 16)]),
      body: ListView(
        children: [
          section('Em conta', Text('R\$ 4.230,10', style: t.textTheme.headlineSmall)),
          section(
            'Novembro: gastou 38% do que entrou',
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _bar(context, 0.38),
                const SizedBox(height: 6),
                const Text('Entrou R\$ 5.000,00 · Gastou R\$ 1.900,00'),
              ],
            ),
          ),
          section(
            'Cartões',
            Column(
              children: [
                _dueLine(context, 'Nubank', 'R\$ 1.240,00', 'vence em 3 dias'),
                _dueLine(context, 'Inter', 'R\$ 310,00', 'vence em 12 dias'),
              ],
            ),
          ),
          section(
            'Recentes',
            Column(
              children: [
                _row(Icons.account_balance_outlined, 'Freela', '19/11 · Verde', '+ R\$ 850,00'),
                _row(Icons.account_balance_outlined, 'Internet', '18/11 · Azul', 'R\$ 99,90'),
                _row(Icons.credit_card, 'Jantar', '13/11 · Nubank', 'R\$ 187,00'),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Início'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Lançamentos'),
          NavigationDestination(icon: Icon(Icons.credit_card), label: 'Cartões'),
        ],
      ),
      floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
    );
  }
}

/// C: abas horizontais Contas | Cartão | Investimento (a ideia do Pierre), aba Contas aberta.
class ProposalC extends StatelessWidget {
  const ProposalC({super.key});
  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          leading: const Icon(Icons.menu),
          title: const Text('Ambrio'),
          actions: const [Icon(Icons.visibility_outlined), SizedBox(width: 16)],
          bottom: const TabBar(tabs: [Tab(text: 'Contas'), Tab(text: 'Cartão'), Tab(text: 'Investimento')]),
        ),
        body: ListView(
          children: [
            Card(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Em conta', style: t.textTheme.labelLarge),
                    Text('R\$ 4.230,10', style: t.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    const Text('Entrou R\$ 5.000,00 · Gastou R\$ 1.900,00'),
                    const SizedBox(height: 6),
                    _bar(context, 0.38),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Text('Lançamentos de novembro', style: t.textTheme.titleSmall),
            ),
            _entries(),
          ],
        ),
        floatingActionButton: FloatingActionButton(onPressed: () {}, child: const Icon(Icons.add)),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
    await loadRealFonts();
    Directory(out).createSync(recursive: true);
  });

  final proposals = <String, Widget>{'A': const ProposalA(), 'B': const ProposalB(), 'C': const ProposalC()};
  for (final dark in [false, true]) {
    for (final e in proposals.entries) {
      testWidgets('proposta ${e.key} ${dark ? 'escuro' : 'claro'}', (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: dark ? AppTheme.dark() : AppTheme.light(),
              home: e.value,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 2.0);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File('$out/proposta-${e.key}-${dark ? 'escuro' : 'claro'}.png').writeAsBytesSync(bytes!.buffer.asUint8List());
        });
      });
    }
  }
}
