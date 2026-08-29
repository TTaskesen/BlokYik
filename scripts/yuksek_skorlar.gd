extends ResponsiveYardimciSahne

@onready var skor_listesi: Label = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/SkorListesi
@onready var geri_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Geri

func _ready() -> void:
	super._ready()
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))
	skorlari_goster()

func skorlari_goster() -> void:
	var skoryon = SkorYoneticisi.new()
	var yuksek = skoryon.yuksek_skoru_oku()
	skor_listesi.text = "Yüksek Skor: %d" % yuksek

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
