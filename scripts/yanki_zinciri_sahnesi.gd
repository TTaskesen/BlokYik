extends TemelSahne

const SUTUN := 8
const SATIR := 9
const BOS := -1
const BOMBA := 4
const RENKLER: Array[Color] = [Color("42b7ff"), Color("fa5573"), Color("ffd34e"), Color("63d98b")]
const RENK_ADLARI := ["mavi", "pembe", "sarı", "yeşil"]
const SEVIYE_HEDEFLERI := [12, 16, 20, 24, 28]
const SEVIYE_HAMLELERI := [18, 18, 19, 20, 21]
const SEVIYE_ADLARI := ["İlk Yankı", "Çift Patlama", "Dar Koridor", "Bomba Ustası", "Son Rezonans"]
const KAYIT_YOLU := "user://yanki_zinciri_ilerleme.cfg"

var hucreler: Array = []
var seviye := 0
var acik_seviye := 0
var hedef_toplanan := 0
var kalan_hamle := 0
var oyun_bitti := false
var sonuc := ""
var rng := RandomNumberGenerator.new()
var hucre_butonlari: Array[Button] = []
var baslik: Label
var durum: Label
var hedef: Label
var mesaj: Label
var sonraki_buton: Button
var tekrar_buton: Button

func _ready() -> void:
	acik_seviye = _ilerleme_oku()
	seviye = mini(acik_seviye, SEVIYE_ADLARI.size() - 1)
	_arayuzu_olustur()
	_seviyeyi_yukle(seviye)

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
	guvenli_alan.add_theme_constant_override("margin_top", 20)
	guvenli_alan.add_theme_constant_override("margin_bottom", 20)
	add_child(guvenli_alan)
	var kaydirici := ScrollContainer.new()
	kaydirici.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kaydirici.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydirici.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guvenli_alan.add_child(kaydirici)
	var icerik := VBoxContainer.new()
	icerik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icerik.add_theme_constant_override("separation", 12)
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
	aciklama.text = "Yan yana aynı renkte en az iki bloğa dokun. Beşli gruplar bomba bırakır; bombalar zincirleme patlar."
	aciklama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aciklama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aciklama.add_theme_color_override("font_color", Color("c4cce0"))
	icerik.add_child(aciklama)
	durum = Label.new()
	durum.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	durum.add_theme_font_size_override("font_size", 18)
	icerik.add_child(durum)
	hedef = Label.new()
	hedef.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hedef.add_theme_font_size_override("font_size", 17)
	hedef.add_theme_color_override("font_color", Color("ffd34e"))
	icerik.add_child(hedef)
	var tahta_paneli := PanelContainer.new()
	tahta_paneli.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var tahta_stili := StyleBoxFlat.new()
	tahta_stili.bg_color = Color("141b2d")
	tahta_stili.border_color = Color("f43f5e")
	tahta_stili.set_border_width_all(2)
	tahta_stili.set_content_margin_all(8)
	tahta_paneli.add_theme_stylebox_override("panel", tahta_stili)
	icerik.add_child(tahta_paneli)
	var izgara := GridContainer.new()
	izgara.columns = SUTUN
	izgara.add_theme_constant_override("h_separation", 4)
	izgara.add_theme_constant_override("v_separation", 4)
	tahta_paneli.add_child(izgara)
	for i in SUTUN * SATIR:
		var buton := Button.new()
		buton.custom_minimum_size = Vector2(38, 38)
		buton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buton.size_flags_vertical = Control.SIZE_EXPAND_FILL
		buton.add_theme_font_size_override("font_size", 18)
		buton.pressed.connect(_hucreye_dokun.bind(i % SUTUN, int(i / SUTUN)))
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
	sonraki_buton.text = "Sonraki Bölüm"
	sonraki_buton.custom_minimum_size = Vector2(164, 52)
	sonraki_buton.visible = false
	sonraki_buton.pressed.connect(_sonraki_seviye)
	eylemler.add_child(sonraki_buton)
	minimum_dokunma_hedeflerini_uygula(icerik)

func _seviyeyi_yukle(yeni_seviye: int) -> void:
	seviye = clampi(yeni_seviye, 0, SEVIYE_ADLARI.size() - 1)
	hedef_toplanan = 0
	kalan_hamle = SEVIYE_HAMLELERI[seviye]
	oyun_bitti = false
	sonuc = ""
	rng.seed = 84721 + seviye * 7919
	hucreler.clear()
	for y in SATIR:
		var satir: Array[int] = []
		for x in SUTUN:
			satir.append(rng.randi_range(0, _kullanilan_renk_sayisi() - 1))
		hucreler.append(satir)
	sonraki_buton.visible = false
	tekrar_buton.visible = false
	mesaj.text = "Aynı renkten büyük grup, daha geniş patlama zinciri oluşturur."
	_arayuzu_guncelle()

func _hucreye_dokun(x: int, y: int) -> void:
	if oyun_bitti or y < 0 or y >= SATIR or x < 0 or x >= SUTUN:
		return
	var grup := _bagli_grubu_bul(Vector2i(x, y))
	var parca_rengi: int = hucreler[y][x]
	if parca_rengi == BOS:
		return
	if parca_rengi == BOMBA:
		grup = [Vector2i(x, y)]
	if parca_rengi != BOMBA and grup.size() < 2:
		mesaj.text = "Patlatmak için aynı renkten en az iki bitişik blok seç."
		return
	kalan_hamle -= 1
	var bomba_birak := parca_rengi != BOMBA and grup.size() >= 5
	var temizlenen := _grubu_patlat(grup)
	if bomba_birak and hucreler[y][x] == BOS:
		hucreler[y][x] = BOMBA
	_yercekimi_ve_doldurma()
	var zincir := _zincir_eslesmelerini_temizle()
	var karistirildi := false
	if hedef_toplanan < SEVIYE_HEDEFLERI[seviye] and not _hamle_var_mi():
		_tahtayi_karistir()
		karistirildi = true
	if hedef_toplanan >= SEVIYE_HEDEFLERI[seviye]:
		_seviyeyi_kazan()
	elif kalan_hamle <= 0:
		_oyunu_kaybet()
	else:
		var aciklama := "%d blok patladı." % temizlenen
		if bomba_birak:
			aciklama += " Beşli grup bomba bıraktı!"
		if zincir > 0:
			aciklama += " %d otomatik yankı zinciri!" % zincir
		if karistirildi:
			aciklama += " Tahta yeni hamle için karıştırıldı."
		mesaj.text = aciklama
	_arayuzu_guncelle()

func _bagli_grubu_bul(baslangic: Vector2i) -> Array[Vector2i]:
	var sonuc_grubu: Array[Vector2i] = []
	var renk: int = hucreler[baslangic.y][baslangic.x]
	if renk < 0 or renk >= RENKLER.size():
		return sonuc_grubu
	var ziyaret_edildi: Dictionary = {}
	var kuyruk: Array[Vector2i] = [baslangic]
	ziyaret_edildi[baslangic] = true
	while not kuyruk.is_empty():
		var hucre: Vector2i = kuyruk.pop_front()
		sonuc_grubu.append(hucre)
		for yon in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var komsu: Vector2i = hucre + yon
			if komsu.x < 0 or komsu.x >= SUTUN or komsu.y < 0 or komsu.y >= SATIR or ziyaret_edildi.has(komsu):
				continue
			if int(hucreler[komsu.y][komsu.x]) == renk:
				ziyaret_edildi[komsu] = true
				kuyruk.append(komsu)
	return sonuc_grubu

func _grubu_patlat(grup: Array[Vector2i]) -> int:
	var temizlenecek: Dictionary = {}
	var bomba_kuyrugu: Array[Vector2i] = []
	for hucre in grup:
		temizlenecek[hucre] = true
		if int(hucreler[hucre.y][hucre.x]) == BOMBA:
			bomba_kuyrugu.append(hucre)
	while not bomba_kuyrugu.is_empty():
		var bomba: Vector2i = bomba_kuyrugu.pop_front()
		for y in range(maxi(0, bomba.y - 1), mini(SATIR, bomba.y + 2)):
			for x in range(maxi(0, bomba.x - 1), mini(SUTUN, bomba.x + 2)):
				var hedef_hucre := Vector2i(x, y)
				if temizlenecek.has(hedef_hucre):
					continue
				if int(hucreler[y][x]) == BOMBA:
					bomba_kuyrugu.append(hedef_hucre)
				temizlenecek[hedef_hucre] = true
	var temizlenen := 0
	for hucre in temizlenecek:
		var renk: int = hucreler[hucre.y][hucre.x]
		if renk == seviye % RENKLER.size():
			hedef_toplanan += 1
		if renk != BOS:
			temizlenen += 1
		hucreler[hucre.y][hucre.x] = BOS
	return temizlenen

func _yercekimi_ve_doldurma() -> void:
	for x in SUTUN:
		var kalan: Array[int] = []
		for y in range(SATIR - 1, -1, -1):
			var renk: int = hucreler[y][x]
			if renk != BOS:
				kalan.append(renk)
		for y in SATIR:
			hucreler[y][x] = BOS
		for indeks in kalan.size():
			hucreler[SATIR - 1 - indeks][x] = kalan[indeks]
		for y in range(SATIR - kalan.size() - 1, -1, -1):
			hucreler[y][x] = rng.randi_range(0, _kullanilan_renk_sayisi() - 1)

func _zincir_eslesmelerini_temizle() -> int:
	var zincir := 0
	while zincir < 8:
		var grup := _ilk_buyuk_grubu_bul()
		if grup.is_empty():
			break
		_grubu_patlat(grup)
		_yercekimi_ve_doldurma()
		zincir += 1
		if hedef_toplanan >= SEVIYE_HEDEFLERI[seviye]:
			break
	return zincir

func _ilk_buyuk_grubu_bul() -> Array[Vector2i]:
	var bakilan: Dictionary = {}
	for y in SATIR:
		for x in SUTUN:
			var hucre := Vector2i(x, y)
			var renk: int = hucreler[y][x]
			if renk < 0 or renk >= RENKLER.size() or bakilan.has(hucre):
				continue
			var grup := _bagli_grubu_bul(hucre)
			for oge in grup:
				bakilan[oge] = true
			if grup.size() >= 3:
				return grup
	return []

func _kullanilan_renk_sayisi() -> int:
	return mini(RENKLER.size(), 3 + int(seviye / 2))

func _hamle_var_mi() -> bool:
	for y in SATIR:
		for x in SUTUN:
			var renk: int = hucreler[y][x]
			if renk == BOMBA:
				return true
			if renk < 0 or renk >= RENKLER.size():
				continue
			if x + 1 < SUTUN and int(hucreler[y][x + 1]) == renk:
				return true
			if y + 1 < SATIR and int(hucreler[y + 1][x]) == renk:
				return true
	return false

func _tahtayi_karistir() -> void:
	var taslar: Array[int] = []
	for y in SATIR:
		for x in SUTUN:
			taslar.append(int(hucreler[y][x]))
	for i in range(taslar.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var gecici: int = taslar[i]
		taslar[i] = taslar[j]
		taslar[j] = gecici
	var indeks := 0
	for y in SATIR:
		for x in SUTUN:
			hucreler[y][x] = taslar[indeks]
			indeks += 1
	if not _hamle_var_mi():
		var renk := rng.randi_range(0, _kullanilan_renk_sayisi() - 1)
		hucreler[0][0] = renk
		hucreler[0][1] = renk

func _seviyeyi_kazan() -> void:
	oyun_bitti = true
	sonuc = "TEBRİKLER! Hedef yankı kristallerini topladın."
	acik_seviye = maxi(acik_seviye, mini(seviye + 1, SEVIYE_ADLARI.size() - 1))
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ilerleme", "acik_seviye", acik_seviye)
	ayarlar.save(KAYIT_YOLU)
	sonraki_buton.visible = seviye < SEVIYE_ADLARI.size() - 1
	tekrar_buton.visible = true

func _oyunu_kaybet() -> void:
	oyun_bitti = true
	sonuc = "Hamleler bitti. Bu bölümü yeniden deneyebilirsin."
	tekrar_buton.visible = true

func _sonraki_seviye() -> void:
	if seviye < SEVIYE_ADLARI.size() - 1 and seviye < acik_seviye:
		_seviyeyi_yukle(seviye + 1)

func _arayuzu_guncelle() -> void:
	durum.text = "BÖLÜM %d / 5  •  %s  •  Hamle: %d" % [seviye + 1, SEVIYE_ADLARI[seviye], kalan_hamle]
	hedef.text = "%s kristal: %d / %d" % [RENK_ADLARI[seviye % RENKLER.size()].capitalize(), hedef_toplanan, SEVIYE_HEDEFLERI[seviye]]
	if oyun_bitti:
		mesaj.text = sonuc
	for y in SATIR:
		for x in SUTUN:
			var buton := hucre_butonlari[y * SUTUN + x]
			var renk: int = hucreler[y][x]
			buton.disabled = oyun_bitti or renk == BOS
			if renk == BOMBA:
				buton.text = "✦"
				buton.add_theme_color_override("font_color", Color.WHITE)
				buton.add_theme_stylebox_override("normal", _hucre_stili(Color("ff8c42")))
			elif renk >= 0 and renk < RENKLER.size():
				buton.text = ""
				buton.add_theme_stylebox_override("normal", _hucre_stili(RENKLER[renk]))
			else:
				buton.text = ""
				buton.add_theme_stylebox_override("normal", _hucre_stili(Color("1b2233")))

func _hucre_stili(renk: Color) -> StyleBoxFlat:
	var stil := StyleBoxFlat.new()
	stil.bg_color = renk
	stil.set_corner_radius_all(5)
	stil.set_content_margin_all(0)
	return stil

func _ilerleme_oku() -> int:
	var ayarlar := ConfigFile.new()
	if ayarlar.load(KAYIT_YOLU) != OK:
		return 0
	return clampi(int(ayarlar.get_value("ilerleme", "acik_seviye", 0)), 0, SEVIYE_ADLARI.size() - 1)

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
