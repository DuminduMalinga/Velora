import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/velora_logo.dart';
import 'welcome_screen.dart';

/// A finite brand animation, never a gate on network availability.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.homeBuilder});
  final WidgetBuilder homeBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  )..addStatusListener(_statusChanged);
  bool _started = false;
  bool _leaving = false;

  CurvedAnimation _interval(double start, double end) => CurvedAnimation(
    parent: _controller,
    curve: Interval(start, end, curve: Curves.easeOutCubic),
  );
  late final _logo = _interval(0, .5);
  late final _name = _interval(.22, .65);
  late final _tagline = _interval(.4, .8);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.value = 1;
    } else if (!_started) {
      _controller.forward();
    }
    _started = true;
  }

  void _statusChanged(AnimationStatus status) {
    if (status != AnimationStatus.completed || _leaving) return;
    _leaving = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement<void, void>(
        veloraRoute(
          WelcomeScreen(homeBuilder: widget.homeBuilder),
          reducedMotion: MediaQuery.disableAnimationsOf(context),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logo.dispose();
    _name.dispose();
    _tagline.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: const Color(0xFF0B1020),
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -.2),
            radius: .8,
            colors: [Color(0xFF142B55), Color(0xFF0B1020)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _logo,
                          builder: (context, child) => Opacity(
                            opacity: _logo.value,
                            child: Transform.rotate(
                              angle: -.07 * (1 - _logo.value),
                              child: Transform.scale(
                                scale: .82 + .18 * _logo.value,
                                child: child,
                              ),
                            ),
                          ),
                          child: const VeloraLogo(size: 152),
                        ),
                        const SizedBox(height: 30),
                        FadeTransition(
                          opacity: _name,
                          child: const Text(
                            'Velora',
                            style: TextStyle(
                              color: Color(0xFFF8FAFC),
                              fontSize: 48,
                              fontWeight: FontWeight.w600,
                              letterSpacing: -2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        FadeTransition(
                          opacity: _tagline,
                          child: const Text(
                            'Discover More. Shop Better.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
                child: Column(
                  children: [
                    SizedBox(
                      width: 48,
                      child: AnimatedBuilder(
                        animation: _controller,
                        builder: (_, _) => LinearProgressIndicator(
                          value: _controller.value,
                          minHeight: 2,
                          borderRadius: BorderRadius.circular(2),
                          color: const Color(0xFF3B82F6),
                          backgroundColor: const Color(0xFF1E2D48),
                          semanticsLabel: 'Opening Velora',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'A LITTLE DISCOVERY. A LOT TO LOVE.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 9,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
