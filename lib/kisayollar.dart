import 'package:flutter/material.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';

class QuickAccessDetailsPanel extends StatelessWidget {
  const QuickAccessDetailsPanel({
    super.key,
    required this.page,
    required this.sales,
    required this.salesError,
    required this.movements,
    required this.movementsError,
    required this.onClose,
    required this.onRefresh,
    required this.onRefreshSales,
  });

  final AdminPage page;
  final List<AntiqueSale> sales;
  final String? salesError;
  final List<StockMovement> movements;
  final String? movementsError;
  final VoidCallback onClose;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onRefreshSales;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSales = page == AdminPage.sales;
    final error = isSales ? salesError : movementsError;
    final width = MediaQuery.sizeOf(context).width < 744
        ? MediaQuery.sizeOf(context).width - 24
        : 720.0;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: onClose,
            child: ColoredBox(color: Colors.black.withValues(alpha: 0.28)),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: Material(
              color: colorScheme.surface,
              elevation: 20,
              shadowColor: Colors.black.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
                side: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                width: width,
                height: MediaQuery.sizeOf(context).height * 0.72,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(
                              isSales
                                  ? Icons.point_of_sale_rounded
                                  : Icons.swap_vert_circle_outlined,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isSales ? 'Satışlar' : 'Stok Hareketleri',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSales
                                      ? '${sales.length} satış kaydı'
                                      : '${movements.length} stok hareketi',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isSales ? onRefreshSales : onRefresh,
                            tooltip: 'Yenile',
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                          IconButton(
                            onPressed: onClose,
                            tooltip: 'Kapat',
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      height: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                    ),
                    Expanded(
                      child: error != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: SelectableText(
                                  isSales
                                      ? 'Satışlar yüklenemedi: $error'
                                      : 'Stok hareketleri yüklenemedi. '
                                            'Supabase SQL kurulumunu çalıştırdıktan '
                                            'sonra yenile.\n$error',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : isSales
                          ? sales.isEmpty
                                ? const Center(
                                    child: Text('Henüz satış kaydı yok.'),
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(18),
                                    itemCount: sales.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 8),
                                    itemBuilder: (context, index) {
                                      final sale = sales[index];
                                      return Card(
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: colorScheme.primary
                                                .withValues(alpha: 0.16),
                                            child: Icon(
                                              Icons.sell_outlined,
                                              color: colorScheme.primary,
                                            ),
                                          ),
                                          title: Text(sale.productName),
                                          subtitle: Text(
                                            '${formatNumber(sale.quantity)} adet × '
                                            '${formatCurrency(sale.unitPrice)}'
                                            '${sale.buyer.isEmpty ? '' : ' • ${sale.buyer}'}'
                                            ' • ${formatDate(sale.soldAt)}',
                                          ),
                                          trailing: Text(
                                            formatCurrency(sale.total),
                                            style: TextStyle(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )
                          : movements.isEmpty
                          ? const Center(
                              child: Text('Henüz stok hareketi kaydedilmemiş.'),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(18),
                              itemCount: movements.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final movement = movements[index];
                                final isDecrease =
                                    movement.newStock < movement.previousStock;
                                final movementColor = isDecrease
                                    ? const Color(0xFFFF8A80)
                                    : colorScheme.primary;
                                final difference =
                                    movement.newStock - movement.previousStock;
                                return Card(
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: movementColor.withValues(
                                        alpha: 0.12,
                                      ),
                                      child: Icon(
                                        isDecrease
                                            ? Icons.south_west_rounded
                                            : Icons.north_east_rounded,
                                        color: movementColor,
                                      ),
                                    ),
                                    title: Text(movement.productName),
                                    subtitle: Text(
                                      '${movement.type} • '
                                      '${formatDate(movement.createdAt)} '
                                      '${movement.createdAt.toLocal().hour.toString().padLeft(2, '0')}:'
                                      '${movement.createdAt.toLocal().minute.toString().padLeft(2, '0')}'
                                      '\nStok: ${formatNumber(movement.previousStock)} → '
                                      '${formatNumber(movement.newStock)}',
                                    ),
                                    isThreeLine: true,
                                    trailing: Text(
                                      '${difference > 0 ? '+' : ''}${formatNumber(difference)}',
                                      style: TextStyle(
                                        color: movementColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
