# Gizlilik politikasını yayınlama rehberi

`docs/privacy-policy/index.html` dosyası yerel olarak hazırlandı. Play Console’a yerel dosya yolu girilemez; sayfa herkese açık bir HTTPS URL’sinde erişilebilir olmalıdır.

## Kullanıcının tamamlaması gerekenler

1. HTML içindeki uygulama, geliştirici ve iletişim bilgilerini kontrol et. Bu projede iletişim adresi `taskesen@msn.com` olarak ayarlanmıştır.
2. HTTPS destekleyen bir barındırma seç: GitHub Pages, Cloudflare Pages veya kendi web alanın.
3. `docs/privacy-policy/index.html` dosyasını seçtiğin hizmette yayınla.
4. Gizli anahtar, hesap şifresi veya özel erişim bilgilerini repoya koyma.
5. Yayındaki URL’yi gizli tarayıcı penceresinde açıp telefonda okunabildiğini kontrol et.
6. Bu URL’yi Play Console → App content → Privacy policy alanına gir.

Uygulama içindeki Hakkında ekranında “Gizlilik Politikası” düğmesi hazırdır. Herkese açık URL henüz verilmediği için düğme şimdilik yayınlanmadığına dair açıklama gösterir. Gerçek URL, `Hakkında` sahnesinin `gizlilik_politikasi_url` export alanına girildikten sonra düğme üzerinden açılır.
