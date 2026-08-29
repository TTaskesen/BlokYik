extends TemelSahne

var ayar_yoneticisi := AyarYoneticisi.new()
@export var kayit_yolu := OyunKayitYoneticisi.KAYIT_YOLU
var kayit_yoneticisi: OyunKayitYoneticisi

@onready var devam_et_butonu: Button = $Panel/DevamEt
@onready var kayit_durum_etiketi: Label = $Panel/KayitDurumu

func _ready() -> void:
	kayit_yoneticisi = OyunKayitYoneticisi.new(kayit_yolu)
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
	get_tree().quit()
