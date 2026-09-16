import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/app_controller.dart';
import 'services/ads_service.dart';
import 'ui/design/app_theme.dart';
import 'ui/home_page.dart';
import 'ui/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(const [
    DeviceOrientation.portraitUp,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  runApp(const VectorCrisisApp());
}

class VectorCrisisApp extends StatefulWidget {
  final AppController? controller;
  final AdsService? ads;
  final bool showSplash;
  final bool initializeAds;

  const VectorCrisisApp({
    super.key,
    this.controller,
    this.ads,
    this.showSplash = true,
    this.initializeAds = true,
  });

  @override
  State<VectorCrisisApp> createState() => _VectorCrisisAppState();
}

class _VectorCrisisAppState extends State<VectorCrisisApp> {
  late final AppController _controller = widget.controller ?? AppController();
  late final AdsService _ads = widget.ads ?? AdsService();
  late Future<void> _boot = _initialize();

  Future<void> _initialize() async {
    final minimumSplash = widget.showSplash
        ? Future<void>.delayed(const Duration(milliseconds: 1200))
        : Future<void>.value();
    await Future.wait([
      _controller.initialize(),
      minimumSplash,
      if (widget.initializeAds) _ads.initialize(),
    ]);
  }

  @override
  void dispose() {
    if (widget.ads == null) _ads.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vector Crisis: Arrow Puzzle',
      theme: buildAppTheme(),
      home: FutureBuilder<void>(
        future: _boot,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashPage();
          }
          if (snapshot.hasError) {
            return _BootError(
              onRetry: () => setState(() => _boot = _initialize()),
            );
          }
          return HomePage(controller: _controller, ads: _ads);
        },
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  final VoidCallback onRetry;

  const _BootError({required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              size: 48,
              color: AppColors.danger,
            ),
            const SizedBox(height: 16),
            const Text(
              'Uygulama başlatılamadı',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text('Lütfen uygulamayı kapatıp yeniden aç.'),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('TEKRAR DENE')),
          ],
        ),
      ),
    ),
  );
}
