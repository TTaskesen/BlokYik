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

func test_kayit_artiklarini_temizle() -> void:
	for yol in [TEST_KAYIT_YOLU, TEST_AYAR_YOLU, TEST_ESKI_AYAR_YOLU, TEST_SKOR_YOLU]:
		AtomikDosyaYardimcisi.tum_artiklari_temizle(yol)

func dosya_icerigini_oku(yol: String) -> String:
	var dosya := FileAccess.open(yol, FileAccess.READ)
	if dosya == null:
		return ""
	var icerik := dosya.get_as_text()
	dosya.close()
	return icerik

func ayar_test_dosyasi_yaz(yol: String, degerler: Dictionary) -> bool:
	var dosya := ConfigFile.new()
	for anahtar in degerler:
		dosya.set_value("ses", anahtar, degerler[anahtar])
	return dosya.save(yol) == OK

func testleri_calistir() -> void:
	var kayit_yoneticisi := OyunKayitYoneticisi.new(TEST_KAYIT_YOLU)
	test_kayit_artiklarini_temizle()
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
	kontrol(not FileAccess.file_exists(TEST_KAYIT_YOLU + ".tmp"), "Başarılı atomik kayıttan sonra geçici dosya kalmamalı.")
	# İkinci başarılı kayıt, önceki geçerli ana kaydı doğrulanmış yedek olarak saklar.
	kontrol(kayit_yoneticisi.kaydet(tahta, skor, aktif, sonraki, 0.25, ParcaUretici.new()), "İkinci atomik kayıt başarılı olmalı.")
	kontrol(FileAccess.file_exists(TEST_KAYIT_YOLU + ".bak"), "Önceki geçerli kayıt yedeklenmeli.")
	# Geçersiz yarım dosya, geçerli ana kaydın önüne geçmemeli.
	var yarim_dosya := FileAccess.open(TEST_KAYIT_YOLU + ".tmp", FileAccess.WRITE)
	yarim_dosya.store_string("yarım-json")
	yarim_dosya.close()
	kontrol(kayit_yoneticisi.yukle().get("skor") == 345, "Geçersiz geçici dosya geçerli ana kaydı bozmamalı.")
	# Ana kayıt bozulursa doğrulanmış yedek otomatik kullanılmalı ve ana dosya geri kurulmalı.
	var ana_dosya := FileAccess.open(TEST_KAYIT_YOLU, FileAccess.WRITE)
	ana_dosya.store_string("bozuk-ana")
	ana_dosya.close()
	var kurtarilan_kayit := kayit_yoneticisi.yukle()
	kontrol(kurtarilan_kayit.get("skor") == 345, "Bozuk ana kayıt geçerli yedekten kurtarılmalı.")
	kontrol(kayit_yoneticisi.kayit_var_mi(), "Yedekten kurtarılan ana kayıt yeniden geçerli olmalı.")
	# Geçici hedefe yazılamazsa önceki geçerli ana kayıt korunmalı.
	DirAccess.make_dir_absolute(TEST_KAYIT_YOLU + ".tmp")
	var onceki_icerik_dosyasi := FileAccess.open(TEST_KAYIT_YOLU, FileAccess.READ)
	var onceki_icerik := onceki_icerik_dosyasi.get_as_text()
	onceki_icerik_dosyasi.close()
	kontrol(not kayit_yoneticisi.kaydet(tahta, skor, aktif, sonraki, 0.25, ParcaUretici.new()), "Yazılamayan geçici hedef açık başarısızlık döndürmeli.")
	var korunan_icerik_dosyasi := FileAccess.open(TEST_KAYIT_YOLU, FileAccess.READ)
	kontrol(korunan_icerik_dosyasi.get_as_text() == onceki_icerik, "Kayıt yazımı başarısız olduğunda önceki ana kayıt korunmalı.")
	korunan_icerik_dosyasi.close()
	DirAccess.remove_absolute(TEST_KAYIT_YOLU + ".tmp")

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
	kontrol(oyun.guncel_level_adi == "Artı Meydanı" and "Artı Meydanı" in oyun.bolum_etiketi.text, "Kayıttan devam edildiğinde doğru bölüm adı gösterilmeli.")
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
	kontrol(oyun.get_node("Arayuz/BilgiPaneli/Kenar/Icerik").get_global_rect().encloses(oyun.bolum_etiketi.get_global_rect()), "Bölüm adı bilgi panelinden taşmamalı.")
	var level_renkleri := {}
	for level_no in range(1, LevelYoneticisi.LEVEL_AYARLARI.size() + 1):
		var level_ayari: Dictionary = oyun.level_yoneticisi.level_ayari_al(level_no)
		kontrol(str(level_ayari.ad) == oyun.level_yoneticisi.level_adi_al(level_no), "Bölüm %d doğru kullanıcı adını vermeli." % level_no)
		kontrol(not level_ayari.has("aktif_hucreler"), "Dekoratif tema bölüm %d oynanış ızgara maskesi eklememeli." % level_no)
		level_renkleri[level_ayari.arka_plan] = true
	kontrol(level_renkleri.size() == LevelYoneticisi.LEVEL_AYARLARI.size(), "Her ana bölüm ayırt edilebilir bir arka plan paletine sahip olmalı.")
	var tema_onceki_skor: int = oyun.skor_yoneticisi.skor
	var tema_onceki_tahta: OyunTahtasi = oyun.tahta
	var tema_onceki_aktif: BlokParcasi = oyun.aktif_parca
	var ucuncu_level_ayari: Dictionary = oyun.level_yoneticisi.level_ayari_al(3)
	oyun.level_kimligini_uygula(ucuncu_level_ayari)
	kontrol(oyun.guncel_level_adi == "Dar Geçit" and oyun.skor_yoneticisi.skor == tema_onceki_skor and oyun.tahta == tema_onceki_tahta and oyun.aktif_parca == tema_onceki_aktif, "Görsel tema değişimi puan, tahta veya aktif parçayı değiştirmemeli.")
	oyun.level_kimligini_uygula(oyun.level_yoneticisi.level_ayari_al(2))

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

	# Satır silme animasyonunda tüm oyuncu girişleri aynı kapıdan engellenmelidir.
	var animasyon_tahtasi := OyunTahtasi.new(10, 20)
	for x in 10:
		animasyon_tahtasi.kilitli_hucreler[Vector2i(x, 19)] = Color.WHITE
	oyun.tahta = animasyon_tahtasi
	oyun.aktif_parca = BlokParcasi.new([["0"]], Color.GREEN)
	oyun.aktif_parca.konum = Vector2i(4, 0)
	oyun.sonraki_parca = BlokParcasi.new([["0"]], Color.CYAN)
	var animasyon_onceki_konum: Vector2i = oyun.aktif_parca.konum
	var animasyon_onceki_skor: int = oyun.skor_yoneticisi.skor
	var animasyon_onceki_tahta: Dictionary = oyun.tahta.kilitli_hucreler.duplicate(true)
	var animasyon_sonraki_parca: BlokParcasi = oyun.sonraki_parca
	var animasyon_satirlari: Array[int] = [19]
	oyun.satir_silme_animasyonunu_oynat(animasyon_satirlari)
	oyun.oyuncu_komutunu_uygula("birak")
	oyun.dokunma_baslangici = Vector2.ZERO
	oyun.dokunmatik_komutu_uygula(Vector2(100, 0))
	kontrol(oyun.aktif_parca.konum == animasyon_onceki_konum, "Animasyon sırasında kilitli/aktif parça hareket etmemeli.")
	kontrol(oyun.skor_yoneticisi.skor == animasyon_onceki_skor, "Animasyon sırasında Bırak tek puan bile üretmemeli.")
	kontrol(oyun.tahta.kilitli_hucreler == animasyon_onceki_tahta, "Animasyon sırasında oyuncu girişi tahtayı değiştirmemeli.")
	await create_timer(0.45).timeout
	kontrol(oyun.aktif_parca == animasyon_sonraki_parca, "Animasyon bitince yeni aktif parçaya geçilmeli.")
	var yeni_parca_onceki_konum: Vector2i = oyun.aktif_parca.konum
	oyun.oyuncu_komutunu_uygula("sol")
	kontrol(oyun.aktif_parca.konum.x == yeni_parca_onceki_konum.x - 1, "Animasyon bitince yeni parçanın kontrolleri yeniden açılmalı.")

	# Ana bölüm değişiminde yeni tahta ve ilerleme hemen kalıcılaştırılmalıdır.
	oyun.skor_yoneticisi.ana_level = 1
	oyun.skor_yoneticisi.alt_seviye = SkorYoneticisi.ALT_SEVIYE_SAYISI
	oyun.skor_yoneticisi.asama_satirlari = SkorYoneticisi.ALT_SEVIYE_ICIN_SATIR - 1
	oyun.kilitlenmis_parcayi_isle(1)
	var bolum_gecisi_kaydi := kayit_yoneticisi.yukle()
	kontrol(bolum_gecisi_kaydi.get("ana_level") == 2, "Ana bölüm değişikliği tamamlanır tamamlanmaz kaydedilmeli.")
	kontrol(oyun.guncel_level_adi == "Artı Meydanı" and "Artı Meydanı" in oyun.seviye_gecis_etiketi.text, "Yeni ana bölüm geçişi doğru bölüm adını ve görsel kimliği göstermeli.")

	# Bitmiş oyun, uygulama kapansa bile devam edilebilir bir kayıt bırakmamalı.
	kayit_yoneticisi.kaydet(tahta, skor, aktif, sonraki, 0.25, ParcaUretici.new())
	oyun.oyunu_sonlandir(true)
	kontrol(not oyun.oyun_aktif and oyun.oyun_bitti_paneli.visible and oyun.sonuc_basligi.text == "TEBRİKLER!", "Final bölüm tamamlanınca oyun durmalı ve TEBRİKLER paneli görünmeli.")
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

	# Ana ve yedek aynı anda bozuksa ikisi de güvenli biçimde temizlenmelidir.
	var cift_bozuk_ana := FileAccess.open(TEST_KAYIT_YOLU, FileAccess.WRITE)
	cift_bozuk_ana.store_string("bozuk-ana")
	cift_bozuk_ana.close()
	var cift_bozuk_yedek := FileAccess.open(TEST_KAYIT_YOLU + ".bak", FileAccess.WRITE)
	cift_bozuk_yedek.store_string("bozuk-yedek")
	cift_bozuk_yedek.close()
	var cift_bozuk_sonuc := kayit_yoneticisi.kayit_durumu()
	kontrol(not cift_bozuk_sonuc.gecerli, "Ana ve yedek bozuksa kayıt oynanabilir sayılmamalı.")
	kontrol(not FileAccess.file_exists(TEST_KAYIT_YOLU) and not FileAccess.file_exists(TEST_KAYIT_YOLU + ".bak"), "Ana ve yedek bozuksa güvenli sıfırlama ikisini de temizlemeli.")

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

	# Mobil ana menü safe area içinde kalır; dar yükseklikte içerik kaydırılarak erişilebilir olur.
	var mobil_menu = MENU_SAHNESI.instantiate()
	mobil_menu.kayit_yolu = TEST_KAYIT_YOLU
	mobil_menu.mobil_arayuz_zorla = true
	root.add_child(mobil_menu)
	await process_frame
	kontrol(not mobil_menu.cikis_butonu.visible, "Android ana menüsünde Çıkış düğmesi görünmemeli.")
	mobil_menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for gorunum in [Vector2(360, 640), Vector2(720, 960), Vector2(480, 1000)]:
		mobil_menu.size = gorunum
		mobil_menu.ana_menu_yerlesimini_guncelle()
		await process_frame
		var kaydirici_dikdortgen: Rect2 = mobil_menu.icerik_kaydirici.get_global_rect()
		var mobil_menu_dikdortgen: Rect2 = mobil_menu.menu_paneli.get_global_rect()
		mobil_menu.cikis_modalini_goster(true)
		await process_frame
		var modal_dikdortgen: Rect2 = mobil_menu.cikis_onayi.get_global_rect()
		print("Ana menü responsive: ", gorunum, " kaydırıcı=", kaydirici_dikdortgen, " içerik=", mobil_menu_dikdortgen)
		print("Çıkış modalı safe area: ", gorunum, " güvenli=[P: (24, 24), S: ", gorunum - Vector2(48, 48), "] modal=", modal_dikdortgen)
		kontrol(kaydirici_dikdortgen.position.x >= 23.0 and kaydirici_dikdortgen.position.y >= 23.0, "Ana menü kaydırıcısı sol/üst güvenli alanı aşmamalı: %s" % gorunum)
		kontrol(kaydirici_dikdortgen.end.x <= gorunum.x - 23.0 and kaydirici_dikdortgen.end.y <= gorunum.y - 23.0, "Ana menü kaydırıcısı sağ/alt güvenli alanı aşmamalı: %s" % gorunum)
		kontrol(mobil_menu_dikdortgen.position.x >= 23.0 and mobil_menu_dikdortgen.end.x <= gorunum.x - 23.0, "Ana menü içeriği yatay güvenli alanda kalmalı: %s" % gorunum)
		kontrol(modal_dikdortgen.position.x >= 23.0 and modal_dikdortgen.position.y >= 23.0, "Çıkış modalı sol/üst safe area sınırında kalmalı: %s modal=%s" % [gorunum, modal_dikdortgen])
		kontrol(modal_dikdortgen.end.x <= gorunum.x - 23.0 and modal_dikdortgen.end.y <= gorunum.y - 23.0, "Çıkış modalı sağ/alt safe area sınırında kalmalı: %s modal=%s" % [gorunum, modal_dikdortgen])
		kontrol(mobil_menu.modal_engelleyici.visible and mobil_menu.modal_engelleyici.mouse_filter == Control.MOUSE_FILTER_STOP and mobil_menu.modal_engelleyici.z_index > mobil_menu.guvenli_alan.z_index and mobil_menu.modal_engelleyici.z_index < mobil_menu.cikis_onayi.z_index, "Modal engelleyici alttaki menü dokunuşlarını tüketmeli: %s" % gorunum)
		for modal_butonu in mobil_menu.cikis_onayi.find_children("*", "Button", true, false):
			kontrol(modal_butonu.size.y >= 96.0, "%s mobil modal dokunma hedefi en az 96 tuval birimi olmalı." % modal_butonu.name)
		mobil_menu.cikis_modalini_goster(false)
		for menu_butonu in mobil_menu.menu_paneli.find_children("*", "Button", true, false):
			if menu_butonu.visible:
				kontrol(menu_butonu.size.y >= 96.0, "%s mobil dokunma hedefi en az 96 tuval birimi olmalı." % menu_butonu.name)
		if mobil_menu_dikdortgen.end.y > kaydirici_dikdortgen.end.y:
			var dikey_cubuk: VScrollBar = mobil_menu.icerik_kaydirici.get_v_scroll_bar()
			kontrol(dikey_cubuk.max_value > dikey_cubuk.page, "Dar görünümde uzun ana menü dikey kaydırılabilir olmalı: %s" % gorunum)
			mobil_menu.icerik_kaydirici.scroll_vertical = roundi(dikey_cubuk.max_value)
			await process_frame
			var son_buton_dikdortgen: Rect2 = mobil_menu.menu_paneli.get_node("Hakkinda").get_global_rect()
			kontrol(son_buton_dikdortgen.position.y >= kaydirici_dikdortgen.position.y and son_buton_dikdortgen.end.y <= kaydirici_dikdortgen.end.y, "Kaydırınca son görünür menü düğmesine güvenli alan içinde erişilebilmeli: %s" % gorunum)
			mobil_menu.icerik_kaydirici.scroll_vertical = 0
	var vazgec_butonu: Button = mobil_menu.get_node("CikisOnayi/Icerik/Vazgec")
	mobil_menu.cikis_modalini_goster(true)
	vazgec_butonu.pressed.emit()
	kontrol(not mobil_menu.cikis_onayi.visible and not mobil_menu.modal_engelleyici.visible, "Vazgeç akışı modalı ve engelleyiciyi kapatmalı.")
	var yakalanan_cikis_istegi := [0]
	mobil_menu.cikis_istegi_isleyicisi = func(): yakalanan_cikis_istegi[0] += 1
	mobil_menu.cikis_modalini_goster(true)
	(mobil_menu.get_node("CikisOnayi/Icerik/Evet") as Button).pressed.emit()
	kontrol(yakalanan_cikis_istegi[0] == 1, "Çıkış onayı yalnız bir çıkış isteği üretmeli.")
	mobil_menu.cikis_modalini_goster(false)
	mobil_menu.geri_istegini_isle()
	kontrol(mobil_menu.cikis_onayi.visible, "Ana menü geri hareketi çıkış onayını açmalı.")
	mobil_menu.geri_istegini_isle()
	kontrol(not mobil_menu.cikis_onayi.visible, "İkinci geri hareketi çıkış onayını kapatmalı.")
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

	# Yeni ayar biçimi iki kanalı bağımsız ve atomik saklamalı.
	var ayarlar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	ayarlar.efektler_acik = false
	ayarlar.muzik_acik = true
	ayarlar.muzik_seviyesi = 0.25
	kontrol(ayarlar.ayarlari_kaydet(), "İlk atomik ayar kaydı başarılı olmalı.")
	var yeniden_yuklenen_ayarlar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(not yeniden_yuklenen_ayarlar.efektler_acik and yeniden_yuklenen_ayarlar.muzik_acik and is_equal_approx(yeniden_yuklenen_ayarlar.muzik_seviyesi, 0.25), "Efekt kapalı/müzik açık tercihi yeniden başlatmada korunmalı.")
	yeniden_yuklenen_ayarlar.efektler_acik = true
	yeniden_yuklenen_ayarlar.muzik_acik = false
	yeniden_yuklenen_ayarlar.muzik_seviyesi = 0.6
	kontrol(yeniden_yuklenen_ayarlar.ayarlari_kaydet(), "İkinci atomik ayar kaydı başarılı olmalı.")
	kontrol(FileAccess.file_exists(TEST_AYAR_YOLU + ".bak") and not FileAccess.file_exists(TEST_AYAR_YOLU + ".tmp"), "Ayar kaydı doğrulanmış yedek bırakmalı, geçici dosya bırakmamalı.")
	var ikinci_yukleme := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(ikinci_yukleme.efektler_acik and not ikinci_yukleme.muzik_acik, "Efekt açık/müzik kapalı tercihi yeniden başlatmada korunmalı.")
	var bozuk_ayar_ana := FileAccess.open(TEST_AYAR_YOLU, FileAccess.WRITE)
	bozuk_ayar_ana.store_string("bozuk-ayar")
	bozuk_ayar_ana.close()
	var yedekten_ayar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(not yedekten_ayar.efektler_acik and yedekten_ayar.muzik_acik and is_equal_approx(yedekten_ayar.muzik_seviyesi, 0.25), "Bozuk ana ayar doğrulanmış yedekten kurtarılmalı.")
	var ana_ayar_icerigi := dosya_icerigini_oku(TEST_AYAR_YOLU)
	DirAccess.make_dir_absolute(TEST_AYAR_YOLU + ".tmp")
	yedekten_ayar.muzik_seviyesi = 0.9
	kontrol(not yedekten_ayar.ayarlari_kaydet(), "ConfigFile geçici hedefe yazamazsa açık başarısızlık dönmeli.")
	kontrol(dosya_icerigini_oku(TEST_AYAR_YOLU) == ana_ayar_icerigi, "Ayar yazımı başarısız olduğunda önceki geçerli ana ayar korunmalı.")
	DirAccess.remove_absolute(TEST_AYAR_YOLU + ".tmp")

	# Yükleme sınırında sayısal değerler clamp edilir; bozuk türler varsayılana döner.
	for veri in [[-1.0, 0.0], [0.0, 0.0], [0.4, 0.4], [1.0, 1.0], [2.5, 1.0]]:
		AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_AYAR_YOLU)
		kontrol(ayar_test_dosyasi_yaz(TEST_AYAR_YOLU, {"efektler": true, "muzik": true, "muzik_seviye": veri[0]}), "Clamp test ayarı yazılabilmeli.")
		var sinirli_ayar := AyarYoneticisi.new(TEST_AYAR_YOLU)
		kontrol(is_equal_approx(sinirli_ayar.muzik_seviyesi, veri[1]), "Müzik seviyesi %s değeri %s olmalı." % veri)
	for gecersiz_seviye in ["yüksek", null, NAN, INF, -INF]:
		kontrol(is_equal_approx(AyarYoneticisi.guvenli_muzik_seviyesi(gecersiz_seviye), AyarYoneticisi.VARSAYILAN_MUZIK_SEVIYESI), "Geçersiz müzik seviyesi güvenli varsayılana dönmeli: %s" % [gecersiz_seviye])
	AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_AYAR_YOLU)
	kontrol(ayar_test_dosyasi_yaz(TEST_AYAR_YOLU, {"efektler": "false", "muzik": 1, "muzik_seviye": 0.2}), "Tür güvenliği test ayarı yazılabilmeli.")
	var bozuk_turlu_ayar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(bozuk_turlu_ayar.efektler_acik and bozuk_turlu_ayar.muzik_acik and is_equal_approx(bozuk_turlu_ayar.muzik_seviyesi, 0.7), "Boolean tür uyumsuzluğu sessizce dönüştürülmemeli.")
	AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_AYAR_YOLU)
	kontrol(ayar_test_dosyasi_yaz(TEST_AYAR_YOLU, {"efektler": false}), "Eksik anahtar test ayarı yazılabilmeli.")
	var eksik_anahtarli_ayar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(not eksik_anahtarli_ayar.efektler_acik and eksik_anahtarli_ayar.muzik_acik and is_equal_approx(eksik_anahtarli_ayar.muzik_seviyesi, 0.7), "Eksik ayar anahtarları güvenli varsayılanlarını kullanmalı.")
	AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_AYAR_YOLU)
	var cift_bozuk_ayar := FileAccess.open(TEST_AYAR_YOLU, FileAccess.WRITE)
	cift_bozuk_ayar.store_string("bozuk-ana")
	cift_bozuk_ayar.close()
	var cift_bozuk_ayar_yedek := FileAccess.open(TEST_AYAR_YOLU + ".bak", FileAccess.WRITE)
	cift_bozuk_ayar_yedek.store_string("bozuk-yedek")
	cift_bozuk_ayar_yedek.close()
	var varsayilan_ayar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(varsayilan_ayar.efektler_acik and varsayilan_ayar.muzik_acik and is_equal_approx(varsayilan_ayar.muzik_seviyesi, 0.7), "Ana ve yedek ayar bozuksa güvenli varsayılanlara dönülmeli.")
	AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_AYAR_YOLU)
	kontrol(ayar_test_dosyasi_yaz(TEST_AYAR_YOLU + ".tmp", {"efektler": false, "muzik": true, "muzik_seviye": 0.35}), "Yarım kalmış geçerli ayar dosyası hazırlanabilmeli.")
	var geciciden_kurtarilan_ayar := AyarYoneticisi.new(TEST_AYAR_YOLU)
	kontrol(not geciciden_kurtarilan_ayar.efektler_acik and geciciden_kurtarilan_ayar.muzik_acik and is_equal_approx(geciciden_kurtarilan_ayar.muzik_seviyesi, 0.35) and FileAccess.file_exists(TEST_AYAR_YOLU) and not FileAccess.file_exists(TEST_AYAR_YOLU + ".tmp"), "Geçerli geçici ayar başlangıçta atomik biçimde tamamlanmalı.")
	var eski_ayar_dosyasi := ConfigFile.new()
	eski_ayar_dosyasi.set_value("ses", "acik", false)
	eski_ayar_dosyasi.set_value("ses", "muzik", true)
	eski_ayar_dosyasi.save(TEST_ESKI_AYAR_YOLU)
	var tasinan_eski_ayar := AyarYoneticisi.new(TEST_ESKI_AYAR_YOLU)
	kontrol(not tasinan_eski_ayar.efektler_acik and not tasinan_eski_ayar.muzik_acik, "Eski ana sessiz ayarı geçişte uygulamayı sessiz tutmalı.")

	# Yüksek skor da doğrulanmış geçici dosya ve yedek üzerinden atomik saklanır.
	AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_SKOR_YOLU)
	var atomik_skor := SkorYoneticisi.new(TEST_SKOR_YOLU)
	atomik_skor.skor = 100
	kontrol(atomik_skor.yuksek_skoru_kaydet(), "İlk atomik yüksek skor yazımı başarılı olmalı.")
	atomik_skor.skor = 120
	kontrol(atomik_skor.yuksek_skoru_kaydet() and FileAccess.file_exists(TEST_SKOR_YOLU + ".bak"), "İkinci yüksek skor yazımı doğrulanmış yedek oluşturmalı.")
	atomik_skor.skor = 10
	kontrol(atomik_skor.yuksek_skoru_kaydet() and int(dosya_icerigini_oku(TEST_SKOR_YOLU)) == 120, "Düşük skor mevcut yüksek skoru düşürmemeli.")
	var yarim_skor := FileAccess.open(TEST_SKOR_YOLU + ".tmp", FileAccess.WRITE)
	yarim_skor.store_string("yarım")
	yarim_skor.close()
	kontrol(SkorYoneticisi.new(TEST_SKOR_YOLU).yuksek_skor == 120, "Geçersiz geçici skor geçerli ana skoru bozmamalı.")
	var bozuk_skor_ana := FileAccess.open(TEST_SKOR_YOLU, FileAccess.WRITE)
	bozuk_skor_ana.store_string("bozuk")
	bozuk_skor_ana.close()
	var kurtarilan_skor := SkorYoneticisi.new(TEST_SKOR_YOLU)
	kontrol(kurtarilan_skor.yuksek_skor == 120 and int(dosya_icerigini_oku(TEST_SKOR_YOLU)) == 120, "Bozuk yüksek skor ana dosyası yedekten kurtarılmalı.")
	var skor_ana_icerigi := dosya_icerigini_oku(TEST_SKOR_YOLU)
	DirAccess.make_dir_absolute(TEST_SKOR_YOLU + ".tmp")
	kurtarilan_skor.skor = 200
	kontrol(not kurtarilan_skor.yuksek_skoru_kaydet(), "Yüksek skor geçici hedefi yazılamazsa başarısızlık dönmeli.")
	kontrol(dosya_icerigini_oku(TEST_SKOR_YOLU) == skor_ana_icerigi, "Skor yazımı başarısız olduğunda önceki geçerli ana skor korunmalı.")
	DirAccess.remove_absolute(TEST_SKOR_YOLU + ".tmp")
	AtomikDosyaYardimcisi.tum_artiklari_temizle(TEST_SKOR_YOLU)
	var gecici_skor := FileAccess.open(TEST_SKOR_YOLU + ".tmp", FileAccess.WRITE)
	gecici_skor.store_string("175")
	gecici_skor.close()
	var geciciden_kurtarilan_skor := SkorYoneticisi.new(TEST_SKOR_YOLU)
	kontrol(geciciden_kurtarilan_skor.yuksek_skor == 175 and FileAccess.file_exists(TEST_SKOR_YOLU) and not FileAccess.file_exists(TEST_SKOR_YOLU + ".tmp"), "Geçerli geçici yüksek skor başlangıçta atomik biçimde tamamlanmalı.")

	var ses_yoneticisi := root.get_node_or_null("SesYonetici") as SesYoneticisi
	kontrol(ses_yoneticisi != null, "Ses yöneticisi autoload olarak bulunmalı.")
	if ses_yoneticisi:
		kontrol(get_nodes_in_group("ses_yoneticisi").size() == 1, "Çalışan ağaçta yalnızca bir ses yöneticisi bulunmalı.")
		ses_yoneticisi.sessiz_surucude_calismayi_zorla = true
		var onceki_efekt_tercihi: bool = ses_yoneticisi.ayar_yoneticisi.efektler_acik
		var onceki_muzik_tercihi: bool = ses_yoneticisi.ayar_yoneticisi.muzik_acik
		var onceki_muzik_seviyesi: float = ses_yoneticisi.ayar_yoneticisi.muzik_seviyesi
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = false
		ses_yoneticisi.ayar_yoneticisi.muzik_acik = true
		ses_yoneticisi.ayarları_uygula()
		ses_yoneticisi.muzik_oynatici.seek(0.2)
		var muzik_konumu := ses_yoneticisi.muzik_oynatici.get_playback_position()
		ses_yoneticisi.ayar_yoneticisi.muzik_seviyesi = 0.4
		ses_yoneticisi.ayarları_uygula()
		kontrol(ses_yoneticisi.muzik_oynatici.playing and ses_yoneticisi.muzik_oynatici.get_playback_position() >= muzik_konumu - 0.05, "Müzik seviyesi değişince çalma konumu başa dönmemeli.")
		ses_yoneticisi.efekt_cal("dondur")
		kontrol(ses_yoneticisi.muzik_oynatici.playing and not ses_yoneticisi.oynatici.playing, "Müzik açık/efekt kapalı kombinasyonu bağımsız çalışmalı.")
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = true
		ses_yoneticisi.ayarları_uygula()
		kontrol(ses_yoneticisi.muzik_oynatici.playing and ses_yoneticisi.muzik_oynatici.get_playback_position() >= muzik_konumu - 0.05, "Efekt tercihi değişince müzik başa dönmemeli.")
		ses_yoneticisi.efekt_cal("dondur")
		var ilk_efekt = ses_yoneticisi.yuklu_sesler.get("dondur")
		var onbellek_boyutu := ses_yoneticisi.yuklu_sesler.size()
		ses_yoneticisi.efekt_cal("dondur")
		kontrol(ses_yoneticisi.yuklu_sesler.size() == onbellek_boyutu and ses_yoneticisi.yuklu_sesler.get("dondur") == ilk_efekt, "Aynı efekt yalnız bir kez üretilip önbellekten kullanılmalı.")
		ses_yoneticisi.ayar_yoneticisi.muzik_seviyesi = 0.0
		ses_yoneticisi.ayarları_uygula()
		var sifir_onceki_konum := ses_yoneticisi.muzik_oynatici.get_playback_position()
		kontrol(is_zero_approx(ses_yoneticisi.muzik_oynatici.volume_linear), "Müzik seviyesi sıfır gerçek lineer sessizlik uygulamalı.")
		ses_yoneticisi.efekt_cal("satir")
		kontrol(ses_yoneticisi.oynatici.playing, "Müzik sıfırken efekt kanalı bağımsız çalışabilmeli.")
		ses_yoneticisi.ayar_yoneticisi.muzik_seviyesi = 0.02
		ses_yoneticisi.ayarları_uygula()
		kontrol(is_equal_approx(ses_yoneticisi.muzik_oynatici.volume_linear, 0.02) and ses_yoneticisi.muzik_oynatici.get_playback_position() >= sifir_onceki_konum - 0.05, "Müzik seviyesi sıfırdan yükselince çalma konumu korunarak ses geri gelmeli.")
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = true
		ses_yoneticisi.ayar_yoneticisi.muzik_acik = false
		ses_yoneticisi.ayarları_uygula()
		ses_yoneticisi.efekt_cal("dondur")
		kontrol(not ses_yoneticisi.muzik_oynatici.playing and ses_yoneticisi.oynatici.playing, "Müzik kapalı/efekt açık kombinasyonu bağımsız çalışmalı.")
		ses_yoneticisi.ayar_yoneticisi.efektler_acik = onceki_efekt_tercihi
		ses_yoneticisi.ayar_yoneticisi.muzik_acik = onceki_muzik_tercihi
		ses_yoneticisi.ayar_yoneticisi.muzik_seviyesi = onceki_muzik_seviyesi
		ses_yoneticisi.ayarları_uygula()

	kontrol(ResourceLoader.exists("res://icon_foreground.svg") and ResourceLoader.exists("res://icon_background.svg"), "Adaptive ikon foreground ve background kaynakları bulunmalı.")

	test_kayit_artiklarini_temizle()
	if ses_yoneticisi:
		ses_yoneticisi.kapanisa_hazirla()
		# AudioServer'ın durdurulan playback nesnelerini kapanıştan önce bırakmasına izin ver.
		await create_timer(0.1).timeout
		await process_frame
	if basarisizlik_sayisi == 0:
		print("Tüm Blok Yık kontrolleri başarılı.")
	quit(basarisizlik_sayisi)
