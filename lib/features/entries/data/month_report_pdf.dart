import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/utils/formatters.dart';
import '../domain/month_report.dart';

const _navy = PdfColor.fromInt(0xFF1B3A5C);
const _muted = PdfColor.fromInt(0xFF5A5A5A);
const _line = PdfColor.fromInt(0xFFCFC9B6);

/// Nome do arquivo: `ambrio-relatorio-2026-11.pdf`.
String monthReportFileName(MonthReport report) =>
    'ambrio-relatorio-${report.month.year}-${report.month.month.toString().padLeft(2, '0')}.pdf';

/// Desenha o [report] em PDF (feat 0030): A4, só com a fonte padrão (por isso o texto passa por
/// [pdfSafe]), legível no celular sem nenhum programa a mais. Nada sai do aparelho: quem chama
/// entrega os bytes ao seletor de arquivo da pessoa.
Future<Uint8List> buildMonthReportPdf(MonthReport report) async {
  final title = 'Relatório de ${report.month.label}';
  final doc = pw.Document(title: title, author: 'Ambrio', creator: 'Ambrio');

  pw.Widget heading(String text) => pw.Padding(
    padding: const pw.EdgeInsets.only(top: 18, bottom: 6),
    child: pw.Text(
      pdfSafe(text),
      style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: _navy),
    ),
  );

  pw.Widget row(String label, int cents, {bool bold = false, double indent = 0}) => pw.Container(
    padding: pw.EdgeInsets.fromLTRB(indent, 3, 0, 3),
    decoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.5))),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(pdfSafe(label), style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null)),
        pw.Text(Formatters.money(cents), style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null)),
      ],
    ),
  );

  final lines = report.lines;
  final balances = report.balances;
  final openCards = report.openCards;

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(36),
      header: (ctx) => ctx.pageNumber == 1
          ? pw.SizedBox()
          : pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(pdfSafe('Ambrio · $title'), style: const pw.TextStyle(fontSize: 9, color: _muted)),
            ),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: _muted),
        ),
      ),
      build: (ctx) => [
        pw.Text(
          'Ambrio',
          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: _navy),
        ),
        pw.Text(pdfSafe(title), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
        pw.Text(
          'Gerado em ${Formatters.date(report.generatedAt)}',
          style: const pw.TextStyle(fontSize: 10, color: _muted),
        ),
        heading('Resumo do mês'),
        if (report.isEmpty)
          pw.Text('Nenhum lançamento neste mês.')
        else ...[
          row('Entradas', report.incomeCents),
          row('Gastos no débito', report.debitExpenseCents),
          row('Gastos nos cartões', report.cardsCents),
          for (final c in report.cards) row(c.name, c.cents, indent: 14),
          row('Total gasto', report.spentCents, bold: true),
          row('Entrou menos o que gastou', report.resultCents, bold: true),
        ],
        if (balances != null) ...[
          heading('Saldo das contas (hoje)'),
          if (balances.isEmpty) pw.Text('Nenhuma conta corrente.'),
          for (final b in balances) row(b.name, b.cents),
        ],
        if (openCards != null && openCards.isNotEmpty) ...[
          heading('Em aberto nos cartões (hoje)'),
          for (final c in openCards) row(c.name, c.cents),
        ],
        if (lines != null) ...[
          heading('Lançamentos'),
          if (lines.isEmpty)
            pw.Text('Nenhum lançamento neste mês.')
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Data', 'Tipo', 'Descrição', 'Conta', 'Valor'],
              data: [
                for (final l in lines)
                  [
                    Formatters.dayMonth(l.date),
                    pdfSafe(l.type),
                    pdfSafe(l.note == null || l.note!.trim().isEmpty ? l.description : '${l.description} (${l.note})'),
                    pdfSafe(l.account),
                    Formatters.money(l.cents),
                  ],
              ],
              headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: _navy),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {4: pw.Alignment.centerRight},
              columnWidths: {
                0: const pw.FixedColumnWidth(36),
                1: const pw.FixedColumnWidth(62),
                2: const pw.FlexColumnWidth(3),
                3: const pw.FlexColumnWidth(2),
                4: const pw.FixedColumnWidth(70),
              },
              border: const pw.TableBorder(horizontalInside: pw.BorderSide(color: _line, width: 0.4)),
              cellPadding: const pw.EdgeInsets.symmetric(vertical: 3, horizontal: 3),
            ),
        ],
        pw.SizedBox(height: 18),
        pw.Text(
          'Controle pessoal feito no app, não é aconselhamento financeiro. Entradas e gastos não incluem '
          'transferências entre contas, pagamento de fatura nem ajustes de saldo.',
          style: const pw.TextStyle(fontSize: 8, color: _muted),
        ),
      ],
    ),
  );
  return doc.save();
}
