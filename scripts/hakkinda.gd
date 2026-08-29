extends ResponsiveYardimciSahne

@export var gizlilik_politikasi_url := ""
@onready var geri_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Geri
@onready var gizlilik_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Gizlilik
@onready var gizlilik_durumu: Label = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/GizlilikDurumu

func _ready() -> void:
	super._ready()
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))
	gizlilik_butonu.pressed.connect(gizlilik_politikasini_ac)

func gizlilik_politikasini_ac() -> void:
	if gizlilik_politikasi_url.strip_edges().is_empty():
		gizlilik_durumu.text = "Gizlilik politikası henüz herkese açık bir URL'de yayınlanmadı."
		return
	OS.shell_open(gizlilik_politikasi_url)

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
