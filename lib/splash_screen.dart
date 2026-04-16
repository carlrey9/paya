import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'constants.dart';
import 'main.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color rustColor = Color(0xFFA03215);

  late final AnimationController _logoController;
  late final AnimationController _textController;
  late final AnimationController _taglineController;
  late final AnimationController _dividerController;
  late final AnimationController _fadeOutController;

  late final Animation<double> _logoFade;
  late final Animation<double> _logoScale;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _dividerWidth;
  late final Animation<double> _fadeOut;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _dividerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeOutController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeIn);
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));

    _taglineFade = CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    );

    _dividerWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _dividerController, curve: Curves.easeInOut),
    );

    _fadeOut = CurvedAnimation(
      parent: _fadeOutController,
      curve: Curves.easeIn,
    );

    _runAnimationSequence();
  }

  Future<void> _runAnimationSequence() async {
    await Future.delayed(const Duration(milliseconds: 200));
    await _logoController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    await _dividerController.forward();

    await Future.delayed(const Duration(milliseconds: 50));
    await _textController.forward();

    await Future.delayed(const Duration(milliseconds: 100));
    await _taglineController.forward();

    // Espera antes de navegar
    await Future.delayed(const Duration(milliseconds: 1800));

    // Fade out y navegar
    await _fadeOutController.forward();

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WelcomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _taglineController.dispose();
    _dividerController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeOut,
      builder: (context, child) {
        return Opacity(opacity: 1.0 - _fadeOut.value, child: child);
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ── Imagen de fondo a pantalla completa ──
            Image.asset('assets/background.jpeg', fit: BoxFit.cover),

            // ── Overlay oscuro en gradiente para legibilidad ──
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.45),
                    Colors.black.withOpacity(0.65),
                    Colors.black.withOpacity(0.80),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // ── Contenido centrado ──
            SafeArea(
              child: Column(
                children: [
                  const Spacer(),

                  // Logo icon animado
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.4),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: rustColor.withOpacity(0.35),
                              blurRadius: 40,
                              spreadRadius: 8,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.restaurant_outlined,
                          size: 48,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Divider animado
                  AnimatedBuilder(
                    animation: _dividerWidth,
                    builder: (context, _) {
                      return SizedBox(
                        width: 60 * _dividerWidth.value,
                        child: Divider(
                          color: Colors.white.withOpacity(0.6),
                          thickness: 1.2,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Nombre del restaurante
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: Text(
                        'Savor Atelier',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 48,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tagline
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Text(
                      'Una experiencia culinaria única',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white70,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Crédito abajo
                  FadeTransition(
                    opacity: _taglineFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 36.0),
                      child: Text(
                        '© Savor Atelier 2026',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Colors.white38,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
