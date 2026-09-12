import 'package:flutter/material.dart';
import 'theme.dart';

/// Full-screen FORGE splash: animated glyph + gold progress bar,
/// then a short fade into [next]. Native-free, runs on every platform.
class ForgeSplash extends StatefulWidget {
  final Widget next;
  final String title;
  final String tagline;
  const ForgeSplash({
    super.key,
    required this.next,
    required this.title,
    this.tagline = 'Open source • free forever',
  });

  @override
  State<ForgeSplash> createState() => _ForgeSplashState();
}

class _ForgeSplashState extends State<ForgeSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _c.forward();
    Future.delayed(const Duration(milliseconds: 2300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 450),
          pageBuilder: (_, anim, __) => FadeTransition(opacity: anim, child: widget.next),
        ),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ForgeColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            radius: 1.2,
            colors: [Color(0xFF1B2A52), ForgeColors.bg],
            stops: [0.0, 0.62],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) {
                    final scale = Tween(begin: 0.7, end: 1.0).transform(
                      Curves.elasticOut.transform(_c.value),
                    );
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: ForgeColors.line),
                          gradient: ForgeColors.cardGradient,
                          boxShadow: [
                            BoxShadow(color: ForgeColors.cy.withValues(alpha: 0.28), blurRadius: 44),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '◈',
                          style: TextStyle(
                            fontSize: 46,
                            color: ForgeColors.cy,
                            shadows: [
                              Shadow(color: ForgeColors.cy.withValues(alpha: 0.8), blurRadius: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: ForgeColors.txt,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.tagline,
                  style: const TextStyle(color: ForgeColors.mut, fontSize: 13, letterSpacing: 1.2),
                ),
                const SizedBox(height: 28),
                AnimatedBuilder(
                  animation: _c,
                  builder: (_, _) {
                    return Container(
                      width: 120,
                      height: 3,
                      decoration: BoxDecoration(
                        color: ForgeColors.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _c.value.clamp(0.0, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            gradient: ForgeColors.goldGradient,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}