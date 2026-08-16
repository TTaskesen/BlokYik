class_name OyunKayitYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://oyun_kayit.save"

func kaydet(tahta: OyunTahtasi, skor_yoneticisi: SkorYoneticisi, aktif_parca: TetrisParcasi, sonraki_parca: TetrisParcasi, dusme_araligi: float, _parca_uretici: ParcaUretici) -> void:
	var dosya := FileAccess.open(KAYIT_YOLU, FileAccess.WRITE)
	if dosya == null:
		return
	
	var data = {
		"genislik": tahta.genislik,
		"yukseklik": tahta.yukseklik,
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
	
	dosya.store_string(JSON.stringify(data))
	dosya.close()

func yukle() -> Dictionary:
	if not FileAccess.file_exists(KAYIT_YOLU):
		return {}
	var dosya := FileAccess.open(KAYIT_YOLU, FileAccess.READ)
	if dosya == null:
		return {}
	var icerik := dosya.get_as_text()
	dosya.close()
	var json = JSON.parse_string(icerik)
	if typeof(json) != TYPE_DICTIONARY:
		return {}
	return json
