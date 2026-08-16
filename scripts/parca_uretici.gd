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

func _init(yeni_parca_havuzu: Array = PARCA_HAVUZU) -> void:
	parca_havuzu = yeni_parca_havuzu

func yeni_parca() -> TetrisParcasi:
	var secim: Dictionary = parca_havuzu[randi_range(0, parca_havuzu.size() - 1)]
	return TetrisParcasi.new(secim.kalip, secim.renk)
