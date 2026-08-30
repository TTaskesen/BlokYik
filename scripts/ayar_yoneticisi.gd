class_name AyarYoneticisi
extends RefCounted

const KAYIT_YOLU := "user://ayarlar.cfg"
const VARSAYILAN_EFEKTLER_ACIK := true
const VARSAYILAN_MUZIK_ACIK := true
const VARSAYILAN_MUZIK_SEVIYESI := 0.7

var kayit_yolu: String
var efektler_acik := VARSAYILAN_EFEKTLER_ACIK
var muzik_acik := VARSAYILAN_MUZIK_ACIK
var muzik_seviyesi := VARSAYILAN_MUZIK_SEVIYESI

func _init(yeni_kayit_yolu: String = KAYIT_YOLU) -> void:
	kayit_yolu = yeni_kayit_yolu
	ayarları_yukle()

static func guvenli_muzik_seviyesi(deger, varsayilan := VARSAYILAN_MUZIK_SEVIYESI) -> float:
	if typeof(deger) != TYPE_INT and typeof(deger) != TYPE_FLOAT:
		return clampf(float(varsayilan), 0.0, 1.0)
	var sayi := float(deger)
	if is_nan(sayi) or is_inf(sayi):
		return clampf(float(varsayilan), 0.0, 1.0)
	return clampf(sayi, 0.0, 1.0)

static func guvenli_bool(deger, varsayilan: bool) -> bool:
	return deger if typeof(deger) == TYPE_BOOL else varsayilan

func ayarları_yukle() -> void:
	efektler_acik = VARSAYILAN_EFEKTLER_ACIK
	muzik_acik = VARSAYILAN_MUZIK_ACIK
	muzik_seviyesi = VARSAYILAN_MUZIK_SEVIYESI
	var kullanilabilir_yol := AtomikDosyaYardimcisi.kurtar(kayit_yolu, _ayar_dosyasi_gecerli_mi)
	if kullanilabilir_yol.is_empty():
		return
	var ayarlar := ConfigFile.new()
	if ayarlar.load(kullanilabilir_yol) != OK:
		return
	var eski_ses_acik := guvenli_bool(ayarlar.get_value("ses", "acik", VARSAYILAN_EFEKTLER_ACIK), VARSAYILAN_EFEKTLER_ACIK)
	if ayarlar.has_section_key("ses", "efektler"):
		efektler_acik = guvenli_bool(ayarlar.get_value("ses", "efektler"), VARSAYILAN_EFEKTLER_ACIK)
		muzik_acik = guvenli_bool(ayarlar.get_value("ses", "muzik", VARSAYILAN_MUZIK_ACIK), VARSAYILAN_MUZIK_ACIK)
	else:
		# Eski "ses/acik" ana anahtarının kapalı olması tüm uygulamayı
		# susturuyordu. İlk geçişte gerçek eski davranışı koru.
		efektler_acik = eski_ses_acik
		muzik_acik = eski_ses_acik and guvenli_bool(ayarlar.get_value("ses", "muzik", VARSAYILAN_MUZIK_ACIK), VARSAYILAN_MUZIK_ACIK)
	muzik_seviyesi = guvenli_muzik_seviyesi(ayarlar.get_value("ses", "muzik_seviye", VARSAYILAN_MUZIK_SEVIYESI))

func efekt_ayarini_kaydet(yeni_deger: bool) -> bool:
	efektler_acik = yeni_deger
	return ayarlari_kaydet()

func muzik_ayarini_kaydet(yeni_deger: bool) -> bool:
	muzik_acik = yeni_deger
	return ayarlari_kaydet()

func ayarlari_kaydet() -> bool:
	efektler_acik = guvenli_bool(efektler_acik, VARSAYILAN_EFEKTLER_ACIK)
	muzik_acik = guvenli_bool(muzik_acik, VARSAYILAN_MUZIK_ACIK)
	muzik_seviyesi = guvenli_muzik_seviyesi(muzik_seviyesi)
	return AtomikDosyaYardimcisi.atomik_yaz(kayit_yolu, _ayar_dosyasi_yaz, _ayar_dosyasi_gecerli_mi)

func muzik_seviyesi_kaydet(deger: float) -> bool:
	muzik_seviyesi = guvenli_muzik_seviyesi(deger)
	return ayarlari_kaydet()

func _ayar_dosyasi_yaz(yol: String) -> bool:
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ses", "efektler", efektler_acik)
	ayarlar.set_value("ses", "muzik", muzik_acik)
	ayarlar.set_value("ses", "muzik_seviye", muzik_seviyesi)
	return ayarlar.save(yol) == OK

func _ayar_dosyasi_gecerli_mi(yol: String) -> bool:
	if not FileAccess.file_exists(yol):
		return false
	var ayarlar := ConfigFile.new()
	if ayarlar.load(yol) != OK or not ayarlar.has_section("ses"):
		return false
	var yeni_bicim := ayarlar.has_section_key("ses", "efektler")
	var eski_bicim := ayarlar.has_section_key("ses", "acik")
	if not yeni_bicim and not eski_bicim:
		return false
	if yeni_bicim and typeof(ayarlar.get_value("ses", "efektler")) != TYPE_BOOL:
		return false
	if eski_bicim and typeof(ayarlar.get_value("ses", "acik")) != TYPE_BOOL:
		return false
	if ayarlar.has_section_key("ses", "muzik") and typeof(ayarlar.get_value("ses", "muzik")) != TYPE_BOOL:
		return false
	if ayarlar.has_section_key("ses", "muzik_seviye"):
		var seviye = ayarlar.get_value("ses", "muzik_seviye")
		if (typeof(seviye) != TYPE_INT and typeof(seviye) != TYPE_FLOAT) or is_nan(float(seviye)) or is_inf(float(seviye)):
			return false
	return true
