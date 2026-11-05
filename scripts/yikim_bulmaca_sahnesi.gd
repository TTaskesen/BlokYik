extends TemelSahne

const TAHTA_GORUNUMU := preload("res://scripts/yikim_bulmaca_tahtasi.gd")
const OYUN_OGRETICI := preload("res://scripts/oyun_ogretici.gd")

class ParcaSekli extends Control:
	var parca_no := -1
	var parca: BlokParcasi
	var kullanildi := false

	func parca_goster(yeni_parca_no: int, yeni_parca: BlokParcasi, kullanildi_mi: bool) -> void:
		parca_no = yeni_parca_no
		parca = yeni_parca
		kullanildi = kullanildi_mi
		queue_redraw()

	func _draw() -> void:
		if parca_no < 0:
			draw_string(ThemeDB.fallback_font, size * 0.5 + Vector2(-8, 8), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("9aa3b8"))
			return
		if parca == null:
			return
		var kalip: Array = parca.kalip[0]
		var hucreler: Array[Vector2i] = []
		var min_x := 999
		var min_y := 999
		var max_x := -1
		var max_y := -1
		for y in kalip.size():
			for x in kalip[y].length():
				if kalip[y][x] == "0":
					hucreler.append(Vector2i(x, y))
					min_x = mini(min_x, x)
					min_y = mini(min_y, y)
					max_x = maxi(max_x, x)
					max_y = maxi(max_y, y)
		if hucreler.is_empty():
			return
		var boyut := minf((size.x - 12.0) / float(max_x - min_x + 1), (size.y - 12.0) / float(max_y - min_y + 1))
		var sekil_boyutu := Vector2((max_x - min_x + 1) * boyut, (max_y - min_y + 1) * boyut)
		var baslangic := (size - sekil_boyutu) * 0.5
		var hucre_rengi := parca.renk.darkened(0.18) if kullanildi else parca.renk
		for hucre in hucreler:
			var hucre_rect := Rect2(baslangic + Vector2(hucre - Vector2i(min_x, min_y)) * boyut, Vector2.ONE * (boyut - 2.0))
			draw_rect(hucre_rect, Color("090d16"), true)
			draw_rect(hucre_rect.grow(-2.0), hucre_rengi, true)

var yonetici := YikimBulmacaYoneticisi.new()
var secili_parca := -1
var secili_donus := 0
var secili_konum := Vector2i(3, 8)
var parca_butonlari: Array[Button] = []
var parca_onizlemeleri: Array[ParcaSekli] = []
var tahta_gorunumu: Control
var bilgi_etiketi: Label
var hedef_etiketi: Label
var sonuc_etiketi: Label
var dondur_butonu: Button
var yerlestir_butonu: Button
var tekrar_butonu: Button
var sonraki_butonu: Button
var geri_al_butonu: Button
var _isaretci_konumu := Vector2.ZERO
var _suruklenen_secim_no := -1
var _surukleme_baslangici := Vector2.ZERO
var _surukleme_hucre_ofseti := Vector2i.ZERO
var _surukleme_hareket_etti := false
var ogretici_acik := false

func _ready() -> void:
	_arayuzu_olustur()
	_bulmacayi_goster()
	var ogretici := OYUN_OGRETICI.new()
	add_child(ogretici)
	ogretici_acik = ogretici.ilk_oynatmada_goster("yikim_bulmaca", ["Altın hedef taşların yanındaki şekil gölgesini incele.", "Üç parçadan birini seçip sürükle veya tahtaya dokun; Döndür ile yönünü değiştir.", "Üç hamlede hedefi temizle. Bazı bulmacalardaki turuncu kapsül kaya engellerini de patlatır; Geri Al son yerleştirmeyi kurtarır."])
	ogretici.kapatildi.connect(func(): ogretici_acik = false)

func _arayuzu_olustur() -> void:
	var arka_plan := ColorRect.new()
	arka_plan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	arka_plan.color = Color("0a0d17")
	arka_plan.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(arka_plan)
	var guvenli_alan := MarginContainer.new()
	guvenli_alan.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	guvenli_alan.add_theme_constant_override("margin_left", 20)
	guvenli_alan.add_theme_constant_override("margin_right", 20)
	guvenli_alan.add_theme_constant_override("margin_top", 24)
	guvenli_alan.add_theme_constant_override("margin_bottom", 24)
	add_child(guvenli_alan)
	var kaydirici := ScrollContainer.new()
	kaydirici.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydirici.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kaydirici.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	guvenli_alan.add_child(kaydirici)
	var icerik := VBoxContainer.new()
	icerik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	icerik.add_theme_constant_override("separation", 10)
	kaydirici.add_child(icerik)
	var ust_satir := HBoxContainer.new()
	ust_satir.add_theme_constant_override("separation", 12)
	icerik.add_child(ust_satir)
	var geri := Button.new()
	geri.text = "‹ Menü"
	geri.custom_minimum_size = Vector2(88, 52)
	geri.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))
	ust_satir.add_child(geri)
	var baslik := Label.new()
	baslik.text = "YIKIM BULMACASI"
	baslik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.add_theme_font_size_override("font_size", 25)
	baslik.add_theme_color_override("font_color", Color("f43f5e"))
	ust_satir.add_child(baslik)
	var bosluk := Control.new()
	bosluk.custom_minimum_size.x = 88
	ust_satir.add_child(bosluk)
	var aciklama := Label.new()
	aciklama.text = "Alttaki şekli tahtaya sürükleyip bırak. Hedef taşların arasındaki boşluğu tamamla."
	aciklama.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	aciklama.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	aciklama.add_theme_font_size_override("font_size", 16)
	aciklama.add_theme_color_override("font_color", Color("c4cce0"))
	icerik.add_child(aciklama)
	bilgi_etiketi = Label.new()
	bilgi_etiketi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bilgi_etiketi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	bilgi_etiketi.add_theme_font_size_override("font_size", 14)
	bilgi_etiketi.add_theme_color_override("font_color", Color("a6b4d9"))
	icerik.add_child(bilgi_etiketi)
	hedef_etiketi = Label.new()
	hedef_etiketi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hedef_etiketi.add_theme_font_size_override("font_size", 18)
	hedef_etiketi.add_theme_color_override("font_color", YikimBulmacaYoneticisi.HEDEF_RENGI)
	icerik.add_child(hedef_etiketi)
	tahta_gorunumu = TAHTA_GORUNUMU.new()
	tahta_gorunumu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tahta_gorunumu.custom_minimum_size = Vector2(300, 360)
	tahta_gorunumu.hucre_secildi.connect(_hucre_secildi)
	icerik.add_child(tahta_gorunumu)
	var parca_satiri := HBoxContainer.new()
	parca_satiri.add_theme_constant_override("separation", 8)
	parca_satiri.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icerik.add_child(parca_satiri)
	for secim_no in 3:
		var buton := Button.new()
		buton.custom_minimum_size = Vector2(94, 82)
		buton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var sekil := ParcaSekli.new()
		sekil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		sekil.mouse_filter = Control.MOUSE_FILTER_IGNORE
		buton.add_child(sekil)
		buton.pressed.connect(_parca_sec.bind(secim_no))
		buton.button_down.connect(_parca_suruklemesini_baslat.bind(secim_no))
		parca_satiri.add_child(buton)
		parca_butonlari.append(buton)
		parca_onizlemeleri.append(sekil)
	var islem_satiri := HBoxContainer.new()
	islem_satiri.add_theme_constant_override("separation", 8)
	islem_satiri.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icerik.add_child(islem_satiri)
	dondur_butonu = Button.new()
	dondur_butonu.text = "Döndür"
	dondur_butonu.custom_minimum_size = Vector2(132, 56)
	dondur_butonu.pressed.connect(_parcayi_dondur)
	islem_satiri.add_child(dondur_butonu)
	yerlestir_butonu = Button.new()
	yerlestir_butonu.text = "Parçayı Yerleştir"
	yerlestir_butonu.custom_minimum_size = Vector2(170, 56)
	yerlestir_butonu.pressed.connect(_parcayi_yerlestir)
	islem_satiri.add_child(yerlestir_butonu)
	geri_al_butonu = Button.new()
	geri_al_butonu.text = "Geri Al"
	geri_al_butonu.custom_minimum_size = Vector2(112, 56)
	geri_al_butonu.disabled = true
	geri_al_butonu.pressed.connect(_geri_al)
	var geri_al_satiri := HBoxContainer.new()
	geri_al_satiri.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icerik.add_child(geri_al_satiri)
	geri_al_satiri.add_child(geri_al_butonu)
	sonuc_etiketi = Label.new()
	sonuc_etiketi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sonuc_etiketi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sonuc_etiketi.custom_minimum_size.y = 36
	sonuc_etiketi.add_theme_font_size_override("font_size", 16)
	icerik.add_child(sonuc_etiketi)
	var sonuc_satiri := HBoxContainer.new()
	sonuc_satiri.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sonuc_satiri.add_theme_constant_override("separation", 8)
	icerik.add_child(sonuc_satiri)
	tekrar_butonu = Button.new()
	tekrar_butonu.text = "Tekrar Dene"
	tekrar_butonu.custom_minimum_size = Vector2(132, 52)
	tekrar_butonu.visible = false
	tekrar_butonu.pressed.connect(_tekrar_dene)
	sonuc_satiri.add_child(tekrar_butonu)
	sonraki_butonu = Button.new()
	sonraki_butonu.text = "Sonraki Bulmaca"
	sonraki_butonu.custom_minimum_size = Vector2(180, 52)
	sonraki_butonu.visible = false
	sonraki_butonu.pressed.connect(_sonraki_bulmaca)
	sonuc_satiri.add_child(sonraki_butonu)

func _bulmacayi_goster() -> void:
	var toplam := YikimBulmacaYoneticisi.BULMACA_SAYISI
	hedef_etiketi.text = "BULMACA %d / %d  •  %s  •  Kalan hamle: %d  •  Hedef taş: %d" % [yonetici.bulmaca_indeksi + 1, toplam, yonetici.bulmaca_adi(), yonetici.kalan_hamle, yonetici.hedef_sayisi()]
	for secim_no in parca_butonlari.size():
		var parca_no: int = yonetici.kullanilabilir_parcalar[secim_no] if secim_no < yonetici.kullanilabilir_parcalar.size() else -1
		var buton := parca_butonlari[secim_no]
		buton.text = ""
		buton.disabled = parca_no < 0 or yonetici.bulmaca_tamamlandi or yonetici.bolum_tamamlandi or yonetici.kalan_hamle <= 0
		buton.modulate = Color("ffd7df") if parca_no == secili_parca else Color.WHITE
		parca_onizlemeleri[secim_no].parca_goster(parca_no, yonetici.parca_al(parca_no) if parca_no >= 0 else null, parca_no < 0)
	if secili_parca not in yonetici.kullanilabilir_parcalar:
		secili_parca = -1
	var taslak: BlokParcasi = null
	var gecerli := false
	if secili_parca >= 0:
		taslak = yonetici.parca_al(secili_parca)
		taslak.konum = secili_konum
		taslak.donus = posmod(secili_donus, taslak.kalip.size())
		gecerli = yonetici.yerlestirme_gecerli_mi(secili_parca, secili_konum, secili_donus)
	tahta_gorunumu.durumu_ayarla(yonetici.tahta, taslak, gecerli, yonetici.cozum_parcasi_al())
	dondur_butonu.disabled = secili_parca < 0 or yonetici.bulmaca_tamamlandi or yonetici.bolum_tamamlandi or yonetici.kalan_hamle <= 0
	yerlestir_butonu.disabled = not gecerli
	geri_al_butonu.disabled = yonetici.geri_al_kaydi.is_empty()
	bilgi_etiketi.text = "Hedef siluetini tamamla. Üç hamlen var; bazı bulmacalarda kaya engelleri ve bölgeyi temizleyen turuncu kapsül bulunur."
	if yonetici.bolum_tamamlandi:
		sonuc_etiketi.text = "TEBRİKLER! 15 yıkım bulmacasının tamamını çözdün."
		tekrar_butonu.text = "Baştan Oyna"
		tekrar_butonu.visible = true
		sonraki_butonu.visible = false
	elif yonetici.bulmaca_tamamlandi:
		sonuc_etiketi.text = "Hedef taşlar temizlendi. Bulmaca tamamlandı!"
		tekrar_butonu.visible = false
		sonraki_butonu.visible = true
	else:
		sonuc_etiketi.text = "" if yonetici.kalan_hamle > 0 else "Hamle kalmadı. Bu bulmacayı yeniden deneyebilirsin."
		tekrar_butonu.visible = yonetici.kalan_hamle <= 0
		sonraki_butonu.visible = false

func _parca_sec(secim_no: int) -> void:
	if secim_no < 0 or secim_no >= yonetici.kullanilabilir_parcalar.size():
		return
	secili_parca = yonetici.kullanilabilir_parcalar[secim_no]
	secili_donus = 0
	var parca := yonetici.parca_al(secili_parca)
	var ayak_y := 0
	for y in range(parca.kalip[0].size() - 1, -1, -1):
		if "0" in parca.kalip[0][y]:
			ayak_y = y
			break
	secili_konum = Vector2i(3, 11 - ayak_y)
	_bulmacayi_goster()

func _parca_suruklemesini_baslat(secim_no: int) -> void:
	_suruklenen_secim_no = secim_no
	_surukleme_baslangici = _isaretci_konumu
	_surukleme_hareket_etti = false
	_parca_sec(secim_no)
	_surukleme_hucre_ofseti = _parca_ankraj_hucresi_al(secili_parca, secili_donus)

func _parca_ankraj_hucresi_al(parca_no: int, donus: int) -> Vector2i:
	var parca := yonetici.parca_al(parca_no)
	parca.donus = posmod(donus, parca.kalip.size())
	parca.konum = Vector2i.ZERO
	var hucreler := parca.hucreler()
	if hucreler.is_empty():
		return Vector2i.ZERO
	var min_x := hucreler[0].x
	var max_x := hucreler[0].x
	var min_y := hucreler[0].y
	var max_y := hucreler[0].y
	for hucre in hucreler:
		min_x = mini(min_x, hucre.x)
		max_x = maxi(max_x, hucre.x)
		min_y = mini(min_y, hucre.y)
		max_y = maxi(max_y, hucre.y)
	return Vector2i(floori(float(min_x + max_x) * 0.5), floori(float(min_y + max_y) * 0.5))

func _input(olay: InputEvent) -> void:
	if ogretici_acik:
		return
	if olay is InputEventScreenTouch:
		_isaretci_konumu = olay.position
		if not olay.pressed:
			_suruklemeyi_bitir()
	elif olay is InputEventScreenDrag:
		_isaretci_konumu = olay.position
		_surukleme_konumunu_guncelle()
	elif olay is InputEventMouseButton and olay.button_index == MOUSE_BUTTON_LEFT:
		_isaretci_konumu = olay.position
		if not olay.pressed:
			_suruklemeyi_bitir()
	elif olay is InputEventMouseMotion:
		_isaretci_konumu = olay.position
		_surukleme_konumunu_guncelle()

func _surukleme_konumunu_guncelle() -> void:
	if _suruklenen_secim_no < 0:
		return
	if not _surukleme_hareket_etti and _isaretci_konumu.distance_to(_surukleme_baslangici) < 8.0:
		return
	_surukleme_hareket_etti = true
	var tahta_noktasi: Vector2 = tahta_gorunumu.get_global_transform_with_canvas().affine_inverse() * _isaretci_konumu
	var hucre: Vector2i = tahta_gorunumu.hucre_konumu_al(tahta_noktasi)
	if hucre.x < 0:
		return
	secili_konum = hucre - _surukleme_hucre_ofseti
	_bulmacayi_goster()

func _suruklemeyi_bitir() -> void:
	if _suruklenen_secim_no < 0:
		return
	_surukleme_konumunu_guncelle()
	if _surukleme_hareket_etti:
		var tahta_noktasi: Vector2 = tahta_gorunumu.get_global_transform_with_canvas().affine_inverse() * _isaretci_konumu
		var hucre: Vector2i = tahta_gorunumu.hucre_konumu_al(tahta_noktasi)
		if hucre.x >= 0:
			secili_konum = hucre - _surukleme_hucre_ofseti
			_bulmacayi_goster()
			_parcayi_yerlestir()
		else:
			sonuc_etiketi.text = "Parçayı tahtadaki bir hücreye bırak."
		get_viewport().set_input_as_handled()
	_suruklenen_secim_no = -1
	_surukleme_hareket_etti = false

func _hucre_secildi(konum: Vector2i) -> void:
	if secili_parca < 0:
		sonuc_etiketi.text = "Önce yerleştireceğin parçayı seç."
		return
	secili_konum = konum
	_bulmacayi_goster()

func _parcayi_dondur() -> void:
	if secili_parca < 0:
		return
	var parca := yonetici.parca_al(secili_parca)
	secili_donus = posmod(secili_donus + 1, parca.kalip.size())
	_bulmacayi_goster()

func _parcayi_yerlestir() -> void:
	if secili_parca < 0:
		return
	var sonuc := yonetici.hamleyi_yap(secili_parca, secili_konum, secili_donus)
	if not sonuc.gecerli:
		sonuc_etiketi.text = "Bu yerleşim çakışıyor veya ızgara dışında."
		return
	if sonuc.bulmaca_tamamlandi:
		secili_parca = -1
	elif yonetici.kalan_hamle > 0:
		var satirlar := yonetici.kullanilabilir_parcalar
		secili_parca = satirlar[0] if not satirlar.is_empty() else -1
		secili_donus = 0
		if not sonuc.satir_silindi and not sonuc.hedef_temizlendi and yonetici.kalan_hamle > 0:
			sonuc_etiketi.text = "Kapsül patladı ve çevresini temizledi. Kalan hamle: %d" % yonetici.kalan_hamle if sonuc.ozel_parca else "Yerleştirme yapıldı; hedef boşluğa uyan şekli bul. Kalan hamle: %d" % yonetici.kalan_hamle
	elif not sonuc.satir_silindi and yonetici.kalan_hamle <= 0:
		sonuc_etiketi.text = "Hamle kalmadı. Bu bulmacayı yeniden deneyebilirsin."
		tekrar_butonu.visible = true
	_bulmacayi_goster()

func _geri_al() -> void:
	if yonetici.geri_al():
		secili_parca = -1
		secili_donus = 0
		sonuc_etiketi.text = "Son yerleştirme geri alındı."

func _tekrar_dene() -> void:
	if yonetici.bolum_tamamlandi:
		yonetici.kampanyayi_sifirla()
	else:
		yonetici.tekrar_dene()
	secili_parca = -1
	secili_donus = 0
	_bulmacayi_goster()

func _sonraki_bulmaca() -> void:
	if yonetici.sonraki_bulmaca():
		secili_parca = -1
		secili_donus = 0
		_bulmacayi_goster()

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
