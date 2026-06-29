import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'data/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/mira_logo.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MiraApp());
}

class MiraApp extends StatelessWidget {
  const MiraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppState.instance,
      builder: (context, _) {
        final accent = AppColors.accents[
            AppState.instance.accent.clamp(0, AppColors.accents.length - 1)];
        return MaterialApp(
          title: 'Mira',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(accent: accent),
          home: const _Bootstrap(),
        );
      },
    );
  }
}

/// Loads on-device state, shows a brief splash, then routes to onboarding
/// or the main app.
class _Bootstrap extends StatefulWidget {
  const _Bootstrap();

  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await AppState.instance.load();
    // Small minimum splash so the logo animation can breathe.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _ready = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) return const _Splash();
    return AppState.instance.hasProfile
        ? const AppShell()
        : const OnboardingScreen();
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
            Text('your calm companion',
                    style: text.bodyMedium?.copyWith(color: AppColors.inkSoft))
                .animate()
                .fadeIn(delay: 300.ms, duration: 700.ms),
          ],
        ),
      ),
    );
  }
}
