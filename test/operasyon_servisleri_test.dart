import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:antika_stok/modeller.dart';
import 'package:antika_stok/operasyon_servisleri.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'cached products can be restored for offline inventory counting',
    () async {
      const product = Antique(
        id: 3,
        name: 'Bakır ibrik',
        category: 'Bakır ve Pirinç Eşyalar',
        year: 1920,
        history: 'Aile koleksiyonu',
        value: 900,
        purchasePrice: 500,
        extraCosts: 20,
        quantity: 4,
        minimumStock: 2,
        offer: '',
        auctionLocation: '',
        location: 'Raf A-2',
        condition: 'İyi',
      );
      await InventoryCache.saveProducts([product]);

      final cached = await InventoryCache.loadProducts();

      expect(cached, hasLength(1));
      expect(cached!.single.id, 3);
      expect(cached.single.quantity, 4);
      expect(cached.single.location, 'Raf A-2');
    },
  );

  test(
    'queued counts keep original server stock when recounting offline',
    () async {
      const initial = OfflineStockCount(
        productId: 3,
        expectedStock: 4,
        countedStock: 5,
        productName: 'Bakır ibrik',
      );
      const recounted = OfflineStockCount(
        productId: 3,
        expectedStock: 5,
        countedStock: 6,
        productName: 'Bakır ibrik',
      );

      await InventoryCache.queueCounts([initial]);
      await InventoryCache.queueCounts([recounted]);

      final pending = await InventoryCache.loadPendingCounts();
      expect(pending, hasLength(1));
      expect(pending.single.expectedStock, 4);
      expect(pending.single.countedStock, 6);
    },
  );
}
