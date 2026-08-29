extends SceneTree

const TEST_KAYIT_YOLU := "user://blok_yik_test_oyun_kayit.save"
const OYUN_SAHNESI := preload("res://scenes/BlokYikOyun.tscn")
const MENU_SAHNESI := preload("res://scenes/AnaMenu.tscn")

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
	var tahta := OyunTahtasi.new(10, 20)
	tahta.kilitli_hucreler[Vector2i(2, 18)] = Color.CORNFLOWER_BLUE
	var skor := SkorYoneticisi.new()
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

	var ses_yoneticisi := root.get_node_or_null("SesYonetici") as SesYoneticisi
	kontrol(ses_yoneticisi != null, "Ses yöneticisi autoload olarak bulunmalı.")
	if ses_yoneticisi:
		kontrol(get_nodes_in_group("ses_yoneticisi").size() == 1, "Çalışan ağaçta yalnızca bir ses yöneticisi bulunmalı.")
		var onceki_ses_tercihi := ses_yoneticisi.ayar_yoneticisi.ses_acik
		ses_yoneticisi.muzik_oynatici.play()
		ses_yoneticisi.ayar_yoneticisi.ses_acik = false
		ses_yoneticisi.ayarları_uygula()
		kontrol(not ses_yoneticisi.muzik_oynatici.playing, "Sessize alma müziği durdurmalı.")
		ses_yoneticisi.ayar_yoneticisi.ses_acik = onceki_ses_tercihi
		ses_yoneticisi.ayarları_uygula()

	DirAccess.remove_absolute(TEST_KAYIT_YOLU)
	if basarisizlik_sayisi == 0:
		print("Tüm Blok Yık kontrolleri başarılı.")
	quit(basarisizlik_sayisi)
