extends TemelSahne

const AYAR_YONETICISI = preload("res://scripts/ayar_yoneticisi.gd")

@onready var ayar_yoneticisi = AYAR_YONETICISI.new()
@onready var ses_acik = $Panel/SesAcik
@onready var muzik_acik = $Panel/MuzikAcik
@onready var muzik_seviye = $Panel/MuzikSeviye
@onready var geri_butonu = $Panel/Geri

func _ready() -> void:
	ses_acik.button_pressed = ayar_yoneticisi.ses_acik
	muzik_acik.button_pressed = ayar_yoneticisi.muzik_acik
	muzik_seviye.value = ayar_yoneticisi.muzik_seviyesi
	
	ses_acik.toggled.connect(_on_ses_toggled)
	muzik_acik.toggled.connect(_on_muzik_toggled)
	muzik_seviye.value_changed.connect(_on_muzik_seviye_changed)
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))

func _on_ses_toggled(deger: bool) -> void:
	ayar_yoneticisi.ses_ayarini_kaydet(deger)

func _on_muzik_toggled(deger: bool) -> void:
	ayar_yoneticisi.muzik_ayarini_kaydet(deger)

func _on_muzik_seviye_changed(deger: float) -> void:
	ayar_yoneticisi.muzik_seviyesi_kaydet(deger)
