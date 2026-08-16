extends TemelSahne

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
var kayit_yoneticisi: OyunKayitYoneticisi
var aktif_parca: TetrisParcasi
var sonraki_parca: TetrisParcasi
var dusme_suresi := 0.0
var dusme_araligi := 0.6
var oyun_aktif := true
var oyun_duraklatildi := false
var dokunma_baslangici := Vector2.ZERO
var satir_silme_animasyonu_aktif := false
var yanan_satirlar: Array[int] = []
var yanma_baslangic_zamani := 0
var _oyun_oturum_id := 0
var _yerlesim_olcegi := 1.0
var _yerlesim_ofseti := Vector2.ZERO

@onready var skor_etiketi: Label = $Arayuz/Skor
@onready var yuksek_skor_etiketi: Label = $Arayuz/YuksekSkor
@onready var seviye_etiketi: Label = $Arayuz/Seviye
@onready var alt_seviye_etiketi: Label = $Arayuz/AltSeviye
@onready var satir_etiketi: Label = $Arayuz/Satir
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

func focusu_birak() -> void:
	var vp = get_viewport()
	if vp:
		vp.gui_release_focus()

func _ready() -> void:
	ses_yoneticisi = get_node("/root/SesYonetici") as SesYoneticisi
	ayar_yoneticisi = ses_yoneticisi.ayar_yoneticisi
	kayit_yoneticisi = OyunKayitYoneticisi.new(kayit_yolu)
	var kayitli_oyun_yuklenecek := bool(get_tree().get_meta("kayitli_oyun_yukle", false))
	get_tree().set_meta("kayitli_oyun_yukle", false)
	if not kayitli_oyun_yuklenecek or not oyunu_yukle():
		yeni_oyunu_baslat()
	ses_toggle_butonu.text = "🔊" if ses_yoneticisi.ses_acik else "🔇"
	$Arayuz/Sol.pressed.connect(func(): komutu_uygula("sol"); focusu_birak())
	$Arayuz/Sag.pressed.connect(func(): komutu_uygula("sag"); focusu_birak())
	$Arayuz/Asagi.pressed.connect(func(): komutu_uygula("asagi"); focusu_birak())
	$Arayuz/Birak.pressed.connect(func(): aninda_indir(); focusu_birak())
	$Arayuz/Duraklat.pressed.connect(duraklatmayi_degistir)
	$Arayuz/OyunBitti/Icerik/YenidenBaslat.pressed.connect(func(): yeniden_baslat(); focusu_birak())
	$Arayuz/OyunBitti/Icerik/MenuyeDon.pressed.connect(func(): menuye_don(); focusu_birak())
	oyun_bitti_paneli.visible = false
	duraklatma_etiketi.visible = false
	duraklat_menu.visible = false
	seviye_gecis_etiketi.visible = false
	seviye_gecis_zamanlayicisi.timeout.connect(func(): seviye_gecis_etiketi.visible = false)
	$Arayuz/Dondur.pressed.connect(func(): komutu_uygula("dondur"); focusu_birak())
	$Arayuz/DuraklatMenu/DuraklatIcerik/DevamEtBtn.pressed.connect(duraklatmayi_degistir)
	$Arayuz/DuraklatMenu/DuraklatIcerik/YenidenBaslatBtn.pressed.connect(func(): yeniden_baslat(); focusu_birak())
	$Arayuz/DuraklatMenu/DuraklatIcerik/AnaMenuBtn.pressed.connect(func(): menuye_don(); focusu_birak())
	$Arayuz/SesToggle.pressed.connect(func(): ses_toggle(); focusu_birak())
	focusu_birak()
	resized.connect(yerlesimi_guncelle)
	yerlesimi_guncelle()
	arayuzu_guncelle()
	queue_redraw()

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
	# Arayüz butonlarının işlediği dokunuşlar buraya ulaşmaz.
	# Böylece bir butona basmak parçayı yanlışlıkla döndürmez.
	if not oyun_aktif:
		return
	if olay is InputEventScreenTouch:
		if olay.pressed:
			dokunma_baslangici = olay.position
		else:
			dokunmatik_komutu_uygula(olay.position)
		return
	var komut := giris_yoneticisi.klavye_komutu(olay)
	if komut == "duraklat":
		duraklatmayi_degistir()
		return
	if oyun_duraklatildi:
		return
	if komut == "birak":
		aninda_indir()
		return
	if komut != "":
		komutu_uygula(komut)

func komutu_uygula(komut: String) -> void:
	if not oyun_aktif or oyun_duraklatildi or satir_silme_animasyonu_aktif:
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
	if not oyun_aktif or oyun_duraklatildi:
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
	if not oyun_aktif:
		return
	oyun_duraklatildi = not oyun_duraklatildi
	duraklatma_etiketi.visible = oyun_duraklatildi
	duraklat_menu.visible = oyun_duraklatildi
	duraklat_butonu.text = "Devam Et" if oyun_duraklatildi else "Durdur"
	duraklat_butonu.release_focus()
	focusu_birak()
	if oyun_duraklatildi:
		oyunu_kaydet()
	if ses_yoneticisi:
		if oyun_duraklatildi:
			ses_yoneticisi.muzik_oynatici.stream_paused = true
		else:
			if ses_yoneticisi.muzik_acik and ses_yoneticisi.ses_acik:
				ses_yoneticisi.muzik_oynatici.stream_paused = false
				if not ses_yoneticisi.muzik_oynatici.playing:
					ses_yoneticisi.muzik_oynatici.play()
	arayuzu_guncelle()

func ses_toggle() -> void:
	if ses_yoneticisi:
		ayar_yoneticisi.ses_ayarini_kaydet(not ses_yoneticisi.ses_acik)
		ses_yoneticisi.ayarları_uygula()
		ses_toggle_butonu.text = "🔊" if ses_yoneticisi.ses_acik else "🔇"

func parcayi_dusur() -> void:
	if satir_silme_animasyonu_aktif:
		return
	aktif_parca.konum.y += 1
	if not tahta.gecerli_mi(aktif_parca):
		aktif_parca.konum.y -= 1
		tahta.parcayi_kilitle(aktif_parca)
		var dolu_satirlar := tahta.dolu_satirlari_bul()
		if not dolu_satirlar.is_empty():
			satir_silme_animasyonunu_oynat(dolu_satirlar)
			return
		kilitlenmis_parcayi_isle(0)
	arayuzu_guncelle()
	queue_redraw()

func satir_silme_animasyonunu_oynat(dolu_satirlar: Array[int]) -> void:
	var animasyon_oturum_id := _oyun_oturum_id
	satir_silme_animasyonu_aktif = true
	yanan_satirlar = dolu_satirlar
	yanma_baslangic_zamani = Time.get_ticks_msec()
	queue_redraw()
	await get_tree().create_timer(0.35).timeout
	if animasyon_oturum_id != _oyun_oturum_id or not is_inside_tree():
		return
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
	elif tahta.oyun_bitti_mi():
		oyunu_sonlandir(false)
	else:
		aktif_parca = sonraki_parca
		sonraki_parca = parca_uretici.yeni_parca()
		# Satır animasyonu bittikten ve yeni parça oluşturulduktan sonra durum tutarlıdır.
		oyunu_kaydet()

func arayuzu_guncelle() -> void:
	skor_etiketi.text = "Skor: %d" % skor_yoneticisi.skor
	yuksek_skor_etiketi.text = "Yüksek Skor: %d" % skor_yoneticisi.yuksek_skor
	seviye_etiketi.text = "Level: %d" % skor_yoneticisi.ana_level
	alt_seviye_etiketi.text = "Seviye: %d / %d" % [skor_yoneticisi.alt_seviye, SkorYoneticisi.ALT_SEVIYE_SAYISI]
	satir_etiketi.text = "Hedef: %d / %d • %d×%d" % [skor_yoneticisi.asama_satirlari, SkorYoneticisi.ALT_SEVIYE_ICIN_SATIR, tahta.genislik, tahta.yukseklik]
	if oyun_duraklatildi:
		durum_etiketi.text = "Oyun duraklatıldı"
	elif oyun_aktif:
		durum_etiketi.text = "W: döndür • Boşluk: bırak • P: duraklat"
	else:
		durum_etiketi.text = "Oyun bitti — yeniden başlatabilir veya menüye dönebilirsin"

func yeniden_baslat() -> void:
	yeni_oyunu_baslat()

func yeni_oyunu_baslat() -> void:
	_oyun_oturum_id += 1
	# Yeniden başlatma, önceki oyunun devam kaydını kullanılamaz hale getirir.
	if kayit_yoneticisi:
		kayit_yoneticisi.kaydi_sil()
	skor_yoneticisi = SkorYoneticisi.new()
	level_ayarini_uygula()
	dusme_suresi = 0.0
	dusme_araligi = 0.6
	oyun_aktif = true
	oyun_duraklatildi = false
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
	seviye_gecis_etiketi.text = "LEVEL %d — SEVİYE %d\nHız %%10 arttı" % [skor_yoneticisi.ana_level, skor_yoneticisi.alt_seviye]
	seviye_gecis_etiketi.visible = true
	seviye_gecis_zamanlayicisi.start()

func level_ayarini_uygula() -> void:
	var ayar := level_yoneticisi.level_ayari_al(skor_yoneticisi.ana_level)
	tahta = OyunTahtasi.new(ayar.genislik, ayar.yukseklik, ayar.get("aktif_hucreler", []))
	parca_uretici = ParcaUretici.new(ayar.parca_havuzu)
	aktif_parca = parca_uretici.yeni_parca()
	sonraki_parca = parca_uretici.yeni_parca()
	if ses_yoneticisi:
		var tema_no = clampi(skor_yoneticisi.ana_level, 1, 3)
		ses_yoneticisi.tema_degistir(tema_no)

func oyunu_sonlandir(tamamlandi_mi: bool) -> void:
	oyun_aktif = false
	# Bitmiş oyun hiçbir zaman devam kaydı olarak geri dönmemeli.
	kayit_yoneticisi.kaydi_sil()
	skor_yoneticisi.yuksek_skoru_kaydet()
	oyun_bitti_paneli.visible = true
	if tamamlandi_mi:
		sonuc_basligi.text = "TEBRİKLER!"
		sonuc_aciklamasi.text = "5 level ve 15 seviyeyi tamamladın!"
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

func dokunmatik_komutu_uygula(bitis_konumu: Vector2) -> void:
	var hareket := bitis_konumu - dokunma_baslangici
	if hareket.length() < 24.0:
		komutu_uygula("dondur")
	elif abs(hareket.x) > abs(hareket.y):
		komutu_uygula("sag" if hareket.x > 0 else "sol")
	elif hareket.y > 0:
		komutu_uygula("asagi")

func _draw() -> void:
	var konum := tahta_konumu()
	var blok_boyutu := guncel_blok_boyutu()
	var tahta_alani := Rect2(konum - Vector2(8, 8) * _yerlesim_olcegi, Vector2(tahta.genislik * blok_boyutu + 16.0 * _yerlesim_olcegi, tahta.yukseklik * blok_boyutu + 16.0 * _yerlesim_olcegi))
	if not tahta.ozel_izgara_mi():
		draw_rect(tahta_alani, Color("111827"), true)
		draw_rect(tahta_alani, Color("f43f5e"), false, 3.0 * _yerlesim_olcegi)
	for y in tahta.yukseklik:
		for x in tahta.genislik:
			if not tahta.hucre_aktif_mi(Vector2i(x, y)):
				continue
			var alan := Rect2(konum + Vector2(x, y) * blok_boyutu, Vector2.ONE * blok_boyutu)
			var hucre := Vector2i(x, y)
			var yanma_rengi := yanma_rengini_al(hucre.y)
			draw_rect(alan, yanma_rengi if yanma_rengi != Color.TRANSPARENT else (Color("111827") if tahta.ozel_izgara_mi() else Color("202535")), true)
			draw_rect(alan, Color("4d566d"), false, 1.0)
	for hucre in tahta.kilitli_hucreler:
		hucre_ciz(hucre, tahta.kilitli_hucreler[hucre])
	if aktif_parca:
		for hucre in aktif_parca.hucreler():
			if hucre.y >= 0:
				hucre_ciz(hucre, aktif_parca.renk)
	sonraki_parcayi_ciz()

func hucre_ciz(hucre: Vector2i, renk: Color) -> void:
	var alan := Rect2(tahta_konumu() + Vector2(hucre) * guncel_blok_boyutu(), Vector2.ONE * guncel_blok_boyutu())
	var yanma_rengi := yanma_rengini_al(hucre.y)
	draw_rect(alan.grow(-2.0 * _yerlesim_olcegi), yanma_rengi if yanma_rengi != Color.TRANSPARENT else renk, true)

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
	# Referans arayüz, her en-boy oranında tam sığacak şekilde ölçeklenir.
	_yerlesim_olcegi = minf(size.x / REFERANS_EKRAN_BOYUTU.x, size.y / REFERANS_EKRAN_BOYUTU.y)
	_yerlesim_ofseti = (size - REFERANS_EKRAN_BOYUTU * _yerlesim_olcegi) * 0.5
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

func sonraki_onizleme_alani() -> Rect2:
	var panel_alani: Rect2 = $Arayuz/SonrakiPaneli.get_global_rect()
	var kenar_boslugu := 12.0 * _yerlesim_olcegi
	var baslik_boslugu := 38.0 * _yerlesim_olcegi
	return Rect2(
		panel_alani.position + Vector2(kenar_boslugu, baslik_boslugu),
		panel_alani.size - Vector2(kenar_boslugu * 2.0, baslik_boslugu + kenar_boslugu)
	)

func oyunu_kaydet() -> void:
	if not oyun_aktif or satir_silme_animasyonu_aktif:
		return
	kayit_yoneticisi.kaydet(tahta, skor_yoneticisi, aktif_parca, sonraki_parca, dusme_araligi, parca_uretici)

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
		aktif_parca = TetrisParcasi.new(a.kalip, Color(a.renk.r, a.renk.g, a.renk.b, a.renk.a))
		aktif_parca.konum = Vector2i(a.x, a.y)
		aktif_parca.donus = a.donus
	# Sonraki parça
	if data.has("sonraki") and data.sonraki != null:
		sonraki_parca = TetrisParcasi.new(data.sonraki.kalip, Color(data.sonraki.renk.r, data.sonraki.renk.g, data.sonraki.renk.b, data.sonraki.renk.a))
	# Kayıtlı tahtaya dokunmadan, yalnızca ilgili levelin parça havuzunu kur.
	var ayar := level_yoneticisi.level_ayari_al(skor_yoneticisi.ana_level)
	parca_uretici = ParcaUretici.new(ayar.parca_havuzu)
	ses_yoneticisi.tema_degistir(clampi(skor_yoneticisi.ana_level, 1, 3))
	arayuzu_guncelle()
	queue_redraw()
	return true
