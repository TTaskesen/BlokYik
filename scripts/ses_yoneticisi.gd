class_name SesYoneticisi
extends Node

const ORNEKLEME_HIZI := 22050
const MUZIK_YOLU := "res://audio/muzik.wav"
const MUZIK_TEMALARI := {
	1: "res://audio/muzik_oyun_baslangic.wav",
	2: "res://audio/muzik_oyun_baslangic.wav",
	3: "res://audio/muzik_oyun_baslangic.wav",
}

var ayar_yoneticisi := AyarYoneticisi.new()
var efektler_acik := true
var muzik_acik := true
var oynatici: AudioStreamPlayer
var muzik_oynatici: AudioStreamPlayer
var yuklu_sesler := {}
var muzik_stream
var sessiz_surucude_calismayi_zorla := false
var _kapanis_basladi := false

func _ready() -> void:
	get_tree().auto_accept_quit = false
	add_to_group("ses_yoneticisi")
	oynatici = AudioStreamPlayer.new()
	add_child(oynatici)
	muzik_oynatici = AudioStreamPlayer.new()
	muzik_oynatici.volume_db = linear_to_db(1.0)
	add_child(muzik_oynatici)
	muzik_oynatici.finished.connect(func(): if muzik_acik: muzik_oynatici.play())
	sesleri_yukle()
	muzik_yukle()
	ayarları_uygula()

func ayarları_uygula() -> void:
	efektler_acik = ayar_yoneticisi.efektler_acik
	muzik_acik = ayar_yoneticisi.muzik_acik
	if muzik_oynatici:
		muzik_oynatici.volume_db = linear_to_db(maxf(ayar_yoneticisi.muzik_seviyesi, 0.001))
	if not efektler_acik and oynatici:
		oynatici.stop()
	if muzik_acik and ses_cikisi_kullanilabilir_mi():
		# Ayarlar veya slider tekrar uygulandığında çalan müziğin konumunu koru.
		if muzik_oynatici:
			muzik_oynatici.stream_paused = false
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

func tema_degistir(tema_no: int) -> void:
	var yol = MUZIK_TEMALARI.get(tema_no)
	if not yol or not ResourceLoader.exists(yol):
		return
	var yeni_stream = load(yol)
	var poz = muzik_oynatici.get_playback_position() if muzik_oynatici.playing else 0.0
	muzik_oynatici.stream = yeni_stream
	muzik_stream = yeni_stream
	if muzik_acik and ses_cikisi_kullanilabilir_mi():
		muzik_oynatici.play()
		muzik_oynatici.seek(poz)


func efekt_cal(efekt_adi: String) -> void:
	if not efektler_acik or not ses_cikisi_kullanilabilir_mi():
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

func uygulamadan_cik() -> void:
	kapanisa_hazirla()
	call_deferred("_temiz_kapanisi_tamamla")

func _temiz_kapanisi_tamamla() -> void:
	await get_tree().create_timer(0.1).timeout
	get_tree().quit()

func seviye_guncelle() -> void:
	if muzik_oynatici:
		var seviye = 0.7
		muzik_oynatici.volume_db = linear_to_db(seviye)

func muzik_baslat() -> void:
	if not muzik_acik or not ses_cikisi_kullanilabilir_mi():
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
