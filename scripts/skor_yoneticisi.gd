class_name SkorYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://yuksek_skor.save"
const ALT_SEVIYE_ICIN_SATIR := 20
const ALT_SEVIYE_SAYISI := 3
const ANA_LEVEL_SAYISI := 5
var kayit_yolu: String
var skor := 0
var yuksek_skor := 0
var silinen_satir := 0
var ana_level := 1
var alt_seviye := 1
var asama_satirlari := 0

func _init(yeni_kayit_yolu: String = KAYIT_YOLU) -> void:
	kayit_yolu = yeni_kayit_yolu
	yuksek_skor = yuksek_skoru_oku()

func satir_ekle(satir_sayisi: int) -> Dictionary:
	var sonuc := {"seviye_degisimi": false, "ana_level_degisimi": false, "oyun_tamamlandi": false}
	if satir_sayisi <= 0:
		return sonuc
	var puanlar := [0, 100, 300, 500, 800]
	skor += puanlar[min(satir_sayisi, 4)] * genel_seviye()
	silinen_satir += satir_sayisi
	asama_satirlari += satir_sayisi
	if asama_satirlari < ALT_SEVIYE_ICIN_SATIR:
		return sonuc
	asama_satirlari -= ALT_SEVIYE_ICIN_SATIR
	if ana_level == ANA_LEVEL_SAYISI and alt_seviye == ALT_SEVIYE_SAYISI:
		sonuc.oyun_tamamlandi = true
		return sonuc
	if alt_seviye < ALT_SEVIYE_SAYISI:
		alt_seviye += 1
	else:
		ana_level += 1
		alt_seviye = 1
		sonuc.ana_level_degisimi = true
	sonuc.seviye_degisimi = true
	return sonuc

func genel_seviye() -> int:
	return (ana_level - 1) * ALT_SEVIYE_SAYISI + alt_seviye

func indirme_puani_ekle(mesafe: int) -> void:
	skor += mesafe * 2

func yuksek_skoru_oku() -> int:
	var kullanilabilir_yol := AtomikDosyaYardimcisi.kurtar(kayit_yolu, _skor_dosyasi_gecerli_mi)
	if kullanilabilir_yol.is_empty():
		return 0
	var dosya := FileAccess.open(kullanilabilir_yol, FileAccess.READ)
	if dosya == null:
		return 0
	var icerik := dosya.get_as_text().strip_edges()
	dosya.close()
	if icerik.is_empty():
		return 0
	return int(icerik)

func yuksek_skoru_kaydet() -> bool:
	# Ana dosyada daha yüksek bir değer varsa onu da koru; burada kurtarma
	# çalıştırmayarak atomik yazma hatalarının açıkça raporlanmasını sağlarız.
	var kayitli_skor := _skor_degerini_oku(kayit_yolu)
	var hedef_skor := maxi(maxi(yuksek_skor, skor), kayitli_skor)
	var basarili := AtomikDosyaYardimcisi.atomik_yaz(
		kayit_yolu,
		func(yol: String) -> bool: return _skor_dosyasi_yaz(yol, hedef_skor),
		_skor_dosyasi_gecerli_mi
	)
	if basarili:
		yuksek_skor = hedef_skor
	return basarili

func _skor_dosyasi_yaz(yol: String, deger: int) -> bool:
	var dosya := FileAccess.open(yol, FileAccess.WRITE)
	if dosya == null:
		return false
	dosya.store_string(str(maxi(0, deger)))
	dosya.flush()
	dosya.close()
	return true

func _skor_dosyasi_gecerli_mi(yol: String) -> bool:
	if not FileAccess.file_exists(yol):
		return false
	var dosya := FileAccess.open(yol, FileAccess.READ)
	if dosya == null:
		return false
	var icerik := dosya.get_as_text().strip_edges()
	dosya.close()
	return icerik.is_valid_int() and int(icerik) >= 0

func _skor_degerini_oku(yol: String) -> int:
	if not _skor_dosyasi_gecerli_mi(yol):
		return 0
	var dosya := FileAccess.open(yol, FileAccess.READ)
	if dosya == null:
		return 0
	var deger := int(dosya.get_as_text().strip_edges())
	dosya.close()
	return deger
