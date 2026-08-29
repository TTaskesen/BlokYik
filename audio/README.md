# Blok Yık ses dosyaları

`muzik.wav` menü müziğidir ve `../tools/create_original_menu_music.py` ile
üçüncü taraf örnek veya kayıt kullanılmadan üretilir. Oyun müziği olan
`muzik_oyun_baslangic.wav` da `create_retro_music.py` ile proje içinde üretilir.

Oyun efektleri (`dondur`, `birak`, `satir`, `oyun_bitti`) lisans belirsizliği
oluşturmaması için dosya olarak tutulmaz. `scripts/ses_yoneticisi.gd`, eksik
dosya durumunda bu efektleri çalışma anında temel dalga biçimleriyle üretir.

İleride dosya eklenirse yalnızca kendin ürettiğin veya lisans belgesi bulunan,
ticari kullanımına izin verilen kısa mono WAV dosyalarını kullan.
