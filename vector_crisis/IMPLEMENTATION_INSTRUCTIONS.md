# Arrow Chaos — Codex için Kritik Uygulama Talimatları

Bu projede en önemli konu sadece 100 adet solvable level üretmek değildir.

Amaç:

**oynanabilir, kısa, anlaşılır, giderek zorlaşan ve birbirini tekrar etmeyen 100 level üretmek.**

Aşağıdaki maddelere özellikle dikkat et.

---

## 1. Level 1–9'a dokunma

Level 1–9 değişmeden korunacak baseline'dır. Level 10–20, erken oyunun
fazla kolay olduğuna dair kullanıcı geri bildirimiyle yeniden dengelenmiştir.

Bunları baseline kabul et.

Şunları yapma:

- level'ları yeniden üretme
- pozisyonları değiştirme
- difficulty balancing bahanesiyle yeniden yazma
- auto-generator ile overwrite etme

Sadece gerçek bir bug veya compile problemi varsa düzelt.

Yeni tasarım:

**Yeni difficulty balancing Level 10'dan başlamalı.**

---

# 2. Gameplay kuralını önce mevcut koddan öğren

LEVEL_DESIGN.md ile mevcut kod arasında çelişki varsa körü körüne dokümana göre gameplay davranışı uydurma.

Önce mevcut kodu incele ve şu mekaniklerin gerçek davranışını çıkar:

- Normal Arrow
- Rotator Arrow
- Frozen Arrow
- Bomb Arrow
- blocked arrow
- combo
- hint
- level completion

Özellikle:

**solver ile gerçek gameplay aynı kuralları kullanmalı.**

Örneğin bomb gameplay'de farklı davranıp solver'da farklı davranıyorsa önce bunu düzelt.

---

# 3. Normal Arrow temel kuralı

Normal arrow sadece baktığı yönde board dışına kadar hiçbir aktif arrow yoksa çıkabilmeli.

Örneğin:

```text
→   →   →
```

soldaki arrow çıkamaz.

En sağdaki çıkabilir.

Collision/physics kullanmak yerine mevcut grid-state logic korunmalı.

---

# 4. Blocked tap level state'i bozmamalı

Önü kapalı arrow'a basıldığında:

- arrow silinmemeli
- pozisyon değiştirmemeli
- yön değiştirmemeli
- board state bozulmamalı

Sadece feedback verilmeli.

Örnek:

- kısa shake
- error haptic
- combo reset

---

# 5. Rotator davranışını net tut

Rotator arrow için mevcut proje davranışını esas al.

Rotator bir tap ile direction değiştiriyorsa:

```text
up
→ right
→ down
→ left
→ up
```

gibi deterministic olmalı.

Rotator state solver'ın state hash'ine dahil edilmeli.

Solver şu iki state'i aynı kabul etmemeli:

```text
rotator facing up
```

ve

```text
rotator facing right
```

Bunlar farklı board state'leridir.

---

# 6. Frozen state mutlaka solver'da bulunmalı

Frozen arrow:

```text
frozen = true
```

ve

```text
frozen = false
```

aynı state değildir.

Unfreeze kuralını gameplay kodundan öğren.

Solver aynı kuralı birebir uygulamalı.

Gameplay'de frozen arrow'a tap edilemiyorsa solver da onu playable move olarak görmemeli.

---

# 7. Bomb behaviour en kritik alanlardan biri

Bomb için önce mevcut implementasyonu analiz et.

Net olarak belirle:

- bomb ne zaman patlıyor?
- çıkınca mı?
- yakınındaki hangi hücreleri etkiliyor?
- frozen arrow'a ne yapıyor?
- rotator'ı direkt siliyor mu?
- başka bomb tetikleniyor mu?

Sonra bu kuralları tek bir ortak mantığa mümkün olduğunca yaklaştır.

Gameplay ve solver farklı bomb logic kullanmamalı.

---

# 8. Sadece solvable level üretme

Şu yanlış yaklaşımı kullanma:

```text
random board oluştur
↓
solver true
↓
kabul et
```

Bu yeterli değildir.

Solvable level çok kötü bir puzzle olabilir.

Level ancak şu kontrolleri geçerse kabul edilmeli:

1. structurally valid
2. solvable
3. progression'a uygun
4. mechanic focus doğru
5. difficulty uygun
6. önceki level'lara aşırı benzemiyor
7. başlangıçta anlamlı playable move var
8. gereksiz uzun değil
9. special arrow mechanic gerçekten kullanılıyor
10. board okunabilir

---

# 9. Level'larda tek ana fikir olsun

Her level küçük bir puzzle fikri taşımalı.

Örneğin Level 31:

```text
Rotator + Frozen dependency
```

ise level'ın ana fikri bu olmalı.

Şunu yapma:

```text
4 rotator
4 frozen
3 bomb
20 normal
```

ve “zor level” deme.

Zorluk = karmaşa değildir.

---

# 10. Special arrow spam yapma

Genel kural:

Normal arrow'lar çoğunlukta kalmalı.

Tercihen:

```text
>= %60 normal
```

Çoğu level için:

```text
Rotator: 0–3
Frozen: 0–4
Bomb: 0–2
```

Challenge level dışında bunların üzerine çıkma.

Rotator için maksimum:

```text
4
```

Bomb için maksimum:

```text
3
```

önerilir.

---

# 11. Difficulty sadece arrow count değildir

20 arrow olan bir level kolay olabilir.

8 arrow olan bir level zor olabilir.

Difficulty değerlendirirken şunlara bak:

- dependency depth
- branching
- special mechanic count
- misleading valid moves
- board density
- number of required state changes
- solution length
- initial valid move count

---

# 12. İlk hamle sayısını kontrol et

İdeal olarak çoğu level başlangıçta:

```text
1–4
```

anlamlı playable move sunsun.

Şu durumları dikkatle değerlendir:

### 0 playable moves

Reject.

### 1 playable move

Tutorial veya dependency level için kabul edilebilir.

Ama her level böyle olmamalı.

### 8–10+ playable moves

Board fazla random ve karar değeri düşük olabilir.

---

# 13. Scripted puzzle üretme

Kötü level:

```text
A
↓
B
↓
C
↓
D
↓
E
↓
F
```

Her state'de sadece tek oynanabilir arrow varsa oyuncu puzzle çözmez.

Sadece verilen sırayı takip eder.

Bazen kullanılabilir ama sık kullanılmamalı.

Tercih:

```text
     A
   /   \
  B     C
   \   /
     D
```

gibi küçük branching yapıları.

---

# 14. Level sonunda payoff oluştur

İyi level'ların önemli kısmı final clean-up hissidir.

Mümkün olduğunda level'ın son kısmında:

```text
3–7 kolay arrow clear
```

oluşsun.

Bu combo ve satisfaction sağlar.

Örnek:

```text
critical move
↓
board opens
↓
tap tap tap tap tap
↓
LEVEL COMPLETE
```

Bu özellikle breather ve milestone level'larda değerlidir.

---

# 15. Breather level'ları unutma

Difficulty lineer artmamalı.

Örneğin:

```text
5
6
7
4
5
6
```

gibi iniş çıkış olmalı.

Özellikle zor milestone level sonrası daha rahat level koy.

Örnek:

```text
Level 70 difficulty 7
Level 71 difficulty 4
```

Bu bilinçli bir tasarım kararıdır.

---

# 16. Board geometry tekrarını kontrol et

Arka arkaya şu tarz 3 level üretme:

```text
center cluster
center cluster
center cluster
```

Varyasyon kullan:

- ring
- cross
- center cluster
- outer edge
- two islands
- diagonal
- asymmetric
- corner based
- horizontal heavy
- vertical heavy

Ama template'i birebir copy-paste etme.

---

# 17. Dominant direction tekrarına dikkat et

Arka arkaya bütün level'larda:

```text
→ → → →
```

ağırlığı olmasın.

Yön dağılımını çeşitlendir.

Bazı level:

- horizontal focused
- vertical focused
- clockwise
- outside-in
- center-out

olabilir.

Ama tekrar kontrolü yap.

---

# 18. Symmetry kullan ama aşırı kullanma

Simetrik board görsel olarak tatmin edici olabilir.

Fakat:

- her level simetrik olmasın
- simetrik board'un çözümü her zaman simetrik olmak zorunda olmasın

Misleading symmetry iyi bir advanced-level tekniğidir.

---

# 19. Level 16–100 tek seferde random generate edilmemeli

LEVEL_DESIGN.md'deki arc'lara göre ilerle.

Batch sırası:

```text
16–25
26–35
36–45
46–60
61–75
76–90
91–100
```

Her batch sonrası:

- solver test
- structural test
- difficulty audit
- repetition audit

çalıştır.

---

# 20. Level metadata ekle

Mevcut model izin veriyorsa şu alanları ekle veya ayrı debug metadata tut:

```text
difficulty
mechanicFocus
isChallenge
isBreather
targetMoves
```

Ama sadece metadata için tüm production architecture'ı bozma.

---

# 21. Target moves yanlış anlaşılmasın

Target moves:

```text
level fail condition
```

olmak zorunda değildir.

Şimdilik balancing/debug metric olabilir.

Amaç:

solver'ın bulunan çözüm uzunluğuyla level designer beklentisini karşılaştırmak.

---

# 22. Solver sadece true/false dönmesin

Mümkünse debug/development için şu bilgileri de üret:

```text
isSolvable
minimumMoves
initialPlayableMoves
visitedStates
dependency estimate
```

Bu metrikler level kalitesi kontrolüne yardım eder.

---

# 23. Solver'da state explosion'a dikkat et

Özellikle rotator bulunduğunda state-space büyüyebilir.

State deduplication kullan.

State hash içine gerekli alanları ekle:

```text
arrow position
arrow direction
arrow type
frozen state
rotator state
bomb-relevant state
```

Aynı gerçek state'i tekrar explore etme.

---

# 24. Runtime'da solver çalıştırmak zorunda değilsin

Solver development validation içindir.

100 level önceden doğrulandıktan sonra production'da level açılışında BFS çalıştırmak zorunda değilsin.

Test/debug tarafında çalışması yeterlidir.

---

# 25. Her level için otomatik test oluştur

En azından tüm catalog için:

```dart
for (final level in levels) {
  expect(solver.isSolvable(level), true);
}
```

olmalı.

Ayrıca validate et:

- duplicate cell yok
- board dışında arrow yok
- invalid type yok
- boş level yok
- invalid frozen state yok

---

# 26. Duplicate level kontrolü yap

Aynı board'un:

```text
sadece level id'si değiştirilmiş
```

versiyonları olmamalı.

Canonical board signature üretip duplicate kontrolü yapabilirsin.

Ancak mirror/rotation similarity de mümkünse debug audit'te raporlansın.

---

# 27. Level 16–25 özel talimatı

İlk batch Rotator Arc.

Amaç rotator mechanic'i öğretmek.

Şu progression korunmalı:

```text
16: tek rotator tanıtım
17: rotator + normal
18: rotator path açma
19: iki rotator dependency
20: rotator milestone
21: breather
22–24: branching / farklı kullanım
25: mastery
```

Level 16'yı gereksiz zorlaştırma.

---

# 28. Level 26–35 özel talimatı

Frozen Arc.

Önce frozen mechanic tek başına anlaşılmalı.

Sonra:

```text
frozen
↓
frozen dependency
↓
rotator + frozen
```

kombinasyonuna geç.

İlk frozen level'larda bomb kullanma.

---

# 29. Level 36–45 özel talimatı

Bomb Arc.

Bomb'ın:

> satisfying shortcut / board opener

olduğu anlaşılmalı.

Bomb her level'da sadece mandatory button gibi kullanılmamalı.

Doğru zamanlama anlamlı olmalı.

---

# 30. Level 46–60 özel talimatı

Mixed mechanics.

Ama her level'ın yine bir ana focus'u olmalı.

Örnek:

```text
46 = rotator + frozen
47 = rotator + bomb
48 = frozen + bomb
49 = first three-way mix
```

Her level'a tüm mechanicleri doldurma.

---

# 31. Level 61–75

Density artırılabilir.

Ama:

```text
more arrows != random arrows
```

Board structure korunmalı.

Bu arc'ta özellikle:

- horizontal dependency
- vertical dependency
- cross dependency
- outer ring
- center lock

gibi patternler kullanılabilir.

---

# 32. Level 76–90

Yeni mechanic ekleme.

Mevcut mechanic'leri daha yaratıcı kullan.

Amaç oyuncunun mastery seviyesine ilerlemesi.

Dependency biraz daha derin olabilir.

Yine de brute force gerektiren puzzle üretme.

---

# 33. Level 91–100

Final mastery.

100. level:

- zor olmalı
- ama unfair olmamalı
- birden fazla phase hissi vermeli
- final bölümde satisfying clear içermeli

Level 100'ü sadece:

```text
çok arrow + çok special
```

ile zorlaştırma.

---

# 34. Mobil okunabilirliğe dikkat et

7x7 grid kullanmadan önce gerçekten ihtiyaç var mı kontrol et.

Arrow'lar küçülüp okunamaz hale geliyorsa 6x6 tercih et.

Gameplay portrait iPhone önceliklidir.

---

# 35. Kod tarafını gereksiz yere yeniden yazma

Bu görev:

**level design ve validation görevidir.**

Bahaneyle:

- state management değiştirme
- oyun motorunu değiştirme
- büyük architecture refactor yapma
- Riverpod/BLoC ekleme

gibi işler yapma.

Sadece görev için gerçekten gerekli teknik değişiklikleri yap.

---

# 36. Mevcut çalışan davranışları koru

Yeni level sistemi eklerken:

- tap
- animation
- combo
- hint
- win
- restart
- next level

gibi çalışan sistemleri bozma.

Her batch sonrası mevcut gameplay regression testi yap.

---

# 37. Kod kalitesi

Level data okunabilir olsun.

Şunun gibi anlamsız giant list üretip bırakma:

```dart
[1,2,3,4,1,2,4,3,1...]
```

Mümkün olduğunca:

```dart
ArrowData(
  row: 2,
  column: 3,
  direction: ArrowDirection.right,
  type: ArrowType.rotator,
)
```

gibi okunabilir format korunsun.

---

# 38. Final audit zorunlu

100 level bittikten sonra rapor üret:

```text
Total Levels: 100
Solvable: 100
Invalid: 0
Duplicates: 0
```

Ardından dağılımları göster:

```text
Difficulty 1:
Difficulty 2:
...
Difficulty 10:
```

ve:

```text
Rotator levels:
Frozen levels:
Bomb levels:
Mixed levels:
Breather levels:
Challenge levels:
```

Ayrıca şunları raporla:

- en yüksek minimum move
- en fazla special arrow içeren level
- en yoğun board
- en fazla başlangıç seçeneği olan level
- duplicate/similarity warning'leri

---

# 39. Manuel inceleme listesi oluştur

100 level teknik olarak tamamlandığında kullanıcıya şu level'ları özellikle manuel test etmesi için listele:

```text
17
20
25
26
30
35
36
40
45
50
60
70
75
80
90
100
```

Bunlar mechanic introduction / mastery / milestone level'larıdır.

---

# 40. En önemli prensip

Şunu sürekli akılda tut:

**Solver oyunun tasarımcısı değildir.**

Solver sadece:

> Bu board çözülebilir mi?

sorusunu cevaplar.

İyi level şu soruya da cevap vermelidir:

> Bu board'u çözmek eğlenceli mi?

Bu nedenle teknik olarak solvable ama kötü görünen, anlamsız veya tekrar eden level'ları reject et.

---

# Şimdi Yapacağın İş

Önce mevcut projeyi ve LEVEL_DESIGN.md'yi tamamen oku.

Sonra mevcut gameplay kurallarını koddan çıkar.

Özellikle:

- rotator
- frozen
- bomb
- solver

davranışlarını karşılaştır.

Tutarsızlık varsa düzelt.

Ardından yalnızca Level 16–25 batch'ini oluştur.

Bu batch için:

1. structural validation çalıştır
2. solver çalıştır
3. difficulty kontrolü yap
4. repetition kontrolü yap
5. testleri çalıştır
6. flutter analyze çalıştır
7. sonucu raporla

16–25 başarılı olduktan sonra aynı prensiplerle LEVEL_DESIGN.md progression'ını izleyerek 26–100 arasını tamamla.

Mevcut 1–9 level'a dokunma.
