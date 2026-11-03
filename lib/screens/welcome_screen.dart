import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/velora_logo.dart';
import '../widgets/welcome_illustration.dart';

PageRouteBuilder<void> veloraRoute(Widget page, {bool reducedMotion = false}) =>
    PageRouteBuilder<void>(
      transitionDuration: Duration(milliseconds: reducedMotion ? 0 : 650),
      reverseTransitionDuration: Duration(
        milliseconds: reducedMotion ? 0 : 350,
      ),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation.drive(CurveTween(curve: Curves.easeInOut)),
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, .025),
            end: Offset.zero,
          ).animate(animation.drive(CurveTween(curve: Curves.easeOutCubic))),
          child: child,
        ),
      ),
    );

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, required this.homeBuilder});
  final WidgetBuilder homeBuilder;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with TickerProviderStateMixin {
  late final _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final _floating = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  );
  late final _reveal = CurvedAnimation(
    parent: _entrance,
    curve: Curves.easeOutCubic,
  );
  bool _started = false;
  bool _opening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
      _floating.stop();
      _floating.value = 0;
    } else {
      if (!_started) _entrance.forward();
      if (!_floating.isAnimating) _floating.repeat();
    }
    _started = true;
  }

  @override
  void dispose() {
    _reveal.dispose();
    _entrance.dispose();
    _floating.dispose();
    super.dispose();
  }

  void _startShopping() {
    if (_opening) return;
    setState(() => _opening = true);
    Navigator.of(context).pushReplacement<void, void>(
      veloraRoute(
        widget.homeBuilder(context),
        reducedMotion: MediaQuery.disableAnimationsOf(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final foreground = dark ? const Color(0xFFF8FAFC) : const Color(0xFF111B35);
    final muted = dark ? const Color(0xFF94A3B8) : const Color(0xFF586982);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dark
            ? const Color(0xFF0B1020)
            : theme.scaffoldBackgroundColor,
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(.5, -.45),
              radius: 1.1,
              colors: dark
                  ? [const Color(0xFF142746), const Color(0xFF0B1020)]
                  : [const Color(0xFFE2ECFF), theme.scaffoldBackgroundColor],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;
                final padding = constraints.maxWidth < 380 ? 24.0 : 32.0;
                final illustrationHeight = wide
                    ? 480.0
                    : (constraints.maxHeight * .31).clamp(180.0, 320.0);
                final content = Column(
                  crossAxisAlignment: wide
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'A WORLD OF FINDS, CURATED FOR YOU',
                      textAlign: wide ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: dark
                            ? const Color(0xFF8AB8FF)
                            : theme.colorScheme.primary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Your Next Favorite,\nJust a Tap Away.',
                      textAlign: wide ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: wide ? 48 : 34,
                        height: 1.15,
                        letterSpacing: -1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: Text(
                        'Explore a world of exciting finds, discover your favorites, and enjoy a smarter shopping experience with Velora.',
                        textAlign: wide ? TextAlign.left : TextAlign.center,
                        style: TextStyle(
                          color: muted,
                          fontSize: 14,
                          height: 1.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),
                    Container(
                      width: 24,
                      height: 2,
                      color: const Color(0xFF3B82F6),
                    ),
                    const SizedBox(height: 18),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Great finds.',
                            style: TextStyle(
                              color: dark
                                  ? const Color(0xFF8AB8FF)
                                  : theme.colorScheme.primary,
                            ),
                          ),
                          const TextSpan(
                            text: ' Beautiful moments.\nAll in one place.',
                          ),
                        ],
                      ),
                      textAlign: wide ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: foreground,
                        fontSize: 16,
                        height: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 390),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _opening ? null : _startShopping,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: const Color(0xFF3B82F6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 19,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  'Start Shopping',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Discover your style with Velora',
                      textAlign: wide ? TextAlign.left : TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                        letterSpacing: .3,
                      ),
                    ),
                  ],
                );
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            padding,
                            24,
                            padding,
                            28,
                          ),
                          child: FadeTransition(
                            opacity: _reveal,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    VeloraLogo(
                                      size: 38,
                                      glow: dark,
                                      onLight: !dark,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Velora',
                                        style: TextStyle(
                                          color: foreground,
                                          fontSize: 25,
                                          letterSpacing: -.8,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: wide ? 44 : 12),
                                if (wide)
                                  Row(
                                    children: [
                                      Expanded(
                                        child: SizedBox(
                                          height: illustrationHeight,
                                          child: WelcomeIllustration(
                                            motion: _floating,
                                            dark: dark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                      Expanded(child: content),
                                    ],
                                  )
                                else ...[
                                  SizedBox(
                                    height: illustrationHeight,
                                    width: double.infinity,
                                    child: WelcomeIllustration(
                                      motion: _floating,
                                      dark: dark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  content,
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
