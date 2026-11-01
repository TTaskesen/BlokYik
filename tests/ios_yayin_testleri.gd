extends RefCounted

const MENU := preload("res://scenes/AnaMenu.tscn")
const OYUN := preload("res://scenes/BlokYikOyun.tscn")
const HAKKINDA := preload("res://scenes/Hakkinda.tscn")
const KAYIT := "user://blok_yik_test_ios_yasam_dongusu.save"
const SKOR := "user://blok_yik_test_ios_yuksek_skor.save"

func calistir(agac: SceneTree, dogrula: Callable) -> void:
	var ses := agac.root.get_node("SesYonetici") as SesYoneticisi
	var asil_platform := ses.platform_adi
	var asil_sessiz_zorla := ses.sessiz_surucude_calismayi_zorla
	ses.sessiz_surucude_calismayi_zorla = true
	AtomikDosyaYardimcisi.tum_artiklari_temizle(KAYIT)
	AtomikDosyaYardimcisi.tum_artiklari_temizle(SKOR)
	var efekt_id := ses.oynatici.get_instance_id()
	var muzik_id := ses.muzik_oynatici.get_instance_id()

	for platform in ["iOS", "Android", "macOS"]:
		var menu = MENU.instantiate()
		menu.platform_adi = platform
		menu.kayit_yolu = KAYIT
		var cikis_sayisi := [0]
		menu.cikis_istegi_isleyicisi = func(): cikis_sayisi[0] += 1
		agac.root.add_child(menu)
		await agac.process_frame
		dogrula.call(menu.cikis_butonu.visible == (platform != "iOS"), "%s çıkış görünürlüğü platforma uygun olmalı." % platform)
		menu._on_cikis_pressed()
		if platform == "iOS":
			menu.geri_istegini_isle()
			menu.cikis_modalini_goster(true)
			(menu.get_node("CikisOnayi/Icerik/Evet") as Button).pressed.emit()
			dogrula.call(cikis_sayisi[0] == 0 and not menu.cikis_onayi.visible, "iOS gizli çıkışa doğrudan erişim bile kapatma isteği üretmemeli.")
			ses.platform_adi = "iOS"
			ses.uygulamadan_cik()
			ses.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
			dogrula.call(not ses._kapanis_basladi and is_instance_valid(ses.oynatici) and is_instance_valid(ses.muzik_oynatici), "iOS quit girişimleri ses oynatıcılarını serbest bırakmamalı.")
		elif platform == "Android":
			dogrula.call(menu.cikis_onayi.visible and cikis_sayisi[0] == 0, "Android çıkışı önce mevcut onay modalını açmalı.")
			(menu.get_node("CikisOnayi/Icerik/Evet") as Button).pressed.emit()
			dogrula.call(cikis_sayisi[0] == 1, "Android Evet yalnız bir çıkış isteği üretmeli.")
		else:
			dogrula.call(cikis_sayisi[0] == 1 and not menu.cikis_onayi.visible, "Masaüstü mevcut doğrudan çıkış davranışını korumalı.")
		menu.queue_free()
		await agac.process_frame

	for platform in ["iOS", "Android"]:
		ses.platform_adi = platform
		var menu = MENU.instantiate()
		menu.platform_adi = platform
		menu.kayit_yolu = KAYIT
		agac.root.add_child(menu)
		await agac.process_frame
		ses.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		ses.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		dogrula.call(not FileAccess.file_exists(KAYIT), "%s menüde arka plana geçiş gereksiz oyun kaydı oluşturmamalı." % platform)
		menu.queue_free()
		await agac.process_frame

		var oyun = OYUN.instantiate()
		oyun.platform_adi = platform
		oyun.kayit_yolu = KAYIT
		oyun.yuksek_skor_kayit_yolu = SKOR
		agac.root.add_child(oyun)
		oyun.set_process(false)
		await agac.process_frame
		dogrula.call(oyun.get_node("Arayuz/Birak").text == "Bırak" and "Boşluk" not in oyun.durum_etiketi.text, "%s dokunmatik metni klavye ifadesi taşımamalı." % platform)
		oyun.platform_adi = "macOS"
		oyun.arayuzu_guncelle()
		dogrula.call(oyun.get_node("Arayuz/Birak").text == "Bırak (Boşluk)" and "W:" in oyun.durum_etiketi.text, "Masaüstü klavye yönlendirmesi korunmalı.")
		oyun.platform_adi = platform
		oyun.tahta = OyunTahtasi.new(10, 20)
		oyun.skor_yoneticisi.skor = 123
		oyun.aktif_parca = BlokParcasi.new([["0"]], Color.GREEN)
		oyun.aktif_parca.konum = Vector2i(4, 8)
		oyun.sonraki_parca = BlokParcasi.new([["00"]], Color.YELLOW)
		ses.notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
		var kayit := oyun.kayit_yoneticisi.yukle() as Dictionary
		dogrula.call(oyun.oyun_duraklatildi and oyun.duraklat_menu.visible and not oyun.oyuncu_girisi_kabul_ediliyor_mu(), "%s odak kaybı aktif oyunu duraklatmalı." % platform)
		dogrula.call(not kayit.is_empty() and kayit.skor == 123 and kayit.aktif.x == 4 and kayit.aktif.y == 8 and kayit.sonraki.kalip == [["00"]], "%s arka plan kaydı skor/parça/sonraki parçayı korumalı." % platform)
		dogrula.call(not FileAccess.file_exists(KAYIT + ".tmp"), "Arka plan atomik kaydı geçici dosya bırakmamalı.")
		ses.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		ses.notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
		dogrula.call(ses.uygulama_arka_planda, "Focus In, henüz Resumed gelmeden askıya alınmış uygulamayı açmamalı.")
		oyun.duraklatmayi_degistir()
		dogrula.call(oyun.oyun_duraklatildi, "Arka plandayken yanlışlıkla Devam Et oyunu başlatmamalı.")
		ses.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		dogrula.call(not ses.uygulama_arka_planda and oyun.oyun_duraklatildi and ses.muzik_oynatici.stream_paused, "%s öne dönüş oyunu veya oyun müziğini kendiliğinden başlatmamalı." % platform)
		oyun._process(1.0)
		dogrula.call(oyun.aktif_parca.konum == Vector2i(4, 8), "Duraklatılmış oyunda zaman geçmesi parçayı düşürmemeli.")
		oyun.duraklatmayi_degistir()
		dogrula.call(not oyun.oyun_duraklatildi and not ses.muzik_oynatici.stream_paused, "Yalnız açık Devam Et işlemi oyun ve ses duraklamasını kaldırmalı.")

		# Gerçek kilitleme akışında, satır henüz silinmemişken arka plana geçilir.
		oyun.yeniden_baslat()
		satir_silme_durumunu_kur(oyun)
		oyun.parcayi_dusur()
		dogrula.call(oyun.satir_silme_animasyonu_aktif, "Satır tamamlanınca animasyon başlamalı.")
		ses.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		kayit = oyun.kayit_yoneticisi.yukle()
		dogrula.call(not oyun.satir_silme_animasyonu_aktif and oyun.oyun_duraklatildi and not kayit.is_empty(), "%s satır animasyonu arka planda tek seferde kararlı/kaydedilebilir sonuca bağlanmalı." % platform)
		dogrula.call(kayit.kilitli.is_empty() and kayit.silinen_satir == 1 and oyun.tahta.gecerli_mi(oyun.aktif_parca), "Arka plan kaydı silinmiş satırla çakışan eski aktif parçayı içermemeli.")
		var animasyon_sonrasi_skor: int = oyun.skor_yoneticisi.skor
		var animasyon_sonrasi_parca = oyun.aktif_parca
		await agac.create_timer(0.45).timeout
		dogrula.call(oyun.skor_yoneticisi.skor == animasyon_sonrasi_skor and oyun.aktif_parca == animasyon_sonrasi_parca and oyun.skor_yoneticisi.silinen_satir == 1, "Bekleyen eski zamanlayıcı ikinci kez puan/parça/satır üretmemeli.")
		ses.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		dogrula.call(oyun.oyun_duraklatildi, "Animasyon sonrası öne dönüş yine kullanıcı onayı beklemeli.")

		# Yeni sahnede atomik arka plan kaydı aynı tahta/ilerleme/parçayla okunur.
		oyun.queue_free()
		await agac.process_frame
		agac.set_meta("kayitli_oyun_yukle", true)
		var yuklenen = OYUN.instantiate()
		yuklenen.platform_adi = platform
		yuklenen.kayit_yolu = KAYIT
		yuklenen.yuksek_skor_kayit_yolu = SKOR
		agac.root.add_child(yuklenen)
		yuklenen.set_process(false)
		await agac.process_frame
		dogrula.call(yuklenen.skor_yoneticisi.skor == animasyon_sonrasi_skor and yuklenen.skor_yoneticisi.silinen_satir == 1 and yuklenen.tahta.kilitli_hucreler.is_empty(), "Arka plan kaydı yeni sahnede doğru skor ve tahtayı yüklemeli.")
		dogrula.call(yuklenen.aktif_parca.kalip == kayit.aktif.kalip and yuklenen.sonraki_parca.kalip == kayit.sonraki.kalip and yuklenen.skor_yoneticisi.ana_level == kayit.ana_level, "Yeniden yükleme bölüm, aktif ve sonraki parçayı korumalı.")

		# Yazma başarısızlığı, mevcut doğrulanmış kaydı bozmadan oyuncuya bildirilir.
		var onceki_kayit := FileAccess.get_file_as_string(KAYIT)
		DirAccess.make_dir_absolute(KAYIT + ".tmp")
		ses.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		dogrula.call(not yuklenen.kayit_uyarisi.is_empty() and "Kayıt yazılamadı" in yuklenen.durum_etiketi.text, "Başarısız arka plan kaydı duraklatılmış ekranda açıklanmalı.")
		dogrula.call(FileAccess.get_file_as_string(KAYIT) == onceki_kayit, "Arka plan yazımı başarısızsa önceki doğrulanmış kayıt korunmalı.")
		DirAccess.remove_absolute(KAYIT + ".tmp")
		ses.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		yuklenen.queue_free()
		await agac.process_frame
		AtomikDosyaYardimcisi.tum_artiklari_temizle(KAYIT)

	# Gerçek oyuncu oyunu yerine seviye eşiklerini kuran 15 geçişlik regresyon.
	var gecis_oyunu = OYUN.instantiate()
	gecis_oyunu.kayit_yolu = KAYIT
	gecis_oyunu.yuksek_skor_kayit_yolu = SKOR
	agac.root.add_child(gecis_oyunu)
	gecis_oyunu.set_process(false)
	await agac.process_frame
	for seviye in range(1, 16):
		dogrula.call(gecis_oyunu.skor_yoneticisi.genel_seviye() == seviye, "Simüle edilmiş ilerlemede %d. seviye doğru olmalı." % seviye)
		gecis_oyunu.skor_yoneticisi.asama_satirlari = SkorYoneticisi.ALT_SEVIYE_ICIN_SATIR - 1
		satir_silme_durumunu_kur(gecis_oyunu)
		gecis_oyunu.parcayi_dusur()
		ses.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		ses.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
		if seviye < 15:
			dogrula.call(gecis_oyunu.kayit_yoneticisi.kayit_var_mi() and gecis_oyunu.oyun_duraklatildi, "Seviye %d sonrası kararlı kayıt bulunmalı ve oyun duraklatılmış kalmalı." % seviye)
			gecis_oyunu.duraklatmayi_degistir()
		else:
			dogrula.call(not gecis_oyunu.oyun_aktif and gecis_oyunu.sonuc_basligi.text == "TEBRİKLER!" and not gecis_oyunu.kayit_yoneticisi.kayit_var_mi(), "Arka planda final geçişi tebrikler ekranını oluşturmalı ve devam kaydı bırakmamalı.")
			dogrula.call(not gecis_oyunu.duraklat_menu.visible and not gecis_oyunu.duraklatma_etiketi.visible and not gecis_oyunu.seviye_gecis_etiketi.visible, "Arka planda final duraklatma ve geçiş panelleriyle üst üste görünmemeli.")
	await agac.create_timer(0.45).timeout
	dogrula.call(gecis_oyunu.sonuc_basligi.text == "TEBRİKLER!", "Eski 15 animasyon zamanlayıcısı final ekranını değiştirmemeli.")
	gecis_oyunu.queue_free()
	await agac.process_frame

	# Gerçek sahne değiştirme sinyalleriyle Hakkında → Lisanslar → Hakkında.
	var hakkinda = HAKKINDA.instantiate()
	hakkinda.platform_adi = "iOS"
	agac.root.add_child(hakkinda)
	agac.current_scene = hakkinda
	await agac.process_frame
	ses.notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	ses.notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	dogrula.call(not FileAccess.file_exists(KAYIT), "Yardımcı sahnede yaşam döngüsü oyun kaydı oluşturmamalı.")
	hakkinda.lisanslar_butonu.pressed.emit()
	await agac.scene_changed
	var lisanslar = agac.current_scene
	dogrula.call(lisanslar.scene_file_path == "res://scenes/Lisanslar.tscn", "Lisans ekranına Hakkında düğmesinden uygulama içinde erişilmeli.")
	dogrula.call(Engine.get_license_text() in lisanslar.lisans_metni.text and "Permission is hereby granted" in lisanslar.lisans_metni.text, "Çevrimdışı ekran Godot'un eksiksiz özgün MIT metnini içermeli.")
	lisanslar.bilesenler_butonu.pressed.emit()
	for bilesen in Engine.get_copyright_info():
		dogrula.call(str(bilesen.name) in lisanslar.lisans_metni.text, "%s bileşen bildirimi çevrimdışı listelenmeli." % bilesen.name)
	for lisans in Engine.get_license_info().values():
		dogrula.call(str(lisans) in lisanslar.lisans_metni.text, "Üçüncü taraf lisans metni eksiksiz bulunmalı.")
	lisanslar.bilesenler_butonu.pressed.emit()
	dogrula.call(not lisanslar.bilesenler_gorunur, "Lisans ekranı kısa Godot görünümüne dönebilmeli.")
	(lisanslar.get_node("GuvenliAlan/IcerikKaydirici/Ortala/Panel/Geri") as Button).pressed.emit()
	await agac.scene_changed
	dogrula.call(agac.current_scene.scene_file_path == "res://scenes/Hakkinda.tscn", "Lisanslar Geri düğmesi Hakkında ekranına dönmeli.")
	dogrula.call(ses.oynatici.get_instance_id() == efekt_id and ses.muzik_oynatici.get_instance_id() == muzik_id and agac.get_nodes_in_group("ses_yoneticisi").size() == 1, "Sahne geçişleri tek ses yöneticisini ve aynı geçerli oynatıcıları korumalı.")
	var son_sahne := agac.current_scene
	agac.current_scene = null
	son_sahne.queue_free()
	await agac.process_frame
	ses.platform_adi = asil_platform
	ses.sessiz_surucude_calismayi_zorla = asil_sessiz_zorla
	AtomikDosyaYardimcisi.tum_artiklari_temizle(KAYIT)
	AtomikDosyaYardimcisi.tum_artiklari_temizle(SKOR)
	print("iOS/Android yaşam döngüsü, çıkış ve çevrimdışı lisans regresyonları tamamlandı.")

func satir_silme_durumunu_kur(oyun: Control) -> void:
	var tahta := OyunTahtasi.new(oyun.tahta.genislik, oyun.tahta.yukseklik)
	var alt_satir := tahta.yukseklik - 1
	for x in tahta.genislik:
		if x != 4:
			tahta.kilitli_hucreler[Vector2i(x, alt_satir)] = Color.WHITE
	oyun.tahta = tahta
	oyun.aktif_parca = BlokParcasi.new([["0"]], Color.GREEN)
	oyun.aktif_parca.konum = Vector2i(4, alt_satir)
	oyun.sonraki_parca = BlokParcasi.new([["00"]], Color.YELLOW)
