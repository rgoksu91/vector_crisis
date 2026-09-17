# Vector Crisis — Apple App Store Asset Pack

This folder keeps visual assets and copy separate so they can be uploaded to
App Store Connect without mixing localized metadata with screenshots.

## Visuals

- `screenshots/iphone/en/`: 6 English iPhone 6.9-inch screenshots, 1320×2868
- `screenshots/iphone/tr/`: 6 Turkish iPhone 6.9-inch screenshots, 1320×2868
- `screenshots/ipad/en/`: 3 English 13-inch iPad screenshots, 2064×2752
- `screenshots/ipad/tr/`: 3 Turkish 13-inch iPad screenshots, 2064×2752
- `brand/app_icon_1024.png`: 1024×1024 icon reference, no alpha
- `brand/store_background_v1.png`: generated campaign background
- `previews/`: contact sheets for quick review; do not upload these

All upload-ready screenshots are PNG, RGB, and have no alpha channel. The
screens use real Simulator captures from the app. `compose_store_assets.sh`
rebuilds the compositions from the raw captures.

## Text and submission material

- `metadata/en-US.md`: English product-page copy
- `metadata/tr-TR.md`: Turkish product-page copy
- `metadata/app_store_connect_checklist.md`: submission and privacy checklist
- `metadata/app_preview_storyboard.md`: optional 30-second preview plan

## Upload order

Upload screenshots in numeric order. English assets belong to the `English
(U.S.)` localization and Turkish assets to the `Turkish` localization.

Official references:

- Screenshot sizes: https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications
- Screenshot upload: https://developer.apple.com/help/app-store-connect/manage-app-information/upload-app-previews-and-screenshots
- App information: https://developer.apple.com/help/app-store-connect/reference/app-information/app-information
- Version metadata: https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information

