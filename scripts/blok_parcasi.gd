class_name BlokParcasi
extends RefCounted

var kalip: Array
var renk: Color
var konum := Vector2i(3, 0)
var donus := 0

func _init(yeni_kalip: Array = [], yeni_renk: Color = Color.WHITE) -> void:
	kalip = yeni_kalip
	renk = yeni_renk

func hucreler() -> Array[Vector2i]:
	var sonuc: Array[Vector2i] = []
	var idx := ((donus % kalip.size()) + kalip.size()) % kalip.size()
	var aktif_kalip: Array = kalip[idx]
	for y in aktif_kalip.size():
		for x in aktif_kalip[y].length():
			if aktif_kalip[y][x] == "0":
				sonuc.append(konum + Vector2i(x, y))
	return sonuc

func dondur() -> void:
	donus += 1

func donusu_geri_al() -> void:
	donus -= 1
