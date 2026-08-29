# Google Play yayın kontrol listesi

Hazırlık tarihi: 29 Ağustos 2026  
Proje: `Blok Yık`  
Kontrol kapsamı: kaynak kodu, `project.godot`, mevcut mağaza varlıkları ve otomatik testler.

## Durum özeti

| Konu | Durum | Kanıt / sonraki adım |
|---|---|---|
| Godot projesi | Tamam | Godot 4.7.0 başlatma ve proje taraması başarılı. |
| Ana sahne | Tamam | `res://scenes/AnaMenu.tscn` tanımlı. |
| Mobil dikey düzen | Tamam | 720×960 referans, `canvas_items`, dikey yön. Gerçek cihaz testi ayrıca gerekli. |
| Android export şablonu | Tamam | Godot 4.7 Android debug/release şablonları kurulu. |
| Android SDK API 36 | Tamam | Yerel SDK içinde `android-36` mevcut. 31 Ağustos 2026 sonrası yeni uygulama/update için API 36 gereklidir. |
| Android App Bundle | Eksik | `export_presets.cfg` yok; Android preset ve release export oluşturulmalı. |
| Paket adı | Kullanıcı kararı gerekli | Kalıcı bir Android application ID seçilmeli. |
| Release imzası | Kullanıcı kararı gerekli | Release keystore kullanıcı tarafından oluşturulmalı; parolası repoya yazılmamalı. |
| İzinler / ağ | Kod incelemesine göre tamam | Ağ çağrısı, reklam, analiz, hesap veya satın alma kodu bulunmadı; final manifest export sonrası doğrulanmalı. |
| Data Safety | Taslak hazır | `outputs/data-safety-cevap-taslagi.md`; Play Console formu yine hesap sahibi tarafından gönderilmeli. |
| Gizlilik politikası | Eksik | `docs/privacy-policy/index.html` hazır; `[ ... ]` yer tutucuları doldurulup HTTPS URL'de yayınlanmalı. |
| Hedef kitle / içerik derecelendirmesi | Kullanıcı kararı gerekli | Play Console anketleri gerçek hedef kitleye göre doldurulmalı. |
| Mağaza metinleri | Tamam | `outputs/play-store-metinleri-tr.md`. |
| Görsel varlıklar | Kısmen tamam | Ölçüler uygun; ekran görüntüleri otomatik üretilmiş, gerçek Android cihaz QA'sı yapılmadı. |
| Test | Kısmen tamam | Headless testlerin işlevsel kontrolleri başarılı; kapanışta Godot ses kaynakları için 6 ObjectDB / 2 resource uyarısı görülüyor. Android cihaz testi ayrıca gerekli. |
| Yeni kişisel hesap kapalı testi | Hesaba bağlı | Hesap 13 Kasım 2023 sonrası açıldıysa 12 testçi ve 14 gün kapalı test gerekir. |
| Marka / isim hakları | Kullanıcı kararı gerekli | Uygulama adı `Blok Yık` olarak değiştirildi; yeni ad ve ikonun başka bir marka ile karışmadığı yine kontrol edilmeli. |

## Teknik inceleme

- `project.godot` ağ izni, reklam veya üçüncü taraf SDK tanımlamıyor.
- Dosya erişimi `user://` altındaki yüksek skor, ayarlar ve devam kaydıyla sınırlı.
- Projede kullanıcı hesabı, bulut kayıt, satın alma veya reklam akışı yok.
- Android manifesti ve export preset henüz üretilmediği için son izin kontrolü AAB export sonrasında yapılmalı.
- Yerel makinede Android SDK API 36 ve Godot 4.7 export şablonları mevcut; JDK 17 yerine JDK 25 seçili. Godot Android rehberi uyumluluk için JDK 17 öneriyor; export öncesi JDK 17 seçilmeli.
- Test runner `Tüm Blok Yık kontrolleri başarılı.` yazdırıyor; ancak çıkışta Godot ses sunucusu kaynakları için `6 ObjectDB instances were leaked` ve `2 resources still in use` uyarısı yeniden gözlendi. Bu, oyun akış testlerini bozmadı fakat yayın öncesi ayrı bir ses yaşam döngüsü incelemesi olarak açık kalmalı.

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
