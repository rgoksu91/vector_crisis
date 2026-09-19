# Vector Crisis: Arrow Puzzle — Release Checklist

Uygulama kimliği:

```text
Android applicationId: com.rgoksu.vectorcrisis
iOS bundle identifier: com.rgoksu.vectorcrisis
```

- App Store ve Google Play açıklamalarını Türkçe ve İngilizce olarak gir.
- Mağaza ekran görüntülerini her iki dil için ayrı yükle.

## AdMob

- [x] Android ve iOS production reklam birimleri `lib/services/ads_service.dart`
  içinde varsayılan değer olarak tanımlı. Gerekirse `--dart-define` ile
  (`ADMOB_ANDROID_INTERSTITIAL_ID`, `ADMOB_ANDROID_REWARDED_ID`,
  `ADMOB_IOS_INTERSTITIAL_ID`, `ADMOB_IOS_REWARDED_ID`) üzerine yazılabilir.
- [x] `AndroidManifest.xml` ve `Info.plist` production AdMob app ID'lerini
  kullanıyor.
- AdMob panelinde GDPR/UMP mesajını yayınla ve test cihazlarını tanımla.
- Gerçek reklam kimliklerini yalnız release öncesi kullan; geliştirme sırasında
  uygulamanın otomatik seçtiği Google test reklam birimlerini kullan.
- İlk 7 level'ın reklamsız kaldığını; ilk geçiş reklamının en erken Level 8
  sonrasında ve iki dakikalık oturumdan sonra çıkabildiğini doğrula.
- Sonraki geçiş reklamları arasında en az üç level ve üç dakika olduğunu;
  ödüllü reklamdan hemen sonra geçiş reklamı çıkmadığını doğrula.
- Ödüllü +3 hamle hakkının jam olmuş board'da görünmediğini ve aynı denemede
  yalnız bir kez kullanılabildiğini doğrula.
- İki ücretsiz ipucundan sonra açık onayla +2 ipucu reklamının sunulduğunu ve
  aynı denemede ikinci kez kullanılamadığını doğrula.

## Signing ve mağaza

- Android release keystore oluştur ve `android/app/build.gradle.kts` içindeki
  geçici debug signing yapılandırmasını release signing ile değiştir.
- Xcode'da doğru Apple Developer Team, provisioning profile ve App Store
  capability ayarlarını seç.
- App Store Connect ve Play Console gizlilik formlarında reklam, cihaz kimliği
  ve uygulama içi ilerleme verilerini doğru beyan et.
- Nihai uygulama ikonu, mağaza ekran görüntüleri, destek URL'si ve gizlilik
  politikası URL'si ekle.
- Sürüm/build numarasını `pubspec.yaml` içinde artır.

## Son doğrulama

- Release komutlarında `--dart-define=TEST_MODE=true` kullanılmadığını doğrula.

```bash
flutter analyze
flutter test
flutter build appbundle --release
flutter build ipa --release
```

- Fiziksel Android ve iPhone'da UMP, interstitial ve rewarded akışlarını test et.
- Uçak modu/reklam yüklenememesi durumunda oyunun reklamsız devam ettiğini test
  et.
- Yeni oyun, devam et, level seçimi ve uygulamayı yeniden açınca ilerleme
  restorasyonunu doğrula.
