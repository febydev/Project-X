import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/app_state.dart';
import '../../models/log_entry.dart';
import '../../services/tips_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_theme.dart';
import '../../widgets/soft_card.dart';
import '../calm/calm_mode_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AppState _state = AppState.instance;

  void _log(LogType type) {
    HapticFeedback.lightImpact();
    _state.addLog(type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 90),
          content: Text('${type.label} logged · just now'),
        ),
      );
  }

  void _openCalm() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CalmModeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            final today = _state.today;
            final profile = _state.profile;
            final ageMonths = profile?.ageInMonths ?? 0;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverList.list(
                    children: [
                      _Greeting(
                        name: _state.babyName,
                        ageLabel: profile?.ageLabel,
                      ),
                      const SizedBox(height: 20),
                      _StatusHero(lastSleep: _state.lastOf(LogType.sleep))
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.1, curve: Curves.easeOut),
                      const SizedBox(height: 14),
                      _CalmCard(onTap: _openCalm)
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 18),
                      _QuickLogRow(onLog: _log)
                          .animate(delay: 150.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 18),
                      _MiraTipCard(tip: TipsService.instance.tipForAge(ageMonths))
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 400.ms),
                      const SizedBox(height: 26),
                      Text('Today',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (today.isEmpty)
                        const _EmptyTimeline()
                      else
                        ...today.take(6).map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _TimelineTile(
                                  entry: e,
                                  onDelete: () => _state.removeLog(e),
                                ),
                              ),
                            ),
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
}

String _greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 5) return 'Still up';
  if (h < 12) return 'Good morning';
  if (h < 17) return 'Good afternoon';
  if (h < 21) return 'Good evening';
  return 'Winding down';
}

String _agoLabel(DateTime time) {
  final d = DateTime.now().difference(time);
  if (d.inMinutes < 1) return 'just now';
  if (d.inMinutes < 60) return '${d.inMinutes}m ago';
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h < 24) return m == 0 ? '${h}h ago' : '${h}h ${m}m ago';
  return '${d.inDays}d ago';
}

String _clock(DateTime t) {
  final hour = t.hour % 12 == 0 ? 12 : t.hour % 12;
  final min = t.minute.toString().padLeft(2, '0');
  final ampm = t.hour < 12 ? 'AM' : 'PM';
  return '$hour:$min $ampm';
}

class _Greeting extends StatelessWidget {
  const _Greeting({required this.name, this.ageLabel});
  final String name;
  final String? ageLabel;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greetingForNow(),
                  style: text.bodyMedium?.copyWith(color: AppColors.inkSoft)),
              const SizedBox(height: 2),
              Text('How is $name?', style: text.headlineMedium),
            ],
          ),
        ),
        if (ageLabel != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.sageContainer,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Text(ageLabel!,
                style: text.labelLarge?.copyWith(color: AppColors.sageDark)),
          ),
      ],
    );
  }
}

class _StatusHero extends StatelessWidget {
  const _StatusHero({required this.lastSleep});
  final LogEntry? lastSleep;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final gradient = Theme.of(context).extension<AppGradient>()!.linear;
    final hasData = lastSleep != null;
    final headline = hasData
        ? 'Awake ${_agoLabel(lastSleep!.time).replaceAll(' ago', '')}'
        : 'Welcome to Mira';
    final sub = hasData
        ? 'Last sleep ended ${_agoLabel(lastSleep!.time)}'
        : 'Log your first moment below to begin.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: gradient,
        boxShadow: const [
          BoxShadow(
              color: Color(0x2A000000), blurRadius: 28, offset: Offset(0, 14)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(40),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_twilight_rounded,
                    color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text('Right now',
                    style: text.labelLarge?.copyWith(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(headline,
              style: text.displaySmall?.copyWith(color: Colors.white)),
          const SizedBox(height: 6),
          Text(sub,
              style: text.bodyMedium
                  ?.copyWith(color: Colors.white.withValues(alpha: 0.85))),
        ],
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
    return SoftCard(
      onTap: onTap,
      color: AppColors.apricotSoft,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.spa_rounded, color: AppColors.apricot),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tough moment right now?',
                    style: text.titleMedium?.copyWith(color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('Open Calm Mode — I\u2019ll walk you through it.',
                    style: text.bodyMedium),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: AppColors.inkSoft),
        ],
      ),
    );
  }
}

class _QuickLogRow extends StatelessWidget {
  const _QuickLogRow({required this.onLog});
  final void Function(LogType) onLog;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final type in LogType.values) ...[
          Expanded(child: _QuickLogButton(type: type, onTap: () => onLog(type))),
          if (type != LogType.values.last) const SizedBox(width: 12),
        ],
      ],
    );
  }
}

class _QuickLogButton extends StatefulWidget {
  const _QuickLogButton({required this.type, required this.onTap});
  final LogType type;
  final VoidCallback onTap;

  @override
  State<_QuickLogButton> createState() => _QuickLogButtonState();
}

class _QuickLogButtonState extends State<_QuickLogButton> {
  double _scale = 1;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) => setState(() => _scale = 1),
      onTapCancel: () => setState(() => _scale = 1),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: SoftCard(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Container(
                height: 52,
                width: 52,
                decoration: BoxDecoration(
                    color: widget.type.softColor, shape: BoxShape.circle),
                child:
                    Icon(widget.type.icon, color: widget.type.color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(widget.type.label,
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiraTipCard extends StatelessWidget {
  const _MiraTipCard({required this.tip});
  final String tip;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: const BoxDecoration(
                color: AppColors.sageContainer, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.sageDark, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A note from Mira', style: text.titleMedium),
                const SizedBox(height: 4),
                Text(tip, style: text.bodyMedium?.copyWith(color: AppColors.ink)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTimeline extends StatelessWidget {
  const _EmptyTimeline();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        children: [
          const Icon(Icons.nightlight_round,
              color: AppColors.inkFaint, size: 30),
          const SizedBox(height: 12),
          Text('Nothing logged yet today',
              style: text.titleMedium?.copyWith(color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text('Tap Feed, Sleep or Diaper to start.',
              style: text.bodyMedium, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.entry, this.onDelete});
  final LogEntry entry;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      onTap: onDelete == null
          ? null
          : () => showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => _DeleteSheet(entry: entry, onDelete: onDelete!),
              ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
                color: entry.type.softColor, shape: BoxShape.circle),
            child: Icon(entry.type.icon, color: entry.type.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.type.label, style: text.titleMedium),
                const SizedBox(height: 2),
                Text(_agoLabel(entry.time), style: text.bodyMedium),
              ],
            ),
          ),
          Text(_clock(entry.time),
              style: text.bodyMedium?.copyWith(color: AppColors.inkFaint)),
        ],
      ),
    );
  }
}

class _DeleteSheet extends StatelessWidget {
  const _DeleteSheet({required this.entry, required this.onDelete});
  final LogEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SoftCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${entry.type.label} · ${_clock(entry.time)}',
                  style: text.titleMedium),
              const SizedBox(height: 16),
              ListTile(
                onTap: () {
                  onDelete();
                  Navigator.pop(context);
                },
                leading: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                title: const Text('Delete this entry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
