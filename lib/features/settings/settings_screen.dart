import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../theme/app_colors.dart';
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
    if (result != null) {
      await _state.setProxyUrl(result);
    }
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

  void _pickAccent(int i) {
    if (i != 0 && !_state.premium) {
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }
    HapticFeedback.selectionClick();
    _state.setAccent(i);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
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
                        decoration: const BoxDecoration(
                            color: AppColors.sageContainer,
                            shape: BoxShape.circle),
                        child: const Icon(Icons.child_care_rounded,
                            color: AppColors.sageDark),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile?.name ?? 'Your baby',
                                style: text.titleLarge),
                            Text(profile?.ageLabel ?? '',
                                style: text.bodyMedium),
                          ],
                        ),
                      ),
                      const Icon(Icons.edit_rounded,
                          size: 18, color: AppColors.inkSoft),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Premium status
                if (!_state.premium)
                  _PremiumBanner(onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const PaywallScreen()));
                  })
                else
                  SoftCard(
                    color: AppColors.sageContainer,
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: AppColors.sageDark),
                        const SizedBox(width: 12),
                        Text('Mira Premium is active',
                            style: text.titleMedium
                                ?.copyWith(color: AppColors.sageDark)),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),

                // Themes
                Text('Theme', style: text.titleLarge),
                const SizedBox(height: 12),
                SoftCard(
                  child: Wrap(
                    spacing: 14,
                    runSpacing: 14,
                    children: [
                      for (int i = 0; i < AppColors.accents.length; i++)
                        _AccentDot(
                          accent: AppColors.accents[i],
                          selected: _state.accent == i,
                          locked: i != 0 && !_state.premium,
                          onTap: () => _pickAccent(i),
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
                      const Icon(Icons.cable_rounded, color: AppColors.sageDark),
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
                                    ? AppColors.apricot
                                    : AppColors.sage,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.inkSoft),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SoftCard(
                  child: Row(
                    children: [
                      const Icon(Icons.insights_rounded,
                          color: AppColors.sageDark),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Let Mira read my logs', style: text.titleMedium),
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
                SoftCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.lock_outline_rounded,
                              color: AppColors.sageDark, size: 20),
                          SizedBox(width: 10),
                          Text('Private by design'),
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
                            fontStyle: FontStyle.italic,
                            color: AppColors.inkFaint),
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
                            Text('Test: unlock Premium', style: text.titleMedium),
                            Text('Temporary switch until billing is added.',
                                style: text.bodyMedium),
                          ],
                        ),
                      ),
                      Switch(
                        value: _state.premium,
                        onChanged: (v) => _state.setPremium(v),
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
                Text('Unlock Mira Premium', style: text.titleMedium),
                Text('Unlimited chat, Calm Mode, reports & themes.',
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

class _AccentDot extends StatelessWidget {
  const _AccentDot({
    required this.accent,
    required this.selected,
    required this.locked,
    required this.onTap,
  });
  final AccentTheme accent;
  final bool selected;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: accent.color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.ink : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: locked
                ? const Icon(Icons.lock_rounded, color: Colors.white, size: 18)
                : (selected
                    ? const Icon(Icons.check_rounded, color: Colors.white)
                    : null),
          ),
          const SizedBox(height: 6),
          Text(accent.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400)),
        ],
      ),
    );
  }
}
