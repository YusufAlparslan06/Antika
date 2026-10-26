import 'package:flutter_test/flutter_test.dart';

import 'package:antika_stok/ayarlar.dart';
import 'package:antika_stok/modeller.dart';

void main() {
  group('sale calculations', () {
    test('calculates total revenue and net profit', () {
      final sale = AntiqueSale(
        id: 1,
        productName: 'Bakır ibrik',
        quantity: 3,
        unitPrice: 120,
        unitCost: 70,
        buyer: 'Müşteri',
        soldAt: DateTime(2026, 10, 26),
      );

      expect(sale.total, 360);
      expect(sale.netProfit, 150);
    });
  });

  group('auction amount validation', () {
    test('accepts a valid amount with comma decimal separator', () {
      expect(validateAuctionAmount('1250,50', 'Fiyat'), isNull);
    });

    test('rejects negative amounts and more than two decimal places', () {
      expect(validateAuctionAmount('-1', 'Fiyat'), isNotNull);
      expect(validateAuctionAmount('1.234', 'Fiyat'), isNotNull);
    });
  });
}
