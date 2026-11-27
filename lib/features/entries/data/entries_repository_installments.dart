part of 'entries_repository.dart';

/// Compra parcelada no cartão (feat 0031). Vive à parte só por tamanho (limite de 400 linhas
/// por arquivo) e como `part` para usar o banco e o `save` do repositório.
extension InstallmentsRepository on EntriesRepository {
  /// Compra parcelada no cartão (feat 0031): grava uma parcela por fatura, de [current]
  /// até [count], numa transação só. [draft] traz o **total** da compra e a data da
  /// parcela [current]; ver [planInstallments]. Devolve os ids na ordem das parcelas.
  ///
  /// Se [current] > 1, as parcelas anteriores não são criadas (já foram pagas); a
  /// primeira criada leva uma observação dizendo isso.
  Future<List<int>> saveInstallments(
    EntryDraft draft, {
    required int count,
    int current = 1,
  }) async {
    if (draft.id != null) {
      throw ArgumentError(
        'Parcelar cria lançamentos novos; não edita um existente.',
      );
    }
    if (draft.type != EntryType.expense) {
      throw ArgumentError('Só despesa pode ser parcelada.');
    }
    final account = await _account(draft.accountId);
    if (!account.kind.isCard) {
      throw ArgumentError('Só compra no cartão pode ser parcelada.');
    }
    final slices = planInstallments(
      totalCents: draft.amountCents,
      count: count,
      current: current,
      date: draft.date,
    );
    final groupId = _newGroupId();
    final before = current - 1;
    final skippedNote = before == 0
        ? null
        : before == 1
        ? 'parcela 1 anterior ao uso do app'
        : 'parcelas 1 a $before anteriores ao uso do app';
    return _db.transaction(() async {
      final ids = <int>[];
      for (final (i, s) in slices.indexed) {
        final own = draft.note?.trim();
        final note = i == 0 && skippedNote != null
            ? (own == null || own.isEmpty ? skippedNote : '$own · $skippedNote')
            : draft.note;
        ids.add(
          await save(
            EntryDraft(
              accountId: draft.accountId,
              type: EntryType.expense,
              description: draft.description,
              amountCents: s.amountCents,
              date: s.date,
              note: note,
              installmentGroupId: groupId,
              installmentNumber: s.number,
              installmentCount: s.count,
            ),
          ),
        );
      }
      return ids;
    });
  }

  String _newGroupId() =>
      '${_now().microsecondsSinceEpoch.toRadixString(36)}-${Random().nextInt(1 << 31).toRadixString(36)}';

  /// As parcelas de uma compra, da primeira à última.
  Future<List<Entry>> installmentsOf(String groupId) =>
      (_db.select(_db.entries)
            ..where((e) => e.installmentGroupId.equals(groupId))
            ..orderBy([(e) => OrderingTerm.asc(e.installmentNumber)]))
          .get();

  /// Exclui todas as parcelas de uma compra e devolve o que saiu (para o "Desfazer").
  Future<List<Entry>> deleteGroup(String groupId) => _db.transaction(() async {
    final all = await installmentsOf(groupId);
    await (_db.delete(
      _db.entries,
    )..where((e) => e.installmentGroupId.equals(groupId))).go();
    return all;
  });

  /// Devolve vários lançamentos excluídos, idênticos ao que eram (o "Desfazer" de [deleteGroup]).
  Future<void> restoreAll(List<Entry> entries) => _db.transaction(() async {
    for (final e in entries) {
      await restore(e);
    }
  });

  /// O que ainda vai cair nos cartões em parcelas **futuras** (data depois de [today]),
  /// por cartão, em centavos. Não entra no "em aberto" (que só conta até hoje).
  Stream<Map<int, int>> watchFutureInstallments({DateTime? today}) {
    final now = today ?? _now();
    final cutoff = Variable<DateTime>(DateTime(now.year, now.month, now.day));
    return _db
        .customSelect(
          '''
          SELECT account_id, SUM(amount_cents) AS cents FROM entries
          WHERE installment_group_id IS NOT NULL AND type = 'expense' AND date > ?1
          GROUP BY account_id
          ''',
          variables: [cutoff],
          readsFrom: {_db.entries},
        )
        .watch()
        .map(
          (rows) => {
            for (final r in rows)
              r.read<int>('account_id'): r.read<int>('cents'),
          },
        );
  }
}
