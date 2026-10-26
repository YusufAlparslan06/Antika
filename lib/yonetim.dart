import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'acik_artirma.dart';
import 'antika.dart';
import 'ayarlar.dart';
import 'ayarlar_ekrani.dart';
import 'kisayollar.dart';
import 'kullanicilar.dart';
import 'mesajlar.dart';
import 'modeller.dart';
import 'navigasyon.dart';
import 'ortak.dart';
import 'operasyon_ekranlari.dart';
import 'operasyon_servisleri.dart';
import 'raporlar.dart';
import 'satis.dart';
import 'stok.dart';
import 'tema.dart';
import 'ana_sayfa.dart';
import 'yedek_ice_aktar.dart';

class AntiqueAdminPage extends StatefulWidget {
  const AntiqueAdminPage({super.key});

  @override
  State<AntiqueAdminPage> createState() => _AntiqueAdminPageState();
}

class _AntiqueAdminPageState extends State<AntiqueAdminPage> {
  final List<Antique> _antiques = [];
  final List<Auction> _auctions = [];
  final List<AntiqueSale> _sales = [];
  final List<StockMovement> _stockMovements = [];
  Antique? _editingAntique;
  AdminPage _currentPage = AdminPage.menu;
  AdminPage? _quickAccessPanel;
  bool _isLoading = true;
  bool _isRoleLoading = true;
  String _currentRole = 'personel';
  bool _isLoadingUsers = false;
  List<AppUser> _users = [];
  String? _usersError;
  String? _loadError;
  String? _salesError;
  String? _stockMovementsError;
  bool _usingOfflineCache = false;
  Antique? _timelineProduct;

  SupabaseClient get _supabase => Supabase.instance.client;

  Future<void> _showChangeHistory() {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Değişiklik Geçmişi'),
        content: SizedBox(
          width: 420,
          height: 420,
          child: ListView(
            shrinkWrap: true,
            children: const [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Text(
                  'Uygulamaya eklenen önemli özellikler ve düzenlemeler.',
                ),
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: Icon(Icons.new_releases_outlined),
                title: Text('v1.6.0  •  Envanter ve veri güvenliği'),
                subtitle: Text('26 Ekim 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Fiziksel stokları karşılaştırıp farkları kaydetmek için envanter sayımı eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Ürün, satış ve açık artırma işlemleri için kullanıcı bilgili işlem geçmişi ve ürün zaman çizelgesi eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Düşük stok ve 7 gün içinde bitecek açık artırmalar için ana ekran hatırlatmaları eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Ürün önbelleği ve çevrimdışı envanter sayımı kuyruğu eklendi; eşitleme stok çakışmalarını kontrol eder.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Excel yedeği için önizlemeli, mevcut kayıtları silmeyen ve yönetici yetkisi gerektiren geri yükleme eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Excel dışa aktarımına ürün, satış ve açık artırma ayrıntıları eklendi; tema tercihi kalıcı hale getirildi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Satışlar Kısayollar panelinden sol ana menüye taşındı.',
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: Icon(Icons.new_releases_outlined),
                title: Text('v1.5.0  •  Ayarlar ve mesajlaşma'),
                subtitle: Text('26 Ekim 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Görünüm ayarları ayrı ekrana taşındı ve uyumlu vurgu renkleri eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Farklı kullanıcı oturumları için ortak mesajlaşma eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Satış geçmişi korunarak ürün silme ve yetki uyarıları iyileştirildi.',
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('v1.4.0  •  Ürün değerlendirme ve formlar'),
                subtitle: Text('26 Ekim 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Ürünlere kondisyon notu ve hasar/restorasyon fotoğrafı ekleme eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Açık artırmalarda kazanan, satış tutarı, ödeme ve teslimat takibi eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Ürün ve açık artırma formlarındaki gereksiz zorunlu alanlar isteğe bağlı yapıldı.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(
                      'Dart dosyalarının adları sadeleştirildi ve ekran bölümleri işaretlendi.',
                    ),
                  ),
                ],
              ),
              ExpansionTile(
                initiallyExpanded: true,
                leading: Icon(Icons.new_releases_outlined),
                title: Text('v1.3.0  •  Arayüz ve düzenlemeler'),
                subtitle: Text('25 Ekim 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Kodlar özelliklerine göre ayrı dosyalara bölündü.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text('Eskilerden logosu menüye eklendi.'),
                  ),
                  ListTile(
                    dense: true,
                    title: Text('“Yeni Ürün Ekle” menü öğesi kaldırıldı.'),
                  ),
                ],
              ),
              ExpansionTile(
                leading: Icon(Icons.insights_outlined),
                title: Text('v1.2.0  •  Raporlama ve görünüm'),
                subtitle: Text('15 Ekim 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text('Raporlar ve müşteri özeti eklendi.'),
                  ),
                  ListTile(
                    dense: true,
                    title: Text('Açık ve koyu tema seçeneği eklendi.'),
                  ),
                ],
              ),
              ExpansionTile(
                leading: Icon(Icons.point_of_sale_outlined),
                title: Text('v1.1.0  •  Satış ve açık artırma'),
                subtitle: Text('24 Eylül 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text('Açık artırma oluşturma ve listeleme eklendi.'),
                  ),
                  ListTile(
                    dense: true,
                    title: Text('Satış kaydı ve stok hareketi takibi eklendi.'),
                  ),
                ],
              ),
              ExpansionTile(
                leading: Icon(Icons.inventory_2_outlined),
                title: Text('v1.0.0  •  İlk envanter sürümü'),
                subtitle: Text('12 Eylül 2026'),
                children: [
                  ListTile(
                    dense: true,
                    title: Text(
                      'Antika ürün kayıtları ve kategoriler eklendi.',
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text('Ürün listesi ve yönetim paneli oluşturuldu.'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  List<CustomerSummary> get _customers {
    final grouped = <String, List<AntiqueSale>>{};
    for (final sale in _sales) {
      final name = sale.buyer.trim();
      if (name.isEmpty) continue;
      grouped.putIfAbsent(name.toLowerCase(), () => []).add(sale);
    }

    final summaries = grouped.values.map((customerSales) {
      final latestFirst = [...customerSales]
        ..sort((a, b) => b.soldAt.compareTo(a.soldAt));
      final products = customerSales
          .map((sale) => sale.productName)
          .toSet()
          .toList();
      return CustomerSummary(
        name: latestFirst.first.buyer.trim(),
        purchaseCount: customerSales.length,
        itemCount: customerSales.fold<int>(
          0,
          (sum, sale) => sum + sale.quantity,
        ),
        totalSpent: customerSales.fold<double>(
          0,
          (sum, sale) => sum + sale.total,
        ),
        lastPurchase: latestFirst.first.soldAt,
        products: products,
      );
    }).toList()..sort((a, b) => b.totalSpent.compareTo(a.totalSpent));
    return summaries;
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Çıkış yapılamadı: $error')));
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAntiques();
    _loadAuctions();
    _loadSales();
    _loadStockMovements();
    _loadCurrentRole();
  }

  bool get _isManager => _currentRole == 'yonetici';

  List<Auction> get _auctionsEndingSoon {
    final now = DateTime.now();
    final limit = now.add(const Duration(days: 7));
    return _auctions
        .where(
          (auction) =>
              auction.status.toLowerCase() == 'aktif' &&
              auction.endDate.isAfter(now) &&
              !auction.endDate.isAfter(limit),
        )
        .toList()
      ..sort((a, b) => a.endDate.compareTo(b.endDate));
  }

  Future<void> _loadCurrentRole() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      if (mounted) setState(() => _isRoleLoading = false);
      return;
    }
    try {
      final row = await _supabase
          .from('kullanici_rolleri')
          .select('rol')
          .eq('kullanici_id', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        _currentRole = (row?['rol'] ?? 'personel').toString();
        _isRoleLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _currentRole = 'personel';
        _isRoleLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcı yetkisi yüklenemedi: $error')),
      );
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = null;
    });
    try {
      final rows = await _supabase.rpc('yonetici_kullanicilari');
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return AppUser(
          id: item['kullanici_id'].toString(),
          email: (item['eposta'] ?? '').toString(),
          fullName: (item['ad'] ?? '').toString(),
          role: (item['rol'] ?? 'personel').toString(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _users = loaded;
        _isLoadingUsers = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _usersError = error.toString();
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _changeUserRole(AppUser user, String role) async {
    try {
      await _supabase.rpc(
        'yonetici_rol_degistir',
        params: {'p_kullanici_id': user.id, 'p_yeni_rol': role},
      );
      await _loadUsers();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${user.email} kullanıcısının rolü '
            '${role == 'yonetici' ? 'Yönetici' : 'Personel'} olarak güncellendi.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Rol güncellenemedi: $error')));
    }
  }

  Future<void> _loadAntiques() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }
    //BURASI VERİTANINDAN ALDIGI YER
    try {
      final rows = await _supabase.from('urunler').select().order('id');
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        final offerValue = item['teklif'] ?? item['teklif_miktari'] ?? 0;
        final auctionLocationValue =
            item['acik_arttirma_yeri'] ??
            item['acik_artirma_yeri'] ??
            item['acik_arttirma_yeri'] ??
            item['acik_arttirma_yeri'] ??
            item['acik_arttirma_yer'] ??
            '';

        return Antique(
          id: (item['id'] as num).toInt(),
          name: (item['ad'] ?? '').toString(),
          category: (item['kategori'] ?? 'Diğer').toString(),
          year: (item['antika_yili'] as num?)?.toInt() ?? 0,
          history: (item['aciklama'] ?? '').toString(),
          value: (item['satis_fiyati'] as num?)?.toDouble() ?? 0,
          quantity: (item['stok'] as num?)?.toInt() ?? 0,
          minimumStock: (item['minimum_stok'] as num?)?.toInt() ?? 3,
          purchasePrice: (item['alis_fiyati'] as num?)?.toDouble() ?? 0,
          extraCosts: (item['ek_masraf'] as num?)?.toDouble() ?? 0,
          offer: offerValue.toString(),
          auctionLocation: auctionLocationValue.toString(),
          location: (item['konum'] ?? '').toString(),
          photoUrl: item['foto_url']?.toString(),
          condition: (item['kondisyon'] ?? '').toString(),
          conditionPhotoUrl: item['kondisyon_foto_url']?.toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _antiques
          ..clear()
          ..addAll(loaded);
        _isLoading = false;
        _usingOfflineCache = false;
      });
      try {
        await InventoryCache.saveProducts(loaded);
      } catch (error) {
        debugPrint('Ürün önbelleği kaydedilemedi: $error');
      }
    } catch (error) {
      if (!mounted) return;
      try {
        final cached = await InventoryCache.loadProducts();
        if (cached != null && cached.isNotEmpty) {
          setState(() {
            _antiques
              ..clear()
              ..addAll(cached);
            _isLoading = false;
            _usingOfflineCache = true;
            _loadError = null;
          });
          return;
        }
      } catch (cacheError) {
        debugPrint('Yerel ürün önbelleği okunamadı: $cacheError');
      }
      setState(() {
        _isLoading = false;
        _usingOfflineCache = false;
        _loadError = error.toString();
      });
    }
  }

  Future<void> _saveInventoryCount(List<OfflineStockCount> counts) async {
    try {
      await _supabase.rpc(
        'envanter_sayimini_uygula',
        params: {
          'p_sayim': counts
              .map(
                (item) => {
                  'product_id': item.productId,
                  'expected_stock': item.expectedStock,
                  'counted_stock': item.countedStock,
                },
              )
              .toList(),
        },
      );
      await Future.wait([_loadAntiques(), _loadStockMovements()]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envanter sayımı kaydedildi.')),
      );
    } on PostgrestException {
      rethrow;
    } catch (error) {
      await InventoryCache.queueCounts(counts);
      final changed = {
        for (final item in counts) item.productId: item.countedStock,
      };
      final updated = _antiques
          .map(
            (product) => changed.containsKey(product.id)
                ? Antique(
                    id: product.id,
                    name: product.name,
                    category: product.category,
                    year: product.year,
                    history: product.history,
                    value: product.value,
                    purchasePrice: product.purchasePrice,
                    extraCosts: product.extraCosts,
                    quantity: changed[product.id]!,
                    minimumStock: product.minimumStock,
                    offer: product.offer,
                    auctionLocation: product.auctionLocation,
                    location: product.location,
                    photoUrl: product.photoUrl,
                    condition: product.condition,
                    conditionPhotoUrl: product.conditionPhotoUrl,
                  )
                : product,
          )
          .toList();
      setState(() {
        _antiques
          ..clear()
          ..addAll(updated);
        _usingOfflineCache = true;
      });
      await InventoryCache.saveProducts(updated);
      debugPrint('Envanter sayımı çevrimdışı kuyruğa alındı: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sayım bu cihazda saklandı; bağlantı gelince eşitleyebilirsin.',
            ),
          ),
        );
      }
    }
  }

  Future<int> _syncPendingStockCounts() async {
    final count = await InventoryCache.syncPendingCounts(_supabase);
    await Future.wait([_loadAntiques(), _loadStockMovements()]);
    return count;
  }

  Future<void> _discardPendingStockCounts() async {
    await InventoryCache.clearPendingCounts();
    await _loadAntiques();
  }

  Future<void> _loadAuctions() async {
    try {
      final rows = await _supabase.from('acik_artirmalar').select().order('id');
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return Auction(
          id: (item['id'] as num?)?.toInt(),
          productId: (item['urun_id'] as num?)?.toInt() ?? 0,
          startingPrice: (item['baslangic_fiyati'] as num?)?.toDouble() ?? 0,
          currentBid: (item['mevcut_teklif'] as num?)?.toDouble() ?? 0,
          startDate:
              DateTime.tryParse((item['baslangic_tarihi'] ?? '').toString()) ??
              DateTime.now(),
          endDate:
              DateTime.tryParse((item['bitis_tarihi'] ?? '').toString()) ??
              DateTime.now(),
          status: (item['durum'] ?? 'Aktif').toString(),
          auctionLocation: '',
          winner: (item['kazanan'] ?? '').toString(),
          finalPrice: (item['son_satis_fiyati'] as num?)?.toDouble() ?? 0,
          paymentStatus: (item['odeme_durumu'] ?? 'Bekliyor').toString(),
          deliveryStatus: (item['teslimat_durumu'] ?? 'Bekliyor').toString(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _auctions
          ..clear()
          ..addAll(loaded);
      });
    } catch (error) {
      if (!mounted) return;
      debugPrint('Açık artırma yükleme hatası: $error');
    }
  }

  Future<void> _loadSales() async {
    try {
      final rows = await _supabase
          .from('satislar')
          .select()
          .order('satis_tarihi', ascending: false);
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return AntiqueSale(
          id: (item['id'] as num).toInt(),
          productName: (item['urun_adi'] ?? '').toString(),
          quantity: (item['adet'] as num).toInt(),
          unitPrice: (item['birim_fiyat'] as num).toDouble(),
          unitCost: (item['birim_maliyet'] as num?)?.toDouble() ?? 0,
          productId: (item['urun_id'] as num?)?.toInt(),
          buyer: (item['alici'] ?? '').toString(),
          soldAt:
              DateTime.tryParse((item['satis_tarihi'] ?? '').toString()) ??
              DateTime.now(),
        );
      }).toList();

      if (!mounted) return;
      setState(() {
        _sales
          ..clear()
          ..addAll(loaded);
        _salesError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _salesError = error.toString());
      debugPrint('Satış kayıtları yüklenemedi: $error');
    }
  }

  Future<void> _loadStockMovements() async {
    try {
      final rows = await _supabase
          .from('stok_hareketleri')
          .select()
          .order('created_at', ascending: false)
          .limit(300);
      final loaded = (rows as List).map((row) {
        final item = Map<String, dynamic>.from(row as Map);
        return StockMovement(
          id: (item['id'] as num).toInt(),
          productName: (item['urun_adi'] ?? 'Silinmiş ürün').toString(),
          type: (item['hareket_tipi'] ?? 'Stok hareketi').toString(),
          quantity: (item['miktar'] as num?)?.toInt() ?? 0,
          previousStock: (item['onceki_stok'] as num?)?.toInt() ?? 0,
          newStock: (item['yeni_stok'] as num?)?.toInt() ?? 0,
          createdAt:
              DateTime.tryParse((item['created_at'] ?? '').toString()) ??
              DateTime.now(),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _stockMovements
          ..clear()
          ..addAll(loaded);
        _stockMovementsError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _stockMovementsError = error.toString());
      debugPrint('Stok hareketleri yüklenemedi: $error');
    }
  }

  Future<void> _saveSale({
    required Antique antique,
    required int quantity,
    required double unitPrice,
    required String buyer,
  }) async {
    try {
      await _supabase.rpc(
        'satis_olustur',
        params: {
          'p_urun_id': antique.id,
          'p_adet': quantity,
          'p_birim_fiyat': unitPrice,
          'p_alici': buyer,
        },
      );

      await Future.wait([_loadAntiques(), _loadSales(), _loadStockMovements()]);
      if (!mounted) return;
      setState(() => _currentPage = AdminPage.sales);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Satış kaydedildi ve stok güncellendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Satış kaydedilemedi: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _insertAntique(Antique antique) async {
    final result = await _supabase
        .from('urunler')
        .insert({
          'ad': antique.name,
          'kategori': antique.category,
          'antika_yili': antique.year,
          'aciklama': antique.history,
          'satis_fiyati': antique.value,
          'alis_fiyati': antique.purchasePrice,
          'ek_masraf': antique.extraCosts,
          'stok': antique.quantity,
          'minimum_stok': antique.minimumStock,
          'konum': antique.location,
          'teklif': antique.offer,
          'acik_arttirma_yeri': antique.auctionLocation,
          'foto_url': null,
          'kondisyon': antique.condition,
          'kondisyon_foto_url': null,
        })
        .select('id')
        .single();

    final id = (result['id'] as num).toInt();
    final photoUrl = await _uploadAntiquePhoto(antique, id);
    if (photoUrl != null) {
      await _supabase
          .from('urunler')
          .update({'foto_url': photoUrl})
          .eq('id', id);
    }
    final conditionPhotoUrl = await _uploadConditionPhoto(antique, id);
    if (conditionPhotoUrl != null) {
      await _supabase
          .from('urunler')
          .update({'kondisyon_foto_url': conditionPhotoUrl})
          .eq('id', id);
    }
  }

  Future<String?> _uploadAntiquePhoto(Antique antique, int id) async {
    final bytes = antique.selectedPhotoBytes;
    final fileName = antique.selectedPhotoName;
    if (bytes == null || fileName == null) return null;

    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
    const bucket = 'urun-fotograflari';
    const objectName = 'kapak';
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          '$id/$objectName',
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _supabase.storage.from(bucket).getPublicUrl('$id/$objectName');
  }

  Future<String?> _uploadConditionPhoto(Antique antique, int id) async {
    final bytes = antique.selectedConditionPhotoBytes;
    final fileName = antique.selectedConditionPhotoName;
    if (bytes == null || fileName == null) return null;

    final extension = fileName.split('.').last.toLowerCase();
    final contentType = switch (extension) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
    const bucket = 'urun-fotograflari';
    const objectName = 'kondisyon';
    await _supabase.storage
        .from(bucket)
        .uploadBinary(
          '$id/$objectName',
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _supabase.storage.from(bucket).getPublicUrl('$id/$objectName');
  }

  Future<void> _saveAuction(Auction auction) async {
    try {
      await _supabase.from('acik_artirmalar').insert({
        'urun_id': auction.productId,
        'baslangic_fiyati': auction.startingPrice,
        'mevcut_teklif': auction.currentBid,
        'baslangic_tarihi': auction.startDate.toUtc().toIso8601String(),
        'bitis_tarihi': auction.endDate.toUtc().toIso8601String(),
        'durum': auction.status,
        'kazanan': auction.winner,
        'son_satis_fiyati': auction.finalPrice,
        'odeme_durumu': auction.paymentStatus,
        'teslimat_durumu': auction.deliveryStatus,
      }).select();
      await _supabase
          .from('urunler')
          .update({'acik_arttirma_yeri': auction.auctionLocation})
          .eq('id', auction.productId);

      await Future.wait([_loadAuctions(), _loadAntiques()]);
      if (!mounted) return;
      setState(() => _currentPage = AdminPage.auction);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açık artırma kaydı oluşturuldu.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Açık artırma kaydı oluşturulamadı: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _deleteAuction(Auction auction) async {
    if (auction.id == null) return;

    try {
      await _supabase.from('acik_artirmalar').delete().eq('id', auction.id!);
      await _loadAuctions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açık artırma kaydı silindi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _updateAuctionResults(Auction auction) async {
    final id = auction.id;
    if (id == null) return;
    try {
      await _supabase
          .from('acik_artirmalar')
          .update({
            'kazanan': auction.winner,
            'son_satis_fiyati': auction.finalPrice,
            'odeme_durumu': auction.paymentStatus,
            'teslimat_durumu': auction.deliveryStatus,
          })
          .eq('id', id);
      await _loadAuctions();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Açık artırma sonuçları güncellendi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sonuçlar güncellenemedi: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _saveAntique(Antique antique) async {
    final matchingIndices = <int>[];
    for (var i = 0; i < _antiques.length; i++) {
      if (_antiques[i].name.trim().toLowerCase() ==
          antique.name.trim().toLowerCase()) {
        matchingIndices.add(i);
      }
    }

    try {
      if (matchingIndices.isNotEmpty) {
        final selectedIndex = await showDialog<int>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Bu antika zaten kayıtlı'),
            content: SizedBox(
              width: 480,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '"${antique.name}" adlı ürün için hangi kayda '
                      '${formatNumber(antique.quantity)} adet eklemek istiyorsun?',
                    ),
                    const SizedBox(height: 12),
                    ...matchingIndices.map((index) {
                      final existing = _antiques[index];
                      return Card(
                        child: ListTile(
                          leading: const Icon(Icons.inventory_2_outlined),
                          title: Text(existing.name),
                          subtitle: Text(
                            'Kategori: ${existing.category}\n'
                            'Yıl: ${existing.year} • Mevcut adet: ${formatNumber(existing.quantity)}\n'
                            'Değer: ${formatCurrency(existing.value)}',
                          ),
                          isThreeLine: true,
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () => Navigator.pop(dialogContext, index),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => Navigator.pop(dialogContext, -1),
                      icon: const Icon(Icons.add),
                      label: const Text('Hayır, ayrı kayıt oluştur'),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('İptal'),
              ),
            ],
          ),
        );

        if (!mounted || selectedIndex == null) return;

        if (selectedIndex == -1) {
          await _insertAntique(antique);
        } else {
          final existing = _antiques[selectedIndex];
          if (existing.id == null) {
            throw Exception('Seçilen kaydın veritabanı kimliği bulunamadı.');
          }
          final updates = <String, dynamic>{
            'stok': existing.quantity + antique.quantity,
          };
          if (antique.condition.isNotEmpty) {
            updates['kondisyon'] = antique.condition;
          }
          final photoUrl = await _uploadAntiquePhoto(antique, existing.id!);
          if (photoUrl != null) updates['foto_url'] = photoUrl;
          final conditionPhotoUrl = await _uploadConditionPhoto(
            antique,
            existing.id!,
          );
          if (conditionPhotoUrl != null) {
            updates['kondisyon_foto_url'] = conditionPhotoUrl;
          }
          await _supabase
              .from('urunler')
              .update(updates)
              .eq('id', existing.id!);
        }

        await _loadAntiques();
        await _loadStockMovements();
        if (!mounted) return;
        setState(() => _currentPage = AdminPage.menu);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              selectedIndex == -1
                  ? 'Ayrı antika kaydı oluşturuldu.'
                  : 'Seçtiğin kaydın stok adedi artırıldı.',
            ),
          ),
        );
        return;
      }

      await _insertAntique(antique);
      await _loadAntiques();
      await _loadStockMovements();
      if (!mounted) return;
      setState(() => _currentPage = AdminPage.menu);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Antika kaydı oluşturuldu.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kaydetme başarısız: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _updateAntique(Antique antique) async {
    final id = antique.id;
    if (id == null) {
      throw StateError('Düzenlenecek ürünün kimliği bulunamadı.');
    }

    try {
      await _supabase
          .from('urunler')
          .update({
            'ad': antique.name,
            'kategori': antique.category,
            'antika_yili': antique.year,
            'aciklama': antique.history,
            'satis_fiyati': antique.value,
            'alis_fiyati': antique.purchasePrice,
            'ek_masraf': antique.extraCosts,
            'stok': antique.quantity,
            'minimum_stok': antique.minimumStock,
            'konum': antique.location,
            'teklif': antique.offer,
            'kondisyon': antique.condition,
          })
          .eq('id', id);

      final photoUrl = await _uploadAntiquePhoto(antique, id);
      if (photoUrl != null) {
        await _supabase
            .from('urunler')
            .update({'foto_url': photoUrl})
            .eq('id', id);
      }
      final conditionPhotoUrl = await _uploadConditionPhoto(antique, id);
      if (conditionPhotoUrl != null) {
        await _supabase
            .from('urunler')
            .update({'kondisyon_foto_url': conditionPhotoUrl})
            .eq('id', id);
      }

      await Future.wait([_loadAntiques(), _loadStockMovements()]);
      if (!mounted) return;
      setState(() {
        _editingAntique = null;
        _currentPage = AdminPage.list;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün güncellendi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ürün güncellenemedi: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _deleteAntique(Antique antique) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ürünü sil'),
        content: Text(
          '"${antique.name}" adlı ürünü silmek istediğine emin misin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirm != true || antique.id == null) return;

    try {
      final deletedRows = await _supabase
          .from('urunler')
          .delete()
          .eq('id', antique.id!)
          .select('id');
      if (deletedRows.isEmpty) {
        throw StateError(
          'Ürün silinemedi. Bu işlem için Yönetici rolü gerekir.',
        );
      }
      await _loadAntiques();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün başarıyla silindi.')));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Silme işlemi başarısız: $error'),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isRoleLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: accentColor(context)),
        ),
      );
    }

    if (_loadError != null) {
      return AdminNavigationScope(
        onNavigate: (destination) => setState(() => _currentPage = destination),
        child: Scaffold(
          appBar: AppBar(
            title: const EskilerdenBrand(fontSize: 30),
            actions: [
              const NotificationMenuButton(),
              IconButton(
                tooltip: 'Çıkış yap',
                onPressed: _signOut,
                icon: const Icon(Icons.logout_rounded),
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_off, size: 48, color: accentColor(context)),
                  const SizedBox(height: 12),
                  const Text('Supabase bağlantısı kurulamadı.'),
                  const SizedBox(height: 8),
                  SelectableText(_loadError!),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _loadAntiques,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final Widget page;
    switch (_currentPage) {
      case AdminPage.menu:
        page = AdminMenu(
          antiqueCount: _antiques.length,
          totalStock: _antiques.fold<int>(
            0,
            (sum, item) => sum + item.quantity,
          ),
          totalValue: _antiques.fold<double>(
            0,
            (sum, item) => sum + item.value * item.quantity,
          ),
          categoryCount: _antiques.map((item) => item.category).toSet().length,
          lowStockAntiques:
              _antiques
                  .where(
                    (item) =>
                        item.minimumStock > 0 &&
                        item.quantity <= item.minimumStock,
                  )
                  .toList()
                ..sort((a, b) => a.quantity.compareTo(b.quantity)),
          auctionsEndingSoon: _auctionsEndingSoon,
          isUsingOfflineCache: _usingOfflineCache,
          isManager: _isManager,
          onSignOut: _signOut,
          onCreateAntique: () =>
              setState(() => _currentPage = AdminPage.create),
          onShowAntiques: () => setState(() => _currentPage = AdminPage.list),
          onShowAuctions: () =>
              setState(() => _currentPage = AdminPage.auction),
          onShowSales: () => setState(() => _currentPage = AdminPage.sales),
          onShowReports: () => setState(() => _currentPage = AdminPage.reports),
          onShowCustomers: () =>
              setState(() => _currentPage = AdminPage.customers),
          onShowStockMovements: () =>
              setState(() => _currentPage = AdminPage.stockMovements),
          onShowInventoryCount: () =>
              setState(() => _currentPage = AdminPage.inventoryCount),
          onShowActivityHistory: () =>
              setState(() => _currentPage = AdminPage.activityHistory),
          onShowBackupImport: () =>
              setState(() => _currentPage = AdminPage.backupImport),
          onShowUsers: () {
            setState(() => _currentPage = AdminPage.users);
            _loadUsers();
          },
        );
      // ÜRÜN EKLEME EKRANI
      case AdminPage.create:
        page = AddAntiquePage(
          key: ValueKey(_editingAntique?.id),
          initialAntique: _editingAntique,
          onCancel: () => setState(() {
            final wasEditing = _editingAntique != null;
            _editingAntique = null;
            _currentPage = wasEditing ? AdminPage.list : AdminPage.menu;
          }),
          onSave: _editingAntique == null ? _saveAntique : _updateAntique,
        );
      // ÜRÜN EKLEME EKRANI BİTİŞİ
      case AdminPage.list:
        page = AntiqueListPage(
          antiques: _antiques,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
          onCreateAntique: () => setState(() {
            _editingAntique = null;
            _currentPage = AdminPage.create;
          }),
          onEdit: (antique) async {
            setState(() {
              _editingAntique = antique;
              _currentPage = AdminPage.create;
            });
          },
          onDelete: _deleteAntique,
          onShowTimeline: (product) => setState(() {
            _timelineProduct = product;
            _currentPage = AdminPage.productTimeline;
          }),
          canDelete: _isManager,
        );
      case AdminPage.auction:
        page = AuctionPage(
          auctions: _auctions,
          antiques: _antiques,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
          onCreateAuction: () =>
              setState(() => _currentPage = AdminPage.createAuction),
          onDelete: _deleteAuction,
          onUpdateResults: _updateAuctionResults,
          canDelete: _isManager,
        );
      case AdminPage.createAuction:
        page = AddAuctionPage(
          antiques: _antiques,
          onCancel: () => setState(() => _currentPage = AdminPage.auction),
          onSave: _saveAuction,
        );
      case AdminPage.sales:
        page = SalesPage(
          sales: _sales,
          error: _salesError,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
          onCreateSale: () =>
              setState(() => _currentPage = AdminPage.createSale),
        );
      case AdminPage.createSale:
        page = CreateSalePage(
          antiques: _antiques,
          onCancel: () => setState(() => _currentPage = AdminPage.sales),
          onSave: _saveSale,
        );
      case AdminPage.reports:
        page = ReportsPage(
          antiques: _antiques,
          auctions: _auctions,
          sales: _sales,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
        );
      case AdminPage.customers:
        page = CustomersPage(
          customers: _customers,
          error: _salesError,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
        );
      case AdminPage.stockMovements:
        page = StockMovementsPage(
          movements: _stockMovements,
          error: _stockMovementsError,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
          onRefresh: _loadStockMovements,
        );
      case AdminPage.users:
        page = UserRolesPage(
          users: _users,
          currentUserId: _supabase.auth.currentUser?.id,
          isLoading: _isLoadingUsers,
          error: _usersError,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
          onRefresh: _loadUsers,
          onChangeRole: _changeUserRole,
        );
      case AdminPage.settings:
        page = SettingsPage(
          onBack: () => setState(() => _currentPage = AdminPage.menu),
        );
      case AdminPage.messages:
        page = MessagesPage(
          onBack: () => setState(() => _currentPage = AdminPage.menu),
        );
      case AdminPage.inventoryCount:
        page = InventoryCountPage(
          products: _antiques.where((product) => product.id != null).toList(),
          isUsingOfflineCache: _usingOfflineCache,
          onBack: () => setState(() => _currentPage = AdminPage.menu),
          onCountSaved: _saveInventoryCount,
          onSyncPending: _syncPendingStockCounts,
          onDiscardPending: _discardPendingStockCounts,
        );
      case AdminPage.activityHistory:
        page = ActivityHistoryPage(
          onBack: () => setState(() => _currentPage = AdminPage.menu),
        );
      case AdminPage.productTimeline:
        final product = _timelineProduct;
        page = product == null
            ? Scaffold(
                appBar: AppBar(
                  leading: IconButton(
                    onPressed: () =>
                        setState(() => _currentPage = AdminPage.list),
                    icon: const Icon(Icons.arrow_back),
                  ),
                ),
                body: const Center(child: Text('Ürün seçilmedi.')),
              )
            : ProductTimelinePage(
                product: product,
                onBack: () => setState(() => _currentPage = AdminPage.list),
              );
      case AdminPage.backupImport:
        page = BackupImportPage(
          onBack: () => setState(() => _currentPage = AdminPage.menu),
        );
    }

    return AdminNavigationScope(
      onNavigate: (destination) {
        setState(() {
          if (destination == AdminPage.users && !_isManager) {
            _currentPage = AdminPage.menu;
            _quickAccessPanel = null;
            return;
          }
          if (destination == AdminPage.backupImport && !_isManager) {
            _currentPage = AdminPage.menu;
            _quickAccessPanel = null;
            return;
          }
          if (destination == AdminPage.stockMovements) {
            _quickAccessPanel = destination;
          } else {
            _currentPage = destination;
            _quickAccessPanel = null;
          }
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showSidebar = constraints.maxWidth >= 850;
          final Widget content;
          if (!showSidebar) {
            content = page;
          } else {
            final isLightTheme =
                Theme.of(context).brightness == Brightness.light;
            content = Scaffold(
              body: Row(
                children: [
                  Container(
                    width: 245,
                    decoration: BoxDecoration(
                      color: isLightTheme
                          ? const Color(0xFFF0EFEA)
                          : const Color(0xFF080808),
                      border: Border(
                        right: BorderSide(
                          color: isLightTheme
                              ? const Color(0xFFE0DDD4)
                              : const Color(0xFF3A3016),
                        ),
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(22, 26, 18, 24),
                            child: Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: isLightTheme
                                        ? const Color(0xFFFFBD59)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      'assets/images/eskilerden_logo.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(child: EskilerdenBrand(fontSize: 22)),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Divider(
                              color: isLightTheme
                                  ? const Color(0xFFE0DDD4)
                                  : const Color(0xFF3A3016),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SidebarItem(
                            icon: Icons.dashboard_rounded,
                            label: 'Genel Bakış',
                            selected: _currentPage == AdminPage.menu,
                            onTap: () =>
                                setState(() => _currentPage = AdminPage.menu),
                          ),
                          SidebarItem(
                            icon: Icons.inventory_2_rounded,
                            label: 'Ürünler',
                            selected: _currentPage == AdminPage.list,
                            onTap: () =>
                                setState(() => _currentPage = AdminPage.list),
                          ),
                          SidebarItem(
                            icon: Icons.gavel_rounded,
                            label: 'Açık Artırma',
                            selected:
                                _currentPage == AdminPage.auction ||
                                _currentPage == AdminPage.createAuction,
                            onTap: () => setState(
                              () => _currentPage = AdminPage.auction,
                            ),
                          ),
                          SidebarItem(
                            icon: Icons.point_of_sale_rounded,
                            label: 'Satışlar',
                            selected: _currentPage == AdminPage.sales,
                            onTap: () =>
                                setState(() => _currentPage = AdminPage.sales),
                          ),
                          SidebarItem(
                            icon: Icons.bar_chart_rounded,
                            label: 'Raporlar',
                            selected: _currentPage == AdminPage.reports,
                            onTap: () => setState(
                              () => _currentPage = AdminPage.reports,
                            ),
                          ),
                          if (_isManager)
                            SidebarItem(
                              icon: Icons.admin_panel_settings_outlined,
                              label: 'Kullanıcı Rolleri',
                              selected: _currentPage == AdminPage.users,
                              onTap: () {
                                setState(() => _currentPage = AdminPage.users);
                                _loadUsers();
                              },
                            ),
                          SidebarItem(
                            icon: Icons.people_alt_rounded,
                            label: 'Müşteriler',
                            selected: _currentPage == AdminPage.customers,
                            onTap: () => setState(
                              () => _currentPage = AdminPage.customers,
                            ),
                          ),
                          const Spacer(),
                          SidebarItem(
                            icon: Icons.history_rounded,
                            label: 'Değişiklik Geçmişi',
                            selected: false,
                            onTap: _showChangeHistory,
                          ),
                          SidebarItem(
                            icon: Icons.logout_rounded,
                            label: 'Çıkış yap',
                            selected: false,
                            onTap: _signOut,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'STOK TAKİP SİSTEMİ  •  v1.6.0',
                              style: TextStyle(
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.4),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(child: page),
                ],
              ),
            );
          }

          return Stack(
            children: [
              Positioned.fill(child: content),
              if (_quickAccessPanel != null)
                Positioned.fill(
                  child: QuickAccessDetailsPanel(
                    page: _quickAccessPanel!,
                    sales: _sales,
                    salesError: _salesError,
                    movements: _stockMovements,
                    movementsError: _stockMovementsError,
                    onClose: () => setState(() => _quickAccessPanel = null),
                    onRefresh: _loadStockMovements,
                    onRefreshSales: _loadSales,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
