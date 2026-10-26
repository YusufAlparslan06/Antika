import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'modeller.dart';

class OfflineStockCount {
  const OfflineStockCount({
    required this.productId,
    required this.expectedStock,
    required this.countedStock,
    required this.productName,
  });

  final int productId;
  final int expectedStock;
  final int countedStock;
  final String productName;

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'expected_stock': expectedStock,
    'counted_stock': countedStock,
    'product_name': productName,
  };

  factory OfflineStockCount.fromJson(Map<String, dynamic> json) =>
      OfflineStockCount(
        productId: json['product_id'] as int,
        expectedStock: json['expected_stock'] as int,
        countedStock: json['counted_stock'] as int,
        productName: json['product_name'] as String,
      );
}

class InventoryCache {
  static const _productsKey = 'offline.inventory.products';
  static const _pendingCountsKey = 'offline.inventory.pending_counts';

  static Future<void> saveProducts(List<Antique> products) async {
    final preferences = await SharedPreferences.getInstance();
    final rows = products
        .where((product) => product.id != null)
        .map(
          (product) => {
            'id': product.id,
            'ad': product.name,
            'kategori': product.category,
            'antika_yili': product.year,
            'aciklama': product.history,
            'satis_fiyati': product.value,
            'stok': product.quantity,
            'minimum_stok': product.minimumStock,
            'alis_fiyati': product.purchasePrice,
            'ek_masraf': product.extraCosts,
            'teklif': product.offer,
            'acik_arttirma_yeri': product.auctionLocation,
            'konum': product.location,
            'foto_url': product.photoUrl,
            'kondisyon': product.condition,
            'kondisyon_foto_url': product.conditionPhotoUrl,
          },
        )
        .toList();
    await preferences.setString(_productsKey, jsonEncode(rows));
  }

  static Future<List<Antique>?> loadProducts() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_productsKey);
    if (encoded == null) return null;
    final rows = jsonDecode(encoded);
    if (rows is! List) {
      throw const FormatException('Yerel ürün önbelleği geçersiz.');
    }
    return rows.map((row) {
      final item = Map<String, dynamic>.from(row as Map);
      return Antique(
        id: (item['id'] as num).toInt(),
        name: (item['ad'] ?? '').toString(),
        category: (item['kategori'] ?? 'Diğer').toString(),
        year: (item['antika_yili'] as num?)?.toInt() ?? 0,
        history: (item['aciklama'] ?? '').toString(),
        value: (item['satis_fiyati'] as num?)?.toDouble() ?? 0,
        quantity: (item['stok'] as num?)?.toInt() ?? 0,
        minimumStock: (item['minimum_stok'] as num?)?.toInt() ?? 3,
        purchasePrice: (item['alis_fiyati'] as num?)?.toDouble() ?? 0,
        extraCosts: (item['ek_masraf'] as num?)?.toDouble() ?? 0,
        offer: (item['teklif'] ?? '').toString(),
        auctionLocation: (item['acik_arttirma_yeri'] ?? '').toString(),
        location: (item['konum'] ?? '').toString(),
        photoUrl: item['foto_url']?.toString(),
        condition: (item['kondisyon'] ?? '').toString(),
        conditionPhotoUrl: item['kondisyon_foto_url']?.toString(),
      );
    }).toList();
  }

  static Future<List<OfflineStockCount>> loadPendingCounts() async {
    final preferences = await SharedPreferences.getInstance();
    final encoded = preferences.getString(_pendingCountsKey);
    if (encoded == null) return [];
    final rows = jsonDecode(encoded);
    if (rows is! List) {
      throw const FormatException('Bekleyen çevrimdışı sayımlar geçersiz.');
    }
    return rows
        .map(
          (row) =>
              OfflineStockCount.fromJson(Map<String, dynamic>.from(row as Map)),
        )
        .toList();
  }

  static Future<void> clearPendingCounts() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingCountsKey);
  }

  static Future<void> queueCounts(List<OfflineStockCount> counts) async {
    final existing = await loadPendingCounts();
    final merged = {for (final item in existing) item.productId: item};
    for (final item in counts) {
      final previous = merged[item.productId];
      merged[item.productId] = previous == null
          ? item
          : OfflineStockCount(
              productId: item.productId,
              expectedStock: previous.expectedStock,
              countedStock: item.countedStock,
              productName: item.productName,
            );
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      _pendingCountsKey,
      jsonEncode(merged.values.map((item) => item.toJson()).toList()),
    );
  }

  static Future<int> syncPendingCounts(SupabaseClient supabase) async {
    final pending = await loadPendingCounts();
    if (pending.isEmpty) return 0;
    final applied = await supabase.rpc(
      'envanter_sayimini_uygula',
      params: {
        'p_sayim': pending
            .map(
              (item) => {
                'product_id': item.productId,
                'expected_stock': item.expectedStock,
                'counted_stock': item.countedStock,
              },
            )
            .toList(),
      },
    );
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_pendingCountsKey);
    return (applied as num).toInt();
  }
}
