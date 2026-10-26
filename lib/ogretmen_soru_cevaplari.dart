/// Öğretmenin sorabileceği temel kod konuları için bağımsız çalışma notları.
///
/// Örnekler ilgili kaynak kodun kısa alıntılarıdır; uygulama çalışma akışına
/// dahil edilmez. Tam uygulama için [source] alanındaki dosyayı inceleyin.
class OgretmenKonu {
  const OgretmenKonu({
    required this.title,
    required this.question,
    required this.answer,
    required this.source,
    required this.code,
  });

  final String title;
  final String question;
  final String answer;
  final String source;
  final String code;
}

const ogretmenSorulari = <OgretmenKonu>[
  OgretmenKonu(
    title: 'Ürün ekleme formu',
    question: 'Ürün formu nasıl doğrulanıp kaydedilmeye gönderiliyor?',
    answer:
        'Formdaki alanlar controller ile okunur. Önce Form validator’ları '
        'çalıştırılır; geçerli değilse kayıt durur. Geçerliyse alanlar Antique '
        'modeline dönüştürülüp üst ekrandaki onSave callback’ine verilir.',
    source: 'lib/antika.dart — AddAntiquePage._save',
    code: r'''
if (!_formKey.currentState!.validate()) return;

await widget.onSave(
  Antique(
    name: _nameController.text.trim(),
    category: _selectedCategory,
    year: int.tryParse(_yearController.text.trim()) ?? 0,
    quantity: int.parse(_quantityController.text.trim()),
    // Diğer form alanları da Antique modeline aktarılır.
  ),
);
''',
  ),
  OgretmenKonu(
    title: 'Ürün modeli',
    question: 'Antique sınıfı ne işe yarıyor?',
    answer:
        'Ürünün kimlik, ad, kategori, fiyat, stok ve fotoğraf gibi alanlarını '
        'tek bir tipte toplar. Form, liste ve veritabanı katmanları bu modeli '
        'kullanarak veri aktarır.',
    source: 'lib/modeller.dart — Antique',
    code: r'''
class Antique {
  const Antique({
    this.id,
    required this.name,
    required this.category,
    required this.year,
    required this.quantity,
    // Ürünün diğer özellikleri...
  });

  final int? id;
  final String name;
  final String category;
  final int year;
  final int quantity;
}
''',
  ),
  OgretmenKonu(
    title: 'Ürünü veritabanına kaydetme',
    question: 'Yeni ürün Supabase’e nasıl ekleniyor?',
    answer:
        'Formdan gelen Antique nesnesi tablo sütunlarına eşlenir. Supabase '
        'insert ile kayıt ekler; select(id).single() yeni ürünün veritabanı '
        'kimliğini döndürür.',
    source: 'lib/yonetim.dart — _insertAntique',
    code: r'''
final result = await _supabase
    .from('urunler')
    .insert({
      'ad': antique.name,
      'kategori': antique.category,
      'antika_yili': antique.year,
      'stok': antique.quantity,
      'satis_fiyati': antique.value,
    })
    .select('id')
    .single();
''',
  ),
  OgretmenKonu(
    title: 'Ürünleri listeleme',
    question: 'Uygulama açılınca ürünler veritabanından nasıl çekiliyor?',
    answer:
        'urunler tablosundan select sorgusu yapılır, kayıtlar id sırasına '
        'göre alınır ve her satır Antique modeline çevrilerek uygulama '
        'listesine konur.',
    source: 'lib/yonetim.dart — _loadAntiques',
    code: r'''
final rows = await _supabase
    .from('urunler')
    .select()
    .order('id');

final loaded = (rows as List).map((row) {
  final item = Map<String, dynamic>.from(row as Map);
  return Antique(
    id: (item['id'] as num).toInt(),
    name: (item['ad'] ?? '').toString(),
    // Veritabanındaki diğer sütunlar da modele çevrilir.
  );
}).toList();
''',
  ),
  OgretmenKonu(
    title: 'Fotoğraf yükleme',
    question: 'Ürün fotoğrafı nerede saklanıyor?',
    answer:
        'Fotoğrafın baytları Supabase Storage’daki urun-fotograflari '
        'bucket’ına yüklenir. Ürün kimliği ve dosya türü yol/Content-Type '
        'belirlemede kullanılır; dönen public URL ürün tablosuna yazılır.',
    source: 'lib/yonetim.dart — _uploadAntiquePhoto',
    code: r'''
await _supabase.storage
    .from('urun-fotograflari')
    .uploadBinary(
      '$id/kapak',
      bytes,
      fileOptions: FileOptions(contentType: contentType, upsert: true),
    );

return _supabase.storage
    .from('urun-fotograflari')
    .getPublicUrl('$id/kapak');
''',
  ),
  OgretmenKonu(
    title: 'Arama ve kategori filtresi',
    question: 'Ürün listesinde arama ve kategori seçimi nasıl çalışıyor?',
    answer:
        'where ile ürünler filtrelenir. Arama ürün adı veya konumda, '
        'kategori filtresi de seçilen kategoride eşleşme arar. İki koşul '
        'birlikte sağlanmalıdır.',
    source: 'lib/antika.dart — _filteredAntiques',
    code: r'''
return widget.antiques.where((antique) {
  final matchesCategory =
      _selectedCategory == 'Tüm kategoriler' ||
      antique.category == _selectedCategory;
  final matchesSearch =
      antique.name.toLowerCase().contains(_searchText.toLowerCase()) ||
      antique.location.toLowerCase().contains(_searchText.toLowerCase());
  return matchesCategory && matchesSearch;
}).toList();
''',
  ),
  OgretmenKonu(
    title: 'Giriş ve hesap oluşturma',
    question: 'E-posta ile giriş ve kayıt nasıl yapılıyor?',
    answer:
        'Form doğrulandıktan sonra Supabase Auth kullanılır. Kayıtta '
        'signUp, girişte signInWithPassword çağrılır; hata olursa ekranda '
        'kullanıcıya gösterilir.',
    source: 'lib/giris.dart — _submit',
    code: r'''
if (_isSignUp) {
  await auth.signUp(
    email: _emailController.text.trim().toLowerCase(),
    password: _passwordController.text,
    data: {'full_name': _nameController.text.trim()},
  );
} else {
  await auth.signInWithPassword(
    email: _emailController.text.trim().toLowerCase(),
    password: _passwordController.text,
  );
}
''',
  ),
  OgretmenKonu(
    title: 'Satış ve stok güncelleme',
    question: 'Satış kaydı stoktan düşmeyi nasıl sağlıyor?',
    answer:
        'Uygulama Supabase’teki satis_olustur fonksiyonunu RPC ile çağırır. '
        'Satış ve stok güncellemesi veritabanı fonksiyonunda birlikte '
        'yürütülür; başarılı olunca ürün, satış ve stok hareketi listeleri '
        'yenilenir.',
    source: 'lib/yonetim.dart — _saveSale; SQL: supabase/urunler_schema.sql',
    code: r'''
await _supabase.rpc(
  'satis_olustur',
  params: {
    'p_urun_id': antique.id,
    'p_adet': quantity,
    'p_birim_fiyat': unitPrice,
    'p_alici': buyer,
  },
);
''',
  ),
  OgretmenKonu(
    title: 'Rol ve yetki kontrolü',
    question: 'Yönetici ile personelin yetkileri nasıl ayrılıyor?',
    answer:
        'Kullanıcının rolü kullanici_rolleri tablosundan okunur. Arayüz '
        'yöneticiye özel işlemleri buna göre gösterir; asıl erişim kontrolü '
        'Supabase Row Level Security politikalarıyla veritabanında da yapılır.',
    source:
        'lib/yonetim.dart — _loadCurrentRole; SQL: supabase/urunler_schema.sql',
    code: r'''
final row = await _supabase
    .from('kullanici_rolleri')
    .select('rol')
    .eq('kullanici_id', user.id)
    .maybeSingle();

_currentRole = (row?['rol'] ?? 'personel').toString();
''',
  ),
  OgretmenKonu(
    title: 'Ürün silme ve güvenlik',
    question: 'Ürün silme işlemi nasıl korunuyor?',
    answer:
        'Önce kullanıcıdan onay istenir. Ardından ürün id ile silinir ve '
        'silinen satır kontrol edilir. Uygulama arayüzündeki kontrolün yanında '
        'Supabase RLS politikası da silme yetkisini yöneticiyle sınırlar.',
    source:
        'lib/yonetim.dart — _deleteAntique; SQL: supabase/urunler_schema.sql',
    code: r'''
final deletedRows = await _supabase
    .from('urunler')
    .delete()
    .eq('id', antique.id!)
    .select('id');

if (deletedRows.isEmpty) {
  throw StateError('Ürün silinemedi veya silme yetkisi yok.');
}
''',
  ),
  OgretmenKonu(
    title: 'Ortak mesajlaşma',
    question: 'Farklı oturumlar mesajları nasıl ortak görüyor?',
    answer:
        'Mesajlar ortak Supabase tablosuna yazılır ve oturum açmış '
        'kullanıcılar tarafından okunur. Her mesajın yanında gönderen adı '
        've veritabanındaki rolü gösterilir.',
    source: 'lib/mesajlar.dart — _loadMessages ve _sendMessage',
    code: r'''
final rows = await _supabase
    .from('uygulama_mesajlari')
    .select('id, gonderen_id, gonderen_adi, gonderen_rol, mesaj, created_at')
    .gt('id', _lastMessageId)
    .order('id')
    .limit(250);
''',
  ),
];
