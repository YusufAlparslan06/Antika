import 'package:flutter/material.dart';

import 'ayarlar.dart';
import 'navigasyon.dart';
import 'ortak.dart';
import 'tema.dart';
import 'modeller.dart';

class AdminMenu extends StatelessWidget {
  const AdminMenu({
    super.key,
    required this.antiqueCount,
    required this.totalStock,
    required this.totalValue,
    required this.categoryCount,
    required this.lowStockAntiques,
    required this.auctionsEndingSoon,
    required this.isUsingOfflineCache,
    required this.isManager,
    required this.onSignOut,
    required this.onCreateAntique,
    required this.onShowAntiques,
    required this.onShowAuctions,
    required this.onShowSales,
    required this.onShowReports,
    required this.onShowCustomers,
    required this.onShowStockMovements,
    required this.onShowUsers,
    required this.onShowInventoryCount,
    required this.onShowActivityHistory,
    required this.onShowBackupImport,
  });

  final int antiqueCount;
  final int totalStock;
  final double totalValue;
  final int categoryCount;
  final List<Antique> lowStockAntiques;
  final List<Auction> auctionsEndingSoon;
  final bool isUsingOfflineCache;
  final bool isManager;
  final VoidCallback onSignOut;
  final VoidCallback onCreateAntique;
  final VoidCallback onShowAntiques;
  final VoidCallback onShowAuctions;
  final VoidCallback onShowInventoryCount;
  final VoidCallback onShowActivityHistory;
  final VoidCallback onShowBackupImport;
  final VoidCallback onShowSales;
  final VoidCallback onShowReports;
  final VoidCallback onShowCustomers;
  final VoidCallback onShowStockMovements;
  final VoidCallback onShowUsers;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const EskilerdenBrand(fontSize: 30),
        actions: [
          const NotificationMenuButton(),
          IconButton(
            tooltip: 'Çıkış yap',
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isUsingOfflineCache) ...[
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: const ListTile(
                  leading: Icon(Icons.cloud_off_outlined),
                  title: Text('Çevrimdışı önbellek gösteriliyor'),
                  subtitle: Text(
                    'Veriler son başarılı eşitlemeden alınmıştır. '
                    'Envanter sayımını kaydettiğinde bağlantı gelince eşitleyebilirsin.',
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(
              'Hoş geldin 👋',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            const Text('Antika envanterinin güncel durumuna göz at.'),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 1050
                    ? 4
                    : constraints.maxWidth > 600
                    ? 2
                    : 1;
                final cardWidth =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        icon: Icons.inventory_2_rounded,
                        title: 'Toplam ürün',
                        value: formatNumber(antiqueCount),
                        subtitle: 'Kayıtlı ürün çeşidi',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        icon: Icons.layers_rounded,
                        title: 'Toplam stok',
                        value: formatNumber(totalStock),
                        subtitle: 'Depodaki toplam adet',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Stok değeri',
                        value: formatCurrency(totalValue),
                        subtitle: 'Satış fiyatı × stok',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: StatCard(
                        icon: Icons.category_rounded,
                        title: 'Kategoriler',
                        value: formatNumber(categoryCount),
                        subtitle: 'Kullanılan kategori',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 26),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          lowStockAntiques.isEmpty
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: lowStockAntiques.isEmpty
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            lowStockAntiques.isEmpty
                                ? 'Düşük stok uyarısı yok'
                                : 'Düşük stok (${lowStockAntiques.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: onShowAntiques,
                          child: const Text('Ürünleri aç'),
                        ),
                      ],
                    ),
                    if (lowStockAntiques.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Stok miktarı belirlenen uyarı eşiklerinin üzerinde.',
                        ),
                      )
                    else ...[
                      const SizedBox(height: 8),
                      ...lowStockAntiques
                          .take(6)
                          .map(
                            (antique) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.inventory_2_outlined),
                              title: Text(antique.name),
                              subtitle: Text(
                                '${antique.category} • '
                                'Eşik: ${formatNumber(antique.minimumStock)} adet',
                              ),
                              trailing: Chip(
                                avatar: const Icon(Icons.warning_amber_rounded),
                                label: Text(
                                  '${formatNumber(antique.quantity)} adet',
                                ),
                              ),
                            ),
                          ),
                      if (lowStockAntiques.length > 6)
                        Text(
                          've ${lowStockAntiques.length - 6} ürün daha',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.event_busy_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            auctionsEndingSoon.isEmpty
                                ? 'Yaklaşan açık artırma yok'
                                : '7 gün içinde bitecek açık artırmalar '
                                      '(${auctionsEndingSoon.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: onShowAuctions,
                          child: const Text('Açık artırmaları aç'),
                        ),
                      ],
                    ),
                    if (auctionsEndingSoon.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      ...auctionsEndingSoon
                          .take(5)
                          .map(
                            (auction) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.hourglass_bottom),
                              title: Text(
                                auction.auctionLocation.isEmpty
                                    ? 'Açık artırma #${auction.id}'
                                    : auction.auctionLocation,
                              ),
                              subtitle: Text(
                                'Bitiş: ${formatDate(auction.endDate.toLocal())}',
                              ),
                              trailing: Text(
                                formatCurrency(auction.currentBid),
                              ),
                            ),
                          ),
                    ] else
                      const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Aktif açık artırmaların bitiş tarihi yakın değil.',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 26),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hızlı işlemler',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text('Envanterini buradan yönetebilirsin.'),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: onCreateAntique,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Yeni ürün ekle'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowAntiques,
                          icon: const Icon(Icons.list_alt_rounded),
                          label: const Text('Ürünleri görüntüle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowAuctions,
                          icon: const Icon(Icons.gavel_rounded),
                          label: const Text('Açık artırma'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowSales,
                          icon: const Icon(Icons.point_of_sale_rounded),
                          label: const Text('Satışlar'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowReports,
                          icon: const Icon(Icons.bar_chart_rounded),
                          label: const Text('Raporları görüntüle'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowCustomers,
                          icon: const Icon(Icons.people_alt_rounded),
                          label: const Text('Müşteriler'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowStockMovements,
                          icon: const Icon(Icons.swap_vert_circle_outlined),
                          label: const Text('Stok hareketleri'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowInventoryCount,
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('Envanter sayımı'),
                        ),
                        OutlinedButton.icon(
                          onPressed: onShowActivityHistory,
                          icon: const Icon(Icons.history_outlined),
                          label: const Text('İşlem geçmişi'),
                        ),
                        if (isManager)
                          OutlinedButton.icon(
                            onPressed: onShowBackupImport,
                            icon: const Icon(Icons.restore_outlined),
                            label: const Text('Yedekten geri yükle'),
                          ),
                        if (isManager)
                          OutlinedButton.icon(
                            onPressed: onShowUsers,
                            icon: const Icon(
                              Icons.admin_panel_settings_outlined,
                            ),
                            label: const Text('Kullanıcı rolleri'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
