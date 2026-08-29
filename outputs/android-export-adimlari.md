# Blok Yık Android App Bundle export adımları

Bu proje için AAB üretimi, kalıcı paket adı ve release imza bilgisi kullanıcı kararı gerektirdiği için otomatik yapılmadı.

## Godot içinde

1. `Project > Export > Add... > Android` ile Android export preset oluştur.
2. Kalıcı bir package/application ID seç. Örnek vermek gerekirse kendi alan adının ters çevrilmiş biçimini kullan; `com.example...` kullanma.
3. Version name olarak `0.1.0`, version code olarak `1` ile başla; her güncellemede version code artır.
4. Export formatını `AAB` seç.
5. Target SDK’yı Android 16 / API 36 veya üzeri yap. 31 Ağustos 2026 itibarıyla Google Play yeni uygulama ve güncellemelerde API 36+ istiyor.
6. Release keystore’u Godot Export ayarlarına bağla ve `Export With Debug` seçeneğini kapat.
7. AAB’yi oluşturup Play Console’un App Bundle Explorer’ında incele.

## Bu makinedeki hazır bileşenler

- Godot: 4.7 stable
- Android SDK: API 36 mevcut
- Godot Android release export template mevcut
- JDK 17 mevcut; Android export öncesi Godot Editor Settings’te JDK 17 seçilmeli.

## Bilinçli olarak yapılmayanlar

- Paket adı uydurulmadı.
- Release keystore oluşturulmadı.
- Keystore parolası dosyaya yazılmadı.
- AAB üretilmedi; çünkü export preset ve imza bilgileri yok.
- Play Console’a uygulama oluşturulmadı veya dosya yüklenmedi.
