extends ResponsiveYardimciSahne

@onready var ayar_yoneticisi = AyarYoneticisi.new()
@onready var efektler_acik = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/EfektlerAcik
@onready var muzik_acik = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/MuzikAcik
@onready var muzik_seviye = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/MuzikSeviye
@onready var kontroller = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Kontroller
@onready var geri_butonu = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Geri
@onready var ses_yoneticisi: SesYoneticisi = get_node("/root/SesYonetici") as SesYoneticisi

func _ready() -> void:
	super._ready()
	efektler_acik.button_pressed = ayar_yoneticisi.efektler_acik
	muzik_acik.button_pressed = ayar_yoneticisi.muzik_acik
	muzik_seviye.value = ayar_yoneticisi.muzik_seviyesi
	kontroller.text = "Dokun: Döndür • Kaydır: Hareket / Hızlı İndir\nEkrandaki düğmeler de kullanılabilir." if mobil_platform_mu() else "W: Döndür • A/D: Sol/Sağ • S: Hızlı İndir\nBoşluk: Bırak • P: Duraklat"
	if mobil_platform_mu():
		muzik_seviye.custom_minimum_size.y = 96.0
	
	efektler_acik.toggled.connect(_on_efektler_toggled)
	muzik_acik.toggled.connect(_on_muzik_toggled)
	muzik_seviye.value_changed.connect(_on_muzik_seviye_changed)
	geri_butonu.pressed.connect(func(): sahneye_gec("res://scenes/AnaMenu.tscn"))

func _on_efektler_toggled(deger: bool) -> void:
	ayar_yoneticisi.efekt_ayarini_kaydet(deger)
	ses_yoneticisi.ayar_yoneticisi.efektler_acik = deger
	ses_yoneticisi.ayarları_uygula()

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/AnaMenu.tscn")

func _on_muzik_toggled(deger: bool) -> void:
	ayar_yoneticisi.muzik_ayarini_kaydet(deger)
	ses_yoneticisi.ayar_yoneticisi.muzik_acik = deger
	ses_yoneticisi.ayarları_uygula()

func _on_muzik_seviye_changed(deger: float) -> void:
	ayar_yoneticisi.muzik_seviyesi_kaydet(deger)
	ses_yoneticisi.ayar_yoneticisi.muzik_seviyesi = clampf(deger, 0.0, 1.0)
	ses_yoneticisi.ayarları_uygula()
