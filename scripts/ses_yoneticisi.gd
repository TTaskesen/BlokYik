class_name SesYoneticisi
extends Node

signal uygulama_arka_plan_durumu_degisti(arka_planda: bool)

const ORNEKLEME_HIZI := 22050
const MUZIK_YOLU := "res://audio/muzik.wav"
const OYUN_MUZIGI_YOLU := "res://audio/muzik_oyun_baslangic.wav"

var ayar_yoneticisi := AyarYoneticisi.new()
var efektler_acik := true
var muzik_acik := true
var oynatici: AudioStreamPlayer
var muzik_oynatici: AudioStreamPlayer
var yuklu_sesler := {}
var muzik_stream
var sessiz_surucude_calismayi_zorla := false
var _kapanis_basladi := false
var platform_adi := OS.get_name()
var uygulama_arka_planda := false
var oyun_sesi_duraklatildi := false
var _uygulama_askida := false
var _uygulama_odaksiz := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().auto_accept_quit = false
	add_to_group("ses_yoneticisi")
	oynatici = AudioStreamPlayer.new()
	add_child(oynatici)
	muzik_oynatici = AudioStreamPlayer.new()
	muzik_oynatici.volume_db = linear_to_db(1.0)
	add_child(muzik_oynatici)
	muzik_oynatici.finished.connect(muzik_baslat)
	sesleri_yukle()
	muzik_yukle()
	ayarları_uygula()

func ayarları_uygula() -> void:
	efektler_acik = ayar_yoneticisi.efektler_acik
	muzik_acik = ayar_yoneticisi.muzik_acik
	if muzik_oynatici:
		# volume_linear = 0 gerçek sessizliktir; efekt oynatıcısını etkilemez.
		muzik_oynatici.volume_linear = AyarYoneticisi.guvenli_muzik_seviyesi(ayar_yoneticisi.muzik_seviyesi)
	if not efektler_acik and oynatici:
		oynatici.stop()
	if muzik_acik and ses_cikisi_kullanilabilir_mi():
		# Ayarlar veya slider tekrar uygulandığında çalan müziğin konumunu koru.
		if muzik_oynatici:
			muzik_duraklamasini_guncelle()
			if not muzik_oynatici.playing:
				muzik_baslat()
	else:
		muzik_durdur()

func sesleri_durdur() -> void:
	if oynatici:
		oynatici.stop()
	if muzik_oynatici:
		muzik_oynatici.stop()

func sesleri_yukle() -> void:
	# Efektler lisans belirsiz dosyalara bağlı kalmadan aşağıdaki sentezleyiciyle
	# çalışma anında üretilir. Lisanslı dosya eklenirse burada açıkça yüklenebilir.
	yuklu_sesler.clear()

func muzik_yukle() -> void:
	if ResourceLoader.exists(MUZIK_YOLU):
		muzik_stream = load(MUZIK_YOLU)
		muzik_oynatici.stream = muzik_stream

func tema_degistir(_tema_no: int) -> void:
	if _kapanis_basladi or not is_instance_valid(muzik_oynatici):
		return
	# Projede belgelenmiş tek oyun müziği var. Sahte tema çeşitliliği
	# oluşturmadan aynı stream'i ve mevcut çalma konumunu koru.
	if not ResourceLoader.exists(OYUN_MUZIGI_YOLU):
		return
	if muzik_oynatici.stream and muzik_oynatici.stream.resource_path == OYUN_MUZIGI_YOLU:
		return
	var yeni_stream = load(OYUN_MUZIGI_YOLU)
	var poz = muzik_oynatici.get_playback_position() if muzik_oynatici.playing else 0.0
	muzik_oynatici.stream = yeni_stream
	muzik_stream = yeni_stream
	if muzik_acik and not uygulama_arka_planda and not oyun_sesi_duraklatildi and ses_cikisi_kullanilabilir_mi():
		muzik_oynatici.play()
		muzik_oynatici.seek(poz)
	muzik_duraklamasini_guncelle()


func efekt_cal(efekt_adi: String) -> void:
	if _kapanis_basladi or uygulama_arka_planda or oyun_sesi_duraklatildi or not is_instance_valid(oynatici) or not efektler_acik or not ses_cikisi_kullanilabilir_mi():
		return
	var frekans := 440.0
	var sure := 0.08
	match efekt_adi:
		"dondur": frekans = 620.0
		"birak": frekans = 180.0
		"satir":
			frekans = 880.0
			sure = 0.18
		"oyun_bitti":
			frekans = 110.0
			sure = 0.35
	# Dictionary.get() çağrısının varsayılan parametresi önceden değerlendirildiği
	# için, kayıtlı ses olsa bile gereksiz bir AudioStreamWAV oluşturuluyordu.
	var ses = yuklu_sesler.get(efekt_adi)
	if ses == null:
		ses = ses_olustur(frekans, sure)
		yuklu_sesler[efekt_adi] = ses
	oynatici.stream = ses
	oynatici.play()

func _exit_tree() -> void:
	kapanisa_hazirla()

func kapanisa_hazirla() -> void:
	if _kapanis_basladi:
		return
	_kapanis_basladi = true
	# AudioServer kapanmadan önce stream ve playback sahiplerini eşzamanlı bırak.
	if oynatici:
		oynatici.stop()
		oynatici.stream = null
		if is_instance_valid(oynatici):
			oynatici.free()
		oynatici = null
	if muzik_oynatici:
		muzik_oynatici.stop()
		muzik_oynatici.stream_paused = false
		muzik_oynatici.stream = null
		if is_instance_valid(muzik_oynatici):
			muzik_oynatici.free()
		muzik_oynatici = null
	yuklu_sesler.clear()
	muzik_stream = null

func _notification(ne: int) -> void:
	if ne == NOTIFICATION_WM_CLOSE_REQUEST and not _kapanis_basladi:
		uygulamadan_cik()
	if platform_adi not in ["iOS", "Android"] or _kapanis_basladi:
		return
	match ne:
		NOTIFICATION_APPLICATION_PAUSED:
			_uygulama_askida = true
		NOTIFICATION_APPLICATION_RESUMED:
			_uygulama_askida = false
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			_uygulama_odaksiz = true
		NOTIFICATION_APPLICATION_FOCUS_IN:
			_uygulama_odaksiz = false
		_:
			return
	var arka_planda := _uygulama_askida or _uygulama_odaksiz
	if arka_planda == uygulama_arka_planda:
		return
	uygulama_arka_planda = arka_planda
	if arka_planda and is_instance_valid(oynatici):
		oynatici.stop()
	# Oyun sahnesi yalnız true durumunda kaydeder; öne dönüş otomatik oynatmaz.
	muzik_duraklamasini_guncelle()
	uygulama_arka_plan_durumu_degisti.emit(arka_planda)
	if not arka_planda:
		muzik_baslat()

func oyun_duraklamasini_ayarla(duraklatildi: bool) -> void:
	oyun_sesi_duraklatildi = duraklatildi
	muzik_duraklamasini_guncelle()
	if not duraklatildi:
		muzik_baslat()

func muzik_duraklamasini_guncelle() -> void:
	if is_instance_valid(muzik_oynatici):
		muzik_oynatici.stream_paused = uygulama_arka_planda or oyun_sesi_duraklatildi

func uygulamadan_cik() -> void:
	# iOS'ta desteklenmeyen quit çağrısından ÖNCE ses kaynaklarını koru.
	if platform_adi == "iOS" or _kapanis_basladi:
		return
	kapanisa_hazirla()
	call_deferred("_temiz_kapanisi_tamamla")

func _temiz_kapanisi_tamamla() -> void:
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func seviye_guncelle() -> void:
	if muzik_oynatici:
		muzik_oynatici.volume_linear = AyarYoneticisi.guvenli_muzik_seviyesi(ayar_yoneticisi.muzik_seviyesi)

func muzik_baslat() -> void:
	if _kapanis_basladi or uygulama_arka_planda or oyun_sesi_duraklatildi or not muzik_acik or not ses_cikisi_kullanilabilir_mi():
		return
	if muzik_oynatici and muzik_oynatici.stream and not muzik_oynatici.playing:
		muzik_oynatici.stream_paused = false
		muzik_oynatici.play()

func muzik_durdur() -> void:
	if muzik_oynatici:
		muzik_oynatici.stop()

func ses_cikisi_kullanilabilir_mi() -> bool:
	# Headless çalıştırmada Dummy sürücü gerçek ses üretmez; playback başlatmamak
	# kapanış sahipliğini gerçek cihaz davranışından ayırır. Ses regresyon testi bunu zorlar.
	return AudioServer.get_driver_name() != "Dummy" or sessiz_surucude_calismayi_zorla

func ses_olustur(frekans: float, sure: float) -> AudioStreamWAV:
	var ornek_sayisi := int(ORNEKLEME_HIZI * sure)
	var veri := PackedByteArray()
	veri.resize(ornek_sayisi * 2)
	for i in ornek_sayisi:
		var solma := 1.0 - float(i) / float(ornek_sayisi)
		var dalga := sin(TAU * frekans * float(i) / ORNEKLEME_HIZI)
		veri.encode_s16(i * 2, int(dalga * solma * 9000.0))
	var akim := AudioStreamWAV.new()
	akim.format = AudioStreamWAV.FORMAT_16_BITS
	akim.mix_rate = ORNEKLEME_HIZI
	akim.stereo = false
	akim.data = veri
	return akim
