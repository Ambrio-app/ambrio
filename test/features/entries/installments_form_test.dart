import 'package:ambrio/app.dart';
import 'package:ambrio/core/database/app_database.dart';
import 'package:ambrio/core/database/database_provider.dart';
import 'package:ambrio/core/utils/clock.dart';
import 'package:ambrio/core/utils/formatters.dart';
import 'package:ambrio/core/widgets/money_text.dart';
import 'package:ambrio/core/widgets/tour_target.dart';
import 'package:ambrio/features/accounts/data/accounts_repository.dart';
import 'package:ambrio/features/accounts/domain/account_kind.dart';
import 'package:ambrio/features/entries/data/entries_repository.dart';
import 'package:ambrio/features/entries/domain/entry_type.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Compra parcelada no formulário e na Situação (feat 0031).
void main() {
  final now = DateTime(2026, 11, 17, 12);

  setUpAll(() async {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
    await initializeDateFormatting('pt_BR');
  });

  late AppDatabase db;
  late EntriesRepository repo;
  late AccountsRepository accounts;
  late int bank;
  late int card;

  setUp(() async {
    db = AppDatabase(DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true));
    repo = EntriesRepository(db, now: () => now);
    accounts = AccountsRepository(db, repo);
    bank = await accounts.create(name: 'Bradesco', kind: AccountKind.checking);
    card = await accounts.create(
      name: 'Nubank',
      kind: AccountKind.creditCard,
      linkedAccountId: bank,
      closingDay: 26,
      dueDay: 5,
    );
  });
  tearDown(() => db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));

  Future<void> openApp(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          tourEnabledProvider.overrideWithValue(false),
          clockProvider.overrideWithValue(() => now),
          balancesHiddenAtStartProvider.overrideWithValue(false),
        ],
        child: const AmbrioApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNewEntry(WidgetTester tester) async {
    await tester.tap(find.byTooltip('Novo lançamento'));
    await tester.pumpAndSettle();
  }

  Future<void> pickInstallments(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text('À vista (1x)'));
    await tester.tap(find.text('À vista (1x)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  testWidgets('o campo Parcelas só aparece em despesa no cartão', (tester) async {
    await openApp(tester);
    await openNewEntry(tester);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Bradesco'));
    await tester.pumpAndSettle();
    expect(find.text('Parcelas'), findsNothing, reason: 'conta corrente não parcela');

    await tester.tap(find.widgetWithText(ChoiceChip, 'Nubank · cartão do Bradesco'));
    await tester.pumpAndSettle();
    expect(find.text('Parcelas'), findsOneWidget);
    expect(find.textContaining('Parcelamento ainda não existe'), findsNothing);
  });

  testWidgets('a prévia mostra o valor de cada parcela, o intervalo e o mês da última', (tester) async {
    await openApp(tester);
    await openNewEntry(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nubank · cartão do Bradesco'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '60001');
    await tester.pumpAndSettle();
    await pickInstallments(tester, '3x');

    expect(
      find.textContaining('${Formatters.money(20001)} na 1ª e 2x de ${Formatters.money(20000)}'),
      findsOneWidget,
    );
    expect(find.textContaining('Parcelas 1/3 a 3/3'), findsOneWidget);
    expect(find.textContaining('a última em janeiro de 2027'), findsOneWidget);
  });

  testWidgets('salvar uma compra em 3x grava três parcelas, uma por mês', (tester) async {
    await openApp(tester);
    await openNewEntry(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nubank · cartão do Bradesco'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '60000');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Geladeira');
    await pickInstallments(tester, '3x');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    final group = await (db.select(db.entries)..where((e) => e.installmentCount.isNotNull())).get();
    expect(group, hasLength(3));
    expect(group.map((e) => e.installmentNumber).toList()..sort(), [1, 2, 3]);
    expect(group.every((e) => e.amountCents == 20000 && e.description == 'Geladeira'), isTrue);
  });

  testWidgets('compra à vista (1x) continua gravando um lançamento comum', (tester) async {
    await openApp(tester);
    await openNewEntry(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Nubank · cartão do Bradesco'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '9990');
    await tester.enterText(find.widgetWithText(TextField, 'Descrição'), 'Livro');
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar'));
    await tester.pumpAndSettle();

    final all = await db.select(db.entries).get();
    expect(all, hasLength(1));
    expect(all.single.installmentCount, isNull);
  });

  testWidgets('"Parcelas a vencer" aparece na Situação e some com o olhinho fechado', (tester) async {
    await repo.saveInstallments(
      EntryDraft(accountId: card, type: EntryType.expense, description: 'Geladeira', amountCents: 60000, date: now),
      count: 3,
    );
    await openApp(tester);
    await tester.tap(find.textContaining('Em conta').first);
    await tester.pumpAndSettle();

    // Hoje só a 1ª parcela pesa; as outras duas (R$ 400,00) ainda vão vencer.
    expect(find.text('Parcelas a vencer ${Formatters.money(40000)}'), findsWidgets);
    expect(find.textContaining('ainda não entram nas faturas abertas'), findsOneWidget);

    await tester.tap(find.byTooltip('Ocultar valores'));
    await tester.pump();
    expect(find.textContaining(Formatters.money(40000)), findsNothing);
  });

  testWidgets('excluir uma parcela pergunta se é só ela ou a compra inteira', (tester) async {
    final ids = await repo.saveInstallments(
      EntryDraft(accountId: card, type: EntryType.expense, description: 'Geladeira', amountCents: 60000, date: now),
      count: 3,
    );
    await openApp(tester);
    await tester.tap(find.textContaining('Geladeira').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Parcela 1/3 de uma compra parcelada'), findsOneWidget);

    await tester.tap(find.byTooltip('Excluir lançamento'));
    await tester.pumpAndSettle();
    expect(find.text('Só esta parcela'), findsOneWidget);
    expect(find.text('Todas as parcelas desta compra'), findsOneWidget);

    await tester.tap(find.text('Todas as parcelas desta compra'));
    await tester.pumpAndSettle();
    expect(await db.select(db.entries).get(), isEmpty);
    expect(ids, hasLength(3));
    expect(find.text('Compra parcelada excluída (3 parcelas).'), findsOneWidget);

    await tester.tap(find.text('Desfazer'));
    await tester.pumpAndSettle();
    expect(await db.select(db.entries).get(), hasLength(3));
  });

  testWidgets('excluir só esta parcela deixa as outras', (tester) async {
    await repo.saveInstallments(
      EntryDraft(accountId: card, type: EntryType.expense, description: 'Geladeira', amountCents: 60000, date: now),
      count: 3,
    );
    await openApp(tester);
    await tester.tap(find.textContaining('Geladeira').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Excluir lançamento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Só esta parcela'));
    await tester.pumpAndSettle();

    expect(await db.select(db.entries).get(), hasLength(2));
  });
}
