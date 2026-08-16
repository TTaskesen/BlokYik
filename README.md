# Tetris Godot

Godot 4.7 ile geliştirilen mobil odaklı Tetris oyunu.

## Özellikler
- Ana Menü, Nasıl Oynanır, Yüksek Skorlar, Ayarlar, Hakkında
- Seviye sistemi ve skor takibi
- Dokunmatik kontroller ve ses/müzik yönetimi
- Android, Masaüstü ve Web desteği

## Proje Yapısı
- `scenes/` - Sahne dosyaları
- `scripts/` - GDScript kaynakları
- `audio/` - Ses efektleri ve müzik
- `icon.svg` - Uygulama ikonu

## Çalıştırma
Godot 4.7 ile `project.godot` açın ve `scenes/AnaMenu.tscn` çalıştırın.

## Otomatik Kontroller
Kayıt yükleme, ses yöneticisi ve yeniden başlatma sırasında satır animasyonunun güvenliği için headless kontrolleri çalıştırın:

```sh
godot --headless --path . --script res://tests/test_runner.gd
```

## Sürümleme
Üç parçalı semantik sürümleme: v0.0.1 → v0.0.2 → ... → v0.1.0 → v1.0.0
