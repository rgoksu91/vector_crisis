import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../app/app_controller.dart';
import '../l10n/generated/app_localizations.dart';
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
        builder: (context, _) {
          final l10n = AppLocalizations.of(context);
          return Column(
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
              Text(
                l10n.settings.toUpperCase(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language_rounded),
                title: Text(l10n.language),
                subtitle: Text(l10n.languageSubtitle),
                trailing: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: controller.localeCode ?? 'system',
                    borderRadius: BorderRadius.circular(16),
                    items: [
                      DropdownMenuItem(
                        value: 'system',
                        child: Text(l10n.systemLanguage),
                      ),
                      DropdownMenuItem(value: 'en', child: Text(l10n.english)),
                      DropdownMenuItem(value: 'tr', child: Text(l10n.turkish)),
                    ],
                    onChanged: (value) => controller.setLocaleCode(
                      value == 'system' ? null : value,
                    ),
                  ),
                ),
              ),
              const Divider(height: 28),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: controller.hapticsEnabled,
                activeThumbColor: AppColors.secondary,
                title: Text(l10n.haptics),
                subtitle: Text(l10n.hapticsSubtitle),
                secondary: const Icon(Icons.vibration_rounded),
                onChanged: controller.setHapticsEnabled,
              ),
              const Divider(height: 28),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text(l10n.adPrivacy),
                subtitle: Text(l10n.adPrivacySubtitle),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final shown = await ads.showPrivacyOptions();
                  if (!context.mounted || shown) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.privacyUnavailable)),
                  );
                },
              ),
              if (kDebugMode) ...[
                const Divider(height: 28),
                Text(
                  l10n.adConfiguration,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.interstitial}: ${AdUnitIds.interstitial}\n'
                  '${l10n.rewarded}: ${AdUnitIds.rewarded}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.adConfigurationWarning,
                  style: TextStyle(
                    color: AppColors.gold.withValues(alpha: 0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          );
        },
      ),
    ),
  ),
);
