extends ResponsiveYardimciSahne

@onready var lisans_metni: RichTextLabel = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/LisansMetni
@onready var bilesenler_butonu: Button = $GuvenliAlan/IcerikKaydirici/Ortala/Panel/Bilesenler
var bilesenler_gorunur := false

func _ready() -> void:
	super._ready()
	$GuvenliAlan/IcerikKaydirici/Ortala/Panel/Geri.pressed.connect(geri_istegini_isle)
	bilesenler_butonu.pressed.connect(bilesenleri_degistir)
	lisans_metni.text = yerel_lisans_metni()

func yerel_lisans_metni(tum_bilesenler := false) -> String:
	# Metin doğrudan çalışan Godot motorunun paketinden gelir; ağ erişimi gerekmez.
	var bolumler := PackedStringArray(["Godot Engine — MIT Lisansı", Engine.get_license_text()])
	if tum_bilesenler:
		bolumler.append("ÜÇÜNCÜ TARAF BİLEŞENLERİ — TELİF BİLDİRİMLERİ")
		for bilesen in Engine.get_copyright_info():
			bolumler.append(str(bilesen.name))
			for parca in bilesen.parts:
				bolumler.append("Dosyalar: " + ", ".join(PackedStringArray(parca.files)))
				bolumler.append("\n".join(PackedStringArray(parca.copyright)))
				bolumler.append("Lisans: " + str(parca.license))
		var lisanslar := Engine.get_license_info()
		var adlar := lisanslar.keys()
		adlar.sort()
		for ad in adlar:
			bolumler.append(str(ad) + "\n" + str(lisanslar[ad]))
	return "\n\n".join(bolumler)

func bilesenleri_degistir() -> void:
	bilesenler_gorunur = not bilesenler_gorunur
	bilesenler_butonu.text = "Yalnız Godot Lisansı" if bilesenler_gorunur else "Üçüncü Taraf Lisansları"
	lisans_metni.text = yerel_lisans_metni(bilesenler_gorunur)
	icerik_kaydirici.scroll_vertical = 0
	call_deferred("_responsive_yerlesimi_guncelle")

func geri_istegini_isle() -> void:
	sahneye_gec("res://scenes/Hakkinda.tscn")
