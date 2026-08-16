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

func gecerli_mi(parca: TetrisParcasi) -> bool:
	for hucre in parca.hucreler():
		if not hucre_aktif_mi(hucre):
			return false
		if hucre.y >= 0 and kilitli_hucreler.has(hucre):
			return false
	return true

func parcayi_kilitle(parca: TetrisParcasi) -> void:
	for hucre in parca.hucreler():
		if hucre.y >= 0:
			kilitli_hucreler[hucre] = parca.renk

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
