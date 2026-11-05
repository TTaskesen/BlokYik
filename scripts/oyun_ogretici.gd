extends CanvasLayer

signal kapatildi

const KAYIT_YOLU := "user://blok_yik_ogretici.cfg"

var mod_kimligi := ""
var adimlar: Array[String] = []
var adim_indeksi := 0
var metin: Label
var ileri_butonu: Button

func _ready() -> void:
	layer = 80

func ilk_oynatmada_goster(yeni_mod_kimligi: String, yeni_adimlar: Array[String]) -> bool:
	var ayarlar := ConfigFile.new()
	if ayarlar.load(KAYIT_YOLU) == OK and bool(ayarlar.get_value("tamamlanan", yeni_mod_kimligi, false)):
		return false
	mod_kimligi = yeni_mod_kimligi
	adimlar = yeni_adimlar.duplicate()
	adim_indeksi = 0
	_arayuzu_olustur()
	_adimi_goster()
	return true

func _arayuzu_olustur() -> void:
	var karartma := ColorRect.new()
	karartma.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	karartma.color = Color(0.02, 0.03, 0.07, 0.82)
	karartma.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(karartma)
	var ortala := CenterContainer.new()
	ortala.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	karartma.add_child(ortala)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(320, 220)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var stil := StyleBoxFlat.new()
	stil.bg_color = Color("141b2d")
	stil.border_color = Color("f43f5e")
	stil.set_border_width_all(2)
	stil.set_corner_radius_all(14)
	stil.set_content_margin_all(20)
	panel.add_theme_stylebox_override("panel", stil)
	ortala.add_child(panel)
	var sutun := VBoxContainer.new()
	sutun.add_theme_constant_override("separation", 14)
	panel.add_child(sutun)
	var baslik := Label.new()
	baslik.text = "OYUN REHBERİ"
	baslik.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	baslik.add_theme_font_size_override("font_size", 22)
	baslik.add_theme_color_override("font_color", Color("f43f5e"))
	sutun.add_child(baslik)
	metin = Label.new()
	metin.custom_minimum_size.y = 92
	metin.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	metin.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	metin.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	metin.add_theme_font_size_override("font_size", 17)
	metin.add_theme_color_override("font_color", Color("f5f7ff"))
	sutun.add_child(metin)
	ileri_butonu = Button.new()
	ileri_butonu.custom_minimum_size.y = 52
	ileri_butonu.pressed.connect(_sonraki_adim)
	sutun.add_child(ileri_butonu)
	var atla := Button.new()
	atla.text = "Şimdi gösterme"
	atla.flat = true
	atla.pressed.connect(_ogreticiyi_kapat)
	sutun.add_child(atla)

func _adimi_goster() -> void:
	if not is_instance_valid(metin):
		return
	metin.text = "%d / %d\n%s" % [adim_indeksi + 1, adimlar.size(), adimlar[adim_indeksi]]
	ileri_butonu.text = "Devam" if adim_indeksi < adimlar.size() - 1 else "Oyuna Başla"

func _sonraki_adim() -> void:
	if adim_indeksi < adimlar.size() - 1:
		adim_indeksi += 1
		_adimi_goster()
	else:
		_ogreticiyi_kapat()

func _ogreticiyi_kapat() -> void:
	var ayarlar := ConfigFile.new()
	ayarlar.load(KAYIT_YOLU)
	ayarlar.set_value("tamamlanan", mod_kimligi, true)
	ayarlar.save(KAYIT_YOLU)
	kapatildi.emit()
	queue_free()
