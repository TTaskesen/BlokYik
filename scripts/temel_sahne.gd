class_name TemelSahne
extends Control

@export var mobil_arayuz_zorla := false

func sahneye_gec(sahne_yolu: String) -> void:
	get_tree().change_scene_to_file(sahne_yolu)

func mobil_platform_mu() -> bool:
	return mobil_arayuz_zorla or OS.has_feature("android")

func _unhandled_input(olay: InputEvent) -> void:
	if olay.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		geri_istegini_isle()

func geri_istegini_isle() -> void:
	pass

func minimum_dokunma_hedeflerini_uygula(kok: Node, zorla := false) -> void:
	if not zorla and not mobil_platform_mu():
		return
	for cocuk in kok.find_children("*", "BaseButton", true, false):
		var buton := cocuk as BaseButton
		buton.custom_minimum_size.y = maxf(buton.custom_minimum_size.y, 96.0)

