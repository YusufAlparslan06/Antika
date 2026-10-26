import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ayarlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';

class AuctionPage extends StatefulWidget {
  const AuctionPage({
    super.key,
    required this.auctions,
    required this.antiques,
    required this.onBack,
    required this.onCreateAuction,
    required this.onDelete,
    required this.onUpdateResults,
    required this.canDelete,
  });

  final List<Auction> auctions;
  final List<Antique> antiques;
  final VoidCallback onBack;
  final VoidCallback onCreateAuction;
  final Future<void> Function(Auction) onDelete;
  final Future<void> Function(Auction) onUpdateResults;
  final bool canDelete;

  @override
  State<AuctionPage> createState() => _AuctionPageState();
}

class _AuctionPageState extends State<AuctionPage> {
  String _selectedStatus = 'Tümü';
  String _productSearchText = '';

  List<Auction> get _filteredAuctions {
    return widget.auctions.where((auction) {
      final matchesStatus =
          _selectedStatus == 'Tümü' || auction.status == _selectedStatus;
      final query = _productSearchText.trim().toLowerCase();
      if (query.isEmpty) return matchesStatus;
      final product = widget.antiques
          .where((antique) => antique.id == auction.productId)
          .firstOrNull;
      final matchesProduct =
          product?.name.toLowerCase().contains(query) == true ||
          product?.category.toLowerCase().contains(query) == true ||
          'ürün #${auction.productId}'.contains(query);
      return matchesStatus && matchesProduct;
    }).toList();
  }

  Future<void> _showAuctionDetails(Auction auction, Antique? product) {
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
                      Container(
                        width: double.infinity,
                        height: screenHeight * 0.46,
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: product?.photoUrl == null
                            ? const Icon(
                                Icons.image_not_supported_outlined,
                                size: 72,
                              )
                            : Image.network(
                                product!.photoUrl!,
                                fit: BoxFit.contain,
                                errorBuilder: (_, _, _) => const Icon(
                                  Icons.broken_image_outlined,
                                  size: 72,
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        product?.name ?? 'Ürün #${auction.productId}',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      if (product != null) ...[
                        _AuctionDetailRow(
                          label: 'Kategori',
                          value: product.category,
                        ),
                        _AuctionDetailRow(
                          label: 'Antika yılı',
                          value: product.year == 0
                              ? 'Belirtilmemiş'
                              : '${product.year}',
                        ),
                        _AuctionDetailRow(
                          label: 'Değeri',
                          value: formatCurrency(product.value),
                        ),
                        _AuctionDetailRow(
                          label: 'Adet',
                          value: formatNumber(product.quantity),
                        ),
                        _AuctionDetailRow(
                          label: 'Tarihsel geçmişi',
                          value: product.history.isEmpty
                              ? 'Bilgi girilmemiş.'
                              : product.history,
                        ),
                        _AuctionDetailRow(
                          label: 'Kondisyon',
                          value: product.condition.isEmpty
                              ? 'Not girilmemiş.'
                              : product.condition,
                        ),
                        if (product.conditionPhotoUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product.conditionPhotoUrl!,
                              height: 200,
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const Icon(
                                Icons.broken_image_outlined,
                                size: 48,
                              ),
                            ),
                          ),
                      ],
                      _AuctionDetailRow(
                        label: 'Açık artırma yeri',
                        value:
                            product == null || product.auctionLocation.isEmpty
                            ? 'Belirtilmemiş'
                            : product.auctionLocation,
                      ),
                      _AuctionDetailRow(
                        label: 'Başlangıç fiyatı',
                        value: formatCurrency(auction.startingPrice),
                      ),
                      _AuctionDetailRow(
                        label: 'Mevcut teklif',
                        value: formatCurrency(auction.currentBid),
                      ),
                      _AuctionDetailRow(
                        label: 'Başlangıç tarihi',
                        value: formatDate(auction.startDate),
                      ),
                      _AuctionDetailRow(
                        label: 'Bitiş tarihi',
                        value: formatDate(auction.endDate),
                      ),
                      _AuctionDetailRow(label: 'Durum', value: auction.status),
                      const SizedBox(height: 12),
                      Text(
                        'Açık artırma sonucu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      _AuctionDetailRow(
                        label: 'Kazanan',
                        value: auction.winner.isEmpty
                            ? 'Belirtilmedi (isteğe bağlı)'
                            : auction.winner,
                      ),
                      _AuctionDetailRow(
                        label: 'Son satış tutarı',
                        value: auction.finalPrice <= 0
                            ? 'Belirtilmedi (isteğe bağlı)'
                            : formatCurrency(auction.finalPrice),
                      ),
                      _AuctionDetailRow(
                        label: 'Ödeme',
                        value: auction.paymentStatus,
                      ),
                      _AuctionDetailRow(
                        label: 'Teslimat',
                        value: auction.deliveryStatus,
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () async {
                          final updated = await _showAuctionResultEditor(
                            auction,
                          );
                          if (updated == null || !dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          await widget.onUpdateResults(updated);
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Sonuçları düzenle'),
                      ),
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

  Future<Auction?> _showAuctionResultEditor(Auction auction) async {
    final winnerController = TextEditingController(text: auction.winner);
    final priceController = TextEditingController(
      text: auction.finalPrice > 0 ? auction.finalPrice.toStringAsFixed(2) : '',
    );
    var paymentStatus = auction.paymentStatus;
    var deliveryStatus = auction.deliveryStatus;
    final formKey = GlobalKey<FormState>();
    try {
      return await showDialog<Auction>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Açık artırma sonucunu kaydet'),
            content: SizedBox(
              width: 420,
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: winnerController,
                        decoration: const InputDecoration(
                          labelText: 'Kazanan / alıcı (isteğe bağlı)',
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: priceController,
                        decoration: const InputDecoration(
                          labelText: 'Son satış tutarı (₺, isteğe bağlı)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                        ],
                        validator: (value) {
                          final raw = value?.trim() ?? '';
                          if (raw.isEmpty) return null;
                          final amount = double.tryParse(
                            raw.replaceAll(',', '.'),
                          );
                          if (amount == null || amount < 0) {
                            return 'Geçerli bir tutar girin.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: paymentStatus,
                        decoration: const InputDecoration(
                          labelText: 'Ödeme durumu',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bekliyor',
                            child: Text('Bekliyor'),
                          ),
                          DropdownMenuItem(
                            value: 'Kısmi ödendi',
                            child: Text('Kısmi ödendi'),
                          ),
                          DropdownMenuItem(
                            value: 'Ödendi',
                            child: Text('Ödendi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => paymentStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: deliveryStatus,
                        decoration: const InputDecoration(
                          labelText: 'Teslimat durumu',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bekliyor',
                            child: Text('Bekliyor'),
                          ),
                          DropdownMenuItem(
                            value: 'Hazırlanıyor',
                            child: Text('Hazırlanıyor'),
                          ),
                          DropdownMenuItem(
                            value: 'Kargoda',
                            child: Text('Kargoda'),
                          ),
                          DropdownMenuItem(
                            value: 'Teslim edildi',
                            child: Text('Teslim edildi'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => deliveryStatus = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
              FilledButton(
                onPressed: () {
                  if (!formKey.currentState!.validate()) return;
                  Navigator.pop(
                    dialogContext,
                    Auction(
                      id: auction.id,
                      productId: auction.productId,
                      startingPrice: auction.startingPrice,
                      currentBid: auction.currentBid,
                      startDate: auction.startDate,
                      endDate: auction.endDate,
                      status: auction.status,
                      auctionLocation: auction.auctionLocation,
                      winner: winnerController.text.trim(),
                      finalPrice:
                          double.tryParse(
                            priceController.text.trim().replaceAll(',', '.'),
                          ) ??
                          0,
                      paymentStatus: paymentStatus,
                      deliveryStatus: deliveryStatus,
                    ),
                  );
                },
                child: const Text('Kaydet'),
              ),
            ],
          ),
        ),
      );
    } finally {
      winnerController.dispose();
      priceController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusOptions = ['Tümü', 'Aktif', 'Bekliyor', 'Tamamlandı', 'İptal'];
    final visibleAuctions = _filteredAuctions;
    final antiquesById = {
      for (final antique in widget.antiques)
        if (antique.id != null) antique.id!: antique,
    };

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Menüye dön',
        ),
        title: const Text('Açık Artırma'),
        actions: [
          const NotificationMenuButton(),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: FilledButton.icon(
              onPressed: widget.onCreateAuction,
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
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Durum filtresi',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                    ),
                    items: statusOptions
                        .map(
                          (status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
                    },
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Ürün ara',
                      hintText: 'Ürün adı veya kategori',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _productSearchText = value);
                    },
                  ),
                ),
                Text('${visibleAuctions.length} açık artırma'),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                clipBehavior: Clip.antiAlias,
                child: visibleAuctions.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.gavel_outlined,
                                size: 48,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                widget.auctions.isEmpty
                                    ? 'Henüz açık artırma kaydı yok.'
                                    : 'Bu duruma uygun açık artırma bulunamadı.',
                                style: Theme.of(context).textTheme.titleMedium,
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
                              DataColumn(label: Text('Ürün')),
                              DataColumn(label: Text('Kategori')),
                              DataColumn(label: Text('Stok')),
                              DataColumn(label: Text('Ürün Değeri')),
                              DataColumn(label: Text('Açık Artırma Yeri')),
                              DataColumn(label: Text('Başlangıç Fiyatı')),
                              DataColumn(label: Text('Mevcut Teklif')),
                              DataColumn(label: Text('Başlangıç Tarihi')),
                              DataColumn(label: Text('Bitiş Tarihi')),
                              DataColumn(label: Text('Durum')),
                              DataColumn(label: Text('İşlem')),
                            ],
                            rows: visibleAuctions.map((auction) {
                              final product = antiquesById[auction.productId];
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      product?.name ??
                                          'Ürün #${auction.productId}',
                                    ),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(product?.category ?? '—'),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(
                                      product == null
                                          ? '—'
                                          : '${formatNumber(product.quantity)} adet',
                                    ),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(
                                      product == null
                                          ? '—'
                                          : formatCurrency(product.value),
                                    ),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(
                                      product == null ||
                                              product.auctionLocation.isEmpty
                                          ? '—'
                                          : product.auctionLocation,
                                    ),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(formatCurrency(auction.startingPrice)),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(formatCurrency(auction.currentBid)),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(formatDate(auction.startDate)),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(formatDate(auction.endDate)),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    Text(auction.status),
                                    onTap: () =>
                                        _showAuctionDetails(auction, product),
                                  ),
                                  DataCell(
                                    widget.canDelete
                                        ? IconButton(
                                            tooltip: 'Açık artırmayı sil',
                                            icon: const Icon(
                                              Icons.delete_outline,
                                              color: Color(0xFFFF6B6B),
                                            ),
                                            onPressed: () =>
                                                widget.onDelete(auction),
                                          )
                                        : const SizedBox.shrink(),
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
}

class AddAuctionPage extends StatefulWidget {
  const AddAuctionPage({
    super.key,
    required this.antiques,
    required this.onCancel,
    required this.onSave,
  });

  final List<Antique> antiques;
  final VoidCallback onCancel;
  final Future<void> Function(Auction) onSave;

  @override
  State<AddAuctionPage> createState() => _AddAuctionPageState();
}

class _AddAuctionPageState extends State<AddAuctionPage> {
  final _formKey = GlobalKey<FormState>();
  final _startingPriceController = TextEditingController();
  final _currentBidController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _auctionLocationController = TextEditingController();
  String _selectedStatus = 'Aktif';
  int? _selectedProductId;

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
    final firstAntique = _availableAntiques.firstOrNull;
    _selectedProductId = firstAntique?.id;
    if (firstAntique != null) {
      _startingPriceController.text = firstAntique.value.toStringAsFixed(2);
      _currentBidController.text = '0';
    }
  }

  @override
  void dispose() {
    _startingPriceController.dispose();
    _currentBidController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _auctionLocationController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final productId = _selectedProductId;
    if (productId == null) return;

    final startDate = DateTime.tryParse(_startDateController.text.trim());
    final endDate = DateTime.tryParse(_endDateController.text.trim());

    if (startDate == null || endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Başlangıç ve bitiş tarihleri için geçerli tarih girin.',
          ),
        ),
      );
      return;
    }

    await widget.onSave(
      Auction(
        productId: productId,
        startingPrice: double.parse(
          _startingPriceController.text.trim().replaceAll(',', '.'),
        ),
        currentBid:
            double.tryParse(
              _currentBidController.text.trim().replaceAll(',', '.'),
            ) ??
            0,
        startDate: startDate,
        endDate: endDate,
        status: _selectedStatus,
        auctionLocation: _auctionLocationController.text.trim(),
      ),
    );
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
        title: const Text('Yeni Açık Artırma'),
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
                    'Açık Artırma Bilgileri',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 20),
                  if (_availableAntiques.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Açık artırma oluşturmak için stokta ürünü olan '
                          'bir antika kaydı bulunmalıdır.',
                        ),
                      ),
                    )
                  else ...[
                    DropdownButtonFormField<int>(
                      initialValue: _selectedProductId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Ürün seç',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableAntiques
                          .map(
                            (antique) => DropdownMenuItem<int>(
                              value: antique.id,
                              child: Text(
                                '${antique.name} • ${antique.category} • '
                                'Stok: ${formatNumber(antique.quantity)} • '
                                '${formatCurrency(antique.value)}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      validator: (value) =>
                          value == null ? 'Bir ürün seçin.' : null,
                      onChanged: (id) {
                        final selected = _availableAntiques
                            .where((antique) => antique.id == id)
                            .firstOrNull;
                        setState(() {
                          _selectedProductId = id;
                          if (selected != null) {
                            _startingPriceController.text = selected.value
                                .toStringAsFixed(2);
                          }
                        });
                      },
                    ),
                    if (_selectedAntique != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        'Seçilen ürün: ${_selectedAntique!.name} • '
                        '${_selectedAntique!.category} • '
                        '${formatNumber(_selectedAntique!.quantity)} adet stok • '
                        '${formatCurrency(_selectedAntique!.value)}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _auctionLocationController,
                    decoration: const InputDecoration(
                      labelText: 'Açık artırma yeri (isteğe bağlı)',
                      hintText: 'Örn. İstanbul / Online',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startingPriceController,
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç fiyatı (₺)',
                      hintText: 'Örn. 2500',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    validator: (value) =>
                        validateAuctionAmount(value, 'Başlangıç fiyatı'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _currentBidController,
                    decoration: const InputDecoration(
                      labelText: 'Mevcut teklif (₺, isteğe bağlı)',
                      hintText: 'Örn. 3200',
                      helperText: 'Boş bırakırsan 0 olarak kaydedilir.',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) return null;
                      return validateAuctionAmount(value, 'Mevcut teklif');
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _startDateController,
                    decoration: const InputDecoration(
                      labelText: 'Başlangıç tarihi',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Başlangıç tarihini girin.';
                      }
                      return DateTime.tryParse(value.trim()) == null
                          ? 'Geçerli tarih girin.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _endDateController,
                    decoration: const InputDecoration(
                      labelText: 'Bitiş tarihi',
                      hintText: 'YYYY-MM-DD',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Bitiş tarihini girin.';
                      }
                      return DateTime.tryParse(value.trim()) == null
                          ? 'Geçerli tarih girin.'
                          : null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Durum',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Aktif', child: Text('Aktif')),
                      DropdownMenuItem(
                        value: 'Bekliyor',
                        child: Text('Bekliyor'),
                      ),
                      DropdownMenuItem(
                        value: 'Tamamlandı',
                        child: Text('Tamamlandı'),
                      ),
                      DropdownMenuItem(value: 'İptal', child: Text('İptal')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStatus = value);
                      }
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
                        label: const Text('Kaydet'),
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
}

class _AuctionDetailRow extends StatelessWidget {
  const _AuctionDetailRow({required this.label, required this.value});

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
