import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../services/ads_service.dart';
import 'design/app_theme.dart';

Future<void> showSettingsSheet(
  BuildContext context, {
  required AppController controller,
  required AdsService ads,
}) => showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
      ),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'AYARLAR',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: controller.hapticsEnabled,
              activeThumbColor: AppColors.secondary,
              title: const Text('Dokunsal geri bildirim'),
              subtitle: const Text('Hamlelerde titreşim kullan'),
              secondary: const Icon(Icons.vibration_rounded),
              onChanged: controller.setHapticsEnabled,
            ),
            const Divider(height: 28),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Reklam gizlilik tercihleri'),
              subtitle: const Text('Onay ve kişiselleştirme seçimlerini yönet'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () async {
                final shown = await ads.showPrivacyOptions();
                if (!context.mounted || shown) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Gizlilik formu şu anda kullanılamıyor.'),
                  ),
                );
              },
            ),
            const Divider(height: 28),
            const Text(
              'REKLAM YAPILANDIRMASI',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Geçiş: ${AdUnitIds.interstitial}\nÖdüllü: ${AdUnitIds.rewarded}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Yayına çıkmadan önce bu iki geçici değeri AdMob reklam birimi kimlikleriyle değiştir.',
              style: TextStyle(
                color: AppColors.gold.withValues(alpha: 0.9),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
);
