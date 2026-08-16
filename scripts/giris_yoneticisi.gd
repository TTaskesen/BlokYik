class_name GirisYoneticisi
extends RefCounted

func _init() -> void:
	aksiyonlari_hazirla()

func aksiyonlari_hazirla() -> void:
	aksiyon_ekle("hareket_sol", KEY_A)
	aksiyon_ekle("hareket_sag", KEY_D)
	aksiyon_ekle("hizli_indir", KEY_S)
	aksiyon_ekle("parcayi_dondur", KEY_W)
	aksiyon_ekle("aninda_indir", KEY_SPACE)
	aksiyon_ekle("duraklat", KEY_P)

func aksiyon_ekle(aksiyon_adi: StringName, tus: Key) -> void:
	if not InputMap.has_action(aksiyon_adi):
		InputMap.add_action(aksiyon_adi)
	for mevcut_olay in InputMap.action_get_events(aksiyon_adi):
		if mevcut_olay is InputEventKey and mevcut_olay.physical_keycode == tus:
			return
	var olay := InputEventKey.new()
	olay.physical_keycode = tus
	InputMap.action_add_event(aksiyon_adi, olay)

func klavye_komutu(olay: InputEvent) -> String:
	if olay.is_action_pressed("ui_left") or olay.is_action_pressed("hareket_sol"):
		return "sol"
	if olay.is_action_pressed("ui_right") or olay.is_action_pressed("hareket_sag"):
		return "sag"
	if olay.is_action_pressed("ui_down") or olay.is_action_pressed("hizli_indir"):
		return "asagi"
	if olay.is_action_pressed("ui_up") or olay.is_action_pressed("parcayi_dondur"):
		return "dondur"
	if olay.is_action_pressed("aninda_indir"):
		return "birak"
	if olay.is_action_pressed("duraklat"):
		return "duraklat"
	return ""
