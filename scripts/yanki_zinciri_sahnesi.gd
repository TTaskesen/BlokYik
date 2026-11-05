extends TemelSahne

const OYUN_OGRETICI := preload("res://scripts/oyun_ogretici.gd")

const SUTUN := 8
const SATIR := 9
const HEDEF_TASI := 4
const RENKLER: Array[Color] = [Color("42b7ff"), Color("fa5573"), Color("ffd34e"), Color("63d98b")]
const RENK_ADLARI := ["mavi", "pembe", "sarı", "yeşil"]
const HEDEF_RENGI := Color("ffca45")
const SEKIL_HEDEFI := 10
const SEVIYE_ADLARI := ["İlk Yankı", "Çift Patlama", "Dar Koridor", "Bomba Ustası", "Son Rezonans"]
const KAYITLI_SEKIL_ADLARI := ["Z", "S", "Çizgi", "Kare", "L", "J", "T", "Artı", "Kanca"]
const KAYIT_YOLU := "user://yanki_zinciri_ilerleme.cfg"
const YENI_SEKILLER := [
	{"ad": "P", "kalip": ["00", "00", "0."]},
	{"ad": "U", "kalip": ["0.0", "000"]},
	{"ad": "V", "kalip": ["0..", "0..", "000"]},
	{"ad": "W", "kalip": ["0..", "00.", ".00"]},
	{"ad": "Y", "kalip": ["0.", "00", "0.", "0."]},
	{"ad": "F", "kalip": [".00", "00.", ".0."]}
]

class HedefSekliOnizlemesi extends Control:
	var hucreler: Array[Vector2i] = []
	var renk := Color.WHITE

	func goster(yeni_hucreler: Array[Vector2i], yeni_renk: Color) -> void:
		hucreler = yeni_hucreler.duplicate()
		renk = yeni_renk
		queue_redraw()

	func _draw() -> void:
		if hucreler.is_empty():
			return
		var min_x := hucreler[0].x
		var max_x := hucreler[0].x
		var min_y := hucreler[0].y
		var max_y := hucreler[0].y
		for hucre in hucreler:
			min_x = mini(min_x, hucre.x)
			max_x = maxi(max_x, hucre.x)
			min_y = mini(min_y, hucre.y)
			max_y = maxi(max_y, hucre.y)
		var hucre_boyutu := minf((size.x - 16.0) / float(max_x - min_x + 1), (size.y - 16.0) / float(max_y - min_y + 1))
		var sekil_boyutu := Vector2(max_x - min_x + 1, max_y - min_y + 1) * hucre_boyutu
		var baslangic := (size - sekil_boyutu) * 0.5
		for hucre in hucreler:
			var konum := baslangic + Vector2(hucre - Vector2i(min_x, min_y)) * hucre_boyutu
			var alan := Rect2(konum, Vector2.ONE * hucre_boyutu).grow(-1.5)
			draw_rect(alan, Color("090d16"), true)
			draw_rect(alan.grow(-3.0), renk, true)

var hucreler: Array = []
var sekil_katalogu: Array[Dictionary] = []
var aktif_sekil: Dictionary = {}
var aktif_sekil_donusleri: Array[String] = []
var aktif_sekil_hucreleri: Array[Vector2i] = []
var seviye := 0
var acik_seviye := 0
var tamamlanan_sekil := 0
var hamle_sayisi := 0
var oyun_bitti := false
var rng := RandomNumberGenerator.new()
var hucre_butonlari: Array[Button] = []
var baslik: Label
var durum: Label
var hedef: Label
var mesaj: Label
var hedef_onizlemesi: HedefSekliOnizlemesi
var sonraki_buton: Button
var tekrar_buton: Button
var geri_al_butonu: Button
var secili_hucre := Vector2i(-1, -1)
var surukleme_baslangici := Vector2i(-1, -1)
var geri_al_kaydi: Dictionary = {}
var ogretici_acik := false

func _ready() -> void:
	sekil_katalogu = _sekil_katalogunu_olustur()
	acik_seviye = _ilerleme_oku()
	seviye = mini(acik_seviye, SEVIYE_ADLARI.size() - 1)
	_arayuzu_olustur()
	_seviyeyi_yukle(seviye)
	var ogretici := OYUN_OGRETICI.new()
	add_child(ogretici)
	ogretici_acik = ogretici.ilk_oynatmada_goster("yanki_zinciri", ["Üstteki siluet tamamlaman gereken şekli gösterir; altın blokları bul.", "Bir bloğa ve sonra yatay/dikey komşusuna dokun ya da bloğu komşusuna sürükle.", "Şekil tamamlanınca yankı dalgası çevredeki renkleri değiştirir. Her aşamada 10 şekli bitir; Geri Al son değiş tokuşu geri çevirir."])
	ogretici.kapatildi.connect(func(): ogretici_acik = false)

func _arayuzu_olustur() -> void:
	var arka_plan := ColorRect.new()
	arka_plan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arka_plan.color = Color("0a0d17")
	arka_plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arka_plan)
	var guvenli_alan := MarginContainer.new()
	guvenli_alan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guvenli_alan.add_theme_constant_override("margin_left", 16)
	guvenli_alan.add_theme_constant_override("margin_right", 16)
	guvenli_alan.add_theme_constant_override("margin_top", 16)
	guvenli_alan.add_theme_constant_override("margin_bottom", 16)
	add_child(guvenli_alan)
	var kaydirici := ScrollContainer.new()
	kaydirici.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kaydirici.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydirici.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guvenli_alan.add_child(kaydirici)
	var icerik := VBoxContainer.new()
	icerik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icerik.add_theme_constant_override("separation", 10)
	kaydirici.add_child(icerik)
	var ust_satir := HBoxContainer.new()
	ust_satir.add_theme_constant_override("separation", 8)
	icerik.add_child(ust_satir)
	var geri := Button.new()
	geri.text = "‹ Menü"
	geri.custom_minimum_size = Vector2(88, 48)
	geri.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))
	ust_satir.add_child(geri)
	baslik = Label.new()
	baslik.text = "YANKI ZİNCİRİ"
	baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.add_theme_font_size_override("font_size", 24)
	baslik.add_theme_color_override("font_color", Color("f43f5e"))
	ust_satir.add_child(baslik)
	var sag_bosluk := Control.new()
	sag_bosluk.custom_minimum_size.x = 88
	ust_satir.add_child(sag_bosluk)
	var aciklama := Label.new()
	aciklama.text = "Hedef şekli altın bloklarla kur. Bir bloğa dokunup komşusuna dokunarak veya bloğu komşusuna sürükleyerek yer değiştir."
	aciklama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aciklama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aciklama.add_theme_color_override("font_color", Color("c4cce0"))
	icerik.add_child(aciklama)
	durum = Label.new()
	durum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	durum.add_theme_font_size_override("font_size", 18)
	icerik.add_child(durum)
	var hedef_paneli := PanelContainer.new()
	hedef_paneli.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var hedef_stili := StyleBoxFlat.new()
	hedef_stili.bg_color = Color("141b2d")
	hedef_stili.border_color = Color("f43f5e")
	hedef_stili.set_border_width_all(2)
	hedef_stili.set_content_margin_all(8)
	hedef_paneli.add_theme_stylebox_override("panel", hedef_stili)
	icerik.add_child(hedef_paneli)
	var hedef_satiri := HBoxContainer.new()
	hedef_satiri.add_theme_constant_override("separation", 12)
	hedef_paneli.add_child(hedef_satiri)
	hedef_onizlemesi = HedefSekliOnizlemesi.new()
	hedef_onizlemesi.custom_minimum_size = Vector2(112, 82)
	hedef_onizlemesi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hedef_satiri.add_child(hedef_onizlemesi)
	var hedef_yazilari := VBoxContainer.new()
	hedef_yazilari.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hedef_satiri.add_child(hedef_yazilari)
	var hedef_basligi := Label.new()
	hedef_basligi.text = "OLUŞTURULACAK ŞEKİL"
	hedef_basligi.add_theme_color_override("font_color", Color("a6b4d9"))
	hedef_yazilari.add_child(hedef_basligi)
	hedef = Label.new()
	hedef.add_theme_font_size_override("font_size", 17)
	hedef.add_theme_color_override("font_color", HEDEF_RENGI)
	hedef_yazilari.add_child(hedef)
	var tahta_paneli := PanelContainer.new()
	tahta_paneli.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tahta_stili := StyleBoxFlat.new()
	tahta_stili.bg_color = Color("141b2d")
	tahta_stili.border_color = Color("f43f5e")
	tahta_stili.set_border_width_all(2)
	tahta_stili.set_content_margin_all(7)
	tahta_paneli.add_theme_stylebox_override("panel", tahta_stili)
	icerik.add_child(tahta_paneli)
	var izgara := GridContainer.new()
	izgara.columns = SUTUN
	izgara.add_theme_constant_override("h_separation", 3)
	izgara.add_theme_constant_override("v_separation", 3)
	tahta_paneli.add_child(izgara)
	var hucre_boyutu := clampf((get_viewport_rect().size.x - 71.0) / float(SUTUN), 28.0, 42.0)
	for i in SUTUN * SATIR:
		var buton := Button.new()
		buton.custom_minimum_size = Vector2.ONE * hucre_boyutu
		buton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buton.size_flags_vertical = Control.SIZE_EXPAND_FILL
		buton.mouse_filter = Control.MOUSE_FILTER_STOP
		buton.add_theme_font_size_override("font_size", 16)
		izgara.add_child(buton)
		hucre_butonlari.append(buton)
	mesaj = Label.new()
	mesaj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mesaj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mesaj.custom_minimum_size.y = 34
	mesaj.add_theme_color_override("font_color", Color("a6b4d9"))
	icerik.add_child(mesaj)
	var eylemler := HBoxContainer.new()
	eylemler.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	eylemler.add_theme_constant_override("separation", 8)
	icerik.add_child(eylemler)
	tekrar_buton = Button.new()
	tekrar_buton.text = "Yeniden Oyna"
	tekrar_buton.custom_minimum_size = Vector2(144, 52)
	tekrar_buton.visible = false
	tekrar_buton.pressed.connect(func(): _seviyeyi_yukle(seviye))
	eylemler.add_child(tekrar_buton)
	sonraki_buton = Button.new()
	sonraki_buton.text = "Sonraki Aşama"
	sonraki_buton.custom_minimum_size = Vector2(164, 52)
	sonraki_buton.visible = false
	sonraki_buton.pressed.connect(_sonraki_seviye)
	eylemler.add_child(sonraki_buton)
	geri_al_butonu = Button.new()
	geri_al_butonu.text = "Son Hamleyi Geri Al"
	geri_al_butonu.custom_minimum_size = Vector2(190, 50)
	geri_al_butonu.disabled = true
	geri_al_butonu.pressed.connect(_geri_al)
	icerik.add_child(geri_al_butonu)

func _sekil_katalogunu_olustur() -> Array[Dictionary]:
	var katalog: Array[Dictionary] = []
	for i in ParcaUretici.PARCA_HAVUZU.size():
		var kalip: Array = ParcaUretici.PARCA_HAVUZU[i].kalip[0]
		katalog.append({"ad": KAYITLI_SEKIL_ADLARI[i], "hucreler": _kaliptan_hucrelere(kalip)})
	for yeni_sekil in YENI_SEKILLER:
		katalog.append({"ad": yeni_sekil.ad, "hucreler": _kaliptan_hucrelere(yeni_sekil.kalip)})
	return katalog

func _kaliptan_hucrelere(kalip: Array) -> Array[Vector2i]:
	var sekil_hucreleri: Array[Vector2i] = []
	for y in kalip.size():
		for x in kalip[y].length():
			if kalip[y][x] == "0":
				sekil_hucreleri.append(Vector2i(x, y))
	return sekil_hucreleri

func _sekil_anahtari(hucreler_: Array[Vector2i]) -> String:
	if hucreler_.is_empty():
		return ""
	var min_x := hucreler_[0].x
	var min_y := hucreler_[0].y
	for hucre in hucreler_:
		min_x = mini(min_x, hucre.x)
		min_y = mini(min_y, hucre.y)
	var normallesmis: Array[Vector2i] = []
	for hucre in hucreler_:
		normallesmis.append(hucre - Vector2i(min_x, min_y))
	normallesmis.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	var oge_metni: PackedStringArray = []
	for hucre in normallesmis:
		oge_metni.append("%d,%d" % [hucre.x, hucre.y])
	return ";".join(oge_metni)

func _hedef_donus_anahtarlari(hucreler_: Array[Vector2i]) -> Array[String]:
	var anahtarlar: Array[String] = []
	var donen := hucreler_.duplicate()
	for _donus in 4:
		var anahtar := _sekil_anahtari(donen)
		if anahtar not in anahtarlar:
			anahtarlar.append(anahtar)
		var yeni_donen: Array[Vector2i] = []
		for hucre in donen:
			yeni_donen.append(Vector2i(-hucre.y, hucre.x))
		donen = yeni_donen
	return anahtarlar

func _seviyeyi_yukle(yeni_seviye: int) -> void:
	seviye = clampi(yeni_seviye, 0, SEVIYE_ADLARI.size() - 1)
	tamamlanan_sekil = 0
	hamle_sayisi = 0
	oyun_bitti = false
	rng.randomize()
	secili_hucre = Vector2i(-1, -1)
	surukleme_baslangici = Vector2i(-1, -1)
	hucreler.clear()
	for y in SATIR:
		var satir: Array[int] = []
		for x in SUTUN:
			satir.append(rng.randi_range(0, RENKLER.size() - 1))
		hucreler.append(satir)
	sonraki_buton.visible = false
	tekrar_buton.visible = false
	_yeni_hedef_sekli_olustur()
	mesaj.text = "Altın blokları hedefte gösterilen şekle göre yan yana getir."
	_arayuzu_guncelle()

func _yeni_hedef_sekli_olustur() -> void:
	var katalog_indeksi := (tamamlanan_sekil + seviye * 3 + rng.randi_range(0, sekil_katalogu.size() - 1)) % sekil_katalogu.size()
	aktif_sekil = sekil_katalogu[katalog_indeksi]
	aktif_sekil_hucreleri = aktif_sekil.hucreler.duplicate()
	aktif_sekil_donusleri = _hedef_donus_anahtarlari(aktif_sekil_hucreleri)
	var gereken_tas_sayisi := aktif_sekil_hucreleri.size()
	for y in SATIR:
		for x in SUTUN:
			if int(hucreler[y][x]) == HEDEF_TASI:
				hucreler[y][x] = rng.randi_range(0, RENKLER.size() - 1)
	var mumkun_hucreler: Array[Vector2i] = []
	for y in SATIR:
		for x in SUTUN:
			mumkun_hucreler.append(Vector2i(x, y))
	var konumlar: Array[Vector2i] = []
	var bulundu := false
	for _deneme in 200:
		konumlar.clear()
		var adaylar := mumkun_hucreler.duplicate()
		adaylar.shuffle()
		for i in gereken_tas_sayisi:
			konumlar.append(adaylar[i])
			var nokta := konumlar[i]
			hucreler[nokta.y][nokta.x] = HEDEF_TASI
		if not _hedef_sekli_tamamlandi():
			bulundu = true
			break
		for nokta in konumlar:
			hucreler[nokta.y][nokta.x] = rng.randi_range(0, RENKLER.size() - 1)
	if not bulundu:
		konumlar.clear()
		for i in gereken_tas_sayisi:
			konumlar.append(Vector2i(i, 0))
		for nokta in konumlar:
			hucreler[nokta.y][nokta.x] = HEDEF_TASI
	hedef_onizlemesi.goster(aktif_sekil_hucreleri, HEDEF_RENGI)

func _hucreye_dokun(konum: Vector2i) -> void:
	if oyun_bitti or not _hucre_konumu_gecerli(konum):
		return
	if secili_hucre.x < 0:
		secili_hucre = konum
		mesaj.text = "Şimdi yatay veya dikey komşu bloğa dokun. Sürükleyip bırakmak da olur."
	elif konum == secili_hucre:
		secili_hucre = Vector2i(-1, -1)
		mesaj.text = "Seçim kaldırıldı. Bir altın bloğa dokun."
	elif _komsu_hucre_mi(secili_hucre, konum):
		_bloklari_degistir(secili_hucre, konum)
	else:
		secili_hucre = konum
		mesaj.text = "Yeni blok seçildi. Yalnızca yatay veya dikey komşusuyla yer değiştirebilir."
	_arayuzu_guncelle()

func _input(olay: InputEvent) -> void:
	if ogretici_acik:
		return
	if oyun_bitti:
		return
	var basildi := false
	var birakildi := false
	var isaretci := Vector2.ZERO
	if olay is InputEventScreenTouch:
		basildi = olay.pressed
		birakildi = not olay.pressed
		isaretci = olay.position
	elif olay is InputEventMouseButton and olay.button_index == MOUSE_BUTTON_LEFT:
		basildi = olay.pressed
		birakildi = not olay.pressed
		isaretci = olay.position
	else:
		return
	var konum := _isaretci_hucresini_al(isaretci)
	if basildi and _hucre_konumu_gecerli(konum):
		surukleme_baslangici = konum
		get_viewport().set_input_as_handled()
	elif birakildi and _hucre_konumu_gecerli(surukleme_baslangici):
		if _hucre_konumu_gecerli(konum) and konum != surukleme_baslangici and _komsu_hucre_mi(surukleme_baslangici, konum):
			_bloklari_degistir(surukleme_baslangici, konum)
		elif konum == surukleme_baslangici:
			_hucreye_dokun(konum)
		elif _hucre_konumu_gecerli(konum):
			secili_hucre = surukleme_baslangici
			mesaj.text = "Blokları yalnızca yanındaki hücreyle değiştirebilirsin."
			_arayuzu_guncelle()
		surukleme_baslangici = Vector2i(-1, -1)
		get_viewport().set_input_as_handled()
	elif birakildi:
		surukleme_baslangici = Vector2i(-1, -1)

func _isaretci_hucresini_al(nokta: Vector2) -> Vector2i:
	for indeks in hucre_butonlari.size():
		if hucre_butonlari[indeks].get_global_rect().has_point(nokta):
			return Vector2i(indeks % SUTUN, floori(float(indeks) / float(SUTUN)))
	return Vector2i(-1, -1)

func _hucre_konumu_gecerli(konum: Vector2i) -> bool:
	return konum.x >= 0 and konum.x < SUTUN and konum.y >= 0 and konum.y < SATIR

func _komsu_hucre_mi(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1

func _bloklari_degistir(a: Vector2i, b: Vector2i) -> void:
	geri_al_kaydi = {
		"hucreler": hucreler.duplicate(true),
		"aktif_sekil": aktif_sekil.duplicate(true),
		"aktif_sekil_hucreleri": aktif_sekil_hucreleri.duplicate(),
		"aktif_sekil_donusleri": aktif_sekil_donusleri.duplicate(),
		"tamamlanan": tamamlanan_sekil,
		"hamle": hamle_sayisi,
		"seviye": seviye,
		"acik_seviye": acik_seviye,
		"oyun_bitti": oyun_bitti
	}
	var gecici: int = hucreler[a.y][a.x]
	hucreler[a.y][a.x] = hucreler[b.y][b.x]
	hucreler[b.y][b.x] = gecici
	hamle_sayisi += 1
	secili_hucre = Vector2i(-1, -1)
	if _hedef_sekli_tamamlandi():
		tamamlanan_sekil += 1
		var dalga_hucreleri := _yanki_dalgasini_uygula()
		if tamamlanan_sekil >= SEKIL_HEDEFI:
			_seviyeyi_kazan()
		else:
			mesaj.text = "Şekil tamamlandı! Yankı dalgası komşu renkleri dönüştürdü."
			_yeni_hedef_sekli_olustur()
			_yanki_dalgasini_goster(dalga_hucreleri)
	else:
		mesaj.text = "Bloklar yer değiştirdi. Altın blokları hedef şekle göre diz."
	_arayuzu_guncelle()

func _yanki_dalgasini_uygula() -> Array[Vector2i]:
	var altin_hucreler: Array[Vector2i] = []
	var dalga: Dictionary = {}
	for y in SATIR:
		for x in SUTUN:
			if int(hucreler[y][x]) == HEDEF_TASI:
				var hucre := Vector2i(x, y)
				altin_hucreler.append(hucre)
	for merkez in altin_hucreler:
		var yonler: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
		for yon in yonler:
			var komsu: Vector2i = merkez + yon
			if _hucre_konumu_gecerli(komsu) and int(hucreler[komsu.y][komsu.x]) != HEDEF_TASI:
				dalga[komsu] = true
	var etkilenenler: Array[Vector2i] = []
	for hucre in dalga:
		var eski_renk: int = hucreler[hucre.y][hucre.x]
		hucreler[hucre.y][hucre.x] = posmod(eski_renk + 1, RENKLER.size())
		etkilenenler.append(hucre)
	return etkilenenler

func _yanki_dalgasini_goster(hucre_listesi: Array[Vector2i]) -> void:
	for hucre in hucre_listesi:
		var buton := hucre_butonlari[hucre.y * SUTUN + hucre.x]
		buton.modulate = Color("fff0b0")
		var parilti := create_tween()
		parilti.tween_property(buton, "modulate", Color.WHITE, 0.45)

func _geri_al() -> void:
	if geri_al_kaydi.is_empty():
		return
	hucreler = geri_al_kaydi.hucreler.duplicate(true)
	aktif_sekil = geri_al_kaydi.aktif_sekil.duplicate(true)
	aktif_sekil_hucreleri = geri_al_kaydi.aktif_sekil_hucreleri.duplicate()
	aktif_sekil_donusleri = geri_al_kaydi.aktif_sekil_donusleri.duplicate()
	tamamlanan_sekil = int(geri_al_kaydi.tamamlanan)
	hamle_sayisi = int(geri_al_kaydi.hamle)
	seviye = int(geri_al_kaydi.seviye)
	acik_seviye = int(geri_al_kaydi.acik_seviye)
	oyun_bitti = bool(geri_al_kaydi.oyun_bitti)
	geri_al_kaydi.clear()
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ilerleme", "acik_seviye", acik_seviye)
	ayarlar.save(KAYIT_YOLU)
	mesaj.text = "Son değiş tokuş geri alındı."
	_arayuzu_guncelle()

func _hedef_sekli_tamamlandi() -> bool:
	var altin_hucreler: Array[Vector2i] = []
	for y in SATIR:
		for x in SUTUN:
			if int(hucreler[y][x]) == HEDEF_TASI:
				altin_hucreler.append(Vector2i(x, y))
	if altin_hucreler.size() != aktif_sekil_hucreleri.size():
		return false
	return _sekil_anahtari(altin_hucreler) in aktif_sekil_donusleri

func _seviyeyi_kazan() -> void:
	oyun_bitti = true
	mesaj.text = "TEBRİKLER! Bu aşamadaki 10 şeklin tamamını kurdun."
	acik_seviye = maxi(acik_seviye, mini(seviye + 1, SEVIYE_ADLARI.size() - 1))
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ilerleme", "acik_seviye", acik_seviye)
	ayarlar.save(KAYIT_YOLU)
	sonraki_buton.visible = seviye < SEVIYE_ADLARI.size() - 1
	tekrar_buton.visible = true

func _sonraki_seviye() -> void:
	if seviye < SEVIYE_ADLARI.size() - 1 and seviye < acik_seviye:
		_seviyeyi_yukle(seviye + 1)

func _arayuzu_guncelle() -> void:
	durum.text = "AŞAMA %d / 5  •  %s  •  Değişim: %d" % [seviye + 1, SEVIYE_ADLARI[seviye], hamle_sayisi]
	hedef.text = "%s şekli  •  %d blok" % [str(aktif_sekil.ad), aktif_sekil_hucreleri.size()]
	if oyun_bitti:
		durum.text = "AŞAMA %d / 5  •  %s  •  %d / %d ŞEKİL" % [seviye + 1, SEVIYE_ADLARI[seviye], tamamlanan_sekil, SEKIL_HEDEFI]
	geri_al_butonu.disabled = geri_al_kaydi.is_empty()
	for y in SATIR:
		for x in SUTUN:
			var buton := hucre_butonlari[y * SUTUN + x]
			var renk: int = hucreler[y][x]
			buton.disabled = oyun_bitti
			buton.text = "◆" if renk == HEDEF_TASI else ""
			buton.add_theme_color_override("font_color", Color("523500") if renk == HEDEF_TASI else Color.WHITE)
			buton.add_theme_stylebox_override("normal", _hucre_stili(HEDEF_RENGI if renk == HEDEF_TASI else RENKLER[renk], renk == HEDEF_TASI, Vector2i(x, y) == secili_hucre))
			buton.add_theme_stylebox_override("hover", _hucre_stili(HEDEF_RENGI if renk == HEDEF_TASI else RENKLER[renk], true, Vector2i(x, y) == secili_hucre))
			buton.add_theme_stylebox_override("pressed", _hucre_stili(HEDEF_RENGI if renk == HEDEF_TASI else RENKLER[renk], true, true))

func _hucre_stili(renk: Color, hedef_tasi_mi: bool, secili_mi: bool) -> StyleBoxFlat:
	var stil := StyleBoxFlat.new()
	stil.bg_color = renk
	stil.set_corner_radius_all(5)
	stil.set_content_margin_all(0)
	if hedef_tasi_mi or secili_mi:
		stil.border_color = Color.WHITE if secili_mi else Color("fff1b8")
		stil.set_border_width_all(2 if secili_mi else 1)
	return stil

func _ilerleme_oku() -> int:
	var ayarlar := ConfigFile.new()
	if ayarlar.load(KAYIT_YOLU) != OK:
		return 0
	return clampi(int(ayarlar.get_value("ilerleme", "acik_seviye", 0)), 0, SEVIYE_ADLARI.size() - 1)

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
