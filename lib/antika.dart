import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:universal_barcode_scanner/universal_barcode_scanner.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';

class AntiqueListPage extends StatefulWidget {
  const AntiqueListPage({
    super.key,
    required this.antiques,
    required this.onBack,
    required this.onCreateAntique,
    required this.onEdit,
    required this.onDelete,
    required this.onShowTimeline,
    required this.canDelete,
  });

  final List<Antique> antiques;
  final VoidCallback onBack;
  final VoidCallback onCreateAntique;
  final Future<void> Function(Antique) onEdit;
  final Future<void> Function(Antique) onDelete;
  final ValueChanged<Antique> onShowTimeline;
  final bool canDelete;

  @override
  State<AntiqueListPage> createState() => _AntiqueListPageState();
}

class _AntiqueListPageState extends State<AntiqueListPage> {
  String _selectedCategory = 'Tüm kategoriler';
  String _searchText = '';

  List<Antique> get _filteredAntiques {
    return widget.antiques.where((antique) {
      final matchesCategory =
          _selectedCategory == 'Tüm kategoriler' ||
          antique.category == _selectedCategory;
      final matchesSearch =
          antique.name.toLowerCase().contains(_searchText.toLowerCase()) ||
          antique.location.toLowerCase().contains(_searchText.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  List<Antique> get _lowStockAntiques => widget.antiques
      .where(
        (antique) =>
            antique.minimumStock > 0 &&
            antique.quantity <= antique.minimumStock,
      )
      .toList();

  Future<void> _scanProductCode() async {
    try {
      final code = await UniversalBarcodeScanner.scan(context);
      if (!mounted || code == null) return;

      final match = RegExp(
        r'^(?:ANTIKA:)?(\d+)$',
        caseSensitive: false,
      ).firstMatch(code.trim());
      final id = match == null ? null : int.tryParse(match.group(1)!);
      Antique? antique;
      for (final item in widget.antiques) {
        if (item.id == id) {
          antique = item;
          break;
        }
      }
      if (antique == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bu koda ait ürün bulunamadı.')),
        );
        return;
      }
      await _showAntiqueDetails(antique);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Barkod veya QR kod taranamadı: $error')),
      );
    }
  }

  Future<void> _showAntiqueDetails(Antique antique) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(
          width: 680,
          height: screenHeight * 0.88,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  tooltip: 'Kapat',
                  onPressed: () => Navigator.pop(dialogContext),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: double.infinity,
                          height: screenHeight * 0.46,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: antique.photoUrl == null
                              ? const Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 72,
                                )
                              : Image.network(
                                  antique.photoUrl!,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, _, _) => const Icon(
                                    Icons.broken_image_outlined,
                                    size: 72,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        antique.name,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      _AntiqueDetailRow(
                        label: 'Kategori',
                        value: antique.category,
                      ),
                      _AntiqueDetailRow(
                        label: 'Antika yılı',
                        value: antique.year == 0
                            ? 'Belirtilmemiş'
                            : '${antique.year}',
                      ),
                      _AntiqueDetailRow(
                        label: 'Teklif',
                        value: antique.offer.isEmpty
                            ? 'Belirtilmemiş'
                            : antique.offer,
                      ),
                      _AntiqueDetailRow(
                        label: 'Açık artırma yeri',
                        value: antique.auctionLocation.isEmpty
                            ? 'Belirtilmemiş'
                            : antique.auctionLocation,
                      ),
                      _AntiqueDetailRow(
                        label: 'Değeri',
                        value: formatCurrency(antique.value),
                      ),
                      _AntiqueDetailRow(
                        label: 'Birim alış bedeli',
                        value: formatCurrency(antique.purchasePrice),
                      ),
                      _AntiqueDetailRow(
                        label: 'Birim tamir/diğer masraf',
                        value: formatCurrency(antique.extraCosts),
                      ),
                      _AntiqueDetailRow(
                        label: 'Tahmini birim net kâr',
                        value: formatCurrency(
                          antique.value -
                              antique.purchasePrice -
                              antique.extraCosts,
                        ),
                      ),
                      _AntiqueDetailRow(
                        label: 'Raf/depo konumu',
                        value: antique.location.isEmpty
                            ? 'Belirtilmemiş'
                            : antique.location,
                      ),
                      _AntiqueDetailRow(
                        label: 'Adet',
                        value: formatNumber(antique.quantity),
                      ),
                      _AntiqueDetailRow(
                        label: 'Stok uyarı eşiği',
                        value: antique.minimumStock == 0
                            ? 'Kapalı'
                            : '${formatNumber(antique.minimumStock)} adet',
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tarihsel geçmişi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        antique.history.isEmpty
                            ? 'Bilgi girilmemiş.'
                            : antique.history,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Kondisyon değerlendirmesi',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (antique.conditionPhotoUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            antique.conditionPhotoUrl!,
                            height: 220,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.broken_image_outlined,
                              size: 48,
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        antique.condition.isEmpty
                            ? 'Kondisyon notu girilmemiş.'
                            : antique.condition,
                        textAlign: TextAlign.center,
                      ),
                      if (antique.id != null) ...[
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            widget.onShowTimeline(antique);
                          },
                          icon: const Icon(Icons.timeline),
                          label: const Text('Ürün zaman çizelgesini aç'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Ürün QR kodu',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: QrImageView(
                            data: 'ANTIKA:${antique.id}',
                            version: QrVersions.auto,
                            size: 160,
                            backgroundColor: Colors.white,
                            semanticsLabel: '${antique.name} ürün QR kodu',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bu kodu uygulamadaki tarama düğmesiyle okutabilirsin.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ÜRÜN LİSTESİ EKRANI BAŞLANGICI
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final visibleAntiques = _filteredAntiques;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Antika Kayıtları'),
        actions: [
          const NotificationMenuButton(),
          IconButton(
            tooltip: 'Barkod veya QR kod tara',
            onPressed: _scanProductCode,
            icon: const Icon(Icons.qr_code_scanner),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: widget.onCreateAntique,
              icon: const Icon(Icons.add),
              label: const Text('Ekle'),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ürün ara',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchText = value.trim());
                    },
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategori filtresi',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'Tüm kategoriler',
                        child: Text(
                          'Tüm kategoriler',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      ...antiqueCategories.map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                ),
                Text('${visibleAntiques.length} kayıt'),
                if (_lowStockAntiques.isNotEmpty)
                  Chip(
                    avatar: const Icon(Icons.warning_amber_rounded),
                    label: Text('${_lowStockAntiques.length} üründe stok az'),
                    backgroundColor: colorScheme.errorContainer,
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: visibleAntiques.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.antiques.isEmpty
                                    ? 'Henüz antika kaydı yok.'
                                    : 'Bu aramaya uygun ürün bulunamadı.',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Arama veya kategori filtresini değiştirebilirsin.',
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Stok durumu')),
                              DataColumn(label: Text('Fotoğraf')),
                              DataColumn(label: Text('Antika Adı')),
                              DataColumn(label: Text('Kategori')),
                              DataColumn(label: Text('Antika Yılı')),
                              DataColumn(label: Text('Teklif')),
                              DataColumn(label: Text('Açık Artırma Yeri')),
                              DataColumn(label: Text('Tarihsel Geçmişi')),
                              DataColumn(label: Text('Değeri')),
                              DataColumn(label: Text('Konum')),
                              DataColumn(label: Text('Adet')),
                              DataColumn(label: Text('İşlem')),
                            ],
                            rows: visibleAntiques.map((antique) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    antique.quantity <= antique.minimumStock &&
                                            antique.minimumStock > 0
                                        ? const Tooltip(
                                            message:
                                                'Stok uyarı eşiğinin altında',
                                            child: Icon(
                                              Icons.warning_amber_rounded,
                                              color: Colors.orange,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    antique.photoUrl == null
                                        ? const Icon(
                                            Icons.image_not_supported_outlined,
                                          )
                                        : ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              antique.photoUrl!,
                                              width: 48,
                                              height: 48,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, _, _) =>
                                                  const Icon(
                                                    Icons.broken_image_outlined,
                                                  ),
                                            ),
                                          ),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(antique.name),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(antique.category),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(antique.year.toString()),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(antique.offer),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(antique.auctionLocation),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    SizedBox(
                                      width: 280,
                                      child: Text(
                                        antique.history,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(formatCurrency(antique.value)),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(
                                      antique.location.isEmpty
                                          ? '—'
                                          : antique.location,
                                    ),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    Text(formatNumber(antique.quantity)),
                                    onTap: () => _showAntiqueDetails(antique),
                                  ),
                                  DataCell(
                                    widget.canDelete
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                tooltip: 'Ürünü düzenle',
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                ),
                                                onPressed: () =>
                                                    widget.onEdit(antique),
                                              ),
                                              IconButton(
                                                tooltip: 'Ürünü sil',
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  color: Color(0xFFFF6B6B),
                                                ),
                                                onPressed: () =>
                                                    widget.onDelete(antique),
                                              ),
                                            ],
                                          )
                                        : IconButton(
                                            tooltip: 'Ürünü düzenle',
                                            icon: const Icon(
                                              Icons.edit_outlined,
                                            ),
                                            onPressed: () =>
                                                widget.onEdit(antique),
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ÜRÜN LİSTESİ EKRANI BİTİŞİ
}

class _AntiqueDetailRow extends StatelessWidget {
  const _AntiqueDetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(child: Text(value, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}

class AddAntiquePage extends StatefulWidget {
  const AddAntiquePage({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.initialAntique,
  });

  final VoidCallback onCancel;
  final Future<void> Function(Antique) onSave;
  final Antique? initialAntique;

  @override
  State<AddAntiquePage> createState() => _AddAntiquePageState();
}

class _AddAntiquePageState extends State<AddAntiquePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _yearController = TextEditingController();
  final _historyController = TextEditingController();
  final _conditionController = TextEditingController();
  final _valueController = TextEditingController();
  final _purchasePriceController = TextEditingController(text: '0');
  final _extraCostsController = TextEditingController(text: '0');
  final _locationController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _minimumStockController = TextEditingController(text: '3');
  final _offerController = TextEditingController();
  String _selectedCategory = 'Diğer';
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  Uint8List? _selectedConditionPhotoBytes;
  String? _selectedConditionPhotoName;

  @override
  void initState() {
    super.initState();
    final antique = widget.initialAntique;
    if (antique == null) return;
    _nameController.text = antique.name;
    _yearController.text = antique.year == 0 ? '' : '${antique.year}';
    _historyController.text = antique.history;
    _conditionController.text = antique.condition;
    _valueController.text = antique.value.toStringAsFixed(2);
    _purchasePriceController.text = antique.purchasePrice.toStringAsFixed(2);
    _extraCostsController.text = antique.extraCosts.toStringAsFixed(2);
    _locationController.text = antique.location;
    _quantityController.text = '${antique.quantity}';
    _minimumStockController.text = '${antique.minimumStock}';
    _offerController.text = antique.offer;
    _selectedCategory = antique.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _yearController.dispose();
    _historyController.dispose();
    _conditionController.dispose();
    _valueController.dispose();
    _purchasePriceController.dispose();
    _extraCostsController.dispose();
    _locationController.dispose();
    _quantityController.dispose();
    _minimumStockController.dispose();
    _offerController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    double amountOrZero(TextEditingController controller) =>
        double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

    await widget.onSave(
      Antique(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        year: int.tryParse(_yearController.text.trim()) ?? 0,
        history: _historyController.text.trim(),
        condition: _conditionController.text.trim(),
        value: amountOrZero(_valueController),
        purchasePrice: amountOrZero(_purchasePriceController),
        extraCosts: amountOrZero(_extraCostsController),
        quantity: int.parse(_quantityController.text.trim()),
        minimumStock: int.tryParse(_minimumStockController.text.trim()) ?? 3,
        offer: _offerController.text.trim(),
        auctionLocation: '',
        location: _locationController.text.trim(),
        id: widget.initialAntique?.id,
        photoUrl: widget.initialAntique?.photoUrl,
        conditionPhotoUrl: widget.initialAntique?.conditionPhotoUrl,
        selectedPhotoBytes: _selectedPhotoBytes,
        selectedPhotoName: _selectedPhotoName,
        selectedConditionPhotoBytes: _selectedConditionPhotoBytes,
        selectedConditionPhotoName: _selectedConditionPhotoName,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Ürün fotoğrafı seç',
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (!mounted || file == null) return;
      final size = await file.length();
      if (!mounted) return;
      if (size != null && size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf boyutu en fazla 10 MB olabilir.'),
          ),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf boyutu en fazla 10 MB olabilir.'),
          ),
        );
        return;
      }
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Fotoğraf seçilemedi: $error')));
    }
  }

  Future<void> _pickConditionPhoto() async {
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Kondisyon fotoğrafı seç',
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (!mounted || file == null) return;
      final size = await file.length();
      if (!mounted) return;
      if (size != null && size > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf boyutu en fazla 10 MB olabilir.'),
          ),
        );
        return;
      }
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > 10 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fotoğraf boyutu en fazla 10 MB olabilir.'),
          ),
        );
        return;
      }
      setState(() {
        _selectedConditionPhotoBytes = bytes;
        _selectedConditionPhotoName = file.name;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kondisyon fotoğrafı seçilemedi: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onCancel,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: Text(
          widget.initialAntique == null ? 'Yeni Antika Kaydı' : 'Ürünü Düzenle',
        ),
        actions: const [NotificationMenuButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.initialAntique == null
                        ? 'Antika Bilgileri'
                        : 'Ürün Bilgilerini Düzenle',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Antika adı',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Antika adını girin.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Kategori (isteğe bağlı)',
                      helperText: 'Seçmezsen "Diğer" olarak kaydedilir.',
                      border: OutlineInputBorder(),
                    ),
                    items: antiqueCategories
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildPhotoPicker(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _yearController,
                    decoration: const InputDecoration(
                      labelText: 'Antika yılı (isteğe bağlı)',
                      hintText: 'Örn. 1920',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      if (value != null &&
                          value.trim().isNotEmpty &&
                          int.tryParse(value.trim()) == null) {
                        return 'Geçerli bir yıl girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _historyController,
                    decoration: const InputDecoration(
                      labelText: 'Tarihsel geçmişi (isteğe bağlı)',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _conditionController,
                    decoration: const InputDecoration(
                      labelText:
                          'Kondisyon / hasar ve restorasyon notları (isteğe bağlı)',
                      hintText:
                          'Örn. sağ köşede çizik, kulp onarılmış, yüzey temizlenmiş',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    minLines: 3,
                    maxLines: 5,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 12),
                  _buildConditionPhotoPicker(),
                  const SizedBox(height: 16),
                  _buildMoneyField(
                    controller: _valueController,
                    label: 'Satış değeri (₺, isteğe bağlı)',
                  ),
                  const SizedBox(height: 16),
                  _buildMoneyField(
                    controller: _purchasePriceController,
                    label: 'Birim alış bedeli (₺, isteğe bağlı)',
                  ),
                  const SizedBox(height: 16),
                  _buildMoneyField(
                    controller: _extraCostsController,
                    label:
                        'Birim tamir/temizlik ve diğer masraf (₺, isteğe bağlı)',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _locationController,
                    decoration: const InputDecoration(
                      labelText: 'Depo/raf konumu (isteğe bağlı)',
                      hintText: 'Örn. Depo 1 / Raf B-3',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _offerController,
                    decoration: const InputDecoration(
                      labelText: 'Teklif (isteğe bağlı)',
                      hintText: 'Örn. 8500 ₺',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Adet',
                      hintText: 'Örn. 3',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final quantity = int.tryParse(value?.trim() ?? '');
                      final minimum = widget.initialAntique == null ? 1 : 0;
                      if (quantity == null || quantity < minimum) {
                        return widget.initialAntique == null
                            ? 'En az 1 adet girin.'
                            : 'Stok 0 veya daha fazla olmalıdır.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _minimumStockController,
                    decoration: const InputDecoration(
                      labelText: 'Stok uyarı eşiği (adet, isteğe bağlı)',
                      helperText:
                          'Boş bırakırsan 3 kullanılır; 0 girersen uyarı kapanır.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: (value) {
                      final raw = value?.trim() ?? '';
                      if (raw.isEmpty) return null;
                      final threshold = int.tryParse(raw);
                      if (threshold == null || threshold < 0) {
                        return '0 veya daha büyük bir eşik girin.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('İptal'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        onPressed: _save,
                        icon: const Icon(Icons.save_outlined),
                        label: Text(
                          widget.initialAntique == null
                              ? 'Kaydet'
                              : 'Değişiklikleri Kaydet',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    final photoBytes = _selectedPhotoBytes;
    final existingPhotoUrl = widget.initialAntique?.photoUrl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoBytes != null
                  ? Image.memory(photoBytes, fit: BoxFit.cover)
                  : existingPhotoUrl != null
                  ? Image.network(
                      existingPhotoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined, size: 34),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined, size: 34),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedPhotoName ?? 'Ürün fotoğrafı (isteğe bağlı)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text('JPG, PNG veya WEBP • En fazla 10 MB'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickPhoto,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          _selectedPhotoBytes == null
                              ? 'Fotoğraf seç (isteğe bağlı)'
                              : 'Değiştir',
                        ),
                      ),
                      if (_selectedPhotoBytes != null)
                        IconButton(
                          tooltip: 'Fotoğrafı kaldır',
                          onPressed: () => setState(() {
                            _selectedPhotoBytes = null;
                            _selectedPhotoName = null;
                          }),
                          icon: const Icon(Icons.delete_outline),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoneyField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Boş bırakırsan 0 olarak kaydedilir.',
        border: const OutlineInputBorder(),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))],
      validator: (value) {
        final raw = (value ?? '').trim();
        if (raw.isEmpty) return null;
        final parsed = double.tryParse(raw.replaceAll(',', '.'));
        if (parsed == null || !parsed.isFinite || parsed < 0) {
          return '0 veya daha büyük geçerli bir tutar girin.';
        }
        return null;
      },
    );
  }

  Widget _buildConditionPhotoPicker() {
    final photoBytes = _selectedConditionPhotoBytes;
    final photoUrl = widget.initialAntique?.conditionPhotoUrl;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: photoBytes != null
                  ? Image.memory(photoBytes, fit: BoxFit.cover)
                  : photoUrl != null
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const Icon(Icons.broken_image_outlined),
                    )
                  : const Icon(Icons.healing_outlined, size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedConditionPhotoName ??
                        'Kondisyon fotoğrafı (isteğe bağlı)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  const Text('Hasarı veya restorasyonu fotoğraflayın.'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickConditionPhoto,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      photoBytes != null || photoUrl != null
                          ? 'Fotoğrafı değiştir'
                          : 'Fotoğraf seç',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
