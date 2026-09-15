# Arrow Chaos

Arrow Chaos, Flutter ve Flame ile geliştirilmiş portre yönelimli bir grid puzzle
MVP'sidir. Oyuncu, önündeki yol açık olan okları board dışına çıkararak level'ı
temizler.

## Oyun kuralları

- Normal ok, baktığı yönde aynı satır veya sütunda başka ok yoksa çıkar.
- Rotator ok, yolu açıksa çıkar; kapalıysa dokunulduğunda saat yönünde 90° döner.
- Frozen ok, ortogonal komşu hücrelerinden birindeki ok kaldırılınca çözülür.
- Bomb ok çıktığında başladığı hücrenin ortogonal komşularındaki okları kaldırır.
- Level 10'dan itibaren yanlış, blocked ve gereksiz Rotator dokunuşları da hamle
  bütçesini tüketir. Board, gösterilen limit dolmadan temizlenmelidir.

`lib/game/logic/board_rules.dart`, canlı oyun ve solver tarafından kullanılan ortak
geometri kurallarını içerir. `LevelSolver`, aynı kurallarla BFS uygulayarak level
çözümlerini doğrular.

## Çalıştırma

Güncel stable Flutter SDK ile:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d ios
```

Projede Android, iOS, macOS, web, Linux ve Windows için Flutter platform
iskeletleri bulunur. Oyun portre moduna sabitlenmiştir.

## İçerik

- 3x3 ile 6x6 arasında 100 kontrollü, arc tabanlı level
- Normal, rotator, frozen ve bomb oklar
- Move-efficiency bütçesi, combo, haptic feedback, hint, restart ve level geçişi
- Sprite gerektirmeyen Canvas çizimleri
- Level veri bütünlüğü, path kuralları, özel oklar ve solver/gameplay uyumu için
  otomatik testler

Level tasarım kaynağı `LEVEL_DESIGN.md`, uygulama kuralları
`IMPLEMENTATION_INSTRUCTIONS.md`, son katalog metrikleri ise `LEVEL_AUDIT.md`
dosyasındadır.
