import 'dart:convert';
import 'dart:io';
import 'package:excel/excel.dart' as xls;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import '../models/models.dart';
import 'tamil_pdf_shaping.dart';

class ExportService {
  static Future<void> exportExcel(List<Entry> entries, Map<String, Category> catMap) async {
    final wb = xls.Excel.createExcel();
    final sheet = wb['பரிவர்த்தனைகள்'];
    sheet.appendRow(['தேதி', 'விவரம்', 'வகை', 'தொகை', 'வருமானம்/செலவு']
        .map((e) => xls.TextCellValue(e))
        .toList());

    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    for (final e in sorted) {
      final cat = catMap[e.category];
      sheet.appendRow([
        xls.TextCellValue(e.date),
        xls.TextCellValue(e.desc),
        xls.TextCellValue(cat?.name ?? e.category),
        xls.DoubleCellValue(e.amount),
        xls.TextCellValue(e.type == 'income' ? 'வருமானம்' : 'செலவு'),
      ]);
    }

    final dir = await getTemporaryDirectory();
    final fileName = 'kanakku_${DateTime.now().toIso8601String().substring(0, 10)}.xlsx';
    final path = '${dir.path}/$fileName';
    final bytes = wb.encode();
    if (bytes != null) {
      final file = File(path);
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(path)], text: 'கணக்கு தாள் — Excel Export');
    }
  }

  static Future<void> exportPdf(
    List<Entry> entries,
    Map<String, Category> catMap,
    String userName,
    String accountName,
  ) async {
    final doc = pw.Document();
    final sorted = [...entries]..sort((a, b) => a.date.compareTo(b.date));
    final income = sorted.where((e) => e.type == 'income').fold(0.0, (s, e) => s + e.amount);
    final expense = sorted.where((e) => e.type == 'expense').fold(0.0, (s, e) => s + e.amount);
    final bal = income - expense;

    // Embed a Tamil-capable font — the pdf package's default core fonts
    // (Helvetica) don't have Tamil glyphs, which is why exports were
    // showing broken/missing-glyph boxes for Tamil text. The Tamil font
    // itself has no Latin glyphs, so add Helvetica as a fallback for any
    // English words mixed into descriptions (e.g. "Opening Balance").
    final tamilFontData = await rootBundle.load('assets/fonts/NotoSansTamil-Regular.ttf');
    final tamilFont = pw.Font.ttf(tamilFontData);
    final latinFallback = pw.Font.helvetica();
    final pdfTheme = pw.ThemeData.withFont(
      base: tamilFont,
      bold: tamilFont,
      fontFallback: [latinFallback],
    );

    doc.addPage(
      pw.MultiPage(
        theme: pdfTheme,
        build: (context) => [
          pw.Header(text: reorderTamilForPdf('கணக்கு தாள்')),
          pw.Text(reorderTamilForPdf('பெயர்: $userName   ஊர்: $accountName')),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            pw.Text(reorderTamilForPdf('வருமானம்: ${income.toStringAsFixed(2)}   ')),
            pw.Text(reorderTamilForPdf('செலவு: ${expense.toStringAsFixed(2)}   ')),
            pw.Text(reorderTamilForPdf('இருப்பு: ${bal.toStringAsFixed(2)}')),
          ]),
          pw.SizedBox(height: 14),
          pw.Table.fromTextArray(
            headers: ['தேதி', 'விவரம்', 'வகை', 'வரவு/செலவு', 'தொகை'].map(reorderTamilForPdf).toList(),
            data: sorted.map((e) {
              final cat = catMap[e.category];
              return [
                e.date,
                reorderTamilForPdf(e.desc),
                reorderTamilForPdf(cat?.name ?? e.category),
                reorderTamilForPdf(e.type == 'income' ? 'வருமானம்' : 'செலவு'),
                e.amount.toStringAsFixed(2),
              ];
            }).toList(),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'kanakku_${DateTime.now().toIso8601String().substring(0, 10)}.pdf',
    );
  }

  static Future<void> backupJson(Map<String, dynamic> payload) async {
    final dir = await getTemporaryDirectory();
    final fileName = 'kanakku_backup_${DateTime.now().toIso8601String().substring(0, 10)}.json';
    final path = '${dir.path}/$fileName';
    final file = File(path);
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
    await Share.shareXFiles([XFile(path)], text: 'கணக்கு தாள் — Backup');
  }
}
