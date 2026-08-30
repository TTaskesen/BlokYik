extends TemelSahne

var ayar_yoneticisi := AyarYoneticisi.new()
@export var kayit_yolu := OyunKayitYoneticisi.KAYIT_YOLU
var kayit_yoneticisi: OyunKayitYoneticisi

@onready var guvenli_alan: MarginContainer = $GuvenliAlan
@onready var icerik_kaydirici: ScrollContainer = $GuvenliAlan/IcerikKaydirici
@onready var ortala: CenterContainer = $GuvenliAlan/IcerikKaydirici/Ortala
@onready var menu_paneli: VBoxContainer = $GuvenliAlan/IcerikKaydirici/Ortala/Panel
@onready var devam_et_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/DevamEt
@onready var kayit_durum_etiketi: Label = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/KayitDurumu
@onready var cikis_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Cikis
@onready var modal_engelleyici: ColorRect = $ModalEngelleyici
@onready var cikis_onayi: PanelContainer = $CikisOnayi
var cikis_istegi_isleyicisi: Callable

func _ready() -> void:
	kayit_yoneticisi = OyunKayitYoneticisi.new(kayit_yolu)
	ana_menu_stilini_uygula()
	cikis_butonu.visible = not mobil_platform_mu()
	cikis_modalini_goster(false)
	$CikisOnayi/Icerik/Evet.pressed.connect(_uygulamadan_cik)
	$CikisOnayi/Icerik/Vazgec.pressed.connect(func(): cikis_modalini_goster(false))
	minimum_dokunma_hedeflerini_uygula(menu_paneli)
	minimum_dokunma_hedeflerini_uygula(cikis_onayi)
	resized.connect(ana_menu_yerlesimini_guncelle)
	ana_menu_yerlesimini_guncelle()
	devam_et_durumunu_guncelle()
	queue_redraw()

func _on_basla_pressed() -> void:
	# Yeni oyun eski devam durumunu asla yanlışlıkla kullanmaz.
	kayit_yoneticisi.kaydi_sil()
	get_tree().set_meta("kayitli_oyun_yukle", false)
	sahneye_gec("res://scenes/BlokYikOyun.tscn")

func _on_nasil_oynanir_pressed() -> void:
	sahneye_gec("res://scenes/NasilOynanir.tscn")

func _on_ayarlar_pressed() -> void:
	sahneye_gec("res://scenes/Ayarlar.tscn")

func _on_devam_et_pressed() -> void:
	if not kayitli_oyuna_devam_etmeye_hazir_mi():
		return
	sahneye_gec("res://scenes/BlokYikOyun.tscn")

func kayitli_oyuna_devam_etmeye_hazir_mi() -> bool:
	var kayit_durumu := kayit_yoneticisi.kayit_durumu()
	if not kayit_durumu.gecerli:
		devam_et_durumunu_guncelle(kayit_durumu)
		return false
	get_tree().set_meta("kayitli_oyun_yukle", true)
	return true

func devam_et_durumunu_guncelle(kayit_durumu: Dictionary = {}) -> void:
	if kayit_durumu.is_empty():
		kayit_durumu = kayit_yoneticisi.kayit_durumu()
	devam_et_butonu.disabled = not kayit_durumu.gecerli
	devam_et_butonu.tooltip_text = kayit_durumu.mesaj
	kayit_durum_etiketi.text = "" if kayit_durumu.gecerli else kayit_durumu.mesaj

func _on_yuksek_skorlar_pressed() -> void:
	sahneye_gec("res://scenes/YuksekSkorlar.tscn")

func _on_hakkinda_pressed() -> void:
	sahneye_gec("res://scenes/Hakkinda.tscn")

func _on_cikis_pressed() -> void:
	if mobil_platform_mu():
		cikis_modalini_goster(true)
		return
	_uygulamadan_cik()

func _uygulamadan_cik() -> void:
	if cikis_istegi_isleyicisi.is_valid():
		cikis_istegi_isleyicisi.call()
		return
	var ses_yoneticisi := get_node_or_null("/root/SesYonetici") as SesYoneticisi
	if ses_yoneticisi:
		ses_yoneticisi.uygulamadan_cik()
	else:
		get_tree().quit()

func geri_istegini_isle() -> void:
	cikis_modalini_goster(not cikis_onayi.visible)

func cikis_modalini_goster(goster: bool) -> void:
	modal_engelleyici.visible = goster
	cikis_onayi.visible = goster
	if goster:
		$CikisOnayi/Icerik/Vazgec.grab_focus()

func ana_menu_yerlesimini_guncelle() -> void:
	_guvenli_alan_bosluklarini_guncelle()
	var yatay_bosluk := float(guvenli_alan.get_theme_constant("margin_left") + guvenli_alan.get_theme_constant("margin_right"))
	var kullanilabilir_genislik := maxf(240.0, size.x - yatay_bosluk - 8.0)
	menu_paneli.custom_minimum_size.x = minf(420.0, kullanilabilir_genislik)
	if mobil_platform_mu():
		menu_paneli.add_theme_constant_override("separation", 14)
		menu_paneli.get_node("Baslik").add_theme_font_size_override("font_size", 50)
	ortala.custom_minimum_size = Vector2(
		kullanilabilir_genislik,
		maxf(icerik_kaydirici.size.y, menu_paneli.get_combined_minimum_size().y)
	)
	var sol_bosluk := float(guvenli_alan.get_theme_constant("margin_left"))
	var ust_bosluk := float(guvenli_alan.get_theme_constant("margin_top"))
	var sag_bosluk := float(guvenli_alan.get_theme_constant("margin_right"))
	var alt_bosluk := float(guvenli_alan.get_theme_constant("margin_bottom"))
	var guvenli_dikdortgen := Rect2(
		Vector2(sol_bosluk, ust_bosluk),
		Vector2(maxf(1.0, size.x - sol_bosluk - sag_bosluk), maxf(1.0, size.y - ust_bosluk - alt_bosluk))
	)
	var onay_boyutu := Vector2(
		minf(360.0, guvenli_dikdortgen.size.x),
		minf(maxf(240.0, cikis_onayi.get_combined_minimum_size().y), guvenli_dikdortgen.size.y)
	)
	cikis_onayi.set_anchors_preset(Control.PRESET_TOP_LEFT)
	cikis_onayi.position = guvenli_dikdortgen.get_center() - onay_boyutu * 0.5
	cikis_onayi.size = onay_boyutu
	queue_redraw()

func ana_menu_stilini_uygula() -> void:
	var vurgu := Color("f43f5e")
	var panel_rengi := Color("141b2d")
	var normal := stil_kutusu(panel_rengi.darkened(0.08), vurgu, 2)
	var hover := stil_kutusu(panel_rengi.lightened(0.08), vurgu.lightened(0.1), 2)
	var basili := stil_kutusu(panel_rengi.lightened(0.16), vurgu, 3)
	for buton in [
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/Basla,
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/NasilOynanir,
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/Ayarlar,
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/DevamEt,
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/YuksekSkorlar,
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/Hakkinda,
		$GuvenliAlan/IcerikKaydirici/Ortala/Panel/Cikis,
		$CikisOnayi/Icerik/Evet,
		$CikisOnayi/Icerik/Vazgec,
	]:
		buton.add_theme_stylebox_override("normal", normal)
		buton.add_theme_stylebox_override("hover", hover)
		buton.add_theme_stylebox_override("pressed", basili)
		buton.add_theme_stylebox_override("focus", basili)
		buton.add_theme_color_override("font_color", Color("f5f7ff"))
		buton.add_theme_color_override("font_hover_color", Color("ffffff"))
	$GuvenliAlan/IcerikKaydirici/Ortala/Panel/KayitDurumu.add_theme_color_override("font_color", vurgu.lightened(0.15))
	$GuvenliAlan/IcerikKaydirici/Ortala/Panel/AltBaslik.add_theme_color_override("font_color", Color("a6b4d9"))

func stil_kutusu(arka_plan: Color, kenar: Color, kenar_genisligi: int) -> StyleBoxFlat:
	var stil := StyleBoxFlat.new()
	stil.bg_color = arka_plan
	stil.border_color = kenar
	stil.set_border_width_all(kenar_genisligi)
	stil.set_corner_radius_all(8)
	stil.content_margin_left = 14.0
	stil.content_margin_right = 14.0
	stil.content_margin_top = 8.0
	stil.content_margin_bottom = 8.0
	return stil

func _draw() -> void:
	if not is_instance_valid(menu_paneli) or menu_paneli.size == Vector2.ZERO:
		return
	var panel_rect := menu_paneli.get_global_rect().grow(18.0)
	draw_rect(panel_rect, Color(0.078, 0.106, 0.176, 0.92), true)
	draw_rect(panel_rect, Color("f43f5e"), false, 2.0)

func _guvenli_alan_bosluklarini_guncelle() -> void:
	var sol := 24.0
	var ust := 24.0
	var sag := 24.0
	var alt := 24.0
	if mobil_platform_mu():
		var pencere_boyutu := Vector2(DisplayServer.window_get_size())
		var guvenli_dikdortgen := DisplayServer.get_display_safe_area()
		if pencere_boyutu.x > 0.0 and pencere_boyutu.y > 0.0 and guvenli_dikdortgen.size.x > 0.0 and guvenli_dikdortgen.size.y > 0.0:
			var olcek := size / pencere_boyutu
			sol = maxf(sol, guvenli_dikdortgen.position.x * olcek.x)
			ust = maxf(ust, guvenli_dikdortgen.position.y * olcek.y)
			sag = maxf(sag, (pencere_boyutu.x - guvenli_dikdortgen.end.x) * olcek.x)
			alt = maxf(alt, (pencere_boyutu.y - guvenli_dikdortgen.end.y) * olcek.y)
	guvenli_alan.add_theme_constant_override("margin_left", roundi(sol))
	guvenli_alan.add_theme_constant_override("margin_top", roundi(ust))
	guvenli_alan.add_theme_constant_override("margin_right", roundi(sag))
	guvenli_alan.add_theme_constant_override("margin_bottom", roundi(alt))
