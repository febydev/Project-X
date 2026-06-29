import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/baby_store.dart';
import '../../models/log_entry.dart';
import '../../theme/app_colors.dart';
import '../../widgets/soft_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BabyStore _store = BabyStore.instance;

  void _log(LogType type) {
    HapticFeedback.lightImpact();
    _store.add(type);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.ink,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.all(16),
          content: Text('${type.label} logged · just now'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedBuilder(
          animation: _store,
          builder: (context, _) {
            final today = _store.today;
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                    child: _Greeting(name: _store.babyName),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: _StatusHero(lastSleep: _store.lastSleep),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: _QuickLogRow(onLog: _log),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                    child: const _MiraTipCard(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
                    child: Text(
                      'Today',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ),
                if (today.isEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      child: const _EmptyTimeline(),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                    sliver: SliverList.separated(
                      itemCount: today.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, i) =>
                          _TimelineTile(entry: today[i]),
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
  const _Greeting({required this.name});
  final String name;

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
        Container(
          height: 46,
          width: 46,
          decoration: const BoxDecoration(
            color: AppColors.sageContainer,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.spa_rounded, color: AppColors.sageDark),
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
    final hasData = lastSleep != null;
    final headline = hasData
        ? 'Awake for ${_agoLabel(lastSleep!.time).replaceAll(' ago', '')}'
        : 'Welcome to Mira';
    final sub = hasData
        ? 'Last sleep ended ${_agoLabel(lastSleep!.time)}'
        : 'Log your first moment below to begin.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.sage, AppColors.sageDark],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2A4E6E5D),
            blurRadius: 30,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
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
                  color: widget.type.softColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.type.icon,
                    color: widget.type.color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(widget.type.label,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiraTipCard extends StatelessWidget {
  const _MiraTipCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      color: AppColors.apricotSoft,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded,
                color: AppColors.apricot, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('A note from Mira',
                    style: text.titleMedium
                        ?.copyWith(color: AppColors.sageDark)),
                const SizedBox(height: 4),
                Text(
                  'Short, frequent naps can be a sign of an overtired baby. '
                  'An earlier wind-down often leads to deeper rest.',
                  style: text.bodyMedium?.copyWith(color: AppColors.ink),
                ),
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
          const Icon(Icons.nightlight_round, color: AppColors.inkFaint, size: 30),
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
  const _TimelineTile({required this.entry});
  final LogEntry entry;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: entry.type.softColor,
              shape: BoxShape.circle,
            ),
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
