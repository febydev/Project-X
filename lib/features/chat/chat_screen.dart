import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/app_state.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/speech_service.dart';
import '../../theme/app_theme.dart';
import '../../theme/mira_palette.dart';
import '../paywall/paywall_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final AppState _state = AppState.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  bool _listening = false;

  static const _suggestions = [
    'My baby won\u2019t stop crying',
    'Help with bedtime',
    'Is this normal for their age?',
    'They keep hitting — what do I do?',
  ];

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send([String? preset]) async {
    final txt = (preset ?? _controller.text).trim();
    if (txt.isEmpty || _sending) return;
    if (!_state.canSendMessage()) {
      _openPaywall();
      return;
    }
    HapticFeedback.lightImpact();
    _controller.clear();
    await _state.addChatMessage(ChatMessage(text: txt, fromMira: false));
    await _state.recordMessageSent();
    _scrollToEnd();

    setState(() => _sending = true);
    final profile = _state.profile;
    final result = await AiService.instance.send(
      proxyUrl: _state.proxyUrl,
      history: _state.chat,
      babyName: profile?.name ?? 'the baby',
      ageMonths: profile?.ageInMonths ?? 0,
      context: _state.aiConsent ? _state.buildAiContext() : null,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    await _state.addChatMessage(ChatMessage(
      text:
          result.ok ? result.reply! : (result.error ?? 'Something went wrong.'),
      fromMira: true,
    ));
    _scrollToEnd();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await SpeechService.instance.stop();
      setState(() => _listening = false);
      return;
    }
    HapticFeedback.mediumImpact();
    final ok = await SpeechService.instance.start(
      onResult: (text, isFinal) {
        setState(() => _controller.text = text);
        if (isFinal) setState(() => _listening = false);
      },
    );
    if (ok) {
      setState(() => _listening = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone unavailable.')),
      );
    }
  }

  void _openPaywall() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _state,
          builder: (context, _) {
            final messages = _state.chat;
            return Column(
              children: [
                _Header(
                    remaining:
                        _state.premium ? null : _state.remainingFreeMessages),
                Expanded(
                  child: messages.isEmpty
                      ? _Welcome(onPick: _send)
                      : ListView.builder(
                          controller: _scroll,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          itemCount: messages.length + (_sending ? 1 : 0),
                          itemBuilder: (context, i) {
                            if (i >= messages.length) {
                              return const _TypingBubble();
                            }
                            return _Bubble(message: messages[i]);
                          },
                        ),
                ),
                _InputBar(
                  controller: _controller,
                  listening: _listening,
                  sending: _sending,
                  onSend: () => _send(),
                  onMic: _toggleMic,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({this.remaining});
  final int? remaining;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Mira', style: text.displaySmall),
                Text('Calm, judgement-free guidance.', style: text.bodyMedium),
              ],
            ),
          ),
          if (remaining != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: p.accentContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text('$remaining left today',
                  style: text.labelLarge
                      ?.copyWith(color: p.onAccentContainer, fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _Welcome extends StatelessWidget {
  const _Welcome({required this.onPick});
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      children: [
        const SizedBox(height: 20),
        Container(
          height: 64,
          width: 64,
          decoration:
              BoxDecoration(color: p.accentContainer, shape: BoxShape.circle),
          child: Icon(Icons.auto_awesome_rounded,
              color: p.onAccentContainer, size: 30),
        ),
        const SizedBox(height: 18),
        Text('How can I help right now?', style: text.headlineSmall),
        const SizedBox(height: 6),
        Text(
          'Ask me anything about the tough moments — crying, sleep, big feelings. '
          'I keep it short, kind and practical.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 24),
        for (final s in _ChatScreenState._suggestions)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SuggestionChip(label: s, onTap: () => onPick(s)),
          ),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: p.hairline),
        ),
        child: Row(
          children: [
            Expanded(child: Text(label, style: text.titleMedium)),
            Icon(Icons.north_east_rounded, size: 16, color: p.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final p = context.palette;
    final fromMira = message.fromMira;
    final gradient = Theme.of(context).extension<AppGradient>()!.linear;
    return Align(
      alignment: fromMira ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        decoration: BoxDecoration(
          color: fromMira ? p.card : null,
          gradient: fromMira ? null : gradient,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(fromMira ? 4 : 20),
            bottomRight: Radius.circular(fromMira ? 20 : 4),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? 0.3 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Text(
          message.text,
          style: text.bodyLarge?.copyWith(
            color: fromMira ? p.ink : Colors.white,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: p.isDark ? 0.3 : 0.06),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: const SizedBox(height: 10, width: 40, child: _Dots()),
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  const _Dots();
  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = context.palette.inkFaint;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(3, (i) {
            final t = (_c.value + i * 0.2) % 1.0;
            final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
            return Transform.scale(
              scale: scale,
              child: Container(
                height: 8,
                width: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          }),
        );
      },
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.listening,
    required this.sending,
    required this.onSend,
    required this.onMic,
  });

  final TextEditingController controller;
  final bool listening;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onMic;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final primary = Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      decoration: BoxDecoration(
        color: p.background,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: p.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: listening ? primary : p.hairline,
                  width: listening ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: listening ? 'Listening…' : 'Message Mira…',
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                  IconButton(
                    onPressed: onMic,
                    icon: Icon(
                      listening ? Icons.stop_rounded : Icons.mic_rounded,
                      color: listening ? primary : p.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: sending ? null : onSend,
            child: Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(color: primary, shape: BoxShape.circle),
              child:
                  const Icon(Icons.arrow_upward_rounded, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
