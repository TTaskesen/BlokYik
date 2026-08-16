extends TemelSahne

const SKOR_YONETICISI = preload("res://scripts/skor_yoneticisi.gd")

@onready var skor_listesi: Label = $Panel/SkorListesi
@onready var geri_butonu: Button = $Panel/Geri

func _ready() -> void:
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))
	skorlari_goster()

func skorlari_goster() -> void:
	var skoryon = SKOR_YONETICISI.new()
	var yuksek = skoryon.yuksek_skoru_oku()
	skor_listesi.text = "Yüksek Skor: %d" % yuksek
