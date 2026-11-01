class_name YikimBulmacaYoneticisi
extends RefCounted

const GENISLIK := 10
const YUKSEKLIK := 12
const BULMACA_SAYISI := 15
const HAMLE_SAYISI := 3
const HEDEF_RENGI := Color("e6a23c")
const KAYIT_YOLU := "user://yikim_bulmaca_ilerleme.cfg"
const BULMACA_ADLARI := [
	"İlk Çatlak", "Dar Hat", "Yan Destek", "Çift Köşe", "Kayan İz",
	"Kırık Basamak", "Çapraz Mühür", "Sıkışık Alan", "Çift Kanca", "Usta Darbesi",
	"Altıgen İz", "Denge Noktası", "Son Savunma", "Kilitli Hat", "Son Yıkım"
]
# Her bulmaca, hedef boşluklarına tam oturan farklı bir parça gerektirir.
const COZUM_PARCALARI := [3, 2, 6, 0, 1, 4, 5, 7, 8, 3, 2, 6, 0, 1, 4]

var kayit_yolu: String
var bulmaca_indeksi := 0
var en_ileri_bulmaca := 0
var kalan_hamle := HAMLE_SAYISI
var tahta := OyunTahtasi.new(GENISLIK, YUKSEKLIK)
var kullanilabilir_parcalar: Array[int] = []
var cozum_parcasi := -1
var bulmaca_tamamlandi := false
var bolum_tamamlandi := false

func _init(yeni_kayit_yolu: String = KAYIT_YOLU) -> void:
	kayit_yolu = yeni_kayit_yolu
	en_ileri_bulmaca = _ilerlemeyi_oku()
	bulmaca_indeksi = mini(en_ileri_bulmaca, BULMACA_SAYISI - 1)
	bulmacayi_yukle(bulmaca_indeksi)
	if en_ileri_bulmaca >= BULMACA_SAYISI:
		bulmaca_tamamlandi = true
		bolum_tamamlandi = true
		tahta.kilitli_hucreler.clear()

func bulmacayi_yukle(indeks: int) -> void:
	bulmaca_indeksi = clampi(indeks, 0, BULMACA_SAYISI - 1)
	cozum_parcasi = COZUM_PARCALARI[bulmaca_indeksi]
	kalan_hamle = HAMLE_SAYISI
	bulmaca_tamamlandi = false
	bolum_tamamlandi = false
	tahta = OyunTahtasi.new(GENISLIK, YUKSEKLIK)
	kullanilabilir_parcalar = _parca_secimlerini_al(bulmaca_indeksi)
	var ayak_izi := _parcanin_alt_satirini_al(cozum_parcasi, 0)
	var sol := int((GENISLIK - 4) / 2)
	for x in GENISLIK:
		if x not in ayak_izi.map(func(kolon: int) -> int: return kolon + sol):
			tahta.kilitli_hucreler[Vector2i(x, YUKSEKLIK - 1)] = HEDEF_RENGI

func bulmaca_adi() -> String:
	return str(BULMACA_ADLARI[bulmaca_indeksi])

func secilebilir_mi(parca_indeksi: int) -> bool:
	return not bulmaca_tamamlandi and not bolum_tamamlandi and kalan_hamle > 0 and parca_indeksi in kullanilabilir_parcalar

func parca_al(parca_indeksi: int) -> BlokParcasi:
	if parca_indeksi < 0 or parca_indeksi >= ParcaUretici.PARCA_HAVUZU.size():
		return null
	var secim: Dictionary = ParcaUretici.PARCA_HAVUZU[parca_indeksi]
	return BlokParcasi.new(secim.kalip, secim.renk)

func yerlestirme_gecerli_mi(parca_indeksi: int, konum: Vector2i, donus: int) -> bool:
	if not secilebilir_mi(parca_indeksi):
		return false
	var parca := parca_al(parca_indeksi)
	parca.konum = konum
	parca.donus = posmod(donus, parca.kalip.size())
	return tahta.gecerli_mi(parca) and not parca.hucreler().is_empty() and _tahtada_kaliyor_mu(parca)

func hamleyi_yap(parca_indeksi: int, konum: Vector2i, donus: int) -> Dictionary:
	var sonuc := {"gecerli": false, "satir_silindi": false, "bulmaca_tamamlandi": false, "bolum_tamamlandi": false, "kalan_hamle": kalan_hamle}
	if not yerlestirme_gecerli_mi(parca_indeksi, konum, donus):
		return sonuc
	var parca := parca_al(parca_indeksi)
	parca.konum = konum
	parca.donus = posmod(donus, parca.kalip.size())
	tahta.parcayi_kilitle(parca)
	kullanilabilir_parcalar.erase(parca_indeksi)
	kalan_hamle -= 1
	var dolu_satirlar := tahta.dolu_satirlari_bul()
	if not dolu_satirlar.is_empty():
		var hedef_silindi := false
		for hucre in tahta.kilitli_hucreler:
			if hucre.y in dolu_satirlar and tahta.kilitli_hucreler[hucre] == HEDEF_RENGI:
				hedef_silindi = true
				break
		tahta.satirlari_sil(dolu_satirlar)
		sonuc.satir_silindi = true
		if hedef_silindi:
			bulmaca_tamamlandi = true
			en_ileri_bulmaca = maxi(en_ileri_bulmaca, bulmaca_indeksi + 1)
			_ilerlemeyi_kaydet()
			if en_ileri_bulmaca >= BULMACA_SAYISI:
				bolum_tamamlandi = true
	sonuc.gecerli = true
	sonuc.bulmaca_tamamlandi = bulmaca_tamamlandi
	sonuc.bolum_tamamlandi = bolum_tamamlandi
	sonuc.kalan_hamle = kalan_hamle
	return sonuc

func sonraki_bulmaca() -> bool:
	if not bulmaca_tamamlandi or bolum_tamamlandi:
		return false
	bulmacayi_yukle(mini(bulmaca_indeksi + 1, BULMACA_SAYISI - 1))
	return true

func tekrar_dene() -> void:
	bulmacayi_yukle(bulmaca_indeksi)

func kampanyayi_sifirla() -> void:
	en_ileri_bulmaca = 0
	_ilerlemeyi_kaydet()
	bulmacayi_yukle(0)

func hedef_sayisi() -> int:
	var toplam := 0
	for renk in tahta.kilitli_hucreler.values():
		if renk == HEDEF_RENGI:
			toplam += 1
	return toplam

func parca_hedef_satirini_tamamlayabilir_mi(parca_indeksi: int, donus: int) -> bool:
	return _parcanin_alt_satirini_al(parca_indeksi, posmod(donus, ParcaUretici.PARCA_HAVUZU[parca_indeksi].kalip.size())) == _parcanin_alt_satirini_al(cozum_parcasi, 0)

func cozum_konumu_al(indeks: int = -1) -> Vector2i:
	var parca_no := cozum_parcasi if indeks < 0 else indeks
	var sol := int((GENISLIK - 4) / 2)
	return Vector2i(sol, YUKSEKLIK - 1 - _parcanin_alt_satir_indeksi(parca_no, 0))

func cozum_donusu() -> int:
	return 0

func _parca_secimlerini_al(indeks: int) -> Array[int]:
	var dogru: int = COZUM_PARCALARI[indeks]
	var hedef_ayak_izi := _parcanin_alt_satirini_al(dogru, 0)
	var secimler: Array[int] = [dogru]
	for uzaklik in range(1, ParcaUretici.PARCA_HAVUZU.size()):
		var aday: int = (dogru + uzaklik + indeks % 2) % ParcaUretici.PARCA_HAVUZU.size()
		if aday == dogru:
			continue
		var donusler: Array = ParcaUretici.PARCA_HAVUZU[aday].kalip
		var ayni_hedefi_tamamlayabilir := false
		for donus in donusler.size():
			if parca_hedef_satirini_tamamlayabilir_mi(aday, donus):
				ayni_hedefi_tamamlayabilir = true
				break
		if not ayni_hedefi_tamamlayabilir and aday not in secimler:
			secimler.append(aday)
		if secimler.size() == 3:
			break
	return secimler

func _parcanin_alt_satir_indeksi(parca_indeksi: int, donus: int) -> int:
	var satirlar: Array = ParcaUretici.PARCA_HAVUZU[parca_indeksi].kalip[donus]
	for y in range(satirlar.size() - 1, -1, -1):
		if "0" in satirlar[y]:
			return y
	return 0

func _parcanin_alt_satirini_al(parca_indeksi: int, donus: int) -> Array[int]:
	var satirlar: Array = ParcaUretici.PARCA_HAVUZU[parca_indeksi].kalip[donus]
	var alt_y := _parcanin_alt_satir_indeksi(parca_indeksi, donus)
	var sonuc: Array[int] = []
	for x in satirlar[alt_y].length():
		if satirlar[alt_y][x] == "0":
			sonuc.append(x)
	return sonuc

func _tahtada_kaliyor_mu(parca: BlokParcasi) -> bool:
	for hucre in parca.hucreler():
		if hucre.y < 0 or hucre.y >= YUKSEKLIK:
			return false
	return true

func _ilerlemeyi_oku() -> int:
	var ayarlar := ConfigFile.new()
	if ayarlar.load(kayit_yolu) != OK:
		return 0
	return clampi(int(ayarlar.get_value("ilerleme", "tamamlanan", 0)), 0, BULMACA_SAYISI)

func _ilerlemeyi_kaydet() -> void:
	var ayarlar := ConfigFile.new()
	ayarlar.set_value("ilerleme", "tamamlanan", en_ileri_bulmaca)
	ayarlar.save(kayit_yolu)
