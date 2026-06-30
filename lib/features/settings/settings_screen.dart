import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../theme/app_colors.dart';
import '../../theme/mira_palette.dart';
import '../../widgets/soft_card.dart';
import '../paywall/paywall_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppState _state = AppState.instance;

  Future<void> _editProxy() async {
    final controller = TextEditingController(text: _state.proxyUrl);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('AI connection'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Paste your Cloudflare Worker URL. This is how Mira reaches the '
              'AI without ever shipping a key in the app.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'https://mira-proxy.you.workers.dev',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null) await _state.setProxyUrl(result);
  }

  Future<void> _editProfile() async {
    final profile = _state.profile;
    if (profile == null) return;
    final controller = TextEditingController(text: profile.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save')),
        ],
      ),
    );
    if (result != null && result.trim().isNotEmpty) {
      await _state.saveProfile(profile.copyWith(name: result.trim()));
    }
  }

  void _pickTheme(int i) {
    if (i != 0 && !_state.premium) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    HapticFeedback.selectionClick();
    _state.setAccent(i);
  }

  void _partner() {
    if (!_state.premium) {
      PaywallScreen.softShow(context, 'Partner & caregiver sync');
      return;
    }
    final existing = _state.partnerCode;
    final code = (existing != null && existing.isNotEmpty)
        ? existing
        : (100000 + Random().nextInt(900000)).toString();
    if (existing == null || existing.isEmpty) {
      _state.setPartner(_state.partnerName ?? 'Partner', code);
    }
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Partner & caregivers'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Share this code with your partner so you both see the same '
              'baby and logs:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 14),
            SelectableText(
              code,
              style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800, letterSpacing: 6),
            ),
            const SizedBox(height: 14),
            const Text(
              'Real-time sync activates once Firebase is connected (one-time '
              'setup — see PARTNER_SYNC.md). Until then this code is saved and '
              'everything stays on your phone.',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Done')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            final profile = _state.profile;
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              children: [
                Text('Settings', style: text.displaySmall),
                const SizedBox(height: 20),

                // Profile
                SoftCard(
                  onTap: _editProfile,
                  child: Row(
                    children: [
                      Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                            color: p.accentContainer, shape: BoxShape.circle),
                        child: Icon(Icons.child_care_rounded,
                            color: p.onAccentContainer),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile?.name ?? 'Your baby',
                                style: text.titleLarge),
                            Text(profile?.ageLabel ?? '', style: text.bodyMedium),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_rounded, size: 18, color: p.inkSoft),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                if (!_state.premium)
                  _PremiumBanner(onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PaywallScreen()));
                  })
                else
                  SoftCard(
                    color: p.accentContainer,
                    child: Row(
                      children: [
                        Icon(Icons.verified_rounded,
                            color: p.onAccentContainer),
                        const SizedBox(width: 12),
                        Text('Mira Premium is active',
                            style: text.titleMedium
                                ?.copyWith(color: p.onAccentContainer)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Themes
                Text('Theme', style: text.titleLarge),
                const SizedBox(height: 12),
                SoftCard(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      for (int i = 0; i < MiraPalette.all.length; i++)
                        _ThemeDot(
                          palette: MiraPalette.all[i],
                          selected: _state.accent == i,
                          locked: i != 0 && !_state.premium,
                          onTap: () => _pickTheme(i),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // AI connection
                Text('Mira AI', style: text.titleLarge),
                const SizedBox(height: 12),
                SoftCard(
                  onTap: _editProxy,
                  child: Row(
                    children: [
                      Icon(Icons.cable_rounded, color: p.onAccentContainer),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI connection', style: text.titleMedium),
                            Text(
                              _state.proxyUrl.isEmpty
                                  ? 'Not connected — tap to set up'
                                  : 'Connected',
                              style: text.bodyMedium?.copyWith(
                                color: _state.proxyUrl.isEmpty
                                    ? const Color(0xFFD08A4E)
                                    : p.accent,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.inkSoft),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  child: Row(
                    children: [
                      Icon(Icons.insights_rounded, color: p.onAccentContainer),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Let Mira read my logs',
                                style: text.titleMedium),
                            Text(
                                'Gives advice tailored to your baby\u2019s real day.',
                                style: text.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                        value: _state.aiConsent,
                        onChanged: (v) => _state.setAiConsent(v),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Partner sync
                Text('Family', style: text.titleLarge),
                const SizedBox(height: 12),
                SoftCard(
                  onTap: _partner,
                  child: Row(
                    children: [
                      Icon(Icons.group_add_rounded, color: p.onAccentContainer),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Add a partner / caregiver',
                                style: text.titleMedium),
                            Text('Share logs with another phone.',
                                style: text.bodyMedium),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.inkSoft),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // About / privacy
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.lock_outline_rounded,
                              color: p.onAccentContainer, size: 20),
                          const SizedBox(width: 10),
                          const Text('Private by design'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your logs and your baby\u2019s details stay on this phone. '
                        'Only the questions you ask Mira are sent to the AI — never your logs.',
                        style: text.bodyMedium,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Mira offers general guidance, not medical advice. '
                        'Always consult your pediatrician for health concerns.',
                        style: text.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic, color: p.inkFaint),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Dev toggle (until real billing is wired in)
                SoftCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Test: unlock Premium',
                                style: text.titleMedium),
                            Text('Temporary switch until billing is added.',
                                style: text.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                          value: _state.premium,
                          onChanged: (v) => _state.setPremium(v)),
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

class _PremiumBanner extends StatelessWidget {
  const _PremiumBanner({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      onTap: onTap,
      color: AppColors.apricotSoft,
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.7),
                shape: BoxShape.circle),
            child: const Icon(Icons.workspace_premium_rounded,
                color: AppColors.apricot),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Unlock Mira Premium',
                    style: text.titleMedium
                        ?.copyWith(color: const Color(0xFF3A2E26))),
                Text('Unlimited chat, Calm Mode, reports & themes.',
                    style: text.bodyMedium
                        ?.copyWith(color: const Color(0xFF6E5C4A))),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded,
              size: 16, color: Color(0xFF6E5C4A)),
        ],
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({
    required this.palette,
    required this.selected,
    required this.locked,
    required this.onTap,
  });
  final MiraPalette palette;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              gradient: palette.gradient,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? p.ink : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: locked
                ? const Icon(Icons.lock_rounded, color: Colors.white, size: 18)
                : (selected
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null),
          ),
          const SizedBox(height: 6),
          Text(palette.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}
