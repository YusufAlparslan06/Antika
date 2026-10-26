import 'package:flutter/material.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';
import 'tema.dart';

class StockMovementsPage extends StatelessWidget {
  const StockMovementsPage({
    super.key,
    required this.movements,
    required this.error,
    required this.onBack,
    required this.onRefresh,
  });

  final List<StockMovement> movements;
  final String? error;
  final VoidCallback onBack;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Stok Hareketleri'),
        actions: [
          const NotificationMenuButton(),
          IconButton(
            tooltip: 'Yenile',
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText(
                  'Stok hareketleri yüklenemedi. Supabase SQL kurulumunu '
                  'çalıştırdıktan sonra yenile.\n$error',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : movements.isEmpty
          ? const Center(child: Text('Henüz stok hareketi kaydedilmemiş.'))
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: movements.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final movement = movements[index];
                final isDecrease = movement.newStock < movement.previousStock;
                final color = isDecrease
                    ? const Color(0xFFFF8A80)
                    : accentColor(context);
                final difference = movement.newStock - movement.previousStock;
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.12),
                      child: Icon(
                        isDecrease
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded,
                        color: color,
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
                        color: color,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
