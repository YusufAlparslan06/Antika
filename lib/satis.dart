import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';
import 'fis.dart';
import 'tema.dart';

class SalesPage extends StatelessWidget {
  const SalesPage({
    super.key,
    required this.sales,
    required this.error,
    required this.onBack,
    required this.onCreateSale,
  });

  final List<AntiqueSale> sales;
  final String? error;
  final VoidCallback onBack;
  final VoidCallback onCreateSale;

  Future<void> _saveReceipt(BuildContext context, AntiqueSale sale) async {
    try {
      final file = await SalesReceiptExporter.export(sale);
      if (!context.mounted || file == null) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satış fişi kaydedildi: ${file.pathSegments.last}'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Satış fişi oluşturulamadı: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Satışlar'),
        actions: [
          const NotificationMenuButton(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: onCreateSale,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Satış kaydet'),
            ),
          ),
        ],
      ),
      body: error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText('Satışlar yüklenemedi: $error'),
              ),
            )
          : sales.isEmpty
          ? const Center(
              child: Text('Henüz satış kaydı yok. İlk satışı kaydedebilirsin.'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: sales.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final sale = sales[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.16),
                      child: Icon(
                        Icons.sell_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(sale.productName),
                    subtitle: Text(
                      '${formatNumber(sale.quantity)} adet × '
                      '${formatCurrency(sale.unitPrice)}'
                      '${sale.buyer.isEmpty ? '' : ' • ${sale.buyer}'}'
                      ' • ${formatDate(sale.soldAt)}\n'
                      'Net kâr: ${formatCurrency(sale.netProfit)}',
                    ),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          formatCurrency(sale.total),
                          style: TextStyle(
                            color: accentColor(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Satış fişini PDF kaydet',
                          onPressed: () => _saveReceipt(context, sale),
                          icon: const Icon(Icons.receipt_long_outlined),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class CreateSalePage extends StatefulWidget {
  const CreateSalePage({
    super.key,
    required this.antiques,
    required this.onCancel,
    required this.onSave,
  });

  final List<Antique> antiques;
  final VoidCallback onCancel;
  final Future<void> Function({
    required Antique antique,
    required int quantity,
    required double unitPrice,
    required String buyer,
  })
  onSave;

  @override
  State<CreateSalePage> createState() => _CreateSalePageState();
}

class _CreateSalePageState extends State<CreateSalePage> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final _buyerController = TextEditingController();
  int? _selectedProductId;
  bool _isSaving = false;

  List<Antique> get _availableAntiques => widget.antiques
      .where((antique) => antique.id != null && antique.quantity > 0)
      .toList();

  Antique? get _selectedAntique {
    for (final antique in _availableAntiques) {
      if (antique.id == _selectedProductId) return antique;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final first = _availableAntiques.firstOrNull;
    _selectedProductId = first?.id;
    if (first != null) {
      _priceController.text = first.value.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _priceController.dispose();
    _buyerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final antique = _selectedAntique;
    if (antique == null || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.onSave(
        antique: antique,
        quantity: int.parse(_quantityController.text.trim()),
        unitPrice: double.parse(
          _priceController.text.trim().replaceAll(',', '.'),
        ),
        buyer: _buyerController.text.trim(),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _availableAntiques;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Satışlara dön',
        ),
        title: const Text('Satış kaydet'),
        actions: const [NotificationMenuButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: available.isEmpty
                    ? const Text(
                        'Satış yapabilmek için stokta ürünü olan bir kayıt '
                        'bulunmalıdır.',
                      )
                    : Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _selectedProductId,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Ürün',
                                prefixIcon: Icon(Icons.inventory_2_outlined),
                              ),
                              items: available
                                  .map(
                                    (antique) => DropdownMenuItem<int>(
                                      value: antique.id,
                                      child: Text(
                                        '${antique.name} • stok: '
                                        '${formatNumber(antique.quantity)}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: _isSaving
                                  ? null
                                  : (id) {
                                      final selected = available
                                          .where((item) => item.id == id)
                                          .firstOrNull;
                                      setState(() {
                                        _selectedProductId = id;
                                        _quantityController.text = '1';
                                        _priceController.text =
                                            selected?.value.toStringAsFixed(
                                              2,
                                            ) ??
                                            '';
                                      });
                                    },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _quantityController,
                              decoration: const InputDecoration(
                                labelText: 'Satılan adet',
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                                final quantity = int.tryParse(value ?? '');
                                if (quantity == null || quantity < 1) {
                                  return 'Geçerli bir adet girin.';
                                }
                                final selected = _selectedAntique;
                                if (selected != null &&
                                    quantity > selected.quantity) {
                                  return 'Stokta yalnızca '
                                      '${formatNumber(selected.quantity)} adet var.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _priceController,
                              decoration: const InputDecoration(
                                labelText: 'Birim satış fiyatı (₺)',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9,.]'),
                                ),
                              ],
                              validator: (value) {
                                final price = double.tryParse(
                                  (value ?? '').trim().replaceAll(',', '.'),
                                );
                                if (price == null ||
                                    !price.isFinite ||
                                    price < 0) {
                                  return 'Geçerli bir fiyat girin.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _buyerController,
                              decoration: const InputDecoration(
                                labelText: 'Alıcı (isteğe bağlı)',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                            const SizedBox(height: 24),
                            FilledButton(
                              onPressed: _isSaving ? null : _save,
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text('Satışı kaydet'),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
