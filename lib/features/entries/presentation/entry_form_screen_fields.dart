part of 'entry_form_screen.dart';

/// O corpo do formulário ligado ao estado da tela (extraído só por tamanho: limite de 400 linhas).
extension _EntryFormBody on _EntryFormScreenState {
  Widget _fields(Account? account, Account? toAccount, List<Account> accounts) {
    final cards = accounts.where((a) => a.kind.isCard).toList();
    // Seleção de conta: muda o estado e refaz a sugestão de descrição.
    void pick(VoidCallback change) => _update(() {
      change();
      _suggestDescription(accounts);
    });

    return EntryFormFields(
      accounts: accounts,
      account: account,
      toAccount: toAccount,
      balances: ref.watch(accountBalancesProvider).value ?? const {},
      amount: _amount,
      amountFocus: _amountFocus,
      interest: _interest,
      description: _description,
      note: _note,
      type: _type,
      formTypes: _isEditing && _type == EntryType.billPayment ? entryFormTypesEditingBill : entryFormTypes,
      date: _date,
      accountId: _accountId,
      isEditing: _isEditing,
      tourIsHere: _tourIsHere,
      submitted: _submitted,
      amountError: _shownAmountError,
      interestCents: _interestCents,
      onAmountChanged: () => _update(() => _lastSaved = null),
      onTypeSelected: (type) => pick(() {
        _type = type;
        if (!type.hasDestination) _toAccountId = null;
      }),
      onFromSelected: (id) => pick(() {
        _accountId = id;
        if (_toAccountId == id) _toAccountId = null;
      }),
      onToSelected: (id) => pick(() => _toAccountId = id),
      onCardSelected: (id) => pick(() {
        _toAccountId = id;
        // Sai da conta dona do cartão, se ele tiver uma (dá para trocar).
        final owner = cards.firstWhere((c) => c.id == id).linkedAccountId;
        if (owner != null) _accountId = owner;
      }),
      onInterestChanged: () => _update(() {}),
      installments: _installments,
      currentInstallment: _currentInstallment,
      onInstallmentsChanged: (n) => _update(() {
        _installments = n;
        if (_currentInstallment > n) _currentInstallment = n;
        _lastSaved = null;
      }),
      onCurrentInstallmentChanged: (k) => _update(() => _currentInstallment = k),
      installmentNote: _isEditing ? installmentNoteOf(_original) : null,
      onPickDate: _pickDate,
      // Só digitação do usuário chega aqui (mudar .text por código não chama
      // onChanged) — daí marcar como "dele" e parar de sugerir.
      onDescriptionTyped: () => _update(() => _descriptionEdited = true),
    );
  }
}
