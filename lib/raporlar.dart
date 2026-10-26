import 'package:flutter/material.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';
import 'ortak.dart';
import 'rapor.dart';
import 'tema.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({
    super.key,
    required this.antiques,
    required this.auctions,
    required this.sales,
    required this.onBack,
  });

  final List<Antique> antiques;
  final List<Auction> auctions;
  final List<AntiqueSale> sales;
  final VoidCallback onBack;

  Future<void> _exportReport(BuildContext context, _ReportFormat format) async {
    try {
      final file = switch (format) {
        _ReportFormat.excel => await ReportExporter.exportExcel(
          antiques: antiques,
          auctions: auctions,
          sales: sales,
        ),
        _ReportFormat.pdf => await ReportExporter.exportPdf(
          antiques: antiques,
          auctions: auctions,
          sales: sales,
        ),
      };
      if (!context.mounted || file == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapor kaydedildi: ${file.pathSegments.last}')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Rapor dışa aktarılamadı: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stockCount = antiques.fold<int>(
      0,
      (sum, antique) => sum + antique.quantity,
    );
    final stockValue = antiques.fold<double>(
      0,
      (sum, antique) => sum + antique.value * antique.quantity,
    );
    final revenue = sales.fold<double>(0, (sum, sale) => sum + sale.total);
    final realizedProfit = sales.fold<double>(
      0,
      (sum, sale) => sum + sale.netProfit,
    );
    final projectedProfit = antiques.fold<double>(
      0,
      (sum, antique) =>
          sum +
          (antique.value - antique.purchasePrice - antique.extraCosts) *
              antique.quantity,
    );
    final soldCount = sales.fold<int>(0, (sum, sale) => sum + sale.quantity);
    final categories = <String, int>{};
    for (final antique in antiques) {
      categories.update(
        antique.category,
        (count) => count + antique.quantity,
        ifAbsent: () => antique.quantity,
      );
    }
    final maxCategoryCount = categories.values.fold<int>(
      0,
      (max, count) => count > max ? count : max,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Raporlar'),
        actions: [
          PopupMenuButton<_ReportFormat>(
            tooltip: 'Raporu dışa aktar',
            icon: const Icon(Icons.download_outlined),
            onSelected: (format) => _exportReport(context, format),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ReportFormat.excel,
                child: ListTile(
                  leading: Icon(Icons.table_view_outlined),
                  title: Text('Verileri Excel olarak dışa aktar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _ReportFormat.pdf,
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('PDF olarak kaydet'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const NotificationMenuButton(),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 900
                    ? 5
                    : constraints.maxWidth >= 560
                    ? 2
                    : 1;
                final width =
                    (constraints.maxWidth - (columns - 1) * 14) / columns;
                return Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: [
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.layers_rounded,
                        title: 'Mevcut stok',
                        value: formatNumber(stockCount),
                        subtitle: 'Satışta olan toplam adet',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.trending_up_rounded,
                        title: 'Gerçekleşen net kâr',
                        value: formatCurrency(realizedProfit),
                        subtitle: 'Satışlardan elde edilen kâr',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.savings_outlined,
                        title: 'Stoktaki tahmini kâr',
                        value: formatCurrency(projectedProfit),
                        subtitle: 'Mevcut stok satılırsa',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Tahmini stok değeri',
                        value: formatCurrency(stockValue),
                        subtitle: 'Ürün fiyatı × mevcut stok',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.payments_rounded,
                        title: 'Toplam satış geliri',
                        value: formatCurrency(revenue),
                        subtitle: '${formatNumber(soldCount)} adet satıldı',
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: StatCard(
                        icon: Icons.gavel_rounded,
                        title: 'Açık artırmalar',
                        value: '${auctions.length}',
                        subtitle: 'Kayıtlı açık artırma',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kategoriye göre stok',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (categories.isEmpty)
                      const Text('Raporlanacak ürün bulunmuyor.')
                    else
                      ...categories.entries.map((entry) {
                        final ratio = maxCategoryCount == 0
                            ? 0.0
                            : entry.value / maxCategoryCount;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(entry.key)),
                                  Text('${formatNumber(entry.value)} adet'),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 8,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.16),
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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

enum _ReportFormat { excel, pdf }

class CustomersPage extends StatelessWidget {
  const CustomersPage({
    super.key,
    required this.customers,
    required this.error,
    required this.onBack,
  });

  final List<CustomerSummary> customers;
  final String? error;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Müşteriler'),
        actions: const [NotificationMenuButton()],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Müşteri satış kayıtları yüklenemedi.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : customers.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Müşteri listesi, satış kaydederken alıcı adı '
                  'girildikçe burada oluşur.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: customers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final customer = customers[index];
                return Card(
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.16),
                      child: Text(
                        customer.name.characters.first.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    title: Text(customer.name),
                    subtitle: Text(
                      '${formatNumber(customer.purchaseCount)} satış • '
                      '${formatNumber(customer.itemCount)} ürün • '
                      'Son alışveriş ${formatDate(customer.lastPurchase)}',
                    ),
                    trailing: Text(
                      formatCurrency(customer.totalSpent),
                      style: TextStyle(
                        color: accentColor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(72, 0, 20, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Aldığı ürünler: ${customer.products.join(', ')}',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
