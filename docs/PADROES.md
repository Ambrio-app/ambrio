# Padrões de texto e símbolos

Regras curtas para o que aparece na tela do Ambrio. O que dá para checar por máquina está em `test/core/texts_test.dart`.

## Texto

- **Sem travessão (—) nem emoji** em texto de tela. Use ponto, dois-pontos ou ponto e vírgula. Só ícones do Material.
- **Plural de verdade**, nunca "(s)": "1 lançamento", "3 lançamentos". Para isso existe `Formatters.count(n, 'lançamento', 'lançamentos')`.
- **Reticências** com o caractere `…`, não três pontos.
- **Dinheiro** sempre por `Formatters.money` ("R$ 1.234,56"); escondido pelo olhinho, `MoneyText` ("R$ ••••").
- **Datas** em dois formatos só: `dd/MM` (`Formatters.dayMonth`) e `dd/MM/yyyy` (`Formatters.date`); o mês por extenso vem de `YearMonth.label`.

## Símbolos

- **`·` (ponto médio)** separa partes de uma linha de apoio: "13/11 · Nubank · cartão".
- **`→` (seta)** só para fluxo de dinheiro entre contas: "Bradesco → fatura Amazon".
- **Ícones:** contorno (`_outlined`) para o neutro; cheio só para selecionado (menu) ou concluído (checklist, "Backup salvo"). O cartão é sempre `Icons.credit_card_outlined`.
- Cor nunca é a única pista: forma, rótulo ou ícone junto (contraste em `test/core/theme/contrast_test.dart`).

## Nome do cartão

- **Em totais e saldos:** `cardTitle`, "Cartão Nubank".
- **Em listas e lançamentos:** `accountLabel`, "Nubank · cartão" (ou "Amazon · cartão do Bradesco" na lista de contas).
- **Sob um título que já diz "Cartões"** (o painel da tela inicial): só o nome, "Nubank".
- Fala do leitor de tela: sempre o nome completo ("Cartão Nubank").
