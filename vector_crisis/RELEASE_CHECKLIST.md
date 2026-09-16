# Vector Crisis: Arrow Puzzle — Release Checklist

Uygulama kimliği:

```text
Android applicationId: com.rgoksu.vectorcrisis
iOS bundle identifier: com.rgoksu.vectorcrisis
```

## AdMob

- `lib/services/ads_service.dart` içindeki `GecisId` değerini gerçek
  interstitial reklam birimi ID'siyle değiştir.
- Aynı dosyadaki `OdulId` değerini gerçek rewarded reklam birimi ID'siyle
  değiştir.
- `android/app/src/main/AndroidManifest.xml` içindeki Google test app ID'sini
  Android AdMob app ID'siyle değiştir.
- `ios/Runner/Info.plist` içindeki Google test app ID'sini iOS AdMob app ID'siyle
  değiştir.
- AdMob panelinde GDPR/UMP mesajını yayınla ve test cihazlarını tanımla.
- Gerçek reklam kimliklerini yalnız release öncesi kullan; geliştirme sırasında
  Google'ın test reklam birimlerini kullan.

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
