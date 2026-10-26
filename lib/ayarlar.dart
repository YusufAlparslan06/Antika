const String supabaseUrl = 'https://rvwwrhyeknagygybbvqz.supabase.co';
const String supabasePublishableKey =
    'sb_publishable_7dmqmOpXQSPj2uztm7yfjw_QUswItSv';

const List<String> antiqueCategories = [
  'Bakır ve Pirinç Eşyalar',
  'Saatler ve Koleksiyonluk Ürünler',
  'Seramik ve Porselen',
  'Kitap, Belge ve Hat Eserleri',
  'Mobilya ve Dekorasyon',
  'Para, Madalya ve Koleksiyon',
  'Diğer',
];

String? validateAuctionAmount(String? value, String fieldName) {
  final input = value?.trim() ?? '';
  if (input.isEmpty) return '$fieldName girin.';

  final normalized = input.replaceAll(',', '.');
  final amount = double.tryParse(normalized);
  if (amount == null || !amount.isFinite || amount < 0) {
    return 'Geçerli bir $fieldName girin.';
  }
  if (amount >= 10000000000) {
    return '$fieldName en fazla 9.999.999.999,99 ₺ olabilir.';
  }
  final decimalPart = normalized.split('.').elementAtOrNull(1);
  if (decimalPart != null && decimalPart.length > 2) {
    return '$fieldName en fazla 2 ondalık basamak içerebilir.';
  }
  return null;
}

String formatNumber(num value, {int decimalDigits = 0}) {
  final fixed = value.toStringAsFixed(decimalDigits);
  final parts = fixed.split('.');
  final isNegative = parts.first.startsWith('-');
  final integer = isNegative ? parts.first.substring(1) : parts.first;
  final groupedInteger = integer.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );
  final sign = isNegative ? '-' : '';
  if (decimalDigits == 0) return '$sign$groupedInteger';
  return '$sign$groupedInteger,${parts[1]}';
}

String formatCurrency(num value) =>
    '${formatNumber(value, decimalDigits: 2)} ₺';

String formatDate(DateTime value) {
  final date = value.toLocal();
  return '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.'
      '${date.year}';
}
