class_name SesYoneticisi
extends Node

const ORNEKLEME_HIZI := 22050
const SES_YOLLARI := {
	"dondur": "res://audio/dondur.wav",
	"birak": "res://audio/birak.wav",
	"satir": "res://audio/satir.wav",
	"oyun_bitti": "res://audio/oyun_bitti.wav",
}
const MUZIK_YOLU := "res://audio/muzik.wav"
const MUZIK_TEMALARI := {
	1: "res://audio/muzik_1.wav",
	2: "res://audio/muzik_2.wav",
	3: "res://audio/muzik_3.wav",
}

var ayar_yoneticisi := AyarYoneticisi.new()
var ses_acik := true
var muzik_acik := true
var oynatici: AudioStreamPlayer
var muzik_oynatici: AudioStreamPlayer
var yuklu_sesler := {}
var muzik_stream

func _ready() -> void:
	add_to_group("ses_yoneticisi")
	oynatici = AudioStreamPlayer.new()
	add_child(oynatici)
	muzik_oynatici = AudioStreamPlayer.new()
	muzik_oynatici.volume_db = linear_to_db(1.0)
	add_child(muzik_oynatici)
	muzik_oynatici.finished.connect(func(): if muzik_acik and ses_acik: muzik_oynatici.play())
	sesleri_yukle()
	muzik_yukle()
	ayarları_uygula()

func ayarları_uygula() -> void:
	ses_acik = ayar_yoneticisi.ses_acik
	muzik_acik = ayar_yoneticisi.muzik_acik
	if muzik_oynatici:
		muzik_oynatici.volume_db = linear_to_db(maxf(ayar_yoneticisi.muzik_seviyesi, 0.001))
	if not ses_acik:
		sesleri_durdur()
	elif muzik_acik:
		muzik_baslat()
	else:
		muzik_durdur()

func sesleri_durdur() -> void:
	if oynatici:
		oynatici.stop()
	if muzik_oynatici:
		muzik_oynatici.stop()

func sesleri_yukle() -> void:
	for efekt_adi in SES_YOLLARI:
		var yol: String = SES_YOLLARI[efekt_adi]
		if ResourceLoader.exists(yol):
			yuklu_sesler[efekt_adi] = load(yol)

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
	if muzik_acik and ses_acik:
		muzik_oynatici.play()
		muzik_oynatici.seek(poz)


func efekt_cal(efekt_adi: String) -> void:
	if not ses_acik:
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
	oynatici.stream = ses
	oynatici.play()

func _exit_tree() -> void:
	# Autoload kapanırken oynatıcılar ses akışlarını ve playback nesnelerini
	# referanslamaya devam etmesin.
	if oynatici:
		oynatici.stop()
		oynatici.stream = null
	if muzik_oynatici:
		muzik_oynatici.stop()
		muzik_oynatici.stream_paused = false
		muzik_oynatici.stream = null
	yuklu_sesler.clear()
	muzik_stream = null

func seviye_guncelle() -> void:
	if muzik_oynatici:
		var seviye = 0.7
		muzik_oynatici.volume_db = linear_to_db(seviye)

func muzik_baslat() -> void:
	if not muzik_acik or not ses_acik:
		return
	if muzik_oynatici and muzik_oynatici.stream:
		muzik_oynatici.stream_paused = false
		muzik_oynatici.play()

func muzik_durdur() -> void:
	if muzik_oynatici:
		muzik_oynatici.stop()

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
