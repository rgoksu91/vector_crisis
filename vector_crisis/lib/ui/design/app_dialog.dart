import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Branded dialog shell shared by the app's confirmation and pause flows.
class AppDialog extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;
  final List<Widget> actions;

  const AppDialog({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actions,
    this.accentColor = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(AppColors.surfaceLight, accentColor, 0.08)!,
                AppColors.surface,
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: accentColor.withValues(alpha: 0.36)),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.12),
                blurRadius: 36,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.48),
                blurRadius: 38,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.32),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 30),
              ),
              const SizedBox(height: 18),
              Text(
                title.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.64),
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              for (var index = 0; index < actions.length; index++) ...[
                SizedBox(width: double.infinity, child: actions[index]),
                if (index != actions.length - 1) const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
