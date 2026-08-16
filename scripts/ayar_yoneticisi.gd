class_name AyarYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://ayarlar.cfg"
var ses_acik := true
var muzik_acik := true
var muzik_seviyesi := 0.7

func _init() -> void:
	ayarları_yukle()

func ayarları_yukle() -> void:
	var ayarlar := ConfigFile.new()
	if ayarlar.load(KAYIT_YOLU) == OK:
		ses_acik = bool(ayarlar.get_value("ses", "acik", true))
		muzik_acik = bool(ayarlar.get_value("ses", "muzik", true))
		muzik_seviyesi = float(ayarlar.get_value("ses", "muzik_seviye", 0.7))

func ses_ayarini_kaydet(yeni_deger: bool) -> void:
	ses_acik = yeni_deger
	ayarlari_kaydet()

func muzik_ayarini_kaydet(yeni_deger: bool) -> void:
	muzik_acik = yeni_deger
	ayarlari_kaydet()

func ayarlari_kaydet() -> void:
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ses", "acik", ses_acik)
	ayarlar.set_value("ses", "muzik", muzik_acik)
	ayarlar.set_value("ses", "muzik_seviye", muzik_seviyesi)
	ayarlar.save(KAYIT_YOLU)

func muzik_seviyesi_kaydet(deger: float) -> void:
	muzik_seviyesi = clamp(deger, 0.0, 1.0)
	ayarlari_kaydet()
