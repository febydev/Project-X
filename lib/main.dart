import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'data/app_state.dart';
import 'features/intro/intro_video_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'theme/app_theme.dart';
import 'theme/mira_palette.dart';
import 'widgets/mira_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MiraApp());
}

class MiraApp extends StatelessWidget {
  const MiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final palette = MiraPalette.all[
            AppState.instance.accent.clamp(0, MiraPalette.all.length - 1)];
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                palette.isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness:
                palette.isDark ? Brightness.dark : Brightness.light,
          ),
        );
        return MaterialApp(
          title: 'Mira',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.fromPalette(palette),
          home: const _Bootstrap(),
        );
      },
    );
  }
}

/// Loads on-device state, shows a brief splash, then routes to the intro
/// video (first launch) → onboarding, or straight to the app.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppState.instance.load();
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _Splash();

    final hasProfile = AppState.instance.hasProfile;
    if (hasProfile) return const AppShell();

    if (!_introDone) {
      return IntroVideoScreen(onDone: () => setState(() => _introDone = true));
    }
    return const OnboardingScreen();
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MiraLogo(size: 96)
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                    begin: const Offset(0.96, 0.96),
                    end: const Offset(1.04, 1.04),
                    duration: 1400.ms,
                    curve: Curves.easeInOut),
            const SizedBox(height: 22),
            Text('Mira', style: text.headlineMedium)
                .animate()
                .fadeIn(duration: 700.ms),
            const SizedBox(height: 4),
            Text('your calm companion', style: text.bodyMedium)
                .animate()
                .fadeIn(delay: 300.ms, duration: 700.ms),
          ],
        ),
      ),
    );
  }
}
