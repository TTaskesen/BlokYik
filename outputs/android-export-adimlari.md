# Blok Yık Android App Bundle export adımları

Güncel Android export preset'i hazırdır. Bu belge hazırlık adımları ile doğrulanmış yayın kanıtını birbirinden ayırır; bu görevde yeni AAB üretilmemiş veya imzalanmamıştır.

## Doğrulanmış mevcut yapılandırma

- Paket: `com.taskesen.blokyik`
- Version name: `0.1.3`
- Version code: `3`
- Format: Android App Bundle
- Min SDK: 24
- Target SDK: 36
- Mimariler: ARMv7 ve ARM64

Son kaynak commit'i `v0.1.2` olduğu ve bu çalışma ek bir düzeltme paketi oluşturduğu için kullanıcı onayıyla `versionName 0.1.3` ve `versionCode 3` değerleri uygulanmıştır. Play Console'daki son kullanılan code yerel dosyalardan kesin doğrulanamadığından yeni AAB yüklenirken code `3` değerinin daha önce kullanılmadığı ayrıca doğrulanmalıdır.

## Godot içinde

1. `export_presets.cfg` içindeki Android preset'i aç ve paket/sürüm değerlerini kontrol et.
2. Her yeni Play yüklemesinden önce version code'u kullanıcı kararıyla artır; betik sürümü kendiliğinden artırmaz.
3. Release keystore'u güvenli konumdan bağla; parola veya anahtar dosyasını repoya ekleme.
4. `tools/build_release_aab.sh --print-output` ile üretilecek sürüm ve yolu parola istemeden kontrol et.
5. Hedef dosya zaten varsa betik üzerine yazmaz; eski dosyayı kullanıcı kararı olmadan silme veya taşıma.
6. Yeni signed AAB'yi fiziksel Android cihazda kurulum, dikey ekran, safe area, dokunma, ses ve kayıt akışlarıyla doğrula.
7. Yalnız doğrulanmış yeni AAB'yi Play Console App Bundle Explorer'a yükle.

## Bu makinedeki hazır bileşenler

- Godot: 4.7 stable
- Android SDK: API 36 mevcut
- Godot Android release export template mevcut
- JDK 17 mevcut; Android export öncesi Godot Editor Settings’te JDK 17 seçilmeli.

## Mevcut AAB incelemesi

- Dosya: `/Users/turguttaskesen/Desktop/Yayına Hazır Dosyalar/Blokyık/BlokYik-v0.1.1-release.aab`
- Boyut: 52.886.955 bayt
- Değiştirilme zamanı: 29 Ağustos 2026 21:29:38 +03:00
- Manifestte görülen paket/sürüm: `com.taskesen.blokyik` / `0.1.1`
- `jarsigner` sonucu: imza doğrulandı; imzalayan `CN=Blok Yık Upload Key`
- Durum: Bu AAB 30 Ağustos kod ve test düzeltmelerinden önce üretildiği için güncel kaynakla aynı değildir ve yeni yayın adayı olarak kullanılmamalıdır.
- Yeni `0.1.3` adayı için henüz AAB yoktur. Yeni imzalı üretim ve fiziksel Android testi tamamlanmadan yayın hazır kabul edilmez.

## Bu görevde bilinçli olarak yapılmayanlar

- Sürüm kullanıcı onayıyla `0.1.3` / code `3` olarak artırıldı.
- Release keystore oluşturulmadı ya da değiştirilmedi.
- Keystore parolası dosyaya yazılmadı.
- Yeni AAB/APK üretilmedi veya imzalanmadı.
- Mevcut AAB silinmedi veya üzerine yazılmadı.
- Play Console'a dosya yüklenmedi ve mevcut gönderim durumu değiştirilmedi.
- Fiziksel Android cihaz testi yapılmadı; yayın öncesinde açık manuel kontroldür.
