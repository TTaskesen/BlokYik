extends TemelSahne

var ayar_yoneticisi := AyarYoneticisi.new()

func _ready() -> void:
	pass

func _on_basla_pressed() -> void:
	sahneye_gec("res://scenes/TetrisOyun.tscn")

func _on_nasil_oynanir_pressed() -> void:
	sahneye_gec("res://scenes/NasilOynanir.tscn")

func _on_ayarlar_pressed() -> void:
	sahneye_gec("res://scenes/Ayarlar.tscn")

func _on_devam_et_pressed() -> void:
	# Kayıt sistemi eklenecek. Şimdilik yeni oyun başlatılıyor.
	sahneye_gec("res://scenes/TetrisOyun.tscn")

func _on_yuksek_skorlar_pressed() -> void:
	sahneye_gec("res://scenes/YuksekSkorlar.tscn")

func _on_hakkinda_pressed() -> void:
	sahneye_gec("res://scenes/Hakkinda.tscn")

func _on_cikis_pressed() -> void:
	get_tree().quit()
