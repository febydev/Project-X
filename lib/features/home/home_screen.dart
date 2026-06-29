import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../controllers/mom_controller.dart';
import '../../data/app_state.dart';
import '../../models/log_entry.dart';
import '../../models/mom_state.dart';
import '../../services/leap_service.dart';
import '../../services/prediction_service.dart';
import '../../services/stats_service.dart';
import '../../theme/category_colors.dart';
import '../../theme/mira_palette.dart';
import '../../widgets/mom_character.dart';
import '../../widgets/soft_card.dart';
import '../calm/calm_mode_screen.dart';
import '../log/add_sleep_screen.dart';
import '../log/log_sheets.dart';
import 'daily_activity_card.dart';
import 'mom_checkin_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppState _state = AppState.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeCheckin();
      // After-10pm tired greeting.
      final hour = DateTime.now().hour;
      if (hour >= 22 || hour < 5) {
        MomController.trigger(MomState.tired,
            holdFor: const Duration(seconds: 5));
      }
      // If a nap window is already open on launch, she points at the clock.
      final nap = PredictionService.instance.nextNap(_state.entries);
      if (nap.ready && (nap.etaMinutes ?? 1) <= 0) {
        MomController.trigger(MomState.pointing);
      }
    });
  }

  void _maybeCheckin() {
    if (!mounted) return;
    if (_state.hasProfile && !_state.hasCheckedInToday) {
      MomCheckinSheet.show(context);
    }
  }

  void _tapSleep() {
    HapticFeedback.lightImpact();
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddSleepScreen()));
  }

  void _tapFeed() {
    HapticFeedback.lightImpact();
    _state.addFeed();
    MomController.trigger(MomState.celebrate);
    _toast('Feeding logged');
  }

  void _tapDiaper() {
    HapticFeedback.lightImpact();
    LogSheets.diaper(context);
  }

  void _tapGrowth() {
    HapticFeedback.lightImpact();
    LogSheets.growth(context);
  }

  void _toast(String msg) {
    final p = context.palette;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.isDark ? p.accentDark : p.ink,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
        content: Text(msg, style: const TextStyle(color: Colors.white)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            final profile = _state.profile;
            final entries = _state.entries;
            final age = _state.ageMonths;
            final leap = profile == null
                ? LeapInfo(inLeap: false)
                : LeapService.instance.current(profile.birthDate);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
                  sliver: SliverList.list(
                    children: [
                      _TopBar(name: _state.babyName),
                      const SizedBox(height: 16),
                      _PredictionCard(state: _state, entries: entries)
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.08, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      if (leap.inLeap || leap.hasUpcoming)
                        _LeapBanner(leap: leap, name: _state.babyName),
                      _SituationLine(
                        text: StatsService.instance
                            .situation(entries, age, _state.babyName),
                      ),
                      const SizedBox(height: 6),
                      _CategoryCard(
                        type: LogType.sleep,
                        subtitle: _sleepSubtitle(),
                        onTap: _tapSleep,
                        running: _state.runningSleep != null,
                      ),
                      const SizedBox(height: 12),
                      _CategoryCard(
                        type: LogType.feed,
                        subtitle: _lastSubtitle(LogType.feed),
                        onTap: _tapFeed,
                        onLongPress: () => LogSheets.feed(context),
                      ),
                      const SizedBox(height: 12),
                      _CategoryCard(
                        type: LogType.diaper,
                        subtitle: _lastSubtitle(LogType.diaper),
                        onTap: _tapDiaper,
                      ),
                      const SizedBox(height: 12),
                      _CategoryCard(
                        type: LogType.growth,
                        subtitle: _growthSubtitle(),
                        onTap: _tapGrowth,
                      ),
                      const SizedBox(height: 16),
                      const DailyActivityCard(),
                      const SizedBox(height: 12),
                      _CalmCard(onTap: () {
                        HapticFeedback.mediumImpact();
                        MomController.trigger(MomState.calm,
                            holdFor: const Duration(seconds: 6));
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const CalmModeScreen()));
                      }),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // Subtitles
  String _sleepSubtitle() {
    if (_state.runningSleep != null) {
      final mins = DateTime.now().difference(_state.runningSleep!.time).inMinutes;
      return 'Sleeping · ${mins}m — tap to end';
    }
    return _lastSubtitle(LogType.sleep);
  }

  String _lastSubtitle(LogType type) {
    final last = _state.lastOf(type);
    if (last == null) return 'Not logged yet';
    final d = DateTime.now().difference(last.time);
    final ago = d.inMinutes < 60
        ? '${d.inMinutes}m ago'
        : (d.inHours < 24 ? '${d.inHours}h ago' : '${d.inDays}d ago');
    return ago;
  }

  String _growthSubtitle() {
    final last = _state.lastOf(LogType.growth);
    if (last == null) return 'Add weight & height';
    final wk = last.details['weightKg'];
    final ht = last.details['heightCm'];
    final parts = <String>[];
    if (wk != null) parts.add('${wk}kg');
    if (ht != null) parts.add('${ht}cm');
    return parts.isEmpty ? 'Logged' : parts.join(' · ');
  }
}

// ===================== widgets =====================
class _TopBar extends StatelessWidget {
  const _TopBar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Row(
      children: [
        Container(
          height: 38,
          width: 38,
          decoration:
              BoxDecoration(color: p.accentContainer, shape: BoxShape.circle),
          child: Icon(Icons.child_care_rounded,
              size: 22, color: p.onAccentContainer),
        ),
        const SizedBox(width: 10),
        Text(name, style: text.titleLarge),
        Icon(Icons.keyboard_arrow_down_rounded, color: p.inkSoft),
        const Spacer(),
        Container(
          height: 40,
          width: 40,
          decoration: BoxDecoration(
              color: p.accentContainer, shape: BoxShape.circle),
          child: Icon(Icons.add_rounded, color: p.onAccentContainer),
        ),
      ],
    );
  }
}

class _PredictionCard extends StatelessWidget {
  const _PredictionCard({required this.state, required this.entries});
  final AppState state;
  final List<LogEntry> entries;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final ready = PredictionService.instance.hasEnough(entries);
    final nap = PredictionService.instance.nextNap(entries);
    final feed = PredictionService.instance.nextFeed(entries);
    final days = PredictionService.instance.daysOfData(entries);

    return SoftCard(
      padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [
                          CategoryColors.sleep,
                          CategoryColors.sleepDark
                        ]),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Text('Mira Predicts',
                          style: text.labelLarge
                              ?.copyWith(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (!ready) ...[
                  Text('Keep logging',
                      style: text.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Log ${(3 - days).clamp(1, 3)} more day(s) and Mira will '
                    'predict ${state.babyName}\u2019s patterns.',
                    style: text.bodyMedium,
                  ),
                ] else ...[
                  Row(
                    children: [
                      _Ring(progress: nap.ready ? nap.progress : 0.0),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nap.ready
                                  ? 'Nap ${nap.etaText}'
                                  : 'Nap window soon',
                              style: text.titleLarge?.copyWith(
                                  color: CategoryColors.sleepDark),
                            ),
                            if (nap.ready)
                              Text('around ${nap.atText}',
                                  style: text.bodyMedium),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (feed.ready) ...[
                    const SizedBox(height: 8),
                    Text('Next feed ${feed.etaText} · ${feed.atText}',
                        style: text.bodyMedium
                            ?.copyWith(color: CategoryColors.feedDark)),
                  ],
                ],
                const SizedBox(height: 10),
                _NapScheduleChips(state: state),
              ],
            ),
          ),
          ValueListenableBuilder<MomState>(
            valueListenable: MomController.state,
            builder: (context, momState, _) => MomCharacter(state: momState),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.progress});
  final double progress;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      width: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 44,
            width: 44,
            child: CircularProgressIndicator(
              value: progress.clamp(0.02, 1.0),
              strokeWidth: 5,
              backgroundColor: CategoryColors.sleepSoft,
              valueColor:
                  const AlwaysStoppedAnimation(CategoryColors.sleep),
            ),
          ),
          const Icon(Icons.bedtime_rounded,
              size: 18, color: CategoryColors.sleepDark),
        ],
      ),
    );
  }
}

class _NapScheduleChips extends StatelessWidget {
  const _NapScheduleChips({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final options = [2, 3, 4];
    return Wrap(
      spacing: 8,
      children: [
        for (final n in options)
          GestureDetector(
            onTap: () => state.setNapSchedule(n),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: state.napSchedule == n
                    ? CategoryColors.sleep
                    : p.accentContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text('$n-nap',
                  style: text.labelLarge?.copyWith(
                      fontSize: 11,
                      color: state.napSchedule == n
                          ? Colors.white
                          : p.inkSoft)),
            ),
          ),
      ],
    );
  }
}

class _LeapBanner extends StatelessWidget {
  const _LeapBanner({required this.leap, required this.name});
  final LeapInfo leap;
  final String name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final title = leap.inLeap
        ? '🧠 $name may be in a developmental leap'
        : '🧠 A leap may start in ${leap.upcomingInDays} day(s)';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SoftCard(
        color: CategoryColors.leapSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: text.titleMedium
                    ?.copyWith(color: const Color(0xFF5E4A86))),
            const SizedBox(height: 4),
            Text(
              leap.description.isEmpty
                  ? 'Extra fussiness is normal during these windows.'
                  : leap.description,
              style: text.bodyMedium?.copyWith(color: const Color(0xFF5E4A86)),
            ),
          ],
        ),
      ),
    );
  }
}

class _SituationLine extends StatelessWidget {
  const _SituationLine({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 10),
      child: Text(text, style: t.bodyMedium),
    );
  }
}

class _CategoryCard extends StatefulWidget {
  const _CategoryCard({
    required this.type,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
    this.running = false,
  });
  final LogType type;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool running;

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            gradient: widget.type.gradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: widget.type.color.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    shape: BoxShape.circle),
                child: Icon(widget.type.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.type.label,
                        style: text.titleLarge?.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: text.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92))),
                  ],
                ),
              ),
              if (widget.running)
                const Icon(Icons.stop_circle_rounded,
                    color: Colors.white, size: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalmCard extends StatelessWidget {
  const _CalmCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration:
                BoxDecoration(color: p.accentContainer, shape: BoxShape.circle),
            child: Icon(Icons.spa_rounded, color: p.onAccentContainer),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tough moment right now?', style: text.titleMedium),
                Text('Open Calm Mode — I\u2019ll walk you through it.',
                    style: text.bodyMedium),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios_rounded, size: 16, color: p.inkFaint),
        ],
      ),
    );
  }
}
