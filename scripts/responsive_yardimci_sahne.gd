class_name ResponsiveYardimciSahne
extends TemelSahne

@export var maksimum_panel_genisligi := 520.0

@onready var guvenli_alan: MarginContainer = $GuvenliAlan
@onready var icerik_kaydirici: ScrollContainer = $GuvenliAlan/IcerikKaydirici
@onready var ortala: CenterContainer = $GuvenliAlan/IcerikKaydirici/Ortala
@onready var responsive_panel: Control = $GuvenliAlan/IcerikKaydirici/Ortala/Panel

func _ready() -> void:
	resized.connect(_responsive_yerlesimi_guncelle)
	minimum_dokunma_hedeflerini_uygula(responsive_panel)
	call_deferred("_responsive_yerlesimi_guncelle")

func _responsive_yerlesimi_guncelle() -> void:
	_guvenli_alan_bosluklarini_guncelle()
	# Dikey kaydırma çubuğu için sekiz birim ayır; panel iki güvenli kenarı da korur.
	var kullanilabilir_genislik := maxf(240.0, size.x - float(guvenli_alan.get_theme_constant("margin_left") + guvenli_alan.get_theme_constant("margin_right")) - 8.0)
	responsive_panel.custom_minimum_size.x = minf(maksimum_panel_genisligi, kullanilabilir_genislik)
	# İçerik kısa olduğunda ortada kalır; uzadığında ScrollContainer kaydırır.
	ortala.custom_minimum_size = Vector2(
		kullanilabilir_genislik,
		maxf(icerik_kaydirici.size.y, responsive_panel.get_combined_minimum_size().y)
	)

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

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
