import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/app_state.dart';
import '../../theme/app_theme.dart';
import '../../theme/mira_palette.dart';
import '../../widgets/mira_logo.dart';
import '../../widgets/primary_button.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _plan = 1; // 0 monthly, 1 yearly

  static const _features = [
    ('Unlimited chats with Mira', Icons.auto_awesome_rounded),
    ('Calm Mode for tough moments', Icons.spa_rounded),
    ('Pediatrician PDF reports', Icons.picture_as_pdf_rounded),
    ('Full history & insights', Icons.timeline_rounded),
    ('Beautiful themes', Icons.palette_rounded),
  ];

  void _subscribe() {
    AppState.instance.setPremium(true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final gradient = Theme.of(context).extension<AppGradient>()!.linear;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                children: [
                  const Center(child: MiraLogo(size: 72))
                      .animate()
                      .fadeIn()
                      .scale(begin: const Offset(0.85, 0.85)),
                  const SizedBox(height: 22),
                  Text('Mira Premium',
                      textAlign: TextAlign.center, style: text.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Peace of mind, whenever you need it.',
                    textAlign: TextAlign.center,
                    style: text.bodyLarge?.copyWith(color: p.inkSoft),
                  ),
                  const SizedBox(height: 28),
                  ..._features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          children: [
                            Container(
                              height: 38,
                              width: 38,
                              decoration: BoxDecoration(
                                  color: p.accentContainer,
                                  shape: BoxShape.circle),
                              child: Icon(f.$2,
                                  color: p.onAccentContainer, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                                child: Text(f.$1, style: text.titleMedium)),
                            Icon(Icons.check_rounded, color: p.accent),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  _PlanTile(
                    title: 'Yearly',
                    price: '\$39.99 / year',
                    subtitle: 'Best value · about \$3.33/mo',
                    selected: _plan == 1,
                    badge: 'Save 44%',
                    gradient: gradient,
                    onTap: () => setState(() => _plan = 1),
                  ),
                  const SizedBox(height: 12),
                  _PlanTile(
                    title: 'Monthly',
                    price: '\$5.99 / month',
                    subtitle: '7-day free trial',
                    selected: _plan == 0,
                    gradient: gradient,
                    onTap: () => setState(() => _plan = 0),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
              child: PrimaryButton(label: 'Start free trial', onPressed: _subscribe),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Cancel anytime · Prices vary by region',
                style: text.bodyMedium?.copyWith(color: p.inkFaint),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.selected,
    required this.gradient,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String subtitle;
  final bool selected;
  final LinearGradient gradient;
  final VoidCallback onTap;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? primary : p.hairline,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? primary : p.inkFaint,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(title, style: text.titleLarge),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                              gradient: gradient,
                              borderRadius: BorderRadius.circular(40)),
                          child: Text(badge!,
                              style: text.labelLarge?.copyWith(
                                  color: Colors.white, fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                  Text(subtitle, style: text.bodyMedium),
                ],
              ),
            ),
            Text(price,
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
