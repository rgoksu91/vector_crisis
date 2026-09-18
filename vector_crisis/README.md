# Vector Crisis: Arrow Puzzle

Vector Crisis, Flutter ve Flame ile geliştirilmiş portre yönelimli tam bir grid
puzzle uygulamasıdır. Oyuncu, önündeki yol açık olan okları board dışına
çıkararak level'ı temizler.

## Oyun kuralları

- Normal ok, baktığı yönde aynı satır veya sütunda başka ok yoksa çıkar.
- Rotator ok, yolu açıksa çıkar; kapalıysa dokunulduğunda saat yönünde 90° döner.
- Frozen ok, ortogonal komşu hücrelerinden birindeki ok kaldırılınca çözülür.
- Bomb ok çıktığında başladığı hücrenin ortogonal komşularındaki okları kaldırır.
  Taş okları kıramaz.
- Taş (Stone) ok board'dan çıkmaz. Dokunulduğunda önündeki ilk engele (ok, duvar
  veya kenar) kadar kayar ve orada kalıcı duvara dönüşür. Önünde boş hücre yoksa
  hareket etmez. Yanlış zamanda kaydırılan taş, başka okların tek çıkış yolunu
  kapatıp level'ı kilitleyebilir.
- Dişli (Gear) ok her hamleden sonra 90° döner. Yani hangi yöne baktığı, o ana
  kadar kaç hamle yaptığına bağlıdır: bir dişliyi çıkarmak için sırasının doğru
  hamlede gelmesi gerekir. Hizalanmadıysa bir hamle beklemen gerekir; bekleme
  butonu da bir hamleye mal olur. Her çıkış bütün dişlileri döndürdüğü için
  "çıkabileni çıkar" gibi sabit bir rutin işe yaramaz.
- Level 4'ten itibaren her dokunuş (blocked, frozen ve Rotator dönüşleri dahil)
  hamle bütçesinden düşer. Board, limit dolmadan temizlenmelidir. 3 yıldız için
  solver'ın bulduğu en kısa çözüm gerekir.
- Taşlı level'larda board artık çözülemez hale gelirse oyun bunu arka planda
  tespit eder ve denemeyi "Tahta tıkandı" ile bitirir. Bu durumda yalnızca
  yeniden başlatma sunulur.

## Mimari

- `lib/game/logic/board_engine.dart`: Board'un bitmask modeli. Tek geçiş
  fonksiyonu `move`, solver, zorluk ölçümü ve generator tarafından ortak
  kullanılır. State; board'daki okları, Rotator başına 2 bit dönüşü ve taş
  başına 3 bit iniş konumunu tutar.
- `lib/game/logic/level_solver.dart`: Alt sınır heuristiği ile A* araması; en
  kısa çözümü ve açılış seçeneklerini döndürür. Oyunda ipucu ve tıkanma
  kontrolü de bunu kullanır.
- `lib/game/logic/level_difficulty.dart`: Level zorluğunu oyuncu
  simülasyonlarıyla ölçer. En önemlisi "stratejist": çıkabileni çıkarır,
  taşları sona saklar, dişli için bekler ve hiç hamle harcamaz. Bu oyuncu bir
  level'ı kolayca 3 yıldızla bitirebiliyorsa level kataloğa alınmaz.
- `lib/game/logic/board_rules.dart`: Canlı oyunun kullandığı ortak geometri
  kuralları.

## Level üretimi

Level 1–3 elle yazılmış öğretici level'lardır. Level 4–300 üretilir:

```bash
tool/generate_campaign.sh     # 6 aralığı paralel üretir, ~40 dk
dart run tool/level_audit.dart
```

- `tool/level_plan.dart`: Level başına board boyutu, özel ok sayıları, hamle
  tabanı ve zorluk eşikleri.
- `tool/level_forge.dart`: Çözülebilirliği garanti eden board inşası.
- `tool/generate_levels.dart`: Adayları arar, eşiklere göre eler ve
  `lib/game/data/campaign/` altına yazar.
- `tool/reindex_campaign.dart`: Aralıklar paralel üretildiği için sınırlarda
  zorluk düşebilir. Bu araç 14. level'dan sonrasını en kısa çözüm uzunluğuna
  göre sıralayıp numaraları yeniden verir.
- `tool/generate_progression.dart`: Eski, kullanılmayan ilk generator denemesi;
  yalnızca referans için yorum satırı olarak saklanır.

## Çalıştırma

Güncel stable Flutter SDK ile:

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d ios
```

Tüm level'ları gerçek ilerlemeyi değiştirmeden açan test modu:

```bash
flutter run --dart-define=TEST_MODE=true
```

`TEST_MODE` varsayılan olarak `false` değerindedir ve etkin olduğunda uygulamada
görünür bir test modu şeridi gösterilir.

Projede Android, iOS, macOS, web, Linux ve Windows için Flutter platform
iskeletleri bulunur. Oyun portre moduna sabitlenmiştir.

## İçerik

- 3x3 ile 8x8 arasında 300 level (3 öğretici + 297 üretilmiş), zorluk hiçbir
  level geçişinde düşmez
- Normal, rotator, frozen, bomb, taş (stone) ve dişli (gear) oklar
- Animasyonlu splash ve ana sayfa; yeni oyun, devam et ve level seçimi
- Kalıcı ilerleme, en iyi hamle, 1–3 yıldız ve kilit açma sistemi
- Cihaz dilini izleyen ve ayarlardan değiştirilebilen Türkçe/İngilizce arayüz
- Move-efficiency bütçesi, combo, haptic feedback, solver tabanlı hint, pause ve
  restart
- Deneme başına 2 ücretsiz ipucu; hak bitince bir kez ödüllü reklamla +2 ipucu
- AdMob geçiş reklamı: öğreticiden sonra, en az üç bölüm ve üç dakikalık
  aralıklarla yalnız doğal bölüm geçişlerinde
- AdMob ödüllü reklamı: hamle bütçesi dolunca deneme başına bir kez isteğe
  bağlı +3 hamle (tıkanan board'da sunulmaz)
- Google UMP onay akışı ve uygulama içi reklam gizlilik tercihleri
- Sprite gerektirmeyen Canvas çizimleri
- Level veri bütünlüğü, taş kuralları, zorluk artışı, zorluk eşikleri ve
  solver/gameplay uyumu için otomatik testler

Güncel katalog metrikleri `LEVEL_AUDIT.md`, level kuralları
`tool/level_plan.dart` dosyasındadır. `LEVEL_DESIGN.md` ve
`IMPLEMENTATION_INSTRUCTIONS.md`, elle tasarlanan ilk 100 level'lık sürümün
tasarım belgeleridir ve tarihsel referans olarak saklanır.

Yayın öncesi zorunlu AdMob, signing ve store ayarları `RELEASE_CHECKLIST.md`
dosyasında listelenmiştir.

Debug build'ler Google'ın resmi test reklam birimlerini kullanır. Production
reklam birimleri release build'e `ADMOB_ANDROID_INTERSTITIAL_ID`,
`ADMOB_ANDROID_REWARDED_ID`, `ADMOB_IOS_INTERSTITIAL_ID` ve
`ADMOB_IOS_REWARDED_ID` dart-define değerleriyle verilir.
