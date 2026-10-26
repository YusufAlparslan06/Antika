import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'ayarlar.dart';
import 'modeller.dart';
import 'rapor_yazifontu.dart';

class SalesReceiptExporter {
  static Future<Uri?> export(AntiqueSale sale) async {
    final regularFontData = await loadReportFont(bold: false);
    final boldFontData = await loadReportFont(bold: true);
    final document = pw.Document();
    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: regularFontData == null
              ? pw.Font.helvetica()
              : pw.Font.ttf(regularFontData),
          bold: boldFontData == null
              ? pw.Font.helveticaBold()
              : pw.Font.ttf(boldFontData),
        ),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Center(
              child: pw.Text(
                'ESKİLERDEN',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.SizedBox(height: 5),
            pw.Center(child: pw.Text('SATIŞ FİŞİ')),
            pw.Divider(height: 28),
            _line('Fiş numarası', '#${sale.id}'),
            _line('Tarih', formatDate(sale.soldAt)),
            _line('Alıcı', sale.buyer.isEmpty ? 'Belirtilmemiş' : sale.buyer),
            pw.SizedBox(height: 18),
            pw.TableHelper.fromTextArray(
              headers: const ['Ürün', 'Adet', 'Birim fiyat', 'Toplam'],
              data: [
                [
                  sale.productName,
                  formatNumber(sale.quantity),
                  formatCurrency(sale.unitPrice),
                  formatCurrency(sale.total),
                ],
              ],
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.all(6),
            ),
            pw.SizedBox(height: 22),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Text(
                'Genel toplam: ${formatCurrency(sale.total)}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Spacer(),
            pw.Center(
              child: pw.Text('Bizi tercih ettiğiniz için teşekkürler.'),
            ),
          ],
        ),
      ),
    );

    return FilePicker.saveFile(
      fileName: 'satis-fisi-${sale.id}.pdf',
      dialogTitle: 'Satış fişini PDF olarak kaydet',
      mimeType: 'application/pdf',
      bytes: Uint8List.fromList(await document.save()),
    );
  }

  static pw.Widget _line(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        children: [
          pw.SizedBox(width: 100, child: pw.Text(label)),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
