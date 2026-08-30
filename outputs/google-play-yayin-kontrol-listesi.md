# Google Play yayın kontrol listesi

Son doğrulama: 30 Ağustos 2026
Proje: `Blok Yık`  
Kontrol kapsamı: kaynak kodu, Android export preset, mevcut AAB, mağaza varlıkları ve otomatik testler.

## Durum özeti

| Konu | Durum | Kanıt / sonraki adım |
|---|---|---|
| Godot projesi | Tamam | Godot 4.7.0 başlatma ve proje taraması başarılı. |
| Ana sahne | Tamam | `res://scenes/AnaMenu.tscn` tanımlı. |
| Mobil dikey düzen | Tamam | 720×960 referans, `canvas_items`, dikey yön. Gerçek cihaz testi ayrıca gerekli. |
| Android export şablonu | Tamam | Godot 4.7 Android debug/release şablonları kurulu. |
| Android SDK API 36 | Tamam | Yerel SDK içinde `android-36` mevcut. 31 Ağustos 2026 sonrası yeni uygulama/update için API 36 gereklidir. |
| Android App Bundle | Eski kaynak adayı | `BlokYik-v0.1.1-release.aab` mevcut; 29 Ağustos 2026 21:29:38 tarihinde oluşturulmuş. Bu kontrol listesindeki kod düzeltmelerini içermediği için güncel yayın adayı değildir. |
| Paket adı | Tamam | Preset ve AAB manifestinde `com.taskesen.blokyik`. |
| Sürüm | Kaynakta güncellendi | Son kaynak commit'i `v0.1.2`; kullanıcı onayıyla `export_presets.cfg` `0.1.3` / code `3` yapıldı. Code `3` değerinin Play Console'da daha önce kullanılmadığı yeni AAB yüklenirken ayrıca doğrulanmalıdır. |
| Release imzası | İmzalı dosya mevcut | `jarsigner` imzayı doğruladı: `CN=Blok Yık Upload Key`; sertifika 14 Ocak 2054'e kadar geçerli. Anahtar/parola repoda tutulmamalı. |
| İzinler / ağ | Kod incelemesine göre tamam | Ağ çağrısı, reklam, analiz, hesap veya satın alma kodu bulunmadı; final manifest export sonrası doğrulanmalı. |
| Data Safety | Taslak hazır | `outputs/data-safety-cevap-taslagi.md`; Play Console formu yine hesap sahibi tarafından gönderilmeli. |
| Gizlilik politikası | Tamam | Uygulamadaki `https://ttaskesen.github.io/BlokYik/` adresi ve doğrudan `/privacy-policy/` adresi 30 Ağustos 2026 tarihinde HTTPS 200 döndürdü. |
| Hedef kitle / içerik derecelendirmesi | Kullanıcı kararı gerekli | Play Console anketleri gerçek hedef kitleye göre doldurulmalı. |
| Mağaza metinleri | Tamam | `outputs/play-store-metinleri-tr.md`. |
| Görsel varlıklar | Kısmen tamam | Ölçüler uygun; ekran görüntüleri otomatik üretilmiş, gerçek Android cihaz QA'sı yapılmadı. |
| Test | Kısmen tamam | Genişletilmiş headless regresyon paketi; modal safe area, ses sıfır seviyesi, ayar clamp/tür güvenliği, atomik skor/ayar kurtarma, bölüm kimliği ve final akışı kontrolleriyle başarılı. Fiziksel Android cihaz testi ayrıca gerekli. |
| Yeni kişisel hesap kapalı testi | Hesaba bağlı | Hesap 13 Kasım 2023 sonrası açıldıysa 12 testçi ve 14 gün kapalı test gerekir. |
| Marka / isim hakları | Kullanıcı kararı gerekli | Uygulama adı `Blok Yık` olarak değiştirildi; yeni ad ve ikonun başka bir marka ile karışmadığı yine kontrol edilmeli. |

## Teknik inceleme

- `project.godot` ağ izni, reklam veya üçüncü taraf SDK tanımlamıyor.
- Dosya erişimi `user://` altındaki yüksek skor, ayarlar ve devam kaydıyla sınırlı.
- Projede kullanıcı hesabı, bulut kayıt, satın alma veya reklam akışı yok.
- Android export preset AAB, min SDK 24, target SDK 36, ARMv7 ve ARM64 için yapılandırılmıştır.
- Release betiği JDK 17 yolunu açıkça kullanır; sürüm adını preset'ten okur ve mevcut AAB'nin üzerine yazmadan durur.
- Beş bölümün adı HUD/geçiş metninde gösterilir ve oynanış maskesini değiştirmeyen veri odaklı renk paletleri uygulanır.
- Projede lisansı belgelenmiş tek oyun müziği korunur. Önceki üç aynı-dosya tema eşlemesi kaldırılmıştır; ayrı müzik çeşitliliği gelecekte lisansı açık içerik üretimi gerektirir.
- Müzik seviyesi `0`, yalnız müzik oynatıcısında gerçek `volume_linear = 0` uygular; efekt kanalı bağımsızdır.
- Oyun kaydı, yüksek skor ve ayarlar ortak atomik yazma yardımcısıyla geçici dosya doğrulaması ve son geçerli yedek üzerinden korunur.
- Mevcut AAB 52.886.955 bayttır. İmza doğrulaması başarılıdır; paket adı güncel preset ile eşleşir ancak AAB sürümü `0.1.1`, güncel export sürümü `0.1.3` olduğu için sürümler artık bilinçli olarak farklıdır.
- Mevcut AAB bu dosyadaki 30 Ağustos kod düzeltmelerinden önce üretildi. Güncel `0.1.3` yayın adayı için yeni signed AAB üretilmeli ve fiziksel Android testinden geçirilmelidir.
- Bu görevde release üretimi, imzalama veya Play Console işlemi yapılmadı. Daha önceki Console yükleme durumu burada yeniden doğrulanmış sayılmaz.
- Kaynak çalışma ağacındaki yeni düzeltmeler henüz commitlenmediği için son commit etiketi `v0.1.2` olarak kalır; Android export sürümü kullanıcı onayıyla `0.1.3` / `versionCode 3` olarak güncellenmiştir.
- Test runner `Tüm Blok Yık kontrolleri başarılı.` yazdırdı. Beş ardışık standart headless çalıştırmada `AudioStreamPlaybackWAV`, `AudioStreamWAV`, `ObjectDB instances were leaked` veya `resources still in use at exit` uyarısı görülmedi.

## Görsel varlık envanteri

| Dosya | Ölçü / format | Amaç | Durum |
|---|---|---|---|
| `google_play_assets/app_icon_512x512.png` | 512×512 PNG, RGBA | Play Store yüksek çözünürlüklü ikon | Ölçü uygun; alpha/ikon hakları ayrıca kontrol edilmeli. |
| `google_play_assets/feature_graphic_1024x500.png` | 1024×500 PNG, RGB | Feature graphic | Ölçü ve alpha durumu uygun; merkez güvenli alanı korunmalı. |
| `google_play_assets/01_ana_menu.png` … `08_oyun_bitti.png` | 1080×1920 PNG, RGB | Telefon ekran görüntüleri | Ölçü uygun; otomatik üretilmiş, gerçek cihaz görüntüsü olarak doğrulanmadı. |

Mevcut ekran görüntülerinde uygulama dışı tanıtım satırları (Godot/platform bilgisi) bulunuyor. Yayın öncesi gerçek Android cihaz ekran görüntüleriyle değiştirmek veya bu satırları kaldırmak daha güvenlidir.

## Resmi kaynaklar

- [Target API level requirements](https://developer.android.com/google/play/requirements/target-sdk)
- [Create and set up your app](https://support.google.com/googleplay/android-developer/answer/9859152)
- [Data safety](https://support.google.com/googleplay/android-developer/answer/10787469)
- [Target audience and app content](https://support.google.com/googleplay/android-developer/answer/9867159)
- [Content ratings](https://support.google.com/googleplay/android-developer/answer/9859655)
- [Preview assets](https://support.google.com/googleplay/android-developer/answer/9866151)
- [New personal developer account testing](https://support.google.com/googleplay/android-developer/answer/14151465)
- [Godot Android export](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html)
- [Google Play Impersonation policy](https://support.google.com/googleplay/android-developer/answer/9888374)
