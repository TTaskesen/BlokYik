class_name LevelYoneticisi
extends RefCounted

# Her ana Level'ın ızgarası ve kullanacağı parça indeksleri burada tanımlıdır.
# Parça indeksleri ParcaUretici.PARCA_HAVUZU sırasını kullanır.
const LEVEL_AYARLARI := [
	{"ad": "Klasik Başlangıç", "genislik": 10, "yukseklik": 20, "parca_indeksleri": [0, 1, 2, 3, 4, 5, 6], "arka_plan": Color("0a0d17"), "panel": Color("141b2d"), "tahta": Color("202535"), "izgara": Color("4d566d"), "vurgu": Color("f43f5e")},
	{"ad": "Artı Meydanı", "genislik": 10, "yukseklik": 20, "parca_indeksleri": [2, 3, 4, 5, 6, 7], "arka_plan": Color("071b22"), "panel": Color("0d2a35"), "tahta": Color("163844"), "izgara": Color("4f7180"), "vurgu": Color("22d3a7")},
	{"ad": "Dar Geçit", "genislik": 9, "yukseklik": 20, "parca_indeksleri": [0, 1, 2, 4, 5, 6, 7, 8], "arka_plan": Color("151025"), "panel": Color("251a3c"), "tahta": Color("302548"), "izgara": Color("6e5b88"), "vurgu": Color("a78bfa")},
	{"ad": "Usta Modu", "genislik": 8, "yukseklik": 20, "parca_indeksleri": [0, 1, 4, 5, 6, 7, 8], "arka_plan": Color("211607"), "panel": Color("35240d"), "tahta": Color("453117"), "izgara": Color("806944"), "vurgu": Color("fbbf24")},
	{"ad": "Final", "genislik": 8, "yukseklik": 18, "parca_indeksleri": [0, 1, 4, 5, 6, 7, 8], "arka_plan": Color("220b13"), "panel": Color("39121f"), "tahta": Color("481b29"), "izgara": Color("875064"), "vurgu": Color("fb7185")},
]

func level_ayari_al(level_numarasi: int) -> Dictionary:
	var ayar: Dictionary = LEVEL_AYARLARI[clampi(level_numarasi - 1, 0, LEVEL_AYARLARI.size() - 1)].duplicate(true)
	var parca_havuzu: Array = []
	for indeks in ayar.parca_indeksleri:
		parca_havuzu.append(ParcaUretici.PARCA_HAVUZU[indeks])
	ayar.parca_havuzu = parca_havuzu
	return ayar

func level_adi_al(level_numarasi: int) -> String:
	return str(LEVEL_AYARLARI[clampi(level_numarasi - 1, 0, LEVEL_AYARLARI.size() - 1)].ad)
