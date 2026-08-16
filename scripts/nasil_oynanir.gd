extends TemelSahne

@onready var geri_butonu: Button = $Panel/Geri

func _ready() -> void:
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))
