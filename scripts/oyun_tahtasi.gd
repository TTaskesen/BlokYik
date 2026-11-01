class_name OyunTahtasi
extends RefCounted

var genislik := 10
var yukseklik := 20
var kilitli_hucreler: Dictionary = {}
var aktif_hucreler: Dictionary = {}

func _init(yeni_genislik := 10, yeni_yukseklik := 20, yeni_aktif_hucreler: Array = []) -> void:
	genislik = yeni_genislik
	yukseklik = yeni_yukseklik
	for hucre in yeni_aktif_hucreler:
		aktif_hucreler[hucre] = true

func hucre_aktif_mi(hucre: Vector2i) -> bool:
	if hucre.x < 0 or hucre.x >= genislik or hucre.y >= yukseklik:
		return false
	return aktif_hucreler.is_empty() or aktif_hucreler.has(hucre)

func ozel_izgara_mi() -> bool:
	return not aktif_hucreler.is_empty()

func gecerli_mi(parca: BlokParcasi) -> bool:
	for hucre in parca.hucreler():
		if not hucre_aktif_mi(hucre):
			return false
		if hucre.y >= 0 and kilitli_hucreler.has(hucre):
			return false
	return true

func parcayi_kilitle(parca: BlokParcasi) -> void:
	for hucre in parca.hucreler():
		if hucre.y >= 0:
			kilitli_hucreler[hucre] = parca.renk

func yikim_kapsulunu_patlat(parca: BlokParcasi) -> Dictionary:
	if parca == null or not parca.yikim_kapsulu:
		return {"temizlenen": 0, "etkilenen_sutunlar": []}
	# Kapsülün her hücresi 3×3 etki alanı üretir; bitişik alanlar birleşir.
	# Böylece 2×2 kapsül yere oturduğunda toplam etki alanı 4×4 olur.
	var yikim_alani: Dictionary = {}
	var etkilenen_sutunlar: Dictionary = {}
	for merkez in parca.hucreler():
		for y in range(merkez.y - 1, merkez.y + 2):
			for x in range(merkez.x - 1, merkez.x + 2):
				var hucre := Vector2i(x, y)
				if hucre_aktif_mi(hucre):
					yikim_alani[hucre] = true
					etkilenen_sutunlar[x] = true
	var temizlenen := 0
	for hucre in yikim_alani:
		if kilitli_hucreler.erase(hucre):
			temizlenen += 1
	var sutunlar: Array[int] = []
	for x in etkilenen_sutunlar:
		sutunlar.append(int(x))
	sutunlar.sort()
	return {"temizlenen": temizlenen, "etkilenen_sutunlar": sutunlar}

func etkilenen_sutunlarda_yercekimi_uygula(sutunlar: Array) -> int:
	var dusen_tas_sayisi := 0
	for sutun_degeri in sutunlar:
		var x := int(sutun_degeri)
		if x < 0 or x >= genislik:
			continue
		var taslar: Array[Dictionary] = []
		for y in range(yukseklik - 1, -1, -1):
			var hucre := Vector2i(x, y)
			if hucre_aktif_mi(hucre) and kilitli_hucreler.has(hucre):
				taslar.append({"y": y, "renk": kilitli_hucreler[hucre]})
		for y in yukseklik:
			var hucre := Vector2i(x, y)
			if hucre_aktif_mi(hucre):
				kilitli_hucreler.erase(hucre)
		for indeks in taslar.size():
			var tas: Dictionary = taslar[indeks]
			var yeni_y := yukseklik - 1 - indeks
			kilitli_hucreler[Vector2i(x, yeni_y)] = tas.renk
			if int(tas.y) != yeni_y:
				dusen_tas_sayisi += 1
	return dusen_tas_sayisi

func dolu_satirlari_bul() -> Array[int]:
	var dolu_satirlar: Array[int] = []
	for y in yukseklik:
		var dolu := true
		var satirda_aktif_hucre_var := false
		for x in genislik:
			var hucre := Vector2i(x, y)
			if not hucre_aktif_mi(hucre):
				continue
			satirda_aktif_hucre_var = true
			if not kilitli_hucreler.has(hucre):
				dolu = false
				break
		if satirda_aktif_hucre_var and dolu:
			dolu_satirlar.append(y)
	return dolu_satirlar

func satirlari_sil(dolu_satirlar: Array[int]) -> int:
	if dolu_satirlar.is_empty():
		return 0
	var yeni_hucreler: Dictionary = {}
	for hucre in kilitli_hucreler:
		if hucre.y not in dolu_satirlar:
			var asagi_kayma := 0
			for satir in dolu_satirlar:
				if satir > hucre.y:
					asagi_kayma += 1
			yeni_hucreler[hucre + Vector2i(0, asagi_kayma)] = kilitli_hucreler[hucre]
	kilitli_hucreler = yeni_hucreler
	return dolu_satirlar.size()

func dolu_satirlari_sil() -> int:
	return satirlari_sil(dolu_satirlari_bul())

func oyun_bitti_mi() -> bool:
	for hucre in kilitli_hucreler:
		if hucre.y < 1:
			return true
	return false
