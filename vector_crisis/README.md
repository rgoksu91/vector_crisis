# Vector Crisis: Arrow Puzzle

Vector Crisis, Flutter ve Flame ile geliştirilmiş portre yönelimli tam bir grid
puzzle uygulamasıdır. Oyuncu, önündeki yol açık olan okları board dışına
çıkararak level'ı temizler.

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
- Animasyonlu splash ve ana sayfa; yeni oyun, devam et ve level seçimi
- Kalıcı ilerleme, en iyi hamle, 1–3 yıldız ve kilit açma sistemi
- Move-efficiency bütçesi, combo, haptic feedback, hint, pause ve restart
- AdMob geçiş reklamı: Level 12'den sonra her dört level geçişinde
- AdMob ödüllü reklamı: başarısız denemede isteğe bağlı +3 hamle
- Google UMP onay akışı ve uygulama içi reklam gizlilik tercihleri
- Sprite gerektirmeyen Canvas çizimleri
- Level veri bütünlüğü, path kuralları, özel oklar ve solver/gameplay uyumu için
  otomatik testler

Level tasarım kaynağı `LEVEL_DESIGN.md`, uygulama kuralları
`IMPLEMENTATION_INSTRUCTIONS.md`, son katalog metrikleri ise `LEVEL_AUDIT.md`
dosyasındadır.

Yayın öncesi zorunlu AdMob, signing ve store ayarları `RELEASE_CHECKLIST.md`
dosyasında listelenmiştir.
