import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

/// Plays the cinematic intro on first launch. If the video can't load (e.g.
/// not yet rendered), it skips straight through so the app never blocks.
class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key, required this.onDone});
  final VoidCallback onDone;

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  VideoPlayerController? _controller;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final c = VideoPlayerController.asset('assets/intro/mira_intro.mp4');
      _controller = c;
      await c.initialize();
      c.addListener(_check);
      await c.play();
      if (mounted) setState(() {});
    } catch (_) {
      _finish();
    }
  }

  void _check() {
    final c = _controller;
    if (c == null) return;
    if (c.value.hasError) {
      _finish();
      return;
    }
    if (c.value.isInitialized &&
        c.value.position >= c.value.duration &&
        c.value.duration > Duration.zero) {
      _finish();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    widget.onDone();
  }

  @override
  void dispose() {
    _controller?.removeListener(_check);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    final ready = c != null && c.value.isInitialized;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (ready)
            FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: c.value.size.width,
                height: c.value.size.height,
                child: VideoPlayer(c),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white24),
            ),
          // Skip button
          Positioned(
            top: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  ),
                  child: const Text('Skip'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
