# App Store Connect Submission Checklist

## Hazır olanlar / Ready

- [x] Uygulama adı / App name: `Vector Crisis: Arrow Puzzle`
- [x] Bundle ID: `com.rgoksu.vectorcrisis`
- [x] Sürüm / Version: `1.0.0 (1)`
- [x] İngilizce ve Türkçe ürün sayfası metinleri / EN and TR product-page copy
- [x] 6.9-inch iPhone screenshots: 6 EN + 6 TR, `1320×2868`, PNG, no alpha
- [x] 13-inch iPad screenshots: 3 EN + 3 TR, `2064×2752`, PNG, no alpha
- [x] 1024×1024 app icon reference, no alpha
- [x] Suggested categories: Games/Puzzle + Games/Strategy
- [x] App Review notes and optional preview storyboard

## Yayından önce mutlaka tamamlanacaklar / Must complete before submission

- [ ] Replace the `GecisId` and `OdulId` release placeholders with real iOS AdMob unit IDs.
- [ ] Replace the test AdMob App ID in `ios/Runner/Info.plist` with the production AdMob App ID.
- [ ] Provide a real public Support URL and Privacy Policy URL in both localizations.
- [ ] Localize `NSUserTrackingUsageDescription`; it is currently Turkish-only in `Info.plist`.
- [ ] Confirm the App Tracking Transparency flow before any tracking-enabled ad request.
- [ ] Create the App Store Connect app record, select the bundle ID, SKU, price, and availability.
- [ ] Complete Agreements, Tax, and Banking in App Store Connect if the app will earn ad revenue.
- [ ] Upload an Archive from Xcode and select the uploaded build for version 1.0.
- [ ] Complete Export Compliance. The app appears to use only standard platform/SDK encryption, but answer from the final binary and SDK set.
- [ ] Complete Content Rights and Advertising declarations.
- [ ] Complete the age-rating questionnaire. With no objectionable content, the expected result is the lowest available rating; Apple makes the final determination.
- [ ] Verify Sign in with Apple is not required because the app has no third-party account login.
- [ ] Confirm the final production build contains no `TEST_MODE` or `STORE_SCREENSHOT_MODE` dart-defines.

## App Privacy — verify against the final AdMob configuration

Google Mobile Ads and consent choices can change what must be declared. In App
Store Connect, verify the final SDK behavior and Google’s current disclosure
guidance. Likely categories to review include:

- Device ID / advertising identifier
- Product interaction and advertising data
- Diagnostics such as crash or performance data
- Data used for third-party advertising
- Data used to track users when personalized advertising is enabled

The app itself stores level progress, stars, language, and haptic preference on
the device. Do not mark the privacy questionnaire solely from this checklist;
match it to the final binary, consent mode, ad-personalization settings, and
privacy policy.

## Screenshot upload map

| App Store Connect slot | English | Turkish |
|---|---|---|
| iPhone 6.9-inch display | `screenshots/iphone/en/01.png` … `06.png` | `screenshots/iphone/tr/01.png` … `06.png` |
| iPad 13-inch display | `screenshots/ipad/en/01.png` … `03.png` | `screenshots/ipad/tr/01.png` … `03.png` |

Screenshots are ordered as: brand promise, level breadth, special arrows,
decision-making, mastery board, limited hints. iPad uses the first three themes.

## Store field limits used

- Name: 30 characters maximum
- Subtitle: 30 characters maximum
- Promotional text: 170 characters maximum
- Description: 4,000 characters maximum
- Keywords: 100 bytes maximum
- Screenshots: 1–10 per device family and localization
- App previews: optional, up to 3 per device size and localization

Always re-check Apple’s current requirements before final submission:

- https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information

