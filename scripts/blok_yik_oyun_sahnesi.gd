extends TemelSahne

const OYUN_OGRETICI := preload("res://scripts/oyun_ogretici.gd")
const BLOK_BOYUTU := 32
const REFERANS_TAHTA_GENISLIGI := 10
const REFERANS_TAHTA_YUKSEKLIGI := 20
const REFERANS_TAHTA_KONUMU := Vector2(190, 100)
const REFERANS_EKRAN_BOYUTU := Vector2(720, 960)

var tahta := OyunTahtasi.new()
var parca_uretici := ParcaUretici.new()
var skor_yoneticisi := SkorYoneticisi.new()
var giris_yoneticisi := GirisYoneticisi.new()
var level_yoneticisi := LevelYoneticisi.new()
var ses_yoneticisi: SesYoneticisi
var ayar_yoneticisi: AyarYoneticisi
@export var kayit_yolu := OyunKayitYoneticisi.KAYIT_YOLU
@export var yuksek_skor_kayit_yolu := SkorYoneticisi.KAYIT_YOLU
var kayit_yoneticisi: OyunKayitYoneticisi
var aktif_parca: BlokParcasi
var sonraki_parca: BlokParcasi
var dusme_suresi := 0.0
var dusme_araligi := 0.6
var oyun_aktif := true
var oyun_duraklatildi := false
var dokunma_baslangici := Vector2.ZERO
var satir_silme_animasyonu_aktif := false
var yanan_satirlar: Array[int] = []
var yanma_baslangic_zamani := 0
var _oyun_oturum_id := 0
var _satir_animasyon_id := 0
var kayit_uyarisi := ""
var _yerlesim_olcegi := 1.0
var _yerlesim_ofseti := Vector2.ZERO
var guncel_level_adi := "Klasik Başlangıç"
var kapsul_gorevi_ilerleme := 0
const KAPSUL_GOREVI_HEDEFI := 3
var geri_al_kaydi: Dictionary = {}
var ogretici_acik := false
var tema_tahta_rengi := Color("202535")
var tema_izgara_rengi := Color("4d566d")
var tema_vurgu_rengi := Color("f43f5e")

@onready var skor_etiketi: Label = $Arayuz/BilgiPaneli/Kenar/Icerik/Skor
@onready var yuksek_skor_etiketi: Label = $Arayuz/BilgiPaneli/Kenar/Icerik/YuksekSkor
@onready var bolum_etiketi: Label = $Arayuz/BilgiPaneli/Kenar/Icerik/Bolum
@onready var alt_seviye_etiketi: Label = $Arayuz/BilgiPaneli/Kenar/Icerik/AltSeviye
@onready var satir_etiketi: Label = $Arayuz/BilgiPaneli/Kenar/Icerik/Satir
@onready var baslik_etiketi: Label = $Arayuz/Baslik
@onready var baslik_alt_etiketi: Label = $Arayuz/BaslikAlt
@onready var durum_etiketi: Label = $Arayuz/Durum
@onready var oyun_bitti_paneli: PanelContainer = $Arayuz/OyunBitti
@onready var duraklatma_etiketi: Label = $Arayuz/Duraklatildi
@onready var duraklat_menu: PanelContainer = $Arayuz/DuraklatMenu
@onready var duraklat_butonu: Button = $Arayuz/Duraklat
@onready var ses_toggle_butonu: Button = $Arayuz/SesToggle
@onready var seviye_gecis_etiketi: Label = $Arayuz/SeviyeGecis
@onready var seviye_gecis_zamanlayicisi: Timer = $Arayuz/SeviyeGecisZamanlayicisi
@onready var sonuc_basligi: Label = $Arayuz/OyunBitti/Icerik/Baslik
@onready var sonuc_aciklamasi: Label = $Arayuz/OyunBitti/Icerik/Aciklama
@onready var geri_al_butonu: Button = $Arayuz/GeriAl

func focusu_birak() -> void:
	var vp = get_viewport()
	if vp:
		vp.gui_release_focus()

func _ready() -> void:
	ses_yoneticisi = get_node("/root/SesYonetici") as SesYoneticisi
	ayar_yoneticisi = ses_yoneticisi.ayar_yoneticisi
	kayit_yoneticisi = OyunKayitYoneticisi.new(kayit_yolu)
	skor_yoneticisi = SkorYoneticisi.new(yuksek_skor_kayit_yolu)
	var kayitli_oyun_yuklenecek := bool(get_tree().get_meta("kayitli_oyun_yukle", false))
	get_tree().set_meta("kayitli_oyun_yukle", false)
	if not kayitli_oyun_yuklenecek or not oyunu_yukle():
		yeni_oyunu_baslat()
	ses_toggle_butonu.text = "Efekt: Açık" if ses_yoneticisi.efektler_acik else "Efekt: Kapalı"
	$Arayuz/Sol.pressed.connect(func(): oyuncu_komutunu_uygula("sol"); focusu_birak())
	$Arayuz/Sag.pressed.connect(func(): oyuncu_komutunu_uygula("sag"); focusu_birak())
	$Arayuz/Asagi.pressed.connect(func(): oyuncu_komutunu_uygula("asagi"); focusu_birak())
	$Arayuz/Birak.pressed.connect(func(): oyuncu_komutunu_uygula("birak"); focusu_birak())
	$Arayuz/Duraklat.pressed.connect(duraklatmayi_degistir)
	$Arayuz/OyunBitti/Icerik/YenidenBaslat.pressed.connect(func(): yeniden_baslat(); focusu_birak())
	$Arayuz/OyunBitti/Icerik/MenuyeDon.pressed.connect(func(): menuye_don(); focusu_birak())
	oyun_bitti_paneli.visible = false
	duraklatma_etiketi.visible = false
	duraklat_menu.visible = false
	seviye_gecis_etiketi.visible = false
	seviye_gecis_zamanlayicisi.timeout.connect(func(): seviye_gecis_etiketi.visible = false)
	$Arayuz/Dondur.pressed.connect(func(): oyuncu_komutunu_uygula("dondur"); focusu_birak())
	$Arayuz/DuraklatMenu/DuraklatIcerik/DevamEtBtn.pressed.connect(duraklatmayi_degistir)
	$Arayuz/DuraklatMenu/DuraklatIcerik/YenidenBaslatBtn.pressed.connect(func(): yeniden_baslat(); focusu_birak())
	$Arayuz/DuraklatMenu/DuraklatIcerik/AnaMenuBtn.pressed.connect(func(): menuye_don(); focusu_birak())
	$Arayuz/SesToggle.pressed.connect(func(): ses_toggle(); focusu_birak())
	geri_al_butonu.pressed.connect(func(): _geri_al(); focusu_birak())
	mobil_oyun_yerlesimini_uygula()
	focusu_birak()
	resized.connect(yerlesimi_guncelle)
	yerlesimi_guncelle()
	arayuzu_guncelle()
	queue_redraw()
	ses_yoneticisi.uygulama_arka_plan_durumu_degisti.connect(uygulama_arka_plan_durumunu_isle)
	if ses_yoneticisi.uygulama_arka_planda:
		uygulama_arka_plan_durumunu_isle(true)
	var ogretici := OYUN_OGRETICI.new()
	add_child(ogretici)
	ogretici_acik = ogretici.ilk_oynatmada_goster("klasik", ["Parçaları satırları tamamlayacak şekilde yerleştir; satırlar puan ve hız kazandırır.", "Turuncu kapsülün çevresindeki çizgili 4×4 alanı gör. Yere oturunca blokları patlatır ve sütunları çökertir.", "Kapsülle en az 4 bloğu tek patlamada temizleyerek Kapsül Görevi'nde ilerle. Son kilitlenen parçayı Geri Al ile geri çevirebilirsin."])
	ogretici.kapatildi.connect(func(): ogretici_acik = false)

func _process(delta: float) -> void:
	if not oyun_aktif or oyun_duraklatildi:
		return
	if satir_silme_animasyonu_aktif:
		queue_redraw()
		return
	dusme_suresi += delta
	if dusme_suresi >= dusme_araligi:
		dusme_suresi = 0.0
		parcayi_dusur()

func _unhandled_input(olay: InputEvent) -> void:
	if ogretici_acik:
		return
	if olay.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		geri_istegini_isle()
		return
	# Arayüz butonlarının işlediği dokunuşlar buraya ulaşmaz.
	# Böylece bir butona basmak parçayı yanlışlıkla döndürmez.
	if olay is InputEventScreenTouch:
		if not oyuncu_girisi_kabul_ediliyor_mu():
			return
		if olay.pressed:
			dokunma_baslangici = olay.position
		else:
			dokunmatik_komutu_uygula(olay.position)
		return
	var komut := giris_yoneticisi.klavye_komutu(olay)
	if komut == "duraklat":
		duraklatmayi_degistir()
		return
	if komut != "":
		oyuncu_komutunu_uygula(komut)

func oyuncu_girisi_kabul_ediliyor_mu() -> bool:
	return oyun_aktif and not oyun_duraklatildi and not satir_silme_animasyonu_aktif and aktif_parca != null

func oyuncu_komutunu_uygula(komut: String) -> void:
	if not oyuncu_girisi_kabul_ediliyor_mu():
		return
	if komut == "birak":
		aninda_indir()
	elif komut in ["sol", "sag", "asagi", "dondur"]:
		komutu_uygula(komut)

func komutu_uygula(komut: String) -> void:
	if not oyuncu_girisi_kabul_ediliyor_mu():
		return
	match komut:
		"sol": aktif_parca.konum.x -= 1
		"sag": aktif_parca.konum.x += 1
		"asagi": aktif_parca.konum.y += 1
		"dondur": aktif_parca.dondur()
	if not tahta.gecerli_mi(aktif_parca):
		match komut:
			"sol": aktif_parca.konum.x += 1
			"sag": aktif_parca.konum.x -= 1
			"asagi": aktif_parca.konum.y -= 1
			"dondur": aktif_parca.donusu_geri_al()
	elif komut == "dondur":
		ses_yoneticisi.efekt_cal("dondur")
	queue_redraw()

func aninda_indir() -> void:
	if not oyuncu_girisi_kabul_ediliyor_mu():
		return
	var mesafe := 0
	while true:
		aktif_parca.konum.y += 1
		if not tahta.gecerli_mi(aktif_parca):
			aktif_parca.konum.y -= 1
			break
		mesafe += 1
	skor_yoneticisi.indirme_puani_ekle(mesafe)
	skor_yoneticisi.yuksek_skoru_kaydet()
	ses_yoneticisi.efekt_cal("birak")
	parcayi_dusur()

func duraklatmayi_degistir() -> void:
	if not oyun_aktif or ses_yoneticisi.uygulama_arka_planda:
		return
	duraklatma_durumunu_ayarla(not oyun_duraklatildi)

func duraklatma_durumunu_ayarla(duraklatildi: bool, kaydet := true) -> void:
	oyun_duraklatildi = duraklatildi
	duraklatma_etiketi.visible = oyun_duraklatildi
	duraklat_menu.visible = oyun_duraklatildi
	duraklat_butonu.text = "Devam Et" if oyun_duraklatildi else "Durdur"
	duraklat_butonu.release_focus()
	focusu_birak()
	if oyun_duraklatildi and kaydet:
		oyunu_kaydet()
	if ses_yoneticisi:
		ses_yoneticisi.oyun_duraklamasini_ayarla(oyun_duraklatildi)
	arayuzu_guncelle()

func uygulama_arka_plan_durumunu_isle(arka_planda: bool) -> void:
	# Öne dönüşte duraklama kaldırılmaz; yalnız oyuncunun Devam Et işlemi açar.
	if not arka_planda or not oyun_aktif:
		return
	duraklatma_durumunu_ayarla(true, false)
	# iOS kısa süre tanır: asenkron animasyonu beklemeden satırı bir kez sonuçlandır.
	# Sonraki parça oluşturulunca mevcut atomik/doğrulanan kayıt sistemi kullanılır.
	if satir_silme_animasyonu_aktif:
		satir_silmeyi_tamamla()
	else:
		oyunu_kaydet()
	skor_yoneticisi.yuksek_skoru_kaydet()
	arayuzu_guncelle()

func ses_toggle() -> void:
	if ses_yoneticisi:
		ayar_yoneticisi.efekt_ayarini_kaydet(not ses_yoneticisi.efektler_acik)
		ses_yoneticisi.ayarları_uygula()
		ses_toggle_butonu.text = "Efekt: Açık" if ses_yoneticisi.efektler_acik else "Efekt: Kapalı"

func geri_istegini_isle() -> void:
	if oyun_aktif:
		duraklatmayi_degistir()

func parcayi_dusur() -> void:
	if satir_silme_animasyonu_aktif:
		return
	aktif_parca.konum.y += 1
	if not tahta.gecerli_mi(aktif_parca):
		aktif_parca.konum.y -= 1
		_geri_al_kaydi_al()
		tahta.parcayi_kilitle(aktif_parca)
		if aktif_parca.yikim_kapsulu:
			var patlama_sonucu: Dictionary = tahta.yikim_kapsulunu_patlat(aktif_parca)
			var temizlenen_hucre: int = int(patlama_sonucu.temizlenen)
			var dusen_taslar := tahta.etkilenen_sutunlarda_yercekimi_uygula(patlama_sonucu.etkilenen_sutunlar)
			skor_yoneticisi.skor += temizlenen_hucre * 25 + dusen_taslar * 10
			if temizlenen_hucre > 0:
				yikim_kapsulu_geri_bildirimi(temizlenen_hucre, dusen_taslar)
			if temizlenen_hucre >= 4 and kapsul_gorevi_ilerleme < KAPSUL_GOREVI_HEDEFI:
				kapsul_gorevi_ilerleme += 1
				if kapsul_gorevi_ilerleme == KAPSUL_GOREVI_HEDEFI:
					skor_yoneticisi.skor += 500
					seviye_gecis_etiketi.text = "KAPSÜL GÖREVİ TAMAMLANDI!\n+500 puan"
					seviye_gecis_etiketi.visible = true
					seviye_gecis_zamanlayicisi.start(2.0)
		var dolu_satirlar := tahta.dolu_satirlari_bul()
		if not dolu_satirlar.is_empty():
			satir_silme_animasyonunu_oynat(dolu_satirlar)
			return
		kilitlenmis_parcayi_isle(0)
	arayuzu_guncelle()
	queue_redraw()

func satir_silme_animasyonunu_oynat(dolu_satirlar: Array[int]) -> void:
	var animasyon_oturum_id := _oyun_oturum_id
	_satir_animasyon_id += 1
	var animasyon_id := _satir_animasyon_id
	satir_silme_animasyonu_aktif = true
	yanan_satirlar = dolu_satirlar.duplicate()
	yanma_baslangic_zamani = Time.get_ticks_msec()
	queue_redraw()
	await get_tree().create_timer(0.35).timeout
	if animasyon_oturum_id != _oyun_oturum_id or animasyon_id != _satir_animasyon_id or not is_inside_tree():
		return
	satir_silmeyi_tamamla()

func satir_silmeyi_tamamla() -> void:
	if not satir_silme_animasyonu_aktif:
		return
	# Eski zamanlayıcı dönse bile aynı satır/puan ikinci kez işlenemez.
	_satir_animasyon_id += 1
	var silinen_satir := tahta.satirlari_sil(yanan_satirlar)
	satir_silme_animasyonu_aktif = false
	yanan_satirlar.clear()
	kilitlenmis_parcayi_isle(silinen_satir)
	arayuzu_guncelle()
	queue_redraw()

func kilitlenmis_parcayi_isle(silinen_satir: int) -> void:
	var seviye_sonucu := skor_yoneticisi.satir_ekle(silinen_satir)
	if silinen_satir > 0:
		ses_yoneticisi.efekt_cal("satir")
		skor_yoneticisi.yuksek_skoru_kaydet()
	if seviye_sonucu.seviye_degisimi:
		seviye_gecisini_goster()
	dusme_araligi = max(0.08, 0.6 * pow(0.9, skor_yoneticisi.genel_seviye() - 1))
	if seviye_sonucu.oyun_tamamlandi:
		oyunu_sonlandir(true)
	elif seviye_sonucu.ana_level_degisimi:
		level_ayarini_uygula()
		# Yeni bölüm tahtası ve parçaları oluşturulduktan hemen sonra ilerlemeyi kalıcılaştır.
		oyunu_kaydet()
	elif tahta.oyun_bitti_mi():
		oyunu_sonlandir(false)
	else:
		aktif_parca = sonraki_parca
		sonraki_parca = parca_uretici.yeni_parca()
		# Satır animasyonu bittikten ve yeni parça oluşturulduktan sonra durum tutarlıdır.
		oyunu_kaydet()

func yikim_kapsulu_geri_bildirimi(temizlenen_hucre: int, dusen_taslar: int) -> void:
	seviye_gecis_etiketi.text = "YIKIM KAPSÜLÜ\n%d hücre • %d taş düştü!" % [temizlenen_hucre, dusen_taslar]
	seviye_gecis_etiketi.visible = true
	seviye_gecis_zamanlayicisi.start(1.5)

func _geri_al_kaydi_al() -> void:
	geri_al_kaydi = {
		"kilitli": tahta.kilitli_hucreler.duplicate(true),
		"aktif_hucreler": tahta.aktif_hucreler.keys().duplicate(),
		"genislik": tahta.genislik,
		"yukseklik": tahta.yukseklik,
		"aktif": _parcayi_kopyala(aktif_parca),
		"sonraki": _parcayi_kopyala(sonraki_parca),
		"skor": skor_yoneticisi.skor,
		"silinen_satir": skor_yoneticisi.silinen_satir,
		"ana_level": skor_yoneticisi.ana_level,
		"alt_seviye": skor_yoneticisi.alt_seviye,
		"asama_satirlari": skor_yoneticisi.asama_satirlari,
		"dusme_araligi": dusme_araligi,
		"kapsul_gorevi": kapsul_gorevi_ilerleme
	}
	geri_al_butonu.disabled = false

func _parcayi_kopyala(kaynak: BlokParcasi) -> BlokParcasi:
	if kaynak == null:
		return null
	var kopya := BlokParcasi.new(kaynak.kalip, kaynak.renk, kaynak.yikim_kapsulu)
	kopya.konum = kaynak.konum
	kopya.donus = kaynak.donus
	return kopya

func _geri_al() -> void:
	if geri_al_kaydi.is_empty():
		return
	var kayit := geri_al_kaydi
	_satir_animasyon_id += 1
	satir_silme_animasyonu_aktif = false
	yanan_satirlar.clear()
	tahta = OyunTahtasi.new(int(kayit.genislik), int(kayit.yukseklik), kayit.aktif_hucreler)
	tahta.kilitli_hucreler = kayit.kilitli.duplicate(true)
	aktif_parca = _parcayi_kopyala(kayit.aktif)
	sonraki_parca = _parcayi_kopyala(kayit.sonraki)
	skor_yoneticisi.skor = int(kayit.skor)
	skor_yoneticisi.silinen_satir = int(kayit.silinen_satir)
	skor_yoneticisi.ana_level = int(kayit.ana_level)
	skor_yoneticisi.alt_seviye = int(kayit.alt_seviye)
	skor_yoneticisi.asama_satirlari = int(kayit.asama_satirlari)
	dusme_araligi = float(kayit.dusme_araligi)
	kapsul_gorevi_ilerleme = int(kayit.kapsul_gorevi)
	var ayar := level_yoneticisi.level_ayari_al(skor_yoneticisi.ana_level)
	parca_uretici = ParcaUretici.new(ayar.parca_havuzu, float(ayar.get("yikim_kapsulu_ihtimali", 0.1)))
	level_kimligini_uygula(ayar)
	ses_yoneticisi.tema_degistir(clampi(skor_yoneticisi.ana_level, 1, 3))
	oyun_aktif = true
	oyun_duraklatildi = false
	duraklatma_durumunu_ayarla(false, false)
	oyun_bitti_paneli.visible = false
	duraklat_menu.visible = false
	duraklatma_etiketi.visible = false
	seviye_gecis_etiketi.visible = false
	seviye_gecis_zamanlayicisi.stop()
	dusme_suresi = 0.0
	kayit_yoneticisi.kaydi_sil()
	geri_al_kaydi.clear()
	geri_al_butonu.disabled = true
	arayuzu_guncelle()
	queue_redraw()

func arayuzu_guncelle() -> void:
	$Arayuz/Birak.text = "Bırak" if mobil_platform_mu() else "Bırak (Boşluk)"
	baslik_etiketi.text = "BÖLÜM %d" % skor_yoneticisi.ana_level
	baslik_alt_etiketi.text = guncel_level_adi.to_upper()
	skor_etiketi.text = "Skor: %d" % skor_yoneticisi.skor
	yuksek_skor_etiketi.text = str(skor_yoneticisi.yuksek_skor)
	bolum_etiketi.text = "Bölüm: %d\n%s" % [skor_yoneticisi.ana_level, guncel_level_adi]
	alt_seviye_etiketi.text = "Seviye: %d / %d" % [skor_yoneticisi.alt_seviye, SkorYoneticisi.ALT_SEVIYE_SAYISI]
	satir_etiketi.text = "Hedef: %d / %d" % [skor_yoneticisi.asama_satirlari, SkorYoneticisi.ALT_SEVIYE_ICIN_SATIR]
	$Arayuz/BilgiPaneli/Kenar/Icerik/KapsulGorevi.text = "Kapsül görevi: %d / %d" % [kapsul_gorevi_ilerleme, KAPSUL_GOREVI_HEDEFI]
	geri_al_butonu.disabled = geri_al_kaydi.is_empty()
	if oyun_duraklatildi:
		durum_etiketi.text = "Oyun duraklatıldı" if kayit_uyarisi.is_empty() else "Duraklatıldı • " + kayit_uyarisi
	elif oyun_aktif:
		durum_etiketi.text = "Dokun: Döndür • Kaydır: Hareket • Aşağı: İndir" if mobil_platform_mu() else "A/D: Hareket • W: Döndür • Boşluk: Bırak • P: Duraklat"
	else:
		durum_etiketi.text = "Oyun bitti — yeniden başlatabilir veya menüye dönebilirsin"

func yeniden_baslat() -> void:
	yeni_oyunu_baslat()

func yeni_oyunu_baslat() -> void:
	_oyun_oturum_id += 1
	kayit_uyarisi = ""
	# Yeniden başlatma, önceki oyunun devam kaydını kullanılamaz hale getirir.
	if kayit_yoneticisi:
		kayit_yoneticisi.kaydi_sil()
	geri_al_kaydi.clear()
	kapsul_gorevi_ilerleme = 0
	skor_yoneticisi = SkorYoneticisi.new(yuksek_skor_kayit_yolu)
	level_ayarini_uygula()
	dusme_suresi = 0.0
	dusme_araligi = 0.6
	oyun_aktif = true
	oyun_duraklatildi = false
	ses_yoneticisi.oyun_duraklamasini_ayarla(false)
	satir_silme_animasyonu_aktif = false
	yanan_satirlar.clear()
	oyun_bitti_paneli.visible = false
	duraklatma_etiketi.visible = false
	duraklat_menu.visible = false
	seviye_gecis_etiketi.visible = false
	seviye_gecis_zamanlayicisi.stop()
	duraklat_butonu.text = "Durdur"
	sonuc_basligi.text = "OYUN BİTTİ"
	sonuc_aciklamasi.text = "Yeni bir oyun başlat veya ana menüye dön."
	arayuzu_guncelle()
	queue_redraw()

func menuye_don() -> void:
	skor_yoneticisi.yuksek_skoru_kaydet()
	sahneye_gec("res://scenes/AnaMenu.tscn")

func seviye_gecisini_goster() -> void:
	var gecis_level_adi := level_yoneticisi.level_adi_al(skor_yoneticisi.ana_level)
	seviye_gecis_etiketi.text = "BÖLÜM %d — %s\nSEVİYE %d • Hız %%10 arttı" % [skor_yoneticisi.ana_level, gecis_level_adi, skor_yoneticisi.alt_seviye]
	seviye_gecis_etiketi.visible = true
	seviye_gecis_zamanlayicisi.start()

func level_ayarini_uygula() -> void:
	var ayar := level_yoneticisi.level_ayari_al(skor_yoneticisi.ana_level)
	level_kimligini_uygula(ayar)
	tahta = OyunTahtasi.new(ayar.genislik, ayar.yukseklik, ayar.get("aktif_hucreler", []))
	parca_uretici = ParcaUretici.new(ayar.parca_havuzu, float(ayar.get("yikim_kapsulu_ihtimali", 0.1)))
	aktif_parca = parca_uretici.yeni_parca()
	sonraki_parca = parca_uretici.yeni_parca()
	if ses_yoneticisi:
		var tema_no = clampi(skor_yoneticisi.ana_level, 1, 3)
		ses_yoneticisi.tema_degistir(tema_no)

func level_kimligini_uygula(ayar: Dictionary) -> void:
	guncel_level_adi = str(ayar.ad)
	tema_tahta_rengi = ayar.tahta
	tema_izgara_rengi = ayar.izgara
	tema_vurgu_rengi = ayar.vurgu
	$ArkaPlan.color = ayar.arka_plan
	$Arayuz/BilgiPaneli.color = ayar.panel
	$Arayuz/SonrakiPaneli.color = ayar.panel
	arayuz_stilini_uygula()
	seviye_gecis_etiketi.add_theme_color_override("font_color", tema_vurgu_rengi)
	arayuzu_guncelle()
	queue_redraw()

func arayuz_stilini_uygula() -> void:
	baslik_alt_etiketi.add_theme_color_override("font_color", tema_vurgu_rengi)
	$Arayuz/BilgiPaneli/Kenar/Icerik/Puanlar.add_theme_color_override("font_color", tema_vurgu_rengi)
	$Arayuz/BilgiPaneli/Kenar/Icerik/YuksekSkorBaslik.add_theme_color_override("font_color", tema_vurgu_rengi)
	$Arayuz/SonrakiBaslik.add_theme_color_override("font_color", tema_vurgu_rengi)
	var normal := stil_kutusu($Arayuz/BilgiPaneli.color.darkened(0.08), tema_vurgu_rengi, 2)
	var hover := stil_kutusu($Arayuz/BilgiPaneli.color.lightened(0.06), tema_vurgu_rengi.lightened(0.12), 2)
	var basili := stil_kutusu($Arayuz/BilgiPaneli.color.lightened(0.12), tema_vurgu_rengi, 3)
	for buton in [$Arayuz/Sol, $Arayuz/Dondur, $Arayuz/Sag, $Arayuz/Asagi, $Arayuz/Birak, $Arayuz/Duraklat, $Arayuz/SesToggle, $Arayuz/GeriAl]:
		buton.add_theme_stylebox_override("normal", normal)
		buton.add_theme_stylebox_override("hover", hover)
		buton.add_theme_stylebox_override("pressed", basili)
		buton.add_theme_stylebox_override("focus", basili)
		buton.add_theme_color_override("font_color", Color("f5f7ff"))
		buton.add_theme_color_override("font_hover_color", Color("ffffff"))

func stil_kutusu(arka_plan: Color, kenar: Color, kenar_genisligi: int) -> StyleBoxFlat:
	var stil := StyleBoxFlat.new()
	stil.bg_color = arka_plan
	stil.border_color = kenar
	stil.set_border_width_all(kenar_genisligi)
	stil.set_corner_radius_all(8)
	stil.content_margin_left = 10.0
	stil.content_margin_right = 10.0
	stil.content_margin_top = 6.0
	stil.content_margin_bottom = 6.0
	return stil

func oyunu_sonlandir(tamamlandi_mi: bool) -> void:
	oyun_aktif = false
	# Arka planda satır tamamlanarak finale ulaşılmışsa iki modal üst üste kalmasın.
	oyun_duraklatildi = false
	duraklatma_etiketi.visible = false
	duraklat_menu.visible = false
	duraklat_butonu.text = "Durdur"
	seviye_gecis_etiketi.visible = false
	seviye_gecis_zamanlayicisi.stop()
	ses_yoneticisi.oyun_duraklamasini_ayarla(false)
	# Bitmiş oyun hiçbir zaman devam kaydı olarak geri dönmemeli.
	kayit_yoneticisi.kaydi_sil()
	skor_yoneticisi.yuksek_skoru_kaydet()
	oyun_bitti_paneli.visible = true
	if tamamlandi_mi:
		sonuc_basligi.text = "TEBRİKLER!"
		sonuc_aciklamasi.text = "5 bölüm ve 15 seviyeyi tamamladın!"
	else:
		sonuc_basligi.text = "OYUN BİTTİ"
		sonuc_aciklamasi.text = "Yeni bir oyun başlat veya ana menüye dön."
	ses_yoneticisi.efekt_cal("oyun_bitti")

func _exit_tree() -> void:
	# Sahne kapatılırsa veya uygulama sonlanırsa mevcut yüksek skor korunur.
	_oyun_oturum_id += 1
	skor_yoneticisi.yuksek_skoru_kaydet()
	# Satır silme animasyonu ve oyun sonu, devam için kararlı durumlar değildir.
	if oyun_aktif and not satir_silme_animasyonu_aktif:
		oyunu_kaydet()
	if is_instance_valid(ses_yoneticisi):
		if ses_yoneticisi.uygulama_arka_plan_durumu_degisti.is_connected(uygulama_arka_plan_durumunu_isle):
			ses_yoneticisi.uygulama_arka_plan_durumu_degisti.disconnect(uygulama_arka_plan_durumunu_isle)
		# Menünün müziği bir önceki oyun sahnesinin duraklamasına bağlı kalmaz.
		ses_yoneticisi.oyun_duraklamasini_ayarla(false)

func dokunmatik_komutu_uygula(bitis_konumu: Vector2) -> void:
	if not oyuncu_girisi_kabul_ediliyor_mu():
		return
	var hareket := bitis_konumu - dokunma_baslangici
	if hareket.length() < 24.0:
		oyuncu_komutunu_uygula("dondur")
	elif abs(hareket.x) > abs(hareket.y):
		oyuncu_komutunu_uygula("sag" if hareket.x > 0 else "sol")
	elif hareket.y > 0:
		oyuncu_komutunu_uygula("asagi")

func mobil_oyun_yerlesimini_uygula(zorla := false) -> void:
	if not zorla and not mobil_platform_mu():
		return
	$Arayuz/Birak.position = Vector2(520, 545)
	$Arayuz/Birak.size = Vector2(180, 96)
	$Arayuz/Duraklat.position = Vector2(520, 646)
	$Arayuz/Duraklat.size = Vector2(180, 96)
	$Arayuz/SesToggle.position = Vector2(520, 747)
	$Arayuz/SesToggle.size = Vector2(180, 96)
	$Arayuz/SesToggle.add_theme_font_size_override("font_size", 16)
	for veri in [
		[$Arayuz/Sol, Vector2(45, 860)],
		[$Arayuz/Dondur, Vector2(150, 860)],
		[$Arayuz/Sag, Vector2(255, 860)],
		[$Arayuz/Asagi, Vector2(360, 860)],
	]:
		var buton := veri[0] as Button
		buton.position = veri[1]
		buton.size = Vector2(90, 96)
	$Arayuz/GeriAl.position = Vector2(520, 860)
	$Arayuz/GeriAl.size = Vector2(180, 96)
	$Arayuz/GeriAl.add_theme_font_size_override("font_size", 18)
	durum_etiketi.position = Vector2(80, 74)
	durum_etiketi.size = Vector2(560, 22)
	durum_etiketi.add_theme_font_size_override("font_size", 13)
	duraklat_menu.position = Vector2(190, 250)
	duraklat_menu.size = Vector2(340, 480)
	oyun_bitti_paneli.position = Vector2(140, 270)
	oyun_bitti_paneli.size = Vector2(440, 400)
	minimum_dokunma_hedeflerini_uygula(duraklat_menu, true)
	minimum_dokunma_hedeflerini_uygula(oyun_bitti_paneli, true)

func _draw() -> void:
	var konum := tahta_konumu()
	var blok_boyutu := guncel_blok_boyutu()
	var tahta_alani := Rect2(konum - Vector2(8, 8) * _yerlesim_olcegi, Vector2(tahta.genislik * blok_boyutu + 16.0 * _yerlesim_olcegi, tahta.yukseklik * blok_boyutu + 16.0 * _yerlesim_olcegi))
	for panel in [$Arayuz/BilgiPaneli, $Arayuz/SonrakiPaneli]:
		var panel_rect: Rect2 = panel.get_global_rect()
		draw_rect(panel_rect.grow(2.0 * _yerlesim_olcegi), tema_vurgu_rengi, false, 2.0 * _yerlesim_olcegi)
	if not tahta.ozel_izgara_mi():
		draw_rect(tahta_alani, tema_tahta_rengi.darkened(0.25), true)
		draw_rect(tahta_alani, tema_vurgu_rengi, false, 4.0 * _yerlesim_olcegi)
	for y in tahta.yukseklik:
		for x in tahta.genislik:
			if not tahta.hucre_aktif_mi(Vector2i(x, y)):
				continue
			var alan := Rect2(konum + Vector2(x, y) * blok_boyutu, Vector2.ONE * blok_boyutu)
			var hucre := Vector2i(x, y)
			var yanma_rengi := yanma_rengini_al(hucre.y)
			draw_rect(alan, yanma_rengi if yanma_rengi != Color.TRANSPARENT else (tema_tahta_rengi.darkened(0.25) if tahta.ozel_izgara_mi() else tema_tahta_rengi), true)
			draw_rect(alan, tema_izgara_rengi, false, 1.0)
	if aktif_parca and aktif_parca.yikim_kapsulu:
		_yikim_kapsulu_alanini_ciz()
	for hucre in tahta.kilitli_hucreler:
		hucre_ciz(hucre, tahta.kilitli_hucreler[hucre])
	if aktif_parca:
		for hucre in aktif_parca.hucreler():
			if hucre.y >= 0:
				hucre_ciz(hucre, aktif_parca.renk, aktif_parca.yikim_kapsulu)
	sonraki_parcayi_ciz()

func _yikim_kapsulu_alanini_ciz() -> void:
	var dusurulecek := _parcayi_kopyala(aktif_parca)
	while true:
		dusurulecek.konum.y += 1
		if not tahta.gecerli_mi(dusurulecek):
			dusurulecek.konum.y -= 1
			break
	var tahmin := tahta.yikim_kapsulu_etkisini_al(dusurulecek)
	for hucre in tahmin.hucreler:
		var alan := Rect2(tahta_konumu() + Vector2(hucre) * guncel_blok_boyutu(), Vector2.ONE * guncel_blok_boyutu())
		var gosterge_alani := alan.grow(-3.0 * _yerlesim_olcegi)
		draw_rect(gosterge_alani, Color(1.0, 0.34, 0.18, 0.2), true)
		draw_rect(gosterge_alani, Color("ff8a50"), false, 1.5 * _yerlesim_olcegi)
		draw_line(gosterge_alani.position + Vector2(5, 5) * _yerlesim_olcegi, gosterge_alani.end - Vector2(5, 5) * _yerlesim_olcegi, Color("ff9c69"), _yerlesim_olcegi)
		draw_line(Vector2(gosterge_alani.end.x, gosterge_alani.position.y) + Vector2(-5, 5) * _yerlesim_olcegi, Vector2(gosterge_alani.position.x, gosterge_alani.end.y) + Vector2(5, -5) * _yerlesim_olcegi, Color("ff9c69"), _yerlesim_olcegi)

func hucre_ciz(hucre: Vector2i, renk: Color, kapsul_mu := false) -> void:
	var alan := Rect2(tahta_konumu() + Vector2(hucre) * guncel_blok_boyutu(), Vector2.ONE * guncel_blok_boyutu())
	var yanma_rengi := yanma_rengini_al(hucre.y)
	draw_rect(alan.grow(-2.0 * _yerlesim_olcegi), yanma_rengi if yanma_rengi != Color.TRANSPARENT else renk, true)
	if kapsul_mu:
		var merkez := alan.get_center()
		draw_circle(merkez, 6.0 * _yerlesim_olcegi, Color("32121a"))
		draw_arc(merkez, 9.0 * _yerlesim_olcegi, 0.0, TAU, 24, Color("fff2d8"), 2.0 * _yerlesim_olcegi)
		draw_circle(merkez, 2.5 * _yerlesim_olcegi, Color("fff2d8"))

func yanma_rengini_al(y: int) -> Color:
	if not satir_silme_animasyonu_aktif or y not in yanan_satirlar:
		return Color.TRANSPARENT
	var ilerleme: float = clampf(float(Time.get_ticks_msec() - yanma_baslangic_zamani) / 350.0, 0.0, 1.0)
	return Color(1.0, 0.9 - ilerleme * 0.7, 0.15, 1.0)

func tahta_konumu() -> Vector2:
	var referans_konum := REFERANS_TAHTA_KONUMU + Vector2(
		(REFERANS_TAHTA_GENISLIGI - tahta.genislik) * BLOK_BOYUTU / 2.0,
		(REFERANS_TAHTA_YUKSEKLIGI - tahta.yukseklik) * BLOK_BOYUTU
	)
	return _yerlesim_ofseti + referans_konum * _yerlesim_olcegi

func guncel_blok_boyutu() -> float:
	return BLOK_BOYUTU * _yerlesim_olcegi

func yerlesimi_guncelle() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var kullanilabilir_alan := Rect2(Vector2.ZERO, size)
	if mobil_platform_mu():
		var pencere_boyutu := Vector2(DisplayServer.window_get_size())
		var guvenli_dikdortgen := DisplayServer.get_display_safe_area()
		if pencere_boyutu.x > 0.0 and pencere_boyutu.y > 0.0 and guvenli_dikdortgen.size.x > 0.0 and guvenli_dikdortgen.size.y > 0.0:
			var ekran_olcegi := size / pencere_boyutu
			kullanilabilir_alan = Rect2(Vector2(guvenli_dikdortgen.position) * ekran_olcegi, Vector2(guvenli_dikdortgen.size) * ekran_olcegi)
	# Referans arayüz safe area içinde her en-boy oranında tam sığar.
	_yerlesim_olcegi = minf(kullanilabilir_alan.size.x / REFERANS_EKRAN_BOYUTU.x, kullanilabilir_alan.size.y / REFERANS_EKRAN_BOYUTU.y)
	_yerlesim_ofseti = kullanilabilir_alan.position + (kullanilabilir_alan.size - REFERANS_EKRAN_BOYUTU * _yerlesim_olcegi) * 0.5
	$Arayuz.position = _yerlesim_ofseti
	$Arayuz.scale = Vector2.ONE * _yerlesim_olcegi
	queue_redraw()

func sonraki_parcayi_ciz() -> void:
	if not sonraki_parca:
		return
	var hucreler := sonraki_parca.hucreler()
	var en_kucuk_x := hucreler[0].x
	var en_kucuk_y := hucreler[0].y
	for hucre in hucreler:
		en_kucuk_x = min(en_kucuk_x, hucre.x)
		en_kucuk_y = min(en_kucuk_y, hucre.y)
	var onizleme_alani := sonraki_onizleme_alani()
	var genislik := 0
	var yukseklik := 0
	for hucre in hucreler:
		genislik = max(genislik, hucre.x - en_kucuk_x + 1)
		yukseklik = max(yukseklik, hucre.y - en_kucuk_y + 1)
	var hucre_boyutu: float = minf(minf(onizleme_alani.size.x / float(genislik), onizleme_alani.size.y / float(yukseklik)), 24.0 * _yerlesim_olcegi)
	var cizim_boyutu := Vector2(genislik, yukseklik) * hucre_boyutu
	var baslangic: Vector2 = onizleme_alani.get_center() - cizim_boyutu * 0.5
	for hucre in hucreler:
		var konum: Vector2 = baslangic + Vector2(hucre.x - en_kucuk_x, hucre.y - en_kucuk_y) * hucre_boyutu
		draw_rect(Rect2(konum, Vector2.ONE * (hucre_boyutu - 3.0 * _yerlesim_olcegi)), sonraki_parca.renk, true)
		if sonraki_parca.yikim_kapsulu:
			var merkez := konum + Vector2.ONE * hucre_boyutu * 0.5
			draw_circle(merkez, 4.0 * _yerlesim_olcegi, Color("32121a"))
			draw_arc(merkez, 6.5 * _yerlesim_olcegi, 0.0, TAU, 20, Color("fff2d8"), 1.5 * _yerlesim_olcegi)

func sonraki_onizleme_alani() -> Rect2:
	var panel_alani: Rect2 = $Arayuz/SonrakiPaneli.get_global_rect()
	var kenar_boslugu := 12.0 * _yerlesim_olcegi
	var baslik_boslugu := 38.0 * _yerlesim_olcegi
	return Rect2(
		panel_alani.position + Vector2(kenar_boslugu, baslik_boslugu),
		panel_alani.size - Vector2(kenar_boslugu * 2.0, baslik_boslugu + kenar_boslugu)
	)

func oyunu_kaydet() -> bool:
	if not oyun_aktif or satir_silme_animasyonu_aktif:
		return false
	var basarili := kayit_yoneticisi.kaydet(tahta, skor_yoneticisi, aktif_parca, sonraki_parca, dusme_araligi, parca_uretici, kapsul_gorevi_ilerleme)
	kayit_uyarisi = "" if basarili else "Kayıt yazılamadı."
	return basarili

func oyunu_yukle() -> bool:
	var data = kayit_yoneticisi.yukle()
	if data.is_empty():
		return false
	_oyun_oturum_id += 1
	# Tahta
	var aktif_hucreler: Array = []
	for item in data.get("aktif_hucreler", []):
		aktif_hucreler.append(Vector2i(int(item.x), int(item.y)))
	tahta = OyunTahtasi.new(int(data.genislik), int(data.yukseklik), aktif_hucreler)
	for item in data.kilitli:
		var h = Vector2i(int(item.x), int(item.y))
		tahta.kilitli_hucreler[h] = Color(item.r, item.g, item.b, item.a)
	# Skor
	kapsul_gorevi_ilerleme = clampi(int(data.get("kapsul_gorevi_ilerleme", 0)), 0, KAPSUL_GOREVI_HEDEFI)
	skor_yoneticisi.skor = int(data.skor)
	skor_yoneticisi.ana_level = int(data.ana_level)
	skor_yoneticisi.alt_seviye = int(data.alt_seviye)
	skor_yoneticisi.asama_satirlari = int(data.asama_satirlari)
	skor_yoneticisi.silinen_satir = int(data.silinen_satir)
	# Düşme
	if data.has("dusme_araligi"):
		dusme_araligi = data.dusme_araligi
	# Aktif parça
	if data.has("aktif") and data.aktif != null:
		var a = data.aktif
		aktif_parca = BlokParcasi.new(a.kalip, Color(a.renk.r, a.renk.g, a.renk.b, a.renk.a), bool(a.get("yikim_kapsulu", false)))
		aktif_parca.konum = Vector2i(a.x, a.y)
		aktif_parca.donus = a.donus
	# Sonraki parça
	if data.has("sonraki") and data.sonraki != null:
		sonraki_parca = BlokParcasi.new(data.sonraki.kalip, Color(data.sonraki.renk.r, data.sonraki.renk.g, data.sonraki.renk.b, data.sonraki.renk.a), bool(data.sonraki.get("yikim_kapsulu", false)))
	# Kayıtlı tahtaya dokunmadan, yalnızca ilgili levelin parça havuzunu kur.
	var ayar := level_yoneticisi.level_ayari_al(skor_yoneticisi.ana_level)
	parca_uretici = ParcaUretici.new(ayar.parca_havuzu, float(ayar.get("yikim_kapsulu_ihtimali", 0.1)))
	level_kimligini_uygula(ayar)
	ses_yoneticisi.tema_degistir(clampi(skor_yoneticisi.ana_level, 1, 3))
	arayuzu_guncelle()
	queue_redraw()
	return true
