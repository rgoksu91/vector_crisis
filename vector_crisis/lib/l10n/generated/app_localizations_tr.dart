// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Vector Crisis: Arrow Puzzle';

  @override
  String get splashTagline => 'OK BULMACASI  •  DÜŞÜN  •  ÇÖZ';

  @override
  String get bootErrorTitle => 'Uygulama başlatılamadı';

  @override
  String get bootErrorBody => 'Uygulamayı kapatıp yeniden açmayı dene.';

  @override
  String get retry => 'TEKRAR DENE';

  @override
  String get testModeBanner => 'TEST MODU';

  @override
  String get settings => 'Ayarlar';

  @override
  String get homeTagline => 'Her oku oku. Sırayı çöz. Kaosu temizle.';

  @override
  String get startNewGameTitle => 'Yeni oyun başlat?';

  @override
  String get startNewGameBody => 'Mevcut ilerleme ve tüm yıldızlar silinecek.';

  @override
  String get cancel => 'VAZGEÇ';

  @override
  String get newGame => 'YENİ OYUN';

  @override
  String continueLevel(int level) {
    return 'DEVAM ET  •  BÖLÜM $level';
  }

  @override
  String get selectLevel => 'BÖLÜM SEÇ';

  @override
  String get handcraftedPuzzles => '100 EL YAPIMI BULMACA';

  @override
  String get completed => 'TAMAMLANDI';

  @override
  String get stars => 'YILDIZ';

  @override
  String get unlockedLevel => 'AÇIK BÖLÜM';

  @override
  String get language => 'Dil';

  @override
  String get languageSubtitle => 'Uygulamada kullanılacak dili seç';

  @override
  String get systemLanguage => 'Sistem dili';

  @override
  String get english => 'İngilizce';

  @override
  String get turkish => 'Türkçe';

  @override
  String get haptics => 'Dokunsal geri bildirim';

  @override
  String get hapticsSubtitle => 'Hamlelerde titreşim kullan';

  @override
  String get adPrivacy => 'Reklam gizlilik tercihleri';

  @override
  String get adPrivacySubtitle => 'Onay ve kişiselleştirme seçimlerini yönet';

  @override
  String get privacyUnavailable =>
      'Gizlilik seçenekleri şu anda kullanılamıyor.';

  @override
  String get adConfiguration => 'REKLAM YAPILANDIRMASI';

  @override
  String get interstitial => 'Geçiş';

  @override
  String get rewarded => 'Ödüllü';

  @override
  String get adConfigurationWarning =>
      'Yayına çıkmadan önce bu geçici değerleri AdMob reklam birimi kimliklerinle değiştir.';

  @override
  String get rewardUnavailable =>
      'Ödüllü reklam henüz hazır değil. Tekrar deneyebilirsin.';

  @override
  String get gamePaused => 'OYUN DURAKLATILDI';

  @override
  String get gamePausedBody => 'Tahta seni bekliyor.';

  @override
  String get resume => 'DEVAM ET';

  @override
  String get restartLevel => 'BÖLÜMÜ YENİDEN BAŞLAT';

  @override
  String get mainMenu => 'ANA MENÜ';

  @override
  String get homeTooltip => 'Ana menü';

  @override
  String get restartTooltip => 'Yeniden başlat';

  @override
  String get hintTooltip => 'İpucu';

  @override
  String get pauseTooltip => 'Duraklat';

  @override
  String levelNumber(int level) {
    return 'BÖLÜM $level';
  }

  @override
  String arrowsRemaining(int count) {
    return '$count OK KALDI';
  }

  @override
  String arrowsAndMoves(int remaining, int moves, int limit) {
    return '$remaining OK  •  $moves/$limit HAMLE';
  }

  @override
  String get movesEnded => 'HAMLE BİTTİ';

  @override
  String get allLevelsCompleted => '100 BÖLÜM TAMAMLANDI';

  @override
  String get boardClear => 'TAHTA TEMİZ';

  @override
  String get failedDescription =>
      'Sırayı yeniden düşün veya reklam izleyerek 3 ek hamle kazan.';

  @override
  String get allDoneDescription => 'Kaosu tamamen kontrol altına aldın.';

  @override
  String completedInMoves(int moves) {
    return '$moves hamlede tamamlandı.';
  }

  @override
  String get watchAdBonus => 'REKLAM İZLE  •  +3 HAMLE';

  @override
  String get restart => 'YENİDEN BAŞLAT';

  @override
  String get returnToMainMenu => 'ANA MENÜYE DÖN';

  @override
  String get nextLevel => 'SONRAKİ BÖLÜM';

  @override
  String get frozenArrowBlocked => 'Buzlu ok: yanındaki bir oku çıkar.';

  @override
  String get rotatorTurned => 'Rotator 90° döndü.';

  @override
  String get pathBlocked => 'Önü kapalı.';

  @override
  String get noAvailableMove => 'Şu an kullanılabilir hamle yok.';

  @override
  String get hintRotate => 'İpucu: turuncu oku döndür.';

  @override
  String get hintMarked => 'İpucu işaretlendi.';

  @override
  String bonusMovesGranted(int count) {
    return '+$count hamle kazandın!';
  }

  @override
  String bombResult(int count) {
    return 'BOOM! +$count';
  }

  @override
  String get campaignCompletedMessage => 'Tüm bölümler tamamlandı!';

  @override
  String get boardClearMessage => 'Tahta temiz!';

  @override
  String get moveLimitReached => 'Hamle sınırı doldu.';

  @override
  String get introTapArrow => 'Oka dokun ve tahta dışına çıkar.';

  @override
  String get introRotator => 'Turuncu: önü kapalıysa 90° döner.';

  @override
  String get introFrozen => 'Buzlu ok: komşu ok çıkınca çözülür.';

  @override
  String get introBomb => 'Kırmızı bomba: komşuları patlatır.';

  @override
  String get introRotatorClockwise =>
      'Turuncu ok önü kapalıyken saat yönünde döner.';
}
