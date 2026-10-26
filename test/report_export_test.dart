import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:antika_stok/modeller.dart';
import 'package:antika_stok/rapor.dart';
import 'package:antika_stok/yedek_ice_aktar.dart';

void main() {
  test(
    'Excel export contains complete inventory, auction and sales sheets',
    () {
      final bytes = ReportExporter.buildExcelBytes(
        antiques: [
          const Antique(
            id: 7,
            name: 'Bakır ibrik',
            category: 'Bakır ve Pirinç Eşyalar',
            year: 1920,
            history: 'Aile koleksiyonu',
            condition: 'Kulp onarılmış',
            value: 900,
            purchasePrice: 500,
            extraCosts: 50,
            quantity: 2,
            minimumStock: 1,
            offer: 'Teklif yok',
            auctionLocation: 'İstanbul',
            location: 'Raf A-2',
            photoUrl: 'https://example.com/photo.jpg',
            conditionPhotoUrl: 'https://example.com/condition.jpg',
          ),
        ],
        auctions: [
          Auction(
            id: 11,
            productId: 7,
            startingPrice: 800,
            currentBid: 850,
            startDate: DateTime(2026, 10, 1),
            endDate: DateTime(2026, 10, 30),
            status: 'Aktif',
            auctionLocation: 'İstanbul',
            winner: 'Müşteri',
            finalPrice: 850,
            paymentStatus: 'Ödendi',
            deliveryStatus: 'Teslim edildi',
          ),
        ],
        sales: [
          AntiqueSale(
            id: 19,
            productName: 'Bakır ibrik',
            quantity: 1,
            unitPrice: 900,
            unitCost: 550,
            productId: 7,
            buyer: 'Müşteri',
            soldAt: DateTime(2026, 10, 26),
          ),
        ],
      );

      final workbook = Excel.decodeBytes(bytes);

      expect(
        workbook.tables.keys,
        containsAll(['Genel Bakis', 'Ürünler', 'Açık Artırmalar', 'Satışlar']),
      );
      expect(workbook['Ürünler'].rows, hasLength(2));
      expect(workbook['Açık Artırmalar'].rows, hasLength(2));
      expect(workbook['Satışlar'].rows, hasLength(2));

      final inventoryHeaders = workbook['Ürünler'].rows.first
          .map((cell) => cell?.value)
          .toList();
      expect(inventoryHeaders, contains(TextCellValue('Kondisyon')));
      expect(inventoryHeaders, contains(TextCellValue('Stok uyarı eşiği')));
      expect(inventoryHeaders, contains(TextCellValue('Ürün fotoğrafı URL')));
    },
  );

  test(
    'backup parser reads exported records and validates identity fields',
    () {
      final bytes = ReportExporter.buildExcelBytes(
        antiques: [
          const Antique(
            id: 21,
            name: 'Porselen vazo',
            category: 'Seramik ve Porselen',
            year: 1930,
            history: '',
            value: 1200,
            quantity: 1,
            offer: '',
            auctionLocation: '',
          ),
        ],
        auctions: [],
        sales: [],
      );

      final parsed = BackupWorkbookParser.parse(bytes);

      expect(parsed.products, hasLength(1));
      expect(parsed.products.single['Kayıt no'], '21');
      expect(parsed.products.single['Ürün'], 'Porselen vazo');
      expect(parsed.auctions, isEmpty);
      expect(parsed.sales, isEmpty);
      expect(
        BackupWorkbookParser.normalizeDate('26.10.2026'),
        '2026-10-26T00:00:00.000',
      );
    },
  );
}
