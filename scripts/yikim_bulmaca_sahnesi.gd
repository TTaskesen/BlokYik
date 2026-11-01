extends TemelSahne

const TAHTA_GORUNUMU := preload("res://scripts/yikim_bulmaca_tahtasi.gd")
const PARCA_ADLARI := ["Z parçası", "S parçası", "Çizgi", "Kare", "L parçası", "J parçası", "T parçası", "Artı", "Kanca"]

var yonetici := YikimBulmacaYoneticisi.new()
var secili_parca := -1
var secili_donus := 0
var secili_konum := Vector2i(3, 8)
var parca_butonlari: Array[Button] = []
var tahta_gorunumu: Control
var bilgi_etiketi: Label
var hedef_etiketi: Label
var sonuc_etiketi: Label
var dondur_butonu: Button
var yerlestir_butonu: Button
var tekrar_butonu: Button
var sonraki_butonu: Button

func _ready() -> void:
	_arayuzu_olustur()
	_bulmacayi_goster()

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
	aciklama.text = "Parçalar düşmez. Doğru şekli seçip hedef taşların arasındaki boşluğa yerleştir."
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
		buton.custom_minimum_size = Vector2(94, 58)
		buton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		buton.pressed.connect(_parca_sec.bind(secim_no))
		parca_satiri.add_child(buton)
		parca_butonlari.append(buton)
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
	minimum_dokunma_hedeflerini_uygula(icerik)

func _bulmacayi_goster() -> void:
	var toplam := YikimBulmacaYoneticisi.BULMACA_SAYISI
	hedef_etiketi.text = "BULMACA %d / %d  •  %s  •  Kalan hamle: %d  •  Hedef taş: %d" % [yonetici.bulmaca_indeksi + 1, toplam, yonetici.bulmaca_adi(), yonetici.kalan_hamle, yonetici.hedef_sayisi()]
	for secim_no in parca_butonlari.size():
		var parca_no: int = yonetici.kullanilabilir_parcalar[secim_no] if secim_no < yonetici.kullanilabilir_parcalar.size() else -1
		var buton := parca_butonlari[secim_no]
		buton.text = PARCA_ADLARI[parca_no] if parca_no >= 0 else "Kullanıldı"
		buton.disabled = parca_no < 0 or yonetici.bulmaca_tamamlandi or yonetici.bolum_tamamlandi or yonetici.kalan_hamle <= 0
		if parca_no == secili_parca:
			buton.add_theme_color_override("font_color", Color("f43f5e"))
		else:
			buton.remove_theme_color_override("font_color")
	if secili_parca not in yonetici.kullanilabilir_parcalar:
		secili_parca = -1
	var taslak: BlokParcasi = null
	var gecerli := false
	if secili_parca >= 0:
		taslak = yonetici.parca_al(secili_parca)
		taslak.konum = secili_konum
		taslak.donus = posmod(secili_donus, taslak.kalip.size())
		gecerli = yonetici.yerlestirme_gecerli_mi(secili_parca, secili_konum, secili_donus)
	tahta_gorunumu.durumu_ayarla(yonetici.tahta, taslak, gecerli)
	dondur_butonu.disabled = secili_parca < 0 or yonetici.bulmaca_tamamlandi or yonetici.bolum_tamamlandi or yonetici.kalan_hamle <= 0
	yerlestir_butonu.disabled = not gecerli
	bilgi_etiketi.text = "1) Bir parça seç.  2) Tahtada başlangıç hücresine dokun.  3) Yerleştir."
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
	_bulmacayi_goster()
	if not sonuc.satir_silindi and yonetici.kalan_hamle > 0:
		sonuc_etiketi.text = "Yerleştirme yapıldı; hedef boşluğa uyan şekli bul. Kalan hamle: %d" % yonetici.kalan_hamle
	elif not sonuc.satir_silindi and yonetici.kalan_hamle <= 0:
		sonuc_etiketi.text = "Hamle kalmadı. Bu bulmacayı yeniden deneyebilirsin."
		tekrar_butonu.visible = true

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
