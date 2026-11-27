import 'package:ambrio/core/utils/clock.dart';
import 'package:ambrio/features/settings/presentation/report_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// A seção "Relatório do mês" de Configurações › Dados (feat 0030).
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [clockProvider.overrideWithValue(() => DateTime(2026, 11, 25))],
        child: const MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ReportSection()))),
      ),
    );
  }

  testWidgets('abre no mês corrente, só com os totais, e explica que o arquivo fica no aparelho', (tester) async {
    await pump(tester);

    expect(find.text('Relatório do mês'), findsOneWidget);
    expect(find.text('Novembro de 2026'), findsOneWidget);
    expect(find.textContaining('gerado aqui no aparelho'), findsOneWidget);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Incluir a lista de lançamentos')).value, isFalse);
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Incluir os saldos')).value, isFalse);
    expect(find.widgetWithText(OutlinedButton, 'Gerar relatório em PDF'), findsOneWidget);
  });

  testWidgets('oferece o mês anterior e liga as opções', (tester) async {
    await pump(tester);

    await tester.tap(find.text('Novembro de 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Outubro de 2026'), findsOneWidget);
    await tester.tap(find.text('Outubro de 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Outubro de 2026'), findsOneWidget);

    await tester.tap(find.widgetWithText(SwitchListTile, 'Incluir os saldos'));
    await tester.pump();
    expect(tester.widget<SwitchListTile>(find.widgetWithText(SwitchListTile, 'Incluir os saldos')).value, isTrue);
  });
}
