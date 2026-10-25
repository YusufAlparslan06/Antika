# Antika Stok

Flutter ile hazırlanmış antika envanter ve açık artırma yönetim uygulaması.

## Supabase kurulumu

1. Supabase projesinin **Authentication > Providers > Email** bölümünde e-posta ile girişin açık olduğundan emin olun.
2. Supabase **SQL Editor** içinde [`supabase/urunler_schema.sql`](./supabase/urunler_schema.sql) dosyasını çalıştırın. Bu şema ürün, açık artırma, satış ve stok hareketi tablolarını oluşturur ve bu tablolara erişimi giriş yapmış kullanıcılarla sınırlar. Şemayı daha önce çalıştırdıysanız, güncel dosyanın tamamını tekrar çalıştırın. Güncel şema mevcut tabloların eksik alanlarını ve stok hareketlerini kaydeden tetikleyiciyi de ekler.
3. Uygulamayı açıp **Hesap oluştur** ile kullanıcı kaydı yapın. Kullanıcı e-postası, adı ve parola özeti Supabase Auth tarafından saklanır; parola uygulamanın kendi tablolarına yazılmaz. Kullanıcı kayıtları Supabase Dashboard'daki **Authentication > Users** bölümünde görülür.
4. Supabase e-posta doğrulamasını etkinleştirdiyseniz, kayıt sırasında gönderilen doğrulama bağlantısını açtıktan sonra giriş yapın.
5. Şifre yenileme bağlantısının uygulamadaki ayrı ekrana dönebilmesi için Supabase **Authentication > URL Configuration** içindeki **Redirect URLs** listesine `https://uygulama-adresiniz/reset-password` adresini ekleyin. Yerel web geliştirmesinde kullanılan tam adres de `http://localhost:<port>/reset-password` biçiminde olmalıdır. E-posta bağlantısı açılınca uygulama bu adreste yeni şifre ekranını gösterir. Başarılı güncellemeden sonra kullanıcı giriş ekranına dönüp yeni şifresiyle giriş yapar.

Yeni hesaplar `auth.users` üzerinde tutulur; kayıt sırasında girilen ad, kullanıcı metadata alanında `full_name` olarak saklanır. Ürün, açık artırma ve satış verileri giriş yapmış kullanıcılar arasında ortaktır. Satış kaydı `satis_olustur` veritabanı fonksiyonuyla atomik olarak oluşturulur ve ürün stoğu aynı işlemde azaltılır.

Müşteriler ekranı, satışlardaki alıcı adlarına göre oluşturulur; alıcı adı boş olan satışlar müşteri listesinde gösterilmez. Stok hareketleri ekranının çalışması için güncel SQL şemasındaki `stok_hareketleri` tablosu ve tetikleyici gereklidir. Şema mevcut stokları bir başlangıç kaydı olarak içe aktarır; sonrasında oluşan stok girişlerini ve çıkışlarını otomatik kaydeder.
