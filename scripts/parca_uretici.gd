class_name ParcaUretici
extends RefCounted

const PARCA_HAVUZU := [
	{"kalip": [[".00.", "00.."], ["0..", "00.", ".0."]], "renk": Color.LIME_GREEN},
	{"kalip": [["00..", ".00."], [".0.", "00.", "0.."]], "renk": Color.RED},
	{"kalip": [["0000"], ["0", "0", "0", "0"]], "renk": Color.CYAN},
	{"kalip": [["00", "00"]], "renk": Color.YELLOW},
	{"kalip": [["0..", "000"], [".00", ".0.", ".0."], ["000", "..0"], [".0.", ".0.", "00."]], "renk": Color.ORANGE},
	{"kalip": [["..0", "000"], [".0.", ".0.", ".00"], ["000", "0.."], ["00.", ".0.", ".0."]], "renk": Color.DODGER_BLUE},
	{"kalip": [[".0.", "000"], [".0.", ".00", ".0."], ["000", ".0."], [".0.", "00.", ".0."]], "renk": Color.MEDIUM_PURPLE},
	{"kalip": [[".0.", "000", ".0."]], "renk": Color.HOT_PINK},
	{"kalip": [["0.0", "000"], ["00", "0.", "00"], ["000", "0.0"], [".0", "00", ".0"]], "renk": Color.GOLD},
]

var parca_havuzu: Array
var yikim_kapsulu_ihtimali := 0.1

func _init(yeni_parca_havuzu: Array = PARCA_HAVUZU, yeni_yikim_kapsulu_ihtimali := 0.1) -> void:
	parca_havuzu = yeni_parca_havuzu
	yikim_kapsulu_ihtimali = clampf(yeni_yikim_kapsulu_ihtimali, 0.0, 1.0)

func yeni_parca() -> BlokParcasi:
	if randf() < yikim_kapsulu_ihtimali:
		return BlokParcasi.new([["00", "00"]], Color("ff633d"), true)
	var secim: Dictionary = parca_havuzu[randi_range(0, parca_havuzu.size() - 1)]
	return BlokParcasi.new(secim.kalip, secim.renk)
