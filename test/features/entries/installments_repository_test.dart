import 'package:ambrio/core/database/app_database.dart';
import 'package:ambrio/features/accounts/data/accounts_repository.dart';
import 'package:ambrio/features/accounts/domain/account_kind.dart';
import 'package:ambrio/features/entries/data/entries_repository.dart';
import 'package:ambrio/features/entries/domain/entry_type.dart';
import 'package:ambrio/core/utils/year_month.dart';
import 'package:drift/drift.dart' show DatabaseConnection, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Compra parcelada no cartão (feat 0031), no banco de verdade (em memória).
void main() {
  setUpAll(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  late AppDatabase db;
  late EntriesRepository repo;
  late AccountsRepository accounts;
  late int bank;
  late int card;
  // Hoje: 17/11/2026. O cartão fecha dia 26 (o padrão "no dia do fechamento ainda é a fatura atual").
  final today = DateTime(2026, 11, 17);

  setUp(() async {
    db = AppDatabase(
      DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
    );
    repo = EntriesRepository(db, now: () => today);
    accounts = AccountsRepository(db, repo);
    bank = await accounts.create(name: 'Bradesco', kind: AccountKind.checking);
    card = await accounts.create(
      name: 'Nubank',
      kind: AccountKind.creditCard,
      closingDay: 26,
      dueDay: 5,
      linkedAccountId: bank,
    );
  });
  tearDown(() => db.close().timeout(const Duration(seconds: 5), onTimeout: () {}));

  EntryDraft purchase({int total = 60001, DateTime? date, String? note}) => EntryDraft(
    accountId: card,
    type: EntryType.expense,
    description: 'Geladeira',
    amountCents: total,
    date: date ?? DateTime(2026, 11, 17),
    note: note,
  );

  test('grava uma linha por parcela, com o mesmo grupo, os números e a data de cada mês', () async {
    final ids = await repo.saveInstallments(purchase(), count: 3);
    expect(ids, hasLength(3));

    final group = await repo.installmentsOf((await repo.find(ids.first))!.installmentGroupId!);
    expect(group.map((e) => e.installmentNumber), [1, 2, 3]);
    expect(group.every((e) => e.installmentCount == 3), isTrue);
    expect(group.map((e) => e.amountCents), [20001, 20000, 20000]);
    expect(group.fold<int>(0, (a, e) => a + e.amountCents), 60001);
    expect(group.map((e) => e.date), [DateTime(2026, 11, 17), DateTime(2026, 12, 17), DateTime(2027, 1, 17)]);
    expect(group.map((e) => e.installmentGroupId).toSet(), hasLength(1));
    expect(group.every((e) => e.description == 'Geladeira'), isTrue);
  });

  test('cada parcela cai na fatura certa pela regra do fechamento', () async {
    // 27/11 é depois do fechamento (dia 26): a 1ª já vai para a fatura de dezembro.
    final ids = await repo.saveInstallments(purchase(date: DateTime(2026, 11, 27)), count: 3);
    final competences = [for (final id in ids) (await repo.find(id))!.competence];
    expect(competences, [202612, 202701, 202702]);
  });

  test('parcelas futuras não entram no em aberto de hoje e passam a entrar quando a data chega', () async {
    await repo.saveInstallments(purchase(), count: 3);
    // Hoje (17/11): só a primeira (R$ 200,01) pesa no cartão.
    expect(await repo.balanceOf(card, today: DateTime(2026, 11, 17)), -20001);
    expect(await repo.balanceOf(card, today: DateTime(2026, 12, 17)), -40001);
    expect(await repo.balanceOf(card, today: DateTime(2027, 1, 17)), -60001);
  });

  test('"parcelas a vencer" soma só o que tem data depois de hoje, por cartão', () async {
    await repo.saveInstallments(purchase(), count: 3);
    final future = await repo.watchFutureInstallments().first;
    expect(future, {card: 40000});
  });

  test('compra que já está na parcela 3 de 6 cria só 3/6 a 6/6, com observação na primeira', () async {
    final ids = await repo.saveInstallments(purchase(total: 60000, note: 'Loja X'), count: 6, current: 3);
    final entries = [for (final id in ids) (await repo.find(id))!];
    expect(entries.map((e) => e.installmentNumber), [3, 4, 5, 6]);
    expect(entries.every((e) => e.amountCents == 10000), isTrue);
    expect(entries.first.note, 'Loja X · parcelas 1 a 2 anteriores ao uso do app');
    expect(entries[1].note, 'Loja X');
    expect(entries.first.date, DateTime(2026, 11, 17));
  });

  test('só cartão e só despesa podem ser parcelados', () async {
    expect(
      () => repo.saveInstallments(
        EntryDraft(
          accountId: bank,
          type: EntryType.expense,
          description: 'Mercado',
          amountCents: 3000,
          date: today,
        ),
        count: 3,
      ),
      throwsArgumentError,
    );
    expect(
      () => repo.saveInstallments(
        EntryDraft(accountId: card, type: EntryType.billPayment, toAccountId: bank, description: 'x', amountCents: 3000, date: today),
        count: 3,
      ),
      throwsArgumentError,
    );
    expect(() => repo.saveInstallments(purchase(), count: 1), throwsArgumentError);
  });

  test('uma falha no meio não deixa parcelas pela metade', () async {
    // 1 centavo para 3 parcelas: o plano recusa antes de gravar qualquer linha.
    await expectLater(() => repo.saveInstallments(purchase(total: 2), count: 3), throwsArgumentError);
    expect(await repo.countForAccount(card), 0);
  });

  test('excluir o grupo apaga todas as parcelas e restaurar devolve idênticas', () async {
    final ids = await repo.saveInstallments(purchase(), count: 3);
    final groupId = (await repo.find(ids.first))!.installmentGroupId!;
    final before = await repo.installmentsOf(groupId);

    final removed = await repo.deleteGroup(groupId);
    expect(removed, hasLength(3));
    expect(await repo.installmentsOf(groupId), isEmpty);

    await repo.restoreAll(removed);
    expect(await repo.installmentsOf(groupId), before);
  });

  test('excluir só uma parcela deixa as outras', () async {
    final ids = await repo.saveInstallments(purchase(), count: 3);
    final groupId = (await repo.find(ids.first))!.installmentGroupId!;
    await repo.delete(ids[1]);
    expect((await repo.installmentsOf(groupId)).map((e) => e.installmentNumber), [1, 3]);
  });

  test('editar uma parcela mexe só nela e ela continua parcela', () async {
    final ids = await repo.saveInstallments(purchase(), count: 3);
    final second = (await repo.find(ids[1]))!;
    await repo.save(
      EntryDraft(
        id: second.id,
        accountId: card,
        type: EntryType.expense,
        description: 'Geladeira (frete)',
        amountCents: 21000,
        date: second.date,
      ),
    );
    final edited = (await repo.find(second.id))!;
    expect(edited.amountCents, 21000);
    expect(edited.installmentNumber, 2, reason: 'sem as colunas no rascunho, nada muda nelas');
    expect(edited.installmentGroupId, second.installmentGroupId);
    expect((await repo.find(ids[0]))!.amountCents, 20001);
  });

  test('recompute (mudar o fechamento do cartão) mantém cada parcela na fatura da sua data', () async {
    final ids = await repo.saveInstallments(purchase(date: DateTime(2026, 11, 25)), count: 2);
    // Fecha dia 20 agora: 25/11 e 25/12 passam para a fatura seguinte.
    await accounts.update(id: card, name: 'Nubank', closingDay: 20, dueDay: 5, linkedAccountId: bank);
    final competences = [for (final id in ids) (await repo.find(id))!.competence];
    expect(competences, [YearMonth(2026, 12).key, YearMonth(2027, 1).key]);
  });

  test('conta com parcelas continua não podendo ser excluída', () async {
    await repo.saveInstallments(purchase(), count: 2);
    await expectLater(accounts.delete(card), throwsA(isA<AccountInUseException>()));
  });
}
