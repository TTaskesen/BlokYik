class_name AtomikDosyaYardimcisi
extends RefCounted

static func gecici_yol(hedef: String) -> String:
	return hedef + ".tmp"

static func yedek_yol(hedef: String) -> String:
	return hedef + ".bak"

static func eski_yol(hedef: String) -> String:
	return hedef + ".old"

static func yedek_gecici_yol(hedef: String) -> String:
	return hedef + ".bak.tmp"

static func atomik_yaz(hedef: String, yazici: Callable, dogrulayici: Callable) -> bool:
	var gecici := gecici_yol(hedef)
	var yedek_gecici := yedek_gecici_yol(hedef)
	# Var olan bir dizini sessizce silmeyiz. Bu durum, yazma hatası testinde
	# önceki geçerli ana dosyanın korunmasını sağlar.
	if DirAccess.dir_exists_absolute(gecici) or DirAccess.dir_exists_absolute(yedek_gecici):
		return false
	_dosyayi_sil(yedek_gecici)
	_dosyayi_sil(gecici)
	var ust_dizin := hedef.get_base_dir()
	if not ust_dizin.is_empty() and DirAccess.make_dir_recursive_absolute(ust_dizin) != OK:
		return false
	if not bool(yazici.call(gecici)) or not bool(dogrulayici.call(gecici)):
		_dosyayi_sil(gecici)
		return false
	if bool(dogrulayici.call(hedef)):
		if not dosyayi_kopyala(hedef, yedek_gecici) or not bool(dogrulayici.call(yedek_gecici)):
			_dosyayi_sil(gecici)
			_dosyayi_sil(yedek_gecici)
			return false
		if not dosyayi_degistir(yedek_gecici, yedek_yol(hedef)):
			_dosyayi_sil(gecici)
			return false
	if not dosyayi_degistir(gecici, hedef):
		_dosyayi_sil(gecici)
		return false
	gecici_artiklari_temizle(hedef)
	return bool(dogrulayici.call(hedef))

static func kurtar(hedef: String, dogrulayici: Callable) -> String:
	if bool(dogrulayici.call(hedef)):
		gecici_artiklari_temizle(hedef)
		return hedef
	var yedek := yedek_yol(hedef)
	if bool(dogrulayici.call(yedek)):
		var yedekten_gecici := gecici_yol(hedef)
		if not DirAccess.dir_exists_absolute(yedekten_gecici):
			_dosyayi_sil(yedekten_gecici)
			if dosyayi_kopyala(yedek, yedekten_gecici) and bool(dogrulayici.call(yedekten_gecici)) and dosyayi_degistir(yedekten_gecici, hedef) and bool(dogrulayici.call(hedef)):
				gecici_artiklari_temizle(hedef)
				return hedef
			_dosyayi_sil(yedekten_gecici)
		return yedek
	var gecici := gecici_yol(hedef)
	if bool(dogrulayici.call(gecici)) and dosyayi_degistir(gecici, hedef) and bool(dogrulayici.call(hedef)):
		gecici_artiklari_temizle(hedef)
		return hedef
	gecici_artiklari_temizle(hedef)
	return ""

static func dosyayi_kopyala(kaynak: String, hedef: String) -> bool:
	if not FileAccess.file_exists(kaynak) or DirAccess.dir_exists_absolute(hedef):
		return false
	var kaynak_dosyasi := FileAccess.open(kaynak, FileAccess.READ)
	if kaynak_dosyasi == null:
		return false
	var icerik := kaynak_dosyasi.get_buffer(kaynak_dosyasi.get_length())
	kaynak_dosyasi.close()
	var hedef_dosyasi := FileAccess.open(hedef, FileAccess.WRITE)
	if hedef_dosyasi == null:
		return false
	hedef_dosyasi.store_buffer(icerik)
	hedef_dosyasi.flush()
	hedef_dosyasi.close()
	return FileAccess.file_exists(hedef)

static func dosyayi_degistir(kaynak: String, hedef: String) -> bool:
	if not FileAccess.file_exists(kaynak) or DirAccess.dir_exists_absolute(hedef):
		return false
	var eski := eski_yol(hedef)
	if DirAccess.dir_exists_absolute(eski):
		return false
	_dosyayi_sil(eski)
	var hedef_tasindi := false
	if FileAccess.file_exists(hedef):
		if DirAccess.rename_absolute(hedef, eski) != OK:
			return false
		hedef_tasindi = true
	if DirAccess.rename_absolute(kaynak, hedef) == OK:
		_dosyayi_sil(eski)
		return true
	if hedef_tasindi:
		DirAccess.rename_absolute(eski, hedef)
	return false

static func gecici_artiklari_temizle(hedef: String) -> void:
	for yol in [gecici_yol(hedef), eski_yol(hedef), yedek_gecici_yol(hedef)]:
		_dosyayi_sil(yol)

static func tum_artiklari_temizle(hedef: String) -> void:
	for yol in [hedef, gecici_yol(hedef), yedek_yol(hedef), eski_yol(hedef), yedek_gecici_yol(hedef)]:
		_yolu_sil(yol)

static func _yolu_sil(yol: String) -> void:
	if FileAccess.file_exists(yol) or DirAccess.dir_exists_absolute(yol):
		DirAccess.remove_absolute(yol)

static func _dosyayi_sil(yol: String) -> void:
	if FileAccess.file_exists(yol):
		DirAccess.remove_absolute(yol)
