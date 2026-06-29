import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/tips_service.dart';
import '../../theme/app_theme.dart';

class CalmModeScreen extends StatefulWidget {
  const CalmModeScreen({super.key});

  @override
  State<CalmModeScreen> createState() => _CalmModeScreenState();
}

class _CalmModeScreenState extends State<CalmModeScreen>
    with SingleTickerProviderStateMixin {
  final _steps = TipsService.instance.calmSteps();
  final _page = PageController();
  int _index = 0;

  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _page.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_index < _steps.length - 1) {
      _page.nextPage(
          duration: const Duration(milliseconds: 350), curve: Curves.easeOut);
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = Theme.of(context).extension<AppGradient>()!.linear;
    final isLast = _index == _steps.length - 1;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    Expanded(
                      child: Text('Calm Mode',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: Colors.white)),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: _steps.length,
                  itemBuilder: (context, i) {
                    final step = _steps[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (i == 0)
                            AnimatedBuilder(
                              animation: _breath,
                              builder: (context, _) {
                                final scale = 0.8 + _breath.value * 0.4;
                                return Container(
                                  height: 160 * scale,
                                  width: 160 * scale,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white
                                        .withValues(alpha: 0.12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    _breath.value < 0.5 ? 'Breathe in' : 'Breathe out',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16),
                                  ),
                                );
                              },
                            ),
                          if (i == 0) const SizedBox(height: 44),
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            step.body,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                    color:
                                        Colors.white.withValues(alpha: 0.9),
                                    height: 1.5),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _steps.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 8,
                    width: i == _index ? 22 : 8,
                    decoration: BoxDecoration(
                      color: Colors.white
                          .withValues(alpha: i == _index ? 1 : 0.4),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isLast ? 'I\u2019m okay now' : 'Next',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
