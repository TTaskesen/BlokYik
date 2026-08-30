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
@onready var cikis_onayi: PanelContainer = $CikisOnayi

func _ready() -> void:
	kayit_yoneticisi = OyunKayitYoneticisi.new(kayit_yolu)
	cikis_butonu.visible = not mobil_platform_mu()
	cikis_onayi.visible = false
	$CikisOnayi/Icerik/Evet.pressed.connect(_uygulamadan_cik)
	$CikisOnayi/Icerik/Vazgec.pressed.connect(func(): cikis_onayi.visible = false)
	minimum_dokunma_hedeflerini_uygula(menu_paneli)
	minimum_dokunma_hedeflerini_uygula(cikis_onayi)
	resized.connect(ana_menu_yerlesimini_guncelle)
	ana_menu_yerlesimini_guncelle()
	devam_et_durumunu_guncelle()

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
		cikis_onayi.visible = true
		return
	_uygulamadan_cik()

func _uygulamadan_cik() -> void:
	var ses_yoneticisi := get_node_or_null("/root/SesYonetici") as SesYoneticisi
	if ses_yoneticisi:
		ses_yoneticisi.uygulamadan_cik()
	else:
		get_tree().quit()

func geri_istegini_isle() -> void:
	cikis_onayi.visible = not cikis_onayi.visible

func ana_menu_yerlesimini_guncelle() -> void:
	_guvenli_alan_bosluklarini_guncelle()
	var yatay_bosluk := float(guvenli_alan.get_theme_constant("margin_left") + guvenli_alan.get_theme_constant("margin_right"))
	var kullanilabilir_genislik := maxf(240.0, size.x - yatay_bosluk - 8.0)
	menu_paneli.custom_minimum_size.x = minf(420.0, kullanilabilir_genislik)
	if mobil_platform_mu():
		menu_paneli.add_theme_constant_override("separation", 14)
		menu_paneli.get_node("Baslik").add_theme_font_size_override("font_size", 52)
	ortala.custom_minimum_size = Vector2(
		kullanilabilir_genislik,
		maxf(icerik_kaydirici.size.y, menu_paneli.get_combined_minimum_size().y)
	)
	var onay_genisligi := minf(360.0, maxf(280.0, size.x - 48.0))
	cikis_onayi.offset_left = -onay_genisligi * 0.5
	cikis_onayi.offset_right = onay_genisligi * 0.5

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
