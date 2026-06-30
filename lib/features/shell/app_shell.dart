import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/mira_palette.dart';
import '../../widgets/animated_background.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/mom_popup_host.dart';
import '../chat/chat_screen.dart';
import '../home/home_screen.dart';
import '../settings/settings_screen.dart';
import '../timeline/timeline_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  static const _tabs = [
    _TabDef('Home', Icons.cottage_rounded),
    _TabDef('Timeline', Icons.timeline_rounded),
    _TabDef('Mira', Icons.auto_awesome_rounded),
    _TabDef('Settings', Icons.tune_rounded),
  ];

  final _screens = const [
    HomeScreen(),
    TimelineScreen(),
    ChatScreen(),
    SettingsScreen(),
  ];

  void _select(int i) {
    if (i == _index) return;
    HapticFeedback.selectionClick();
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          IndexedStack(index: _index, children: _screens),
          const MomPopupHost(),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.fromLTRB(
            20, 0, 20, 14 + MediaQuery.of(context).padding.bottom),
        child: GlassContainer(
          radius: 26,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (int i = 0; i < _tabs.length; i++)
                _NavItem(
                  def: _tabs[i],
                  selected: _index == i,
                  onTap: () => _select(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabDef {
  const _TabDef(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.def,
    required this.selected,
    required this.onTap,
  });

  final _TabDef def;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final faint = context.palette.inkFaint;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: selected
                ? primary.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                def.icon,
                size: 24,
                color: selected ? primary : faint,
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? primary : faint,
                ),
                child: Text(def.label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
