class_name LevelYoneticisi
extends RefCounted

const PARCA_URETICI = preload("res://scripts/parca_uretici.gd")

# Her ana Level'ın ızgarası ve kullanacağı parça indeksleri burada tanımlıdır.
# Parça indeksleri ParcaUretici.PARCA_HAVUZU sırasını kullanır.
const LEVEL_AYARLARI := [
	{"ad": "Klasik Başlangıç", "genislik": 10, "yukseklik": 20, "parca_indeksleri": [0, 1, 2, 3, 4, 5, 6]},
	{"ad": "Artı Meydanı", "genislik": 10, "yukseklik": 20, "parca_indeksleri": [2, 3, 4, 5, 6, 7]},
	{"ad": "Dar Geçit", "genislik": 9, "yukseklik": 20, "parca_indeksleri": [0, 1, 2, 4, 5, 6, 7, 8]},
	{"ad": "Usta Modu", "genislik": 8, "yukseklik": 20, "parca_indeksleri": [0, 1, 4, 5, 6, 7, 8]},
	{"ad": "Final", "genislik": 8, "yukseklik": 18, "parca_indeksleri": [0, 1, 4, 5, 6, 7, 8]},
]

func level_ayari_al(level_numarasi: int) -> Dictionary:
	var ayar: Dictionary = LEVEL_AYARLARI[clampi(level_numarasi - 1, 0, LEVEL_AYARLARI.size() - 1)].duplicate(true)
	var parca_havuzu: Array = []
	for indeks in ayar.parca_indeksleri:
		parca_havuzu.append(PARCA_URETICI.PARCA_HAVUZU[indeks])
	ayar.parca_havuzu = parca_havuzu
	return ayar
