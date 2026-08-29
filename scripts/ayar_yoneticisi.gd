class_name AyarYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://ayarlar.cfg"
var kayit_yolu: String
var efektler_acik := true
var muzik_acik := true
var muzik_seviyesi := 0.7

func _init(yeni_kayit_yolu: String = KAYIT_YOLU) -> void:
	kayit_yolu = yeni_kayit_yolu
	ayarları_yukle()

func ayarları_yukle() -> void:
	var ayarlar := ConfigFile.new()
	if ayarlar.load(kayit_yolu) == OK:
		var eski_ses_acik := bool(ayarlar.get_value("ses", "acik", true))
		if ayarlar.has_section_key("ses", "efektler"):
			efektler_acik = bool(ayarlar.get_value("ses", "efektler", true))
			muzik_acik = bool(ayarlar.get_value("ses", "muzik", true))
		else:
			# Eski "ses/acik" ana anahtarının kapalı olması tüm uygulamayı
			# susturuyordu. İlk geçişte gerçek eski davranışı koru.
			efektler_acik = eski_ses_acik
			muzik_acik = eski_ses_acik and bool(ayarlar.get_value("ses", "muzik", true))
		muzik_seviyesi = float(ayarlar.get_value("ses", "muzik_seviye", 0.7))

func efekt_ayarini_kaydet(yeni_deger: bool) -> void:
	efektler_acik = yeni_deger
	ayarlari_kaydet()

func muzik_ayarini_kaydet(yeni_deger: bool) -> void:
	muzik_acik = yeni_deger
	ayarlari_kaydet()

func ayarlari_kaydet() -> void:
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ses", "efektler", efektler_acik)
	ayarlar.set_value("ses", "muzik", muzik_acik)
	ayarlar.set_value("ses", "muzik_seviye", muzik_seviyesi)
	ayarlar.save(kayit_yolu)

func muzik_seviyesi_kaydet(deger: float) -> void:
	muzik_seviyesi = clamp(deger, 0.0, 1.0)
	ayarlari_kaydet()
