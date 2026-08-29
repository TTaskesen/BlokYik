extends SceneTree

const TEST_KAYIT_YOLU := "user://blok_yik_test_oyun_kayit.save"
const TEST_AYAR_YOLU := "user://blok_yik_test_ayarlar.cfg"
const TEST_ESKI_AYAR_YOLU := "user://blok_yik_test_eski_ayarlar.cfg"
const TEST_SKOR_YOLU := "user://blok_yik_test_yuksek_skor.save"
const OYUN_SAHNESI := preload("res://scenes/BlokYikOyun.tscn")
const MENU_SAHNESI := preload("res://scenes/AnaMenu.tscn")
const YARDIMCI_SAHNELER := [
	preload("res://scenes/Ayarlar.tscn"),
	preload("res://scenes/NasilOynanir.tscn"),
	preload("res://scenes/Hakkinda.tscn"),
	preload("res://scenes/YuksekSkorlar.tscn"),
]

class GeriSayacSahnesi extends TemelSahne:
	var geri_sayisi := 0
	func geri_istegini_isle() -> void:
		geri_sayisi += 1

var basarisizlik_sayisi := 0

func _init() -> void:
	call_deferred("testleri_calistir")

func kontrol(kosul: bool, mesaj: String) -> void:
	if not kosul:
		basarisizlik_sayisi += 1
		push_error("BAŞARISIZ: " + mesaj)

func testleri_calistir() -> void:
	var kayit_yoneticisi := OyunKayitYoneticisi.new(TEST_KAYIT_YOLU)
	DirAccess.remove_absolute(TEST_KAYIT_YOLU)
	DirAccess.remove_absolute(TEST_AYAR_YOLU)
	DirAccess.remove_absolute(TEST_ESKI_AYAR_YOLU)
	DirAccess.remove_absolute(TEST_SKOR_YOLU)
	var tahta := OyunTahtasi.new(10, 20)
	tahta.kilitli_hucreler[Vector2i(2, 18)] = Color.CORNFLOWER_BLUE
	var skor := SkorYoneticisi.new(TEST_SKOR_YOLU)
	skor.skor = 345
	skor.ana_level = 2
	skor.alt_seviye = 3
	skor.asama_satirlari = 12
	skor.silinen_satir = 42
	var aktif := BlokParcasi.new([["00"]], Color.RED)
	aktif.konum = Vector2i(4, 7)
	aktif.donus = 1
	var sonraki := BlokParcasi.new([["0"], ["0"]], Color.YELLOW)
	kayit_yoneticisi.kaydet(tahta, skor, aktif, sonraki, 0.25, ParcaUretici.new())
	kontrol(kayit_yoneticisi.kayit_var_mi(), "Kayıt yöneticisi yeni kaydı bulmalı.")
	var ham_kayit := kayit_yoneticisi.yukle()
	kontrol(ham_kayit.get("surum") == OyunKayitYoneticisi.SURUM, "Geçerli kayıtta desteklenen şema sürümü bulunmalı.")

	var menu = MENU_SAHNESI.instantiate()
	menu.kayit_yolu = TEST_KAYIT_YOLU
	root.add_child(menu)
	await process_frame
	kontrol(not menu.devam_et_butonu.disabled, "Kayıt varken Devam Et etkin olmalı.")
	menu.kayitli_oyuna_devam_etmeye_hazir_mi()
	kontrol(bool(get_meta("kayitli_oyun_yukle", false)), "Devam Et kayıt yükleme isteğini iletmeli.")
	if is_instance_valid(menu):
		menu.queue_free()
	await process_frame

	set_meta("kayitli_oyun_yukle", true)
	var oyun = OYUN_SAHNESI.instantiate()
	oyun.kayit_yolu = TEST_KAYIT_YOLU
	oyun.yuksek_skor_kayit_yolu = TEST_SKOR_YOLU
	root.add_child(oyun)
	await process_frame
	kontrol(oyun.skor_yoneticisi.skor == 345, "Yüklenen skor korunmalı.")
	kontrol(oyun.skor_yoneticisi.ana_level == 2 and oyun.skor_yoneticisi.alt_seviye == 3, "Yüklenen level bilgisi korunmalı.")
	kontrol(oyun.tahta.kilitli_hucreler.has(Vector2i(2, 18)), "Yüklenen tahta hücresi korunmalı.")
	kontrol(oyun.aktif_parca.konum == Vector2i(4, 7), "Yüklenen aktif parça korunmalı.")
	kontrol(oyun.sonraki_parca.kalip == [["0"], ["0"]], "Yüklenen sonraki parça korunmalı.")

	# Referans arayüz dar ekranlarda küçülür; önizleme paneli başlık ve butonlardan ayrıdır.
	oyun.size = Vector2(360, 480)
	oyun.yerlesimi_guncelle()
	var onizleme_alani: Rect2 = oyun.sonraki_onizleme_alani()
	var sonraki_paneli: Control = oyun.get_node("Arayuz/SonrakiPaneli")
	kontrol(is_equal_approx(oyun._yerlesim_olcegi, 0.5), "Dar ekran yerleşimi referans arayüzü orantılı küçültmeli.")
	kontrol(onizleme_alani.size.x > 0.0 and onizleme_alani.size.y > 0.0 and sonraki_paneli.get_global_rect().encloses(onizleme_alani), "Sonraki parça önizlemesi kendi responsive panelinde kalmalı.")
	oyun.size = Vector2(720, 960)
	oyun.yerlesimi_guncelle()
	oyun.arayuzu_guncelle()
	var bilgi_paneli: Control = oyun.get_node("Arayuz/BilgiPaneli")
	for etiket_yolu in ["Arayuz/BilgiPaneli/Kenar/Icerik/Puanlar", "Arayuz/BilgiPaneli/Kenar/Icerik/Skor", "Arayuz/BilgiPaneli/Kenar/Icerik/YuksekSkorBaslik", "Arayuz/BilgiPaneli/Kenar/Icerik/YuksekSkor", "Arayuz/BilgiPaneli/Kenar/Icerik/Bolum", "Arayuz/BilgiPaneli/Kenar/Icerik/AltSeviye", "Arayuz/BilgiPaneli/Kenar/Icerik/Satir"]:
		var bilgi_etiketi: Label = oyun.get_node(etiket_yolu)
		kontrol(bilgi_paneli.get_global_rect().encloses(bilgi_etiketi.get_global_rect()), "%s bilgi panelinin içinde kalmalı." % bilgi_etiketi.name)
		kontrol(bilgi_etiketi.get_minimum_size().x <= bilgi_etiketi.size.x, "%s metni sağ taraftan taşmamalı." % bilgi_etiketi.name)
	oyun.yuksek_skor_etiketi.text = "999999999"
	kontrol(oyun.yuksek_skor_etiketi.text == "999999999", "Dokuz basamaklı yüksek skor eksiksiz gösterilmeli.")
	kontrol(oyun.yuksek_skor_etiketi.get_minimum_size().x <= oyun.yuksek_skor_etiketi.size.x, "Dokuz basamaklı yüksek skor panelden taşmamalı.")
	oyun.arayuzu_guncelle()
	kontrol(oyun.bolum_etiketi.text.begins_with("Bölüm:"), "Genel ilerleme oyuncuya Bölüm olarak gösterilmeli.")

	# Mobil ana kontroller 48 dp hedefi için 720 tabanlı tuvalde en az 96 birimdir.
	oyun.mobil_arayuz_zorla = true
	oyun.mobil_oyun_yerlesimini_uygula(true)
	oyun.arayuzu_guncelle()
	for buton_yolu in ["Arayuz/Sol", "Arayuz/Dondur", "Arayuz/Sag", "Arayuz/Asagi", "Arayuz/Birak", "Arayuz/Duraklat", "Arayuz/SesToggle"]:
		var mobil_buton: Button = oyun.get_node(buton_yolu)
		kontrol(mobil_buton.size.y >= 96.0, "%s mobil dokunma hedefi en az 96 tuval birimi olmalı." % mobil_buton.name)
	kontrol("Dokun:" in oyun.durum_etiketi.text and "Kaydır:" in oyun.durum_etiketi.text, "Android oyun ekranı mobil yönlendirmeyi göstermeli.")
	oyun.geri_istegini_isle()
	kontrol(oyun.oyun_duraklatildi, "Oyun sırasında geri hareketi oyunu duraklatmalı.")
	oyun.geri_istegini_isle()
	kontrol(not oyun.oyun_duraklatildi, "Duraklatılmış oyunda geri hareketi oyuna dönmeli.")

	# Her kilitlenme sonrasında, yeni aktif ve sonraki parça ile tutarlı bir kayıt oluşmalı.
	oyun.tahta = OyunTahtasi.new(10, 20)
	oyun.aktif_parca = BlokParcasi.new([["0"]], Color.GREEN)
	oyun.aktif_parca.konum = Vector2i(3, 19)
	oyun.sonraki_parca = BlokParcasi.new([["00"]], Color.CYAN)
	oyun.parcayi_dusur()
	var kilit_sonrasi_kayit := kayit_yoneticisi.yukle()
	kontrol(not kilit_sonrasi_kayit.is_empty(), "Parça kilitlenince devam kaydı oluşmalı.")
	kontrol(kilit_sonrasi_kayit.aktif != null and kilit_sonrasi_kayit.sonraki != null, "Kilit sonrası kayıtta aktif ve sonraki parça bulunmalı.")

	var satir_tahtasi := OyunTahtasi.new(10, 20)
	for x in 10:
		satir_tahtasi.kilitli_hucreler[Vector2i(x, 19)] = Color.WHITE
	oyun.tahta = satir_tahtasi
	var silinecek_satirlar: Array[int] = [19]
	oyun.satir_silme_animasyonunu_oynat(silinecek_satirlar)
	oyun.yeniden_baslat()
	await create_timer(0.45).timeout
	kontrol(oyun.skor_yoneticisi.skor == 0, "Eski satır animasyonu yeniden başlatılan oyunun skorunu değiştirmemeli.")
	kontrol(oyun.tahta.kilitli_hucreler.is_empty(), "Eski satır animasyonu yeniden başlatılan oyunun tahtasını değiştirmemeli.")
	kontrol(not kayit_yoneticisi.kayit_var_mi(), "Yeni oyun eski devam kaydını temizlemeli.")

	# Bitmiş oyun, uygulama kapansa bile devam edilebilir bir kayıt bırakmamalı.
	kayit_yoneticisi.kaydet(tahta, skor, aktif, sonraki, 0.25, ParcaUretici.new())
	oyun.oyunu_sonlandir(false)
	kontrol(not kayit_yoneticisi.kayit_var_mi(), "Oyun sonu kaydı Devam Et için kullanılamamalı.")
	oyun.queue_free()
	await process_frame

	var oyun_sonu_menu = MENU_SAHNESI.instantiate()
	oyun_sonu_menu.kayit_yolu = TEST_KAYIT_YOLU
	root.add_child(oyun_sonu_menu)
	await process_frame
	kontrol(oyun_sonu_menu.devam_et_butonu.disabled, "Oyun sonundan sonra menü Devam Et düğmesini pasifleştirmeli.")
	oyun_sonu_menu.queue_free()
	await process_frame

	# Eski sürüm ve bozuk JSON kayıtları temizlenmeli, menüde açıklanmalıdır.
	var bozuk_dosya := FileAccess.open(TEST_KAYIT_YOLU, FileAccess.WRITE)
	bozuk_dosya.store_string('{"surum": 999}')
	bozuk_dosya.close()
	var uyumsuz_menu = MENU_SAHNESI.instantiate()
	uyumsuz_menu.kayit_yolu = TEST_KAYIT_YOLU
	root.add_child(uyumsuz_menu)
	await process_frame
	kontrol(uyumsuz_menu.devam_et_butonu.disabled, "Desteklenmeyen sürüm Devam Et'i etkinleştirmemeli.")
	kontrol("sürümü desteklenmiyor" in uyumsuz_menu.kayit_durum_etiketi.text, "Menü desteklenmeyen kayıt sürümünü açıklamalı.")
	uyumsuz_menu.queue_free()
	await process_frame

	var eksik_kayit := ham_kayit.duplicate(true)
	eksik_kayit.erase("skor")
	bozuk_dosya = FileAccess.open(TEST_KAYIT_YOLU, FileAccess.WRITE)
	bozuk_dosya.store_string(JSON.stringify(eksik_kayit))
	bozuk_dosya.close()
	var eksik_menu = MENU_SAHNESI.instantiate()
	eksik_menu.kayit_yolu = TEST_KAYIT_YOLU
	root.add_child(eksik_menu)
	await process_frame
	kontrol(eksik_menu.devam_et_butonu.disabled, "Eksik alanlı kayıt Devam Et'i etkinleştirmemeli.")
	kontrol("bozuk" in eksik_menu.kayit_durum_etiketi.text, "Menü eksik alanlı kaydı açıklamalı.")
	eksik_menu.queue_free()
	await process_frame

	bozuk_dosya = FileAccess.open(TEST_KAYIT_YOLU, FileAccess.WRITE)
	bozuk_dosya.store_string("bu bir JSON değil")
	bozuk_dosya.close()
	var bozuk_menu = MENU_SAHNESI.instantiate()
	bozuk_menu.kayit_yolu = TEST_KAYIT_YOLU
	root.add_child(bozuk_menu)
	await process_frame
	kontrol(bozuk_menu.devam_et_butonu.disabled, "Bozuk JSON Devam Et'i etkinleştirmemeli.")
	kontrol("bozuk" in bozuk_menu.kayit_durum_etiketi.text, "Menü bozuk kaydı açıklamalı.")
	kontrol(not FileAccess.file_exists(TEST_KAYIT_YOLU), "Geçersiz kayıt güvenli biçimde temizlenmeli.")
	bozuk_menu.queue_free()
	await process_frame

	# Yardımcı ekranlar dar, referans ve geniş görünümde yatay taşmamalı.
	for yardimci_paket in YARDIMCI_SAHNELER:
		var yardimci = yardimci_paket.instantiate()
		root.add_child(yardimci)
		await process_frame
		for gorunum in [Vector2(360, 640), Vector2(720, 960), Vector2(1024, 600)]:
			yardimci.set_anchors_preset(Control.PRESET_TOP_LEFT)
			yardimci.size = gorunum
			yardimci._responsive_yerlesimi_guncelle()
			await process_frame
			var panel_dikdortgen: Rect2 = yardimci.responsive_panel.get_global_rect()
			kontrol(panel_dikdortgen.position.x >= 23.0, "%s paneli sol güvenli alanı aşmamalı: görünüm=%s panel=%s" % [yardimci.name, gorunum, panel_dikdortgen])
			kontrol(panel_dikdortgen.end.x <= gorunum.x - 23.0, "%s paneli sağ güvenli alanı aşmamalı: görünüm=%s panel=%s" % [yardimci.name, gorunum, panel_dikdortgen])
		yardimci.queue_free()
		await process_frame

	# Mobil ana menüde Çıkış gizlenir; geri hareketi güvenli onayı açıp kapatır.
	var mobil_menu = MENU_SAHNESI.instantiate()
	mobil_menu.kayit_yolu = TEST_KAYIT_YOLU
	mobil_menu.mobil_arayuz_zorla = true
	root.add_child(mobil_menu)
	await process_frame
	kontrol(not mobil_menu.cikis_butonu.visible, "Android ana menüsünde Çıkış düğmesi görünmemeli.")
	mobil_menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	mobil_menu.size = Vector2(360, 640)
	mobil_menu.ana_menu_yerlesimini_guncelle()
	await process_frame
	var mobil_menu_dikdortgen: Rect2 = mobil_menu.menu_paneli.get_global_rect()
	kontrol(mobil_menu_dikdortgen.position.x >= 23.0 and mobil_menu_dikdortgen.end.x <= 337.0, "Ana menü dar görünümde yatay taşmamalı.")
	mobil_menu.geri_istegini_isle()
	kontrol(mobil_menu.cikis_onayi.visible, "Ana menü geri hareketi çıkış onayını açmalı.")
	mobil_menu.geri_istegini_isle()
	kontrol(not mobil_menu.cikis_onayi.visible, "İkinci geri hareketi çıkış onayını kapatmalı.")
	for menu_butonu in mobil_menu.get_node("Panel").find_children("*", "Button", true, false):
		if menu_butonu.visible:
			kontrol(menu_butonu.size.y >= 96.0, "%s mobil dokunma hedefi en az 96 tuval birimi olmalı." % menu_butonu.name)
	mobil_menu.queue_free()
	await process_frame

	# ui_cancel bir sahnede yalnız bir kez işlenmeli.
	var geri_testi := GeriSayacSahnesi.new()
	root.add_child(geri_testi)
	var geri_olayi := InputEventAction.new()
	geri_olayi.action = "ui_cancel"
	geri_olayi.pressed = true
	geri_testi._unhandled_input(geri_olayi)
	kontrol(geri_testi.geri_sayisi == 1, "ui_cancel aynı sahnede yalnız bir geri işlemi üretmeli.")
	geri_testi.queue_free()
	await process_frame

	# Yeni ayar biçimi iki kanalı bağımsız ve kalıcı saklamalı.
	var ayarlar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	ayarlar.efekt_ayarini_kaydet(false)
	ayarlar.muzik_ayarini_kaydet(true)
	var yeniden_yuklenen_ayarlar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(not yeniden_yuklenen_ayarlar.efektler_acik and yeniden_yuklenen_ayarlar.muzik_acik, "Efekt kapalı/müzik açık tercihi yeniden başlatmada korunmalı.")
	yeniden_yuklenen_ayarlar.efekt_ayarini_kaydet(true)
	yeniden_yuklenen_ayarlar.muzik_ayarini_kaydet(false)
	var ikinci_yukleme := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(ikinci_yukleme.efektler_acik and not ikinci_yukleme.muzik_acik, "Efekt açık/müzik kapalı tercihi yeniden başlatmada korunmalı.")
	var eski_ayar_dosyasi := ConfigFile.new()
	eski_ayar_dosyasi.set_value("ses", "acik", false)
	eski_ayar_dosyasi.set_value("ses", "muzik", true)
	eski_ayar_dosyasi.save(TEST_ESKI_AYAR_YOLU)
	var tasinan_eski_ayar := AyarYoneticisi.new(TEST_ESKI_AYAR_YOLU)
	kontrol(not tasinan_eski_ayar.efektler_acik and not tasinan_eski_ayar.muzik_acik, "Eski ana sessiz ayarı geçişte uygulamayı sessiz tutmalı.")

	var ses_yoneticisi := root.get_node_or_null("SesYonetici") as SesYoneticisi
	kontrol(ses_yoneticisi != null, "Ses yöneticisi autoload olarak bulunmalı.")
	if ses_yoneticisi:
		kontrol(get_nodes_in_group("ses_yoneticisi").size() == 1, "Çalışan ağaçta yalnızca bir ses yöneticisi bulunmalı.")
		var onceki_efekt_tercihi: bool = ses_yoneticisi.ayar_yoneticisi.efektler_acik
		var onceki_muzik_tercihi: bool = ses_yoneticisi.ayar_yoneticisi.muzik_acik
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = false
		ses_yoneticisi.ayar_yoneticisi.muzik_acik = true
		ses_yoneticisi.ayarları_uygula()
		ses_yoneticisi.efekt_cal("dondur")
		kontrol(ses_yoneticisi.muzik_oynatici.playing and not ses_yoneticisi.oynatici.playing, "Müzik açık/efekt kapalı kombinasyonu bağımsız çalışmalı.")
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = true
		ses_yoneticisi.ayar_yoneticisi.muzik_acik = false
		ses_yoneticisi.ayarları_uygula()
		ses_yoneticisi.efekt_cal("dondur")
		kontrol(not ses_yoneticisi.muzik_oynatici.playing and ses_yoneticisi.oynatici.playing, "Müzik kapalı/efekt açık kombinasyonu bağımsız çalışmalı.")
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = onceki_efekt_tercihi
		ses_yoneticisi.ayar_yoneticisi.muzik_acik = onceki_muzik_tercihi
		ses_yoneticisi.ayarları_uygula()

	kontrol(ResourceLoader.exists("res://icon_foreground.svg") and ResourceLoader.exists("res://icon_background.svg"), "Adaptive ikon foreground ve background kaynakları bulunmalı.")

	DirAccess.remove_absolute(TEST_KAYIT_YOLU)
	DirAccess.remove_absolute(TEST_AYAR_YOLU)
	DirAccess.remove_absolute(TEST_ESKI_AYAR_YOLU)
	DirAccess.remove_absolute(TEST_SKOR_YOLU)
	if basarisizlik_sayisi == 0:
		print("Tüm Blok Yık kontrolleri başarılı.")
	quit(basarisizlik_sayisi)
