class_name SkorYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://yuksek_skor.save"
const ALT_SEVIYE_ICIN_SATIR := 20
const ALT_SEVIYE_SAYISI := 3
const ANA_LEVEL_SAYISI := 5
var skor := 0
var yuksek_skor := 0
var silinen_satir := 0
var ana_level := 1
var alt_seviye := 1
var asama_satirlari := 0

func _init() -> void:
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
	if not FileAccess.file_exists(KAYIT_YOLU):
		return 0
	var dosya := FileAccess.open(KAYIT_YOLU, FileAccess.READ)
	if dosya == null:
		return 0
	var icerik := dosya.get_as_text().strip_edges()
	dosya.close()
	if icerik.is_empty():
		return 0
	var deger := int(icerik) if icerik.is_valid_int() else 0
	return max(0, deger)

func yuksek_skoru_kaydet() -> void:
	yuksek_skor = max(yuksek_skor, skor)
	# user:// dizininin varlığını garanti et
	DirAccess.make_dir_recursive_absolute("user://")
	var dosya := FileAccess.open(KAYIT_YOLU, FileAccess.WRITE)
	if dosya != null:
		dosya.store_string(str(yuksek_skor))
		dosya.close()
