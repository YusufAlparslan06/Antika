import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'ayarlar.dart';
import 'modeller.dart';
import 'rapor_yazifontu.dart';

class ReportExporter {
  static Future<Uri?> exportExcel({
    required List<Antique> antiques,
    required List<Auction> auctions,
    required List<AntiqueSale> sales,
  }) async {
    final bytes = buildExcelBytes(
      antiques: antiques,
      auctions: auctions,
      sales: sales,
    );
    return FilePicker.saveFile(
      fileName: 'eskilerden-veri-disa-aktarim.xlsx',
      dialogTitle: 'Ürün, satış ve açık artırma verilerini dışa aktar',
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      bytes: Uint8List.fromList(bytes),
    );
  }

  static List<int> buildExcelBytes({
    required List<Antique> antiques,
    required List<Auction> auctions,
    required List<AntiqueSale> sales,
  }) {
    final workbook = Excel.createExcel();
    workbook.rename('Sheet1', 'Genel Bakis');
    final overview = workbook['Genel Bakis'];
    overview.appendRow([
      TextCellValue('Rapor tarihi'),
      TextCellValue(formatDate(DateTime.now())),
    ]);
    overview.appendRow([
      TextCellValue('Ürün çeşidi'),
      IntCellValue(antiques.length),
    ]);
    overview.appendRow([
      TextCellValue('Mevcut toplam stok'),
      IntCellValue(
        antiques.fold<int>(0, (total, antique) => total + antique.quantity),
      ),
    ]);
    overview.appendRow([
      TextCellValue('Tahmini stok değeri (₺)'),
      DoubleCellValue(
        antiques.fold<double>(
          0,
          (total, antique) => total + antique.value * antique.quantity,
        ),
      ),
    ]);
    overview.appendRow([
      TextCellValue('Açık artırma sayısı'),
      IntCellValue(auctions.length),
    ]);
    overview.appendRow([
      TextCellValue('Satış adedi'),
      IntCellValue(sales.fold<int>(0, (total, sale) => total + sale.quantity)),
    ]);
    overview.appendRow([
      TextCellValue('Satış geliri (₺)'),
      DoubleCellValue(
        sales.fold<double>(0, (total, sale) => total + sale.total),
      ),
    ]);
    overview.appendRow([
      TextCellValue('Gerçekleşen net kâr (₺)'),
      DoubleCellValue(
        sales.fold<double>(0, (total, sale) => total + sale.netProfit),
      ),
    ]);
    overview.appendRow([
      TextCellValue('Mevcut stokta tahmini net kâr (₺)'),
      DoubleCellValue(
        antiques.fold<double>(
          0,
          (total, antique) =>
              total +
              (antique.value - antique.purchasePrice - antique.extraCosts) *
                  antique.quantity,
        ),
      ),
    ]);

    final inventory = workbook['Ürünler'];
    inventory.appendRow([
      TextCellValue('Kayıt no'),
      TextCellValue('Ürün'),
      TextCellValue('Kategori'),
      TextCellValue('Yıl'),
      TextCellValue('Tarihsel geçmiş'),
      TextCellValue('Kondisyon'),
      TextCellValue('Birim değer (₺)'),
      TextCellValue('Alış bedeli (₺)'),
      TextCellValue('Ek masraf (₺)'),
      TextCellValue('Tahmini birim net kâr (₺)'),
      TextCellValue('Stok'),
      TextCellValue('Stok uyarı eşiği'),
      TextCellValue('Teklif'),
      TextCellValue('Açık artırma yeri'),
      TextCellValue('Depo/raf konumu'),
      TextCellValue('Ürün fotoğrafı URL'),
      TextCellValue('Kondisyon fotoğrafı URL'),
    ]);
    for (final antique in antiques) {
      inventory.appendRow([
        antique.id == null ? TextCellValue('') : IntCellValue(antique.id!),
        TextCellValue(antique.name),
        TextCellValue(antique.category),
        IntCellValue(antique.year),
        TextCellValue(antique.history),
        TextCellValue(antique.condition),
        DoubleCellValue(antique.value),
        DoubleCellValue(antique.purchasePrice),
        DoubleCellValue(antique.extraCosts),
        DoubleCellValue(
          antique.value - antique.purchasePrice - antique.extraCosts,
        ),
        IntCellValue(antique.quantity),
        IntCellValue(antique.minimumStock),
        TextCellValue(antique.offer),
        TextCellValue(antique.auctionLocation),
        TextCellValue(antique.location),
        TextCellValue(antique.photoUrl ?? ''),
        TextCellValue(antique.conditionPhotoUrl ?? ''),
      ]);
    }

    final auctionSheet = workbook['Açık Artırmalar'];
    auctionSheet.appendRow([
      TextCellValue('Kayıt no'),
      TextCellValue('Ürün kayıt no'),
      TextCellValue('Başlangıç fiyatı (₺)'),
      TextCellValue('Mevcut teklif (₺)'),
      TextCellValue('Başlangıç tarihi'),
      TextCellValue('Bitiş tarihi'),
      TextCellValue('Durum'),
      TextCellValue('Açık artırma yeri'),
      TextCellValue('Kazanan'),
      TextCellValue('Son satış fiyatı (₺)'),
      TextCellValue('Ödeme durumu'),
      TextCellValue('Teslimat durumu'),
    ]);
    for (final auction in auctions) {
      auctionSheet.appendRow([
        auction.id == null ? TextCellValue('') : IntCellValue(auction.id!),
        IntCellValue(auction.productId),
        DoubleCellValue(auction.startingPrice),
        DoubleCellValue(auction.currentBid),
        TextCellValue(auction.startDate.toIso8601String()),
        TextCellValue(auction.endDate.toIso8601String()),
        TextCellValue(auction.status),
        TextCellValue(auction.auctionLocation),
        TextCellValue(auction.winner),
        DoubleCellValue(auction.finalPrice),
        TextCellValue(auction.paymentStatus),
        TextCellValue(auction.deliveryStatus),
      ]);
    }

    final saleSheet = workbook['Satışlar'];
    saleSheet.appendRow([
      TextCellValue('Kayıt no'),
      TextCellValue('Ürün kayıt no'),
      TextCellValue('Ürün'),
      TextCellValue('Adet'),
      TextCellValue('Birim fiyat (₺)'),
      TextCellValue('Toplam (₺)'),
      TextCellValue('Birim maliyet (₺)'),
      TextCellValue('Net kâr (₺)'),
      TextCellValue('Alıcı'),
      TextCellValue('Satış tarihi'),
    ]);
    for (final sale in sales) {
      saleSheet.appendRow([
        IntCellValue(sale.id),
        sale.productId == null
            ? TextCellValue('')
            : IntCellValue(sale.productId!),
        TextCellValue(sale.productName),
        IntCellValue(sale.quantity),
        DoubleCellValue(sale.unitPrice),
        DoubleCellValue(sale.total),
        DoubleCellValue(sale.unitCost),
        DoubleCellValue(sale.netProfit),
        TextCellValue(sale.buyer),
        TextCellValue(sale.soldAt.toIso8601String()),
      ]);
    }

    final bytes = workbook.encode();
    if (bytes == null) {
      throw StateError('Excel dışa aktarım dosyası oluşturulamadı.');
    }
    return bytes;
  }

  static Future<Uri?> exportPdf({
    required List<Antique> antiques,
    required List<Auction> auctions,
    required List<AntiqueSale> sales,
  }) async {
    final regularFontData = await loadReportFont(bold: false);
    final boldFontData = await loadReportFont(bold: true);
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        theme: pw.ThemeData.withFont(
          base: regularFontData == null
              ? pw.Font.helvetica()
              : pw.Font.ttf(regularFontData),
          bold: boldFontData == null
              ? pw.Font.helveticaBold()
              : pw.Font.ttf(boldFontData),
        ),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 12),
          child: pw.Text(
            'Eskilerden • ${formatDate(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 12),
          child: pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9),
          ),
        ),
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Envanter ve satış raporu')),
          pw.Text(
            'Ürün çeşidi: ${antiques.length}   •   '
            'Toplam stok: ${formatNumber(antiques.fold<int>(0, (total, antique) => total + antique.quantity))}   •   '
            'Stok değeri: ${formatCurrency(antiques.fold<double>(0, (total, antique) => total + antique.value * antique.quantity))}   •   '
            'Açık artırma: ${auctions.length}   •   '
            'Satış geliri: ${formatCurrency(sales.fold<double>(0, (total, sale) => total + sale.total))}   •   '
            'Gerçekleşen net kâr: ${formatCurrency(sales.fold<double>(0, (total, sale) => total + sale.netProfit))}',
          ),
          pw.SizedBox(height: 18),
          pw.Header(level: 1, child: pw.Text('Ürünler')),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Ürün',
              'Kategori',
              'Yıl',
              'Teklif',
              'Açık artırma yeri',
              'Değer (₺)',
              'Alış (₺)',
              'Ek masraf (₺)',
              'Net kâr/adet (₺)',
              'Stok',
              'Konum',
            ],
            data: antiques
                .map(
                  (antique) => [
                    antique.name,
                    antique.category,
                    antique.year.toString(),
                    antique.offer,
                    antique.auctionLocation,
                    formatCurrency(antique.value),
                    formatCurrency(antique.purchasePrice),
                    formatCurrency(antique.extraCosts),
                    formatCurrency(
                      antique.value -
                          antique.purchasePrice -
                          antique.extraCosts,
                    ),
                    formatNumber(antique.quantity),
                    antique.location,
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(5),
          ),
          pw.SizedBox(height: 20),
          pw.Header(level: 1, child: pw.Text('Satışlar')),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Ürün',
              'Adet',
              'Birim fiyat',
              'Toplam',
              'Birim maliyet',
              'Net kâr',
              'Alıcı',
              'Tarih',
            ],
            data: sales
                .map(
                  (sale) => [
                    sale.productName,
                    formatNumber(sale.quantity),
                    formatCurrency(sale.unitPrice),
                    formatCurrency(sale.total),
                    formatCurrency(sale.unitCost),
                    formatCurrency(sale.netProfit),
                    sale.buyer,
                    formatDate(sale.soldAt),
                  ],
                )
                .toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellPadding: const pw.EdgeInsets.all(5),
          ),
        ],
      ),
    );

    return FilePicker.saveFile(
      fileName: 'eskilerden-rapor.pdf',
      dialogTitle: 'PDF raporunu kaydet',
      mimeType: 'application/pdf',
      bytes: await document.save(),
    );
  }
}
