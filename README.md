# Antika Stok

Flutter ile hazırlanmış antika envanter ve açık artırma yönetim uygulaması.

## Supabase kurulumu

1. Supabase projesinin **Authentication > Providers > Email** bölümünde e-posta ile girişin açık olduğundan emin olun.
2. Supabase **SQL Editor** içinde [`supabase/urunler_schema.sql`](./supabase/urunler_schema.sql) dosyasının tamamını çalıştırın. Bu şema ürün, açık artırma, satış, stok hareketi ve kullanıcı rolü tablolarını oluşturur; masraf, raf konumu, stok maliyeti ve rol erişimlerini de ekler. Şemayı daha önce çalıştırdıysanız güncel dosyanın tamamını tekrar çalıştırabilirsiniz.
3. Uygulamayı açıp **Hesap oluştur** ile kullanıcı kaydı yapın. Kullanıcı e-postası, adı ve parola özeti Supabase Auth tarafından saklanır; parola uygulamanın kendi tablolarına yazılmaz. Kullanıcı kayıtları Supabase Dashboard'daki **Authentication > Users** bölümünde görülür.
4. Supabase e-posta doğrulamasını etkinleştirdiyseniz, kayıt sırasında gönderilen doğrulama bağlantısını açtıktan sonra giriş yapın.
5. Şifre yenileme bağlantısının uygulamadaki ayrı ekrana dönebilmesi için Supabase **Authentication > URL Configuration** içindeki **Redirect URLs** listesine `https://uygulama-adresiniz/reset-password` adresini ekleyin. Yerel web geliştirmesinde kullanılan tam adres de `http://localhost:<port>/reset-password` biçiminde olmalıdır. E-posta bağlantısı açılınca uygulama bu adreste yeni şifre ekranını gösterir. Başarılı güncellemeden sonra kullanıcı giriş ekranına dönüp yeni şifresiyle giriş yapar.

Yeni hesaplar `auth.users` üzerinde tutulur; kayıt sırasında girilen ad, kullanıcı metadata alanında `full_name` olarak saklanır. Ürün, açık artırma ve satış verileri giriş yapmış kullanıcılar arasında ortaktır. Satış kaydı `satis_olustur` veritabanı fonksiyonuyla atomik olarak oluşturulur ve ürün stoğu aynı işlemde azaltılır.

Müşteriler ekranı, satışlardaki alıcı adlarına göre oluşturulur; alıcı adı boş olan satışlar müşteri listesinde gösterilmez. Stok hareketleri ekranının çalışması için güncel SQL şemasındaki `stok_hareketleri` tablosu ve tetikleyici gereklidir. Şema mevcut stokları bir başlangıç kaydı olarak içe aktarır; sonrasında oluşan stok girişlerini ve çıkışlarını otomatik kaydeder.

Antika kaydına JPG, PNG veya WEBP biçiminde 10 MB'a kadar fotoğraf eklenebilir. Ürün fotoğrafları ortak envanterde görüntülenir ve URL'ye sahip olan herkesçe görülebilen bir Supabase Storage alanında saklanır; özel kişisel fotoğraf yüklemeyin. Bunun için güncel SQL şemasının Supabase SQL Editor'da bir kez çalıştırılmış olması gerekir. Ürün listesinde **Düzenle** ile kayıtlı ürünün bilgileri güncellenebilir. Her ürünün stok uyarı eşiği ayarlanabilir; mevcut adet bu eşiğe eşit veya altındaysa ana sayfada ve ürün listesinde uyarı görünür, eşik `0` ise uyarı kapalıdır. Ürün detayındaki QR kodu basılıp **Ürünler** listesindeki tarama düğmesiyle okunabilir; barkod/QR taraması kamera erişimi gerektirir. **Raporlar** ekranındaki indirme menüsünden envanter ve satış kayıtları Excel (`.xlsx`) veya PDF (`.pdf`) olarak kaydedilebilir.

Ürün formunda birim alış bedeli, birim tamir/diğer masrafı ve depo/raf konumu tutulur. Net kâr, satış fiyatından bu birim maliyetlerin çıkarılmasıyla hesaplanır; satış kaydı anındaki maliyet ayrıca saklanır. Satışlar ekranındaki fiş düğmesi, alıcıya verilebilecek PDF satış fişi oluşturur.

**Ayarlar** bölümünde açık/koyu görünüm ve uyumlu vurgu renkleri seçilebilir. Sağ üstteki mesaj simgesi, giriş yapmış kullanıcıların ortak mesaj ekranını açar; mesajlar farklı kullanıcı oturumları arasında Supabase üzerinden paylaşılır ve ekran açıkken periyodik olarak yenilenir. Mesajların yanında gönderenin yönetici/personel rolü de gösterilir. Mesajlaşma tablosu ve erişim kuralları için güncel `supabase/urunler_schema.sql` dosyasını Supabase SQL Editor'da çalıştırın.

Tema ve vurgu rengi cihazda kalıcı saklanır. **Raporlar** ekranındaki Excel dışa aktarımı ürün, satış ve açık artırma kayıtlarını ayrı sayfalarda içerir; ürün kimliği, stok eşiği, kondisyon ve fotoğraf bağlantıları dahil verileri dosya olarak saklayabilirsiniz. Bu dışa aktarım geri yükleme/import özelliği değildir.

Ana ekranda **Envanter sayımı** fiziksel stok farklarını doğrulayarak kaydeder; internet yoksa son ürün önbelleğiyle çalışıp sayımı yerel kuyruğa alır. Kuyruk sunucuya gönderilirken, sayım sırasında çevrimiçi stok değişmişse çakışma nedeniyle durur ve bekleyen kayıtları korur. Bu çevrimdışı destek şu an ürün görüntüleme ve stok sayımı/eşitlemesiyle sınırlıdır. Ana ekrandaki **İşlem geçmişi**, Supabase SQL kurulumuyla etkinleşen ürün/satış/açık artırma işlemlerini; ürün detayındaki **Zaman çizelgesi** ise ilgili ürün olaylarını gösterir. **7 gün içinde bitecek açık artırmalar** ana ekranda hatırlatılır. Yönetici, ana ekrandaki **Yedekten geri yükle** ile bu uygulamanın Excel dosyasını güvenli önizlemeden sonra içe alabilir. İçe aktarma kayıt numarasına göre birleştirir/günceller, veritabanında olmayan yedek kayıtlarını ekler ve mevcut kayıtları silmez. Bu özellikler için güncel `supabase/urunler_schema.sql` dosyasını Supabase SQL Editor'da çalıştırın.

Öğretmenin sorabileceği önemli uygulama kodları, kısa açıklamalar ve örneklerle `lib/ogretmen_soru_cevaplari.dart` dosyasında ayrı bir çalışma kaynağı olarak bulunur. Bu dosya uygulamanın çalışma akışına dahil değildir.

Ürün düzenleme formunda kondisyon/hasar/restorasyon notu ve kondisyon fotoğrafı eklenebilir; ürün detayında birlikte görüntülenir. Açık artırma detayındaki **Sonuçları düzenle** ile kazanan/alıcı, son satış tutarı, ödeme durumu ve teslimat durumu kaydedilir. Bu alanların Supabase'de oluşturulması için `supabase/urunler_schema.sql` dosyasının güncel halini SQL Editor'da çalıştırın.

Ürün silme yalnızca **Yönetici** rolüyle yapılabilir. Silinen ürünün geçmiş satışları korunur; ürün bağlantısı kaldırılır, satıştaki ürün adı ve tutarlar geçmiş kaydı olarak kalır. Bu davranış için güncel şemadaki `satislar.urun_id` foreign key değişikliğini Supabase SQL Editor'da uygulayın.

Ürün formunda yalnızca **Antika adı** ve **Adet** zorunludur. Kategori seçimi yapılmazsa **Diğer** kullanılır. Yıl, geçmiş, kondisyon notu/fotoğrafı, ürün fotoğrafı, satış değeri, alış bedeli, ek masraf, depo/raf konumu, teklif ve stok uyarı eşiği isteğe bağlıdır; boş fiyat ve masraf alanları `0`, boş stok uyarı eşiği `3` olarak kaydedilir. Açık artırmada ürün, başlangıç fiyatı ve tarihler zorunludur; yer ve mevcut teklif isteğe bağlıdır. Hesap oluştururken ad-soyad ve satış sırasında alıcı bilgisi boş bırakılabilir.

### Kullanıcı rolleri

Yeni kullanıcılar varsayılan olarak **Personel** rolü alır. İlk yöneticiyi oluşturmak için önce hesabını uygulamada kaydet, ardından şema dosyasını çalıştırdıktan sonra aşağıdaki sorguda e-posta adresini kendi hesabınla değiştirip Supabase SQL Editor'da çalıştır:

```sql
update public.kullanici_rolleri r
set rol = 'yonetici'
from auth.users u
where r.kullanici_id = u.id
  and lower(u.email) = lower('yonetici@ornek.com');
```

Bu yönetici uygulamadaki **Kullanıcı Rolleri** sayfasından diğer kayıtlı kullanıcıları yönetici veya personel yapabilir. Yöneticiler tüm işlemleri ve silme/rol atamalarını yapabilir. Personel ürün ekleyip düzenleyebilir ve satış kaydedebilir; kayıt silemez ve rol atayamaz.

## Windows masaüstü kurulumu

Windows sürümünü ve kurulum dosyasını üretmek için Flutter Windows derleme araçları ile Inno Setup 6 kurulu olmalıdır. Proje kökünde PowerShell'de şu komutları çalıştırın:

```powershell
flutter build windows --release
powershell.exe -NoProfile -ExecutionPolicy Bypass -File windows\generate_app_icon.ps1
& "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe" windows\installer.iss
```

Kurulum dosyası `dist\Eskilerden-Setup-x64-1.0.4.exe` konumunda oluşturulur. Kurulum sihirbazı hedef klasörün seçilmesine izin verir ve isteğe bağlı masaüstü kısayolu oluşturur.
Simge dosyası `assets\images\eskilerden_logo.png` görselinden oluşturulur.
Windows uygulaması her açılışta bu bilgisayardaki kayıtlı oturumu kapatır ve giriş ekranını gösterir.

## Web'de yayınlama

GitHub Actions, `main` dalına her gönderimde Flutter web sürümünü oluşturup GitHub Pages'e yayınlar. Depo ayarlarında **Settings > Pages > Build and deployment > Source** seçeneğinin **GitHub Actions** olduğundan emin olun. Yayın adresi `https://yusufalparslan06.github.io/Antika/` olacaktır.

Şifre sıfırlama bağlantısının yayınlanan sitede çalışması için bu tam adresi Supabase **Authentication > URL Configuration > Redirect URLs** bölümüne ekleyin: `https://yusufalparslan06.github.io/Antika/reset-password`.
