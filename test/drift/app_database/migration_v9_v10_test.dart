// ignore_for_file: unused_local_variable, unused_import
import 'package:ambrio/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/schema.dart';
import 'generated/schema_v10.dart' as v10;
import 'generated/schema_v9.dart' as v9;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  // v10 só adiciona as colunas da compra parcelada (feat 0031). O que importa: quem já
  // tinha lançamentos (inclusive as parcelas da planilha, que são linhas comuns) continua
  // com os mesmos valores, datas e competências, e todos viram "não parcelado".
  test('migração v9 -> v10 mantém os lançamentos e os deixa não parcelados', () async {
    const at = 1764115200;
    await verifier.testWithDataIntegrity(
      oldVersion: 9,
      newVersion: 10,
      createOld: v9.DatabaseAtV9.new,
      createNew: v10.DatabaseAtV10.new,
      openTestedDatabase: AppDatabase.new,
      createItems: (batch, oldDb) {
        batch.insertAll(oldDb.accounts, [
          const v9.AccountsData(id: 1, name: 'Caixa conta', kind: 'checking', createdAt: at, closingDayInCurrent: 0),
          const v9.AccountsData(
            id: 2,
            name: 'Caixa',
            kind: 'creditCard',
            linkedAccountId: 1,
            closingDay: 26,
            dueDay: 5,
            createdAt: at,
            closingDayInCurrent: 1,
          ),
        ]);
        batch.insertAll(oldDb.entries, [
          const v9.EntriesData(
            id: 1,
            accountId: 2,
            type: 'expense',
            description: 'Compra parcelada na planilha',
            amountCents: 9990,
            date: at,
            note: 'parcela até 03/2026 · compra em 20/10/2025',
            competence: 202512,
            createdAt: at,
          ),
          const v9.EntriesData(
            id: 2,
            accountId: 1,
            type: 'income',
            description: 'Salário',
            amountCents: 500000,
            date: at,
            competence: 202511,
            createdAt: at,
          ),
        ]);
        batch.insertAll(oldDb.appSettings, [
          const v9.AppSettingsData(
            id: 1,
            monthStartDay: 1,
            themeMode: 0,
            textScale: 1.0,
            highContrast: 0,
            tourStep: 0,
            aiConsentVersion: 0,
            aiConsentServices: '',
            privacyNoticeVersion: 0,
          ),
        ]);
      },
      validateItems: (newDb) async {
        final entries = await (newDb.select(newDb.entries)..orderBy([(e) => OrderingTerm.asc(e.id)])).get();
        expect(entries, hasLength(2));
        expect(entries.map((e) => e.amountCents), [9990, 500000]);
        expect(entries.map((e) => e.competence), [202512, 202511]);
        expect(entries.first.note, 'parcela até 03/2026 · compra em 20/10/2025');
        for (final e in entries) {
          expect(e.installmentGroupId, isNull);
          expect(e.installmentNumber, isNull);
          expect(e.installmentCount, isNull);
        }
      },
    );
  });
}
