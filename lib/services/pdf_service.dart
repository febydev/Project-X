import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../models/baby_profile.dart';
import '../models/log_entry.dart';

/// Builds a clean "for your pediatrician" PDF from on-device logs and
/// opens the system share/print sheet. Nothing leaves the device unless the
/// parent chooses to share it.
class PdfService {
  PdfService._();
  static final PdfService instance = PdfService._();

  Future<void> generateAndShare({
    required BabyProfile profile,
    required List<LogEntry> entries,
    int days = 7,
  }) async {
    final now = DateTime.now();
    final from = now.subtract(Duration(days: days));
    final scoped = entries.where((e) => e.time.isAfter(from)).toList()
      ..sort((a, b) => a.time.compareTo(b.time));

    final byDay = <String, List<LogEntry>>{};
    for (final e in scoped) {
      final key = DateFormat('EEEE, MMM d').format(e.time);
      byDay.putIfAbsent(key, () => []).add(e);
    }

    int count(LogType t) => scoped.where((e) => e.type == t).length;

    final doc = pw.Document();
    final dateFmt = DateFormat('h:mm a');

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Mira — Care Summary',
                  style: pw.TextStyle(
                      fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(
                '${profile.name} · ${profile.ageLabel} · last $days days',
                style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
              ),
              pw.Divider(color: PdfColors.grey300),
            ],
          ),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _stat('Feeds', count(LogType.feed)),
              _stat('Sleeps', count(LogType.sleep)),
              _stat('Diapers', count(LogType.diaper)),
            ],
          ),
          pw.SizedBox(height: 20),
          for (final day in byDay.keys) ...[
            pw.Text(day,
                style: pw.TextStyle(
                    fontSize: 13, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey200),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(4),
              },
              children: [
                for (final e in byDay[day]!)
                  pw.TableRow(children: [
                    _cell(dateFmt.format(e.time)),
                    _cell(e.type.label),
                    _cell(e.note ?? '—'),
                  ]),
              ],
            ),
            pw.SizedBox(height: 14),
          ],
          pw.SizedBox(height: 10),
          pw.Text(
            'This summary is general information for your visit, not medical advice. '
            'Always consult your pediatrician for health concerns.',
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic),
          ),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'mira-care-summary.pdf',
    );
  }

  pw.Widget _stat(String label, int value) => pw.Column(
        children: [
          pw.Text('$value',
              style:
                  pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          pw.Text(label,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
        ],
      );

  pw.Widget _cell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
      );
}
