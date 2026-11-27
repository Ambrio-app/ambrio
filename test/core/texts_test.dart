import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Trava dos textos (feat 0044): o app não pode presumir a planilha, o vocabulário
/// ou os bancos de uma pessoa só. Olha só o código em `lib/`, linha a linha, e
/// ignora comentários.
void main() {
  // Onde o nome das tabelas do autor é permitido: as instruções que vão para a IA
  // (não aparecem na tela) e os nomes internos das colunas lidas.
  const allowedFiles = {
    'anthropic_table_locator.dart',
    'openai_compatible_table_locator.dart',
    'llm_table_locator.dart',
  };

  final banned = <String, RegExp>{
    'o "Até" da planilha': RegExp(r'"Até" da planilha'),
    'banco citado como regra': RegExp(r'Itaú e Mercado Pago|Nubank: próxima'),
    'nome de aba do autor na tela': RegExp(
      r'"Despesas Gerais"|"Entrada de Valor"|"Gastos Recorrentes"',
    ),
    'nome antigo do app': RegExp(r'IziFnc(?!/)'),
    // Padrões de texto (feat 0055, docs/PADROES.md): sem travessão, sem emoji e sem "(s)".
    'travessão no texto (use ponto, dois-pontos ou ponto e vírgula)': RegExp(
      r' — ',
    ),
    'emoji no texto (só ícones do Material)': RegExp(
      '[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B50}]',
      unicode: true,
    ),
    // Só dentro de aspas e colado à palavra ("lançamento(s)"), não em código como `for (final s in x)`.
    'plural entre parênteses (use o plural de verdade)': RegExp(
      r'''['"][^'"]*[a-zà-ú]\(s\)[^'"]*['"]''',
    ),
  };

  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  for (final entry in banned.entries) {
    test('nenhum texto do app tem: ${entry.key}', () {
      final hits = <String>[];
      for (final file in files) {
        final name = file.path.split(RegExp(r'[\\/]')).last;
        if (allowedFiles.contains(name)) continue;
        final lines = file.readAsLinesSync();
        for (var i = 0; i < lines.length; i++) {
          final line = lines[i].trimLeft();
          if (line.startsWith('//')) continue;
          if (entry.value.hasMatch(line)) hits.add('${file.path}:${i + 1}');
        }
      }
      expect(
        hits,
        isEmpty,
        reason:
            'texto que presume o layout ou o nome antigo: ${hits.join(', ')}',
      );
    });
  }
}
