extends ResponsiveYardimciSahne

@onready var geri_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Geri

func _ready() -> void:
	super._ready()
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")
