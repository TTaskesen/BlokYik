# Google Play Data Safety cevap taslağı

Bu taslak kaynak kodu ve proje ayarlarının 29 Ağustos 2026 tarihli incelemesine dayanır. Play Console’da gönderilmeden önce final Android export manifesti ve kullanılan tüm eklentiler tekrar kontrol edilmelidir.

## Ana sorular

**Uygulamanız herhangi bir kullanıcı verisi topluyor veya paylaşıyor mu?**  
Taslak cevap: Hayır.

Gerekçe: Kaynak kodunda ağ isteği, hesap, reklam, analiz, bulut kayıt veya üçüncü taraf veri SDK’sı bulunamadı. Oyun kaydı, yüksek skor ve ayarlar `user://` altında cihaz içinde tutuluyor.

**Uygulama verileri üçüncü taraflarla paylaşıyor mu?**  
Taslak cevap: Hayır.

**Veriler aktarım sırasında şifreleniyor mu?**  
Taslak: Ağ üzerinden veri aktarımı yok. Formun bu soruya sunduğu seçenek, Play Console’un güncel arayüzündeki uygulama davranışı açıklamasına göre seçilmeli.

**Kullanıcı verilerini silme isteği gönderebilir mi?**  
Taslak: Hesap veya sunucu verisi yok. Yerel veriler uygulama ayarları/işletim sistemi üzerinden uygulama verileri temizlenerek veya uygulama kaldırılarak silinebilir.

## Yerel dosyalar

- `user://oyun_kayit.save`: devam eden oyunun tahtası, parçaları, skor ve level durumu.
- `user://yuksek_skor.save`: yüksek skor.
- `user://ayarlar.cfg`: ses efektleri, müzik ve müzik seviyesi tercihleri.

Bunlar kişisel kimlik bilgisi değildir ve proje kodunda cihaz dışına gönderilmez.

## Doğrulanması gerekenler

- Release AAB’nin ürettiği manifestte gereksiz izin olmadığını kontrol et.
- Android export preset’e sonradan reklam, analiz, çökme raporu veya başka SDK eklenirse bu taslağı yeniden değerlendir.
- Gizlilik politikası URL’sini gerçek HTTPS adresiyle değiştir.
