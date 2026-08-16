class_name TemelSahne
extends Control

func sahneye_gec(sahne_yolu: String) -> void:
	get_tree().change_scene_to_file(sahne_yolu)

