import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../data/app_state.dart';
import '../../models/baby_profile.dart';
import '../../theme/app_colors.dart';
import '../../widgets/mira_logo.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/soft_card.dart';
import '../shell/app_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  DateTime? _birthDate;
  bool _consent = true;

  bool get _valid =>
      _nameController.text.trim().isNotEmpty && _birthDate != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? now,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
      helpText: 'When was your little one born?',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _finish() async {
    await AppState.instance.saveProfile(
      BabyProfile(name: _nameController.text.trim(), birthDate: _birthDate!),
    );
    await AppState.instance.setAiConsent(_consent);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, a, __) => FadeTransition(
          opacity: a,
          child: const AppShell(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(child: MiraLogo(size: 84))
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOut),
              const SizedBox(height: 28),
              Text('Welcome to Mira', style: text.displaySmall)
                  .animate(delay: 200.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 8),
              Text(
                'A calm companion for the beautiful, exhausting first years. '
                'Let\u2019s start with your little one.',
                style: text.bodyLarge?.copyWith(color: AppColors.inkSoft),
              )
                  .animate(delay: 350.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 36),
              _Field(
                label: 'Their name',
                child: TextField(
                  controller: _nameController,
                  onChanged: (_) => setState(() {}),
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Mia',
                    border: InputBorder.none,
                  ),
                  style: text.titleLarge,
                ),
              )
                  .animate(delay: 500.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: _pickDate,
                child: _Field(
                  label: 'Date of birth',
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _birthDate == null
                              ? 'Tap to choose'
                              : '${_birthDate!.day}/${_birthDate!.month}/${_birthDate!.year}',
                          style: text.titleLarge?.copyWith(
                            color: _birthDate == null
                                ? AppColors.inkFaint
                                : AppColors.ink,
                          ),
                        ),
                      ),
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.inkSoft, size: 20),
                    ],
                  ),
                ),
              )
                  .animate(delay: 650.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 14),
              SoftCard(
                padding: const EdgeInsets.fromLTRB(18, 8, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Let Mira understand your situation',
                              style: text.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            'Mira can read your logs to give advice tailored to '
                            'your baby. It stays on your phone and is only used to '
                            'answer you — never sold or shared.',
                            style: text.bodyMedium
                                ?.copyWith(color: AppColors.inkSoft),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _consent,
                      onChanged: (v) => setState(() => _consent = v),
                    ),
                  ],
                ),
              )
                  .animate(delay: 750.ms)
                  .fadeIn(duration: 500.ms)
                  .slideY(begin: 0.2, curve: Curves.easeOut),
              const SizedBox(height: 30),
              PrimaryButton(
                label: 'Begin',
                icon: Icons.arrow_forward_rounded,
                onPressed: _valid ? _finish : null,
              ).animate(delay: 850.ms).fadeIn(duration: 500.ms),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  'Everything stays private on your phone.',
                  style: text.bodyMedium?.copyWith(color: AppColors.inkFaint),
                ),
              ).animate(delay: 950.ms).fadeIn(duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SoftCard(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: text.labelLarge?.copyWith(
                  color: AppColors.inkFaint, fontSize: 11, letterSpacing: 1)),
          const SizedBox(height: 2),
          child,
        ],
      ),
    );
  }
}
