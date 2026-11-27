import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/year_month.dart';
import '../data/entries_repository.dart';
import '../domain/competence.dart';
import '../domain/entry_type.dart';

/// Transferência: outra conta (nunca cartão, nunca a própria origem). Pagar
/// fatura: um cartão. Os outros tipos não têm destino.
Account? resolveToAccount(
  EntryType type,
  List<Account> accounts,
  int? toAccountId,
  Account? origin,
) => switch (type) {
  EntryType.transfer =>
    accounts
        .where((a) => a.id == toAccountId && !a.kind.isCard && a.id != origin?.id)
        .firstOrNull,
  EntryType.billPayment => accounts.where((a) => a.id == toAccountId && a.kind.isCard).firstOrNull,
  _ => null,
};

/// A descrição que o formulário sugere enquanto a pessoa não escreve a dela;
/// nulo = nada a sugerir (campo limpo).
String? suggestedDescription(EntryType type, Account? to) => switch (type) {
  EntryType.transfer => 'Transferência',
  EntryType.billPayment => to == null ? 'Pagamento fatura' : 'Pagamento fatura ${to.name}',
  _ => null,
};

/// Exclui na hora e oferece **Desfazer** por alguns segundos, em vez de
/// perguntar antes: perguntar "tem certeza?" todo mundo responde "sim" sem ler,
/// e o erro só aparece depois. O aviso fica no messenger do app (não na tela),
/// então continua visível na lista para onde voltamos.
void showEntryDeletedUndo(ScaffoldMessengerState messenger, EntriesRepository repo, Entry entry) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: const Text('Lançamento excluído.'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.restore(entry)),
      ),
    );
}

/// Os tipos que o formulário oferece ao **criar**. Ajuste fica de fora de propósito,
/// e pagar fatura saiu daqui na 0042: tem tela própria (`BillPaymentScreen`).
const entryFormTypes = [
  EntryType.expense,
  EntryType.income,
  EntryType.transfer,
];

/// Ao **editar** um pagamento de fatura antigo, o formulário ainda mostra o tipo.
const entryFormTypesEditingBill = [...entryFormTypes, EntryType.billPayment];

/// O mês que o repositório vai gravar: usa a mesma regra dele (inclusive a do
/// dia do fechamento do cartão), para o "Vai para" nunca discordar.
YearMonth entryCompetence(Account account, int startDay, DateTime date) => competenceForAccount(
  date: date,
  kind: account.kind,
  closingDay: account.closingDay,
  closingDayInCurrent: account.closingDayInCurrent,
  monthStartDay: startDay,
);

Future<DateTime?> pickEntryDate(BuildContext context, DateTime initial) => showDatePicker(
  context: context,
  initialDate: initial,
  firstDate: DateTime(2000),
  lastDate: DateTime(2100),
);

/// Excluir uma parcela: a pessoa escolhe entre só esta e a compra inteira (feat 0031).
/// `true` = todas as parcelas da compra; `false` = só esta; nulo = desistiu.
Future<bool?> askDeleteWholePurchase(BuildContext context, Entry entry) {
  final label = '${entry.installmentNumber}/${entry.installmentCount}';
  return showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Esta é a parcela $label de uma compra parcelada.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Só esta parcela'),
            onTap: () => Navigator.of(context).pop(false),
          ),
          ListTile(
            leading: const Icon(Icons.delete_sweep_outlined),
            title: const Text('Todas as parcelas desta compra'),
            onTap: () => Navigator.of(context).pop(true),
          ),
          ListTile(
            leading: const Icon(Icons.close),
            title: const Text('Cancelar'),
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    ),
  );
}

/// Como [showEntryDeletedUndo], para a compra parcelada inteira: o Desfazer devolve todas as parcelas.
void showInstallmentsDeletedUndo(ScaffoldMessengerState messenger, EntriesRepository repo, List<Entry> entries) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text('Compra parcelada excluída (${Formatters.count(entries.length, 'parcela', 'parcelas')}).'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(label: 'Desfazer', onPressed: () => repo.restoreAll(entries)),
      ),
    );
}

/// Exclui o lançamento aberto, fecha a tela e oferece **Desfazer**. Se for uma parcela,
/// pergunta antes se é só esta ou a compra inteira (feat 0031); desistir não exclui nada.
Future<void> deleteEntryWithUndo(BuildContext context, EntriesRepository repo, Entry entry) async {
  final messenger = ScaffoldMessenger.of(context);
  final groupId = entry.installmentGroupId;
  if (groupId != null) {
    final whole = await askDeleteWholePurchase(context, entry);
    if (whole == null || !context.mounted) return;
    if (whole) {
      final removed = await repo.deleteGroup(groupId);
      if (!context.mounted) return;
      context.pop();
      showInstallmentsDeletedUndo(messenger, repo, removed);
      return;
    }
  }
  await repo.delete(entry.id);
  if (!context.mounted) return;
  context.pop();
  showEntryDeletedUndo(messenger, repo, entry);
}

/// Ao editar uma parcela: lembra de qual compra ela é e que editar muda só ela.
String? installmentNoteOf(Entry? entry) => entry?.installmentCount == null
    ? null
    : 'Parcela ${entry!.installmentNumber}/${entry.installmentCount} de uma compra parcelada. Editar muda só esta parcela.';
