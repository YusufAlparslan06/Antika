import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';
import 'operasyon_servisleri.dart';

class InventoryCountPage extends StatefulWidget {
  const InventoryCountPage({
    super.key,
    required this.products,
    required this.onBack,
    required this.onCountSaved,
    required this.onSyncPending,
    required this.onDiscardPending,
    required this.isUsingOfflineCache,
  });

  final List<Antique> products;
  final VoidCallback onBack;
  final Future<void> Function(List<OfflineStockCount>) onCountSaved;
  final Future<int> Function() onSyncPending;
  final Future<void> Function() onDiscardPending;
  final bool isUsingOfflineCache;

  @override
  State<InventoryCountPage> createState() => _InventoryCountPageState();
}

class _InventoryCountPageState extends State<InventoryCountPage> {
  final _controllers = <int, TextEditingController>{};
  bool _isSaving = false;
  bool _isSyncing = false;
  int _pendingCount = 0;
  List<OfflineStockCount> _pendingCounts = [];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final pending = await InventoryCache.loadPendingCounts();
      if (mounted) {
        setState(() {
          _pendingCounts = pending;
          _pendingCount = pending.length;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bekleyen sayımlar okunamadı: $error')),
        );
      }
    }
  }

  Future<void> _syncPending() async {
    setState(() => _isSyncing = true);
    try {
      final count = await widget.onSyncPending();
      if (!mounted) return;
      await _loadPendingCount();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count bekleyen stok sayımı eşitlendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eşitleme başarısız, kayıtlar korundu: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _discardPending() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Bekleyen sayımları sil?'),
        content: const Text(
          'Eşitlenmemiş sayım değerleri bu cihazdan silinir. Sunucudaki stok '
          'değişmez; güncel veriyi yenileyip yeniden sayım yapabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sayım kuyruğunu sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.onDiscardPending();
    if (!mounted) return;
    setState(() {
      _pendingCount = 0;
      _pendingCounts = [];
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(Antique product) =>
      _controllers.putIfAbsent(
        product.id!,
        () => TextEditingController(text: product.quantity.toString()),
      );

  Future<void> _saveCount() async {
    final counts = <OfflineStockCount>[];
    for (final product in widget.products) {
      final controller = _controllerFor(product);
      final quantity = int.tryParse(controller.text.trim());
      if (quantity == null || quantity < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.name}: geçerli adet girin.')),
        );
        return;
      }
      if (quantity != product.quantity) {
        counts.add(
          OfflineStockCount(
            productId: product.id!,
            expectedStock: product.quantity,
            countedStock: quantity,
            productName: product.name,
          ),
        );
      }
    }
    if (counts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sayımda stok farkı bulunamadı.')),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      await widget.onCountSaved(counts);
      if (mounted) widget.onBack();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sayım kaydedilemedi: $error')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Envanter sayımı'),
        actions: const [NotificationMenuButton()],
      ),
      body: widget.products.isEmpty
          ? const Center(child: Text('Sayılacak ürün bulunamadı.'))
          : Column(
              children: [
                if (widget.isUsingOfflineCache || _pendingCount > 0)
                  Card(
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ListTile(
                      leading: const Icon(Icons.cloud_sync_outlined),
                      title: Text(
                        widget.isUsingOfflineCache
                            ? 'Çevrimdışı sayım modu'
                            : 'Eşitlenmeyi bekleyen sayım: $_pendingCount',
                      ),
                      subtitle: const Text(
                        'Stok farkları yerel olarak saklanır; sunucudaki stok '
                        'değişmemişse bağlantı kurulduğunda uygulanır.',
                      ),
                      trailing: _pendingCount == 0
                          ? null
                          : IconButton(
                              tooltip: 'Bekleyen sayımları eşitle',
                              onPressed: _isSyncing ? null : _syncPending,
                              icon: _isSyncing
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.sync),
                            ),
                    ),
                  ),
                if (_pendingCounts.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _pendingCounts
                                .map(
                                  (item) =>
                                      '${item.productName}: '
                                      '${item.expectedStock} → ${item.countedStock}',
                                )
                                .join(' • '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        TextButton(
                          onPressed: _discardPending,
                          child: const Text('Kuyruğu sil'),
                        ),
                      ],
                    ),
                  ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Raflardaki gerçek adetleri gir. Sayım anındaki stok '
                    'değişmişse güncelleme çakışma uyarısıyla durdurulur.',
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: widget.products.length,
                    itemBuilder: (context, index) {
                      final product = widget.products[index];
                      final controller = _controllerFor(product);
                      return Card(
                        child: ListTile(
                          title: Text(product.name),
                          subtitle: Text(
                            '${product.location.isEmpty ? product.category : product.location} '
                            '• Sistemde ${formatNumber(product.quantity)} adet',
                          ),
                          trailing: SizedBox(
                            width: 100,
                            child: TextField(
                              controller: controller,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Sayım',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _isSaving ? null : _saveCount,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.fact_check_outlined),
                        label: const Text('Sayımı kaydet'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class ActivityHistoryPage extends StatefulWidget {
  const ActivityHistoryPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<ActivityHistoryPage> createState() => _ActivityHistoryPageState();
}

class _ActivityHistoryPageState extends State<ActivityHistoryPage> {
  List<Map<String, dynamic>> _rows = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('islem_gecmisi')
          .select()
          .order('created_at', ascending: false)
          .limit(500);
      if (!mounted) return;
      setState(() {
        _rows = (data as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Menüye dön',
      ),
      title: const Text('İşlem geçmişi'),
      actions: [
        IconButton(
          onPressed: _load,
          tooltip: 'Yenile',
          icon: const Icon(Icons.refresh),
        ),
        const NotificationMenuButton(),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText('İşlem geçmişi yüklenemedi: $_error'),
            ),
          )
        : _rows.isEmpty
        ? const Center(
            child: Text(
              'Henüz geçmiş kaydı yok. Supabase SQL güncellemesini çalıştırın.',
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _rows.length,
            itemBuilder: (context, index) {
              final row = _rows[index];
              final createdAt = DateTime.tryParse(
                (row['created_at'] ?? '').toString(),
              );
              final colorScheme = Theme.of(context).colorScheme;
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      _iconFor(row['kayit_turu'].toString()),
                      color: colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    '${_recordLabel(row['kayit_turu'].toString())} '
                    '${row['islem'] ?? ''}',
                  ),
                  subtitle: Text(
                    '${row['yapan_adi'] ?? 'Kullanıcı'} • '
                    '${row['yapan_rol'] == 'yonetici' ? 'Yönetici' : 'Personel'}'
                    '${row['urun_id'] == null ? '' : ' • Ürün #${row['urun_id']}'}'
                    '${createdAt == null ? '' : ' • ${formatDate(createdAt.toLocal())} ${_time(createdAt)}'}',
                  ),
                ),
              );
            },
          ),
  );
}

class ProductTimelinePage extends StatefulWidget {
  const ProductTimelinePage({
    super.key,
    required this.product,
    required this.onBack,
  });

  final Antique product;
  final VoidCallback onBack;

  @override
  State<ProductTimelinePage> createState() => _ProductTimelinePageState();
}

class _ProductTimelinePageState extends State<ProductTimelinePage> {
  List<Map<String, dynamic>> _events = [];
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rows = await Supabase.instance.client
          .from('islem_gecmisi')
          .select()
          .eq('urun_id', widget.product.id!)
          .order('created_at', ascending: false)
          .limit(200);
      if (!mounted) return;
      setState(() {
        _events = (rows as List)
            .map((row) => Map<String, dynamic>.from(row as Map))
            .toList();
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        onPressed: widget.onBack,
        icon: const Icon(Icons.arrow_back),
        tooltip: 'Ürünlere dön',
      ),
      title: Text('${widget.product.name} • Zaman çizelgesi'),
      actions: const [NotificationMenuButton()],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText('Zaman çizelgesi yüklenemedi: $_error'),
            ),
          )
        : _events.isEmpty
        ? const Center(
            child: Text(
              'Ürün geçmişi yok. SQL güncellemesinden sonra yeni işlemler burada görünür.',
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: _events.length,
            itemBuilder: (context, index) {
              final event = _events[index];
              final date = DateTime.tryParse(
                (event['created_at'] ?? '').toString(),
              );
              return ListTile(
                leading: const Icon(Icons.circle_outlined),
                title: Text(
                  '${_recordLabel(event['kayit_turu'].toString())} '
                  '${event['islem'] ?? ''}',
                ),
                subtitle: Text(
                  '${event['yapan_adi'] ?? 'Kullanıcı'}'
                  '${date == null ? '' : ' • ${formatDate(date.toLocal())} ${_time(date)}'}',
                ),
              );
            },
          ),
  );
}

IconData _iconFor(String type) => switch (type) {
  'urunler' => Icons.inventory_2_outlined,
  'satislar' => Icons.point_of_sale_outlined,
  'acik_artirmalar' => Icons.gavel_outlined,
  _ => Icons.history,
};

String _recordLabel(String type) => switch (type) {
  'urunler' => 'Ürün',
  'satislar' => 'Satış',
  'acik_artirmalar' => 'Açık artırma',
  _ => 'Kayıt',
};

String _time(DateTime value) {
  final local = value.toLocal();
  return '${local.hour.toString().padLeft(2, '0')}:'
      '${local.minute.toString().padLeft(2, '0')}';
}
