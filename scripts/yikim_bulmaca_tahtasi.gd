extends Control

signal hucre_secildi(konum: Vector2i)

var tahta: OyunTahtasi
var secili_parca: BlokParcasi
var hedef_parca: BlokParcasi
var onizleme_gecerli := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(300, 360)

func durumu_ayarla(yeni_tahta: OyunTahtasi, yeni_parca: BlokParcasi, gecerli: bool, yeni_hedef: BlokParcasi = null) -> void:
	tahta = yeni_tahta
	secili_parca = yeni_parca
	onizleme_gecerli = gecerli
	hedef_parca = yeni_hedef
	queue_redraw()

func hucre_konumu_al(nokta: Vector2) -> Vector2i:
	var hucre_boyutu := floorf(minf(size.x / YikimBulmacaYoneticisi.GENISLIK, size.y / YikimBulmacaYoneticisi.YUKSEKLIK))
	if hucre_boyutu <= 0.0:
		return Vector2i(-1, -1)
	var tahta_boyutu := Vector2(hucre_boyutu * YikimBulmacaYoneticisi.GENISLIK, hucre_boyutu * YikimBulmacaYoneticisi.YUKSEKLIK)
	var baslangic := (size - tahta_boyutu) * 0.5
	var hucre_konumu := ((nokta - baslangic) / hucre_boyutu).floor()
	if hucre_konumu.x < 0 or hucre_konumu.x >= YikimBulmacaYoneticisi.GENISLIK or hucre_konumu.y < 0 or hucre_konumu.y >= YikimBulmacaYoneticisi.YUKSEKLIK:
		return Vector2i(-1, -1)
	return Vector2i(hucre_konumu)

func _draw() -> void:
	var hucre_boyutu := floorf(minf(size.x / YikimBulmacaYoneticisi.GENISLIK, size.y / YikimBulmacaYoneticisi.YUKSEKLIK))
	if hucre_boyutu <= 0.0:
		return
	var tahta_boyutu := Vector2(hucre_boyutu * YikimBulmacaYoneticisi.GENISLIK, hucre_boyutu * YikimBulmacaYoneticisi.YUKSEKLIK)
	var baslangic := (size - tahta_boyutu) * 0.5
	draw_rect(Rect2(baslangic - Vector2.ONE * 4.0, tahta_boyutu + Vector2.ONE * 8.0), Color("f43f5e"), false, 2.0)
	for y in YikimBulmacaYoneticisi.YUKSEKLIK:
		for x in YikimBulmacaYoneticisi.GENISLIK:
			var hucre := Vector2i(x, y)
			var alan := Rect2(baslangic + Vector2(hucre) * hucre_boyutu, Vector2.ONE * (hucre_boyutu - 1.0))
			draw_rect(alan, Color("202535"), true)
			draw_rect(alan, Color("4d566d"), false, 1.0)
			if tahta and tahta.kilitli_hucreler.has(hucre):
				var renk: Color = tahta.kilitli_hucreler[hucre]
				draw_rect(alan.grow(-2.0), renk, true)
	if hedef_parca:
		for hucre in hedef_parca.hucreler():
			if hucre.x < 0 or hucre.x >= YikimBulmacaYoneticisi.GENISLIK or hucre.y < 0 or hucre.y >= YikimBulmacaYoneticisi.YUKSEKLIK or tahta.kilitli_hucreler.has(hucre):
				continue
			var alan := Rect2(baslangic + Vector2(hucre) * hucre_boyutu, Vector2.ONE * (hucre_boyutu - 1.0)).grow(-2.0)
			draw_rect(alan, Color(YikimBulmacaYoneticisi.HEDEF_RENGI, 0.18), true)
			draw_rect(alan, YikimBulmacaYoneticisi.HEDEF_RENGI, false, 2.0)
	if secili_parca:
		var renk := secili_parca.renk if onizleme_gecerli else Color("ef476f", 0.52)
		for hucre in secili_parca.hucreler():
			if hucre.x < 0 or hucre.x >= YikimBulmacaYoneticisi.GENISLIK or hucre.y < 0 or hucre.y >= YikimBulmacaYoneticisi.YUKSEKLIK:
				continue
			var alan := Rect2(baslangic + Vector2(hucre) * hucre_boyutu, Vector2.ONE * (hucre_boyutu - 1.0))
			draw_rect(alan.grow(-2.0), renk, true)

func _gui_input(olay: InputEvent) -> void:
	var dokunma_noktasi: Vector2
	if olay is InputEventScreenTouch:
		if not olay.pressed:
			return
		dokunma_noktasi = olay.position
	elif olay is InputEventMouseButton:
		if not olay.pressed or olay.button_index != MOUSE_BUTTON_LEFT:
			return
		dokunma_noktasi = olay.position
	else:
		return
	var hucre_konumu := hucre_konumu_al(dokunma_noktasi)
	if hucre_konumu.x < 0:
		return
	hucre_secildi.emit(hucre_konumu)
	accept_event()
