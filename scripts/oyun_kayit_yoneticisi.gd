class_name OyunKayitYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://oyun_kayit.save"
const SURUM := 1
const GEREKLI_ALANLAR := ["surum", "durum", "genislik", "yukseklik", "aktif_hucreler", "kilitli", "skor", "ana_level", "alt_seviye", "asama_satirlari", "silinen_satir", "dusme_araligi", "aktif", "sonraki"]
var kayit_yolu: String
var son_kayit_mesaji := "Kaydedilmiş oyun yok."

func _init(yeni_kayit_yolu: String = KAYIT_YOLU) -> void:
	kayit_yolu = yeni_kayit_yolu

func kaydet(tahta: OyunTahtasi, skor_yoneticisi: SkorYoneticisi, aktif_parca: BlokParcasi, sonraki_parca: BlokParcasi, dusme_araligi: float, _parca_uretici: ParcaUretici) -> bool:
	if tahta == null or skor_yoneticisi == null or aktif_parca == null or sonraki_parca == null:
		return false
	var data = {
		"surum": SURUM,
		"durum": "devam",
		"genislik": tahta.genislik,
		"yukseklik": tahta.yukseklik,
		"aktif_hucreler": [],
		"kilitli": [],
		"skor": skor_yoneticisi.skor,
		"ana_level": skor_yoneticisi.ana_level,
		"alt_seviye": skor_yoneticisi.alt_seviye,
		"asama_satirlari": skor_yoneticisi.asama_satirlari,
		"silinen_satir": skor_yoneticisi.silinen_satir,
		"dusme_araligi": dusme_araligi,
		"aktif": null,
		"sonraki": null
	}
	for hucre in tahta.aktif_hucreler:
		data.aktif_hucreler.append({"x": hucre.x, "y": hucre.y})
	
	for hucre in tahta.kilitli_hucreler:
		var c = tahta.kilitli_hucreler[hucre]
		data.kilitli.append({"x": hucre.x, "y": hucre.y, "r": c.r, "g": c.g, "b": c.b, "a": c.a})
	
	if aktif_parca:
		data.aktif = {
			"x": aktif_parca.konum.x,
			"y": aktif_parca.konum.y,
			"donus": aktif_parca.donus,
			"renk": {"r": aktif_parca.renk.r, "g": aktif_parca.renk.g, "b": aktif_parca.renk.b, "a": aktif_parca.renk.a},
			"kalip": aktif_parca.kalip
		}
	if sonraki_parca:
		data.sonraki = {
			"renk": {"r": sonraki_parca.renk.r, "g": sonraki_parca.renk.g, "b": sonraki_parca.renk.b, "a": sonraki_parca.renk.a},
			"kalip": sonraki_parca.kalip
		}
	
	if not _atomik_kaydet(data):
		son_kayit_mesaji = "Kayıt yazılamadı; önceki geçerli kayıt korundu."
		return false
	son_kayit_mesaji = "Kaydedilmiş oyun devam etmeye hazır."
	return true

func yukle() -> Dictionary:
	var durum := kayit_durumu()
	return durum.data if durum.gecerli else {}

func kayit_var_mi() -> bool:
	return kayit_durumu().gecerli

func kayit_durumu() -> Dictionary:
	var sonuc := {"gecerli": false, "mesaj": "Kaydedilmiş oyun yok.", "data": {}}
	var ana_sonuc := _dosyadaki_kaydi_oku(kayit_yolu)
	if ana_sonuc.gecerli:
		_gecici_artiklari_temizle()
		son_kayit_mesaji = "Kaydedilmiş oyun devam etmeye hazır."
		return {"gecerli": true, "mesaj": son_kayit_mesaji, "data": ana_sonuc.data}
	var yedek_sonuc := _dosyadaki_kaydi_oku(_yedek_yolu())
	if yedek_sonuc.gecerli:
		_dosyayi_icerikten_geri_yukle(_yedek_yolu(), kayit_yolu)
		_gecici_artiklari_temizle()
		son_kayit_mesaji = "Bozuk kayıt güvenli yedekten kurtarıldı."
		return {"gecerli": true, "mesaj": son_kayit_mesaji, "data": yedek_sonuc.data}
	var gecici_sonuc := _dosyadaki_kaydi_oku(_gecici_yol())
	if gecici_sonuc.gecerli:
		_dosyayi_degistir(_gecici_yol(), kayit_yolu)
		son_kayit_mesaji = "Yarım kalan kayıt güvenli biçimde tamamlandı."
		return {"gecerli": true, "mesaj": son_kayit_mesaji, "data": gecici_sonuc.data}
	if not FileAccess.file_exists(kayit_yolu) and not FileAccess.file_exists(_yedek_yolu()) and not FileAccess.file_exists(_gecici_yol()):
		son_kayit_mesaji = sonuc.mesaj
		return sonuc
	var hata_mesaji: String = ana_sonuc.mesaj if not ana_sonuc.mesaj.is_empty() else "Kayıt uyumsuz veya bozuk; silindi."
	return _gecersiz_kaydi_isle(hata_mesaji)

func kaydi_sil() -> void:
	AtomikDosyaYardimcisi.tum_artiklari_temizle(kayit_yolu)
	son_kayit_mesaji = "Kaydedilmiş oyun yok."

func _gecersiz_kaydi_isle(mesaj: String) -> Dictionary:
	kaydi_sil()
	son_kayit_mesaji = mesaj
	return {"gecerli": false, "mesaj": mesaj, "data": {}}

func _atomik_kaydet(data: Dictionary) -> bool:
	return AtomikDosyaYardimcisi.atomik_yaz(
		kayit_yolu,
		func(yol: String) -> bool: return _json_dosyasi_yaz(yol, data),
		func(yol: String) -> bool: return bool(_dosyadaki_kaydi_oku(yol).gecerli)
	)

func _json_dosyasi_yaz(yol: String, data: Dictionary) -> bool:
	var dosya := FileAccess.open(yol, FileAccess.WRITE)
	if dosya == null:
		return false
	dosya.store_string(JSON.stringify(data))
	dosya.flush()
	dosya.close()
	return true

func _dosyadaki_kaydi_oku(yol: String) -> Dictionary:
	if not FileAccess.file_exists(yol):
		return {"gecerli": false, "mesaj": "", "data": {}}
	var dosya := FileAccess.open(yol, FileAccess.READ)
	if dosya == null:
		return {"gecerli": false, "mesaj": "Kayıt uyumsuz veya bozuk; silindi.", "data": {}}
	var icerik := dosya.get_as_text()
	dosya.close()
	var json_parser := JSON.new()
	if json_parser.parse(icerik) != OK or typeof(json_parser.data) != TYPE_DICTIONARY:
		return {"gecerli": false, "mesaj": "Kayıt uyumsuz veya bozuk; silindi.", "data": {}}
	var dogrulama_mesaji := _kaydi_dogrula(json_parser.data)
	return {"gecerli": dogrulama_mesaji.is_empty(), "mesaj": dogrulama_mesaji, "data": json_parser.data if dogrulama_mesaji.is_empty() else {}}

func _dosyayi_icerikten_geri_yukle(kaynak: String, hedef: String) -> bool:
	var gecici := _gecici_yol()
	if not AtomikDosyaYardimcisi.dosyayi_kopyala(kaynak, gecici):
		return false
	return _dosyayi_degistir(gecici, hedef)

func _dosyayi_degistir(kaynak: String, hedef: String) -> bool:
	return AtomikDosyaYardimcisi.dosyayi_degistir(kaynak, hedef)

func _gecici_artiklari_temizle() -> void:
	AtomikDosyaYardimcisi.gecici_artiklari_temizle(kayit_yolu)

func _gecici_yol() -> String:
	return AtomikDosyaYardimcisi.gecici_yol(kayit_yolu)

func _yedek_yolu() -> String:
	return AtomikDosyaYardimcisi.yedek_yol(kayit_yolu)

func _kaydi_dogrula(data: Dictionary) -> String:
	if not data.has("surum") or not _tam_sayi_mi(data.surum) or int(data.surum) != SURUM:
		return "Kayıt sürümü desteklenmiyor; silindi."
	if not data.has_all(GEREKLI_ALANLAR):
		return "Kayıt uyumsuz veya bozuk; silindi."
	if data.durum != "devam":
		return "Kayıt oynanabilir durumda değil; silindi."
	if not _tam_sayi_mi(data.genislik) or not _tam_sayi_mi(data.yukseklik) or int(data.genislik) < 4 or int(data.yukseklik) < 4:
		return "Kayıt uyumsuz veya bozuk; silindi."
	if not _tam_sayi_mi(data.skor) or int(data.skor) < 0 or not _tam_sayi_mi(data.ana_level) or int(data.ana_level) < 1 or int(data.ana_level) > SkorYoneticisi.ANA_LEVEL_SAYISI:
		return "Kayıt uyumsuz veya bozuk; silindi."
	if not _tam_sayi_mi(data.alt_seviye) or int(data.alt_seviye) < 1 or int(data.alt_seviye) > SkorYoneticisi.ALT_SEVIYE_SAYISI or not _tam_sayi_mi(data.asama_satirlari) or int(data.asama_satirlari) < 0 or int(data.asama_satirlari) >= SkorYoneticisi.ALT_SEVIYE_ICIN_SATIR or not _tam_sayi_mi(data.silinen_satir) or int(data.silinen_satir) < 0:
		return "Kayıt uyumsuz veya bozuk; silindi."
	if not _sayi_mi(data.dusme_araligi) or float(data.dusme_araligi) <= 0.0 or float(data.dusme_araligi) > 10.0:
		return "Kayıt uyumsuz veya bozuk; silindi."
	if not (data.aktif_hucreler is Array) or not (data.kilitli is Array) or not _parca_gecerli_mi(data.aktif, int(data.genislik), int(data.yukseklik), true) or not _parca_gecerli_mi(data.sonraki, int(data.genislik), int(data.yukseklik), false):
		return "Kayıt uyumsuz veya bozuk; silindi."
	var aktif_hucre_maskesi := {}
	var kilitli_hucreler := {}
	for hucre in data.aktif_hucreler:
		if not _koordinat_gecerli_mi(hucre, int(data.genislik), int(data.yukseklik)) or aktif_hucre_maskesi.has(Vector2i(int(hucre.x), int(hucre.y))):
			return "Kayıt uyumsuz veya bozuk; silindi."
		var hucre_konumu := Vector2i(int(hucre.x), int(hucre.y))
		aktif_hucre_maskesi[hucre_konumu] = true
	for hucre in data.kilitli:
		if not _koordinat_gecerli_mi(hucre, int(data.genislik), int(data.yukseklik)) or not _renk_gecerli_mi(hucre) or kilitli_hucreler.has(Vector2i(int(hucre.x), int(hucre.y))):
			return "Kayıt uyumsuz veya bozuk; silindi."
		var kilitli_hucre_konumu := Vector2i(int(hucre.x), int(hucre.y))
		kilitli_hucreler[kilitli_hucre_konumu] = true
	if not _aktif_parca_tahtada_gecerli_mi(data.aktif, int(data.genislik), int(data.yukseklik), aktif_hucre_maskesi, kilitli_hucreler):
		return "Kayıt uyumsuz veya bozuk; silindi."
	return ""

func _parca_gecerli_mi(parca, genislik: int, yukseklik: int, konum_gerekli: bool) -> bool:
	if not (parca is Dictionary) or not parca.has_all(["kalip", "renk"]):
		return false
	if konum_gerekli and not parca.has_all(["x", "y", "donus"]):
		return false
	if not _kalip_gecerli_mi(parca.kalip) or not _renk_gecerli_mi(parca.renk):
		return false
	if konum_gerekli and (not _tam_sayi_mi(parca.x) or not _tam_sayi_mi(parca.y) or not _tam_sayi_mi(parca.donus) or int(parca.x) < -4 or int(parca.x) >= genislik or int(parca.y) < -4 or int(parca.y) >= yukseklik):
		return false
	return true

func _kalip_gecerli_mi(kalip) -> bool:
	if not (kalip is Array) or kalip.is_empty():
		return false
	var dolu_hucre_var := false
	for donus in kalip:
		if not (donus is Array) or donus.is_empty():
			return false
		for satir in donus:
			if not satir is String or satir.is_empty() or satir.length() > 4:
				return false
			for karakter in satir:
				if karakter != "0" and karakter != ".":
					return false
				if karakter == "0":
					dolu_hucre_var = true
	return dolu_hucre_var

func _aktif_parca_tahtada_gecerli_mi(parca: Dictionary, genislik: int, yukseklik: int, aktif_hucre_maskesi: Dictionary, kilitli_hucreler: Dictionary) -> bool:
	var kalip: Array = parca.kalip
	var donus_kalibi: Array = kalip[posmod(int(parca.donus), kalip.size())]
	for y in donus_kalibi.size():
		var satir: String = donus_kalibi[y]
		for x in satir.length():
			if satir[x] != "0":
				continue
			var hucre := Vector2i(int(parca.x) + x, int(parca.y) + y)
			if hucre.x < 0 or hucre.x >= genislik or hucre.y >= yukseklik:
				return false
			if hucre.y >= 0 and (kilitli_hucreler.has(hucre) or (not aktif_hucre_maskesi.is_empty() and not aktif_hucre_maskesi.has(hucre))):
				return false
	return true

func _renk_gecerli_mi(renk) -> bool:
	if not (renk is Dictionary) or not renk.has_all(["r", "g", "b", "a"]):
		return false
	for kanal in [renk.r, renk.g, renk.b, renk.a]:
		if not _sayi_mi(kanal) or float(kanal) < 0.0 or float(kanal) > 1.0:
			return false
	return true

func _koordinat_gecerli_mi(hucre, genislik: int, yukseklik: int) -> bool:
	return hucre is Dictionary and hucre.has_all(["x", "y"]) and _tam_sayi_mi(hucre.x) and _tam_sayi_mi(hucre.y) and int(hucre.x) >= 0 and int(hucre.x) < genislik and int(hucre.y) >= 0 and int(hucre.y) < yukseklik

func _sayi_mi(deger) -> bool:
	return typeof(deger) == TYPE_INT or typeof(deger) == TYPE_FLOAT

func _tam_sayi_mi(deger) -> bool:
	return _sayi_mi(deger) and is_equal_approx(float(deger), round(float(deger)))
