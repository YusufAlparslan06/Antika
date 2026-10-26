import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'navigasyon.dart';

class BackupWorkbookData {
  const BackupWorkbookData({
    required this.products,
    required this.auctions,
    required this.sales,
  });

  final List<Map<String, String>> products;
  final List<Map<String, String>> auctions;
  final List<Map<String, String>> sales;
}

class BackupWorkbookParser {
  static BackupWorkbookData parse(List<int> bytes) {
    final workbook = Excel.decodeBytes(bytes);
    final products = _readSheet(workbook, 'Ürünler');
    final auctions = _readSheet(workbook, 'Açık Artırmalar');
    final sales = _readSheet(workbook, 'Satışlar');
    _validateRows(products, 'Kayıt no', 'Ürün');
    _validateRows(auctions, 'Kayıt no', 'Ürün kayıt no');
    _validateRows(sales, 'Kayıt no', 'Ürün');
    if (products.isEmpty) {
      throw const FormatException(
        'Seçilen dosya beklenen ürün/satış/açık artırma sayfalarını içermiyor.',
      );
    }
    return BackupWorkbookData(
      products: products,
      auctions: auctions,
      sales: sales,
    );
  }

  static List<Map<String, String>> _readSheet(Excel workbook, String name) {
    final sheet = workbook.tables[name];
    if (sheet == null || sheet.rows.isEmpty) {
      if (name == 'Açık Artırmalar' || name == 'Satışlar') return [];
      throw FormatException('Excel dosyasında "$name" sayfası bulunamadı.');
    }
    final headers = sheet.rows.first.map(_cellText).toList();
    final result = <Map<String, String>>[];
    for (final row in sheet.rows.skip(1)) {
      final values = <String, String>{};
      for (
        var index = 0;
        index < headers.length && index < row.length;
        index++
      ) {
        final header = headers[index].trim();
        if (header.isNotEmpty) values[header] = _cellText(row[index]).trim();
      }
      if (values.values.any((value) => value.isNotEmpty)) result.add(values);
    }
    return result;
  }

  static String _cellText(Data? cell) {
    final value = cell?.value;
    if (value == null) return '';
    return switch (value) {
      TextCellValue(:final value) => value.text ?? '',
      IntCellValue(:final value) => value.toString(),
      DoubleCellValue(:final value) => value.toString(),
      BoolCellValue(:final value) => value.toString(),
      DateCellValue() => value.toString(),
      TimeCellValue() => value.toString(),
      DateTimeCellValue() => value.toString(),
      FormulaCellValue(:final formula) => formula,
    };
  }

  static void _validateRows(
    List<Map<String, String>> rows,
    String idColumn,
    String requiredColumn,
  ) {
    for (var index = 0; index < rows.length; index++) {
      final row = rows[index];
      if (int.tryParse(row[idColumn] ?? '') == null ||
          (row[requiredColumn] ?? '').isEmpty) {
        throw FormatException(
          '${index + 2}. satırda kayıt numarası veya zorunlu alan hatalı.',
        );
      }
    }
  }

  static String? normalizeDate(String? value) {
    if (value == null || value.isEmpty) return value;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toIso8601String();
    final localized = RegExp(r'^(\d{2})\.(\d{2})\.(\d{4})$').firstMatch(value);
    if (localized == null) return value;
    return DateTime(
      int.parse(localized.group(3)!),
      int.parse(localized.group(2)!),
      int.parse(localized.group(1)!),
    ).toIso8601String();
  }
}

class BackupImportPage extends StatefulWidget {
  const BackupImportPage({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<BackupImportPage> createState() => _BackupImportPageState();
}

class _BackupImportPageState extends State<BackupImportPage> {
  List<Map<String, String>> _products = [];
  List<Map<String, String>> _auctions = [];
  List<Map<String, String>> _sales = [];
  String? _fileName;
  String? _error;
  bool _isImporting = false;
  bool _isReading = false;

  Future<void> _selectBackup() async {
    setState(() {
      _isReading = true;
      _error = null;
      _fileName = null;
      _products = [];
      _auctions = [];
      _sales = [];
    });
    try {
      final file = await FilePicker.pickFile(
        dialogTitle: 'Eskilerden Excel yedeğini seç',
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
      );
      if (file == null) {
        if (mounted) setState(() => _isReading = false);
        return;
      }
      final bytes = await file.readAsBytes();
      final parsed = BackupWorkbookParser.parse(bytes);
      if (!mounted) return;
      setState(() {
        _fileName = file.name;
        _products = parsed.products;
        _auctions = parsed.auctions;
        _sales = parsed.sales;
        _isReading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isReading = false;
      });
    }
  }

  Future<void> _import() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yedeği içe aktar'),
        content: const Text(
          'Yedekteki kayıt numaraları mevcut kayıtlarla eşleştirilir. '
          'Eşleşen kayıtlar güncellenir, yeniler eklenir. Yedekte olmayan '
          'mevcut kayıtlar silinmez. Bu işlem geri alınamaz; devam etmeden '
          'önce güncel dışa aktarım al.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('İçe aktar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _isImporting = true;
      _error = null;
    });
    try {
      final result = await Supabase.instance.client.rpc(
        'yedek_verisini_aktar',
        params: {
          'p_urunler': _products,
          'p_acik_artirmalar': _auctions
              .map(
                (row) => {
                  ...row,
                  'Başlangıç tarihi': BackupWorkbookParser.normalizeDate(
                    row['Başlangıç tarihi'],
                  ),
                  'Bitiş tarihi': BackupWorkbookParser.normalizeDate(
                    row['Bitiş tarihi'],
                  ),
                },
              )
              .toList(),
          'p_satislar': _sales
              .map(
                (row) => {
                  ...row,
                  'Satış tarihi': BackupWorkbookParser.normalizeDate(
                    row['Satış tarihi'],
                  ),
                },
              )
              .toList(),
        },
      );
      if (!mounted) return;
      final counts = Map<String, dynamic>.from(result as Map);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'İçe aktarıldı: ${counts['products']} ürün, '
            '${counts['auctions']} açık artırma, ${counts['sales']} satış.',
          ),
        ),
      );
      widget.onBack();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'İçe aktarma başarısız: $error');
    } finally {
      if (mounted) setState(() => _isImporting = false);
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
        title: const Text('Yedekten geri yükle'),
        actions: const [NotificationMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Card(
            child: ListTile(
              leading: Icon(Icons.security_outlined),
              title: Text('Yönetici yetkisi gerekir'),
              subtitle: Text(
                'Yalnızca uygulamanın Excel yedeği içe alınabilir. '
                'Kayıtlar ID ile eşleşir; yedekte bulunmayan mevcut veriler silinmez.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _isReading || _isImporting ? null : _selectBackup,
            icon: _isReading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open_outlined),
            label: Text(_fileName ?? 'Excel yedek dosyası seç'),
          ),
          if (_fileName != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _PreviewRow(label: 'Ürün', count: _products.length),
                  _PreviewRow(label: 'Açık artırma', count: _auctions.length),
                  _PreviewRow(label: 'Satış', count: _sales.length),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isImporting ? null : _import,
              icon: _isImporting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restore),
              label: const Text('Önizlenen verileri içe aktar'),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            SelectableText(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) =>
      ListTile(title: Text('$label kaydı'), trailing: Text(count.toString()));
}
