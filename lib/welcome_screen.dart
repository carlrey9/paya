import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'main.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  static const Color rustColor = Color(0xFFA03215);

  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideUp = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const CustomerMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Imagen de fondo ──
          Image.asset(
            'assets/background.jpeg',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),

          // ── Gradiente: claro arriba, muy oscuro abajo ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x55000000),
                  Color(0x88000000),
                  Color(0xDD000000),
                  Color(0xF2000000),
                ],
                stops: [0.0, 0.35, 0.65, 1.0],
              ),
            ),
          ),

          // ── Contenido ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeIn,
              child: SlideTransition(
                position: _slideUp,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Top: logo + nombre ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              Icons.restaurant_outlined,
                              size: 22,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Savor Atelier',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Spacer(),
                          // ── 3-dot menu for staff ──
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.white70,
                            ),
                            color: const Color(0xFFFCF9F5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            onSelected: (value) {
                              if (value == 'chef') {
                                showChefAuthDialog(context);
                              } else if (value == 'admin') {
                                showAdminAuthDialog(context);
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'chef',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.restaurant_menu,
                                      color: Color(0xFFA03215),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Consola del chef',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFFA03215),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'admin',
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.admin_panel_settings_outlined,
                                      color: Color(0xFF0F3460),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Admin',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF0F3460),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // ── Contenido principal abajo ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Etiqueta
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: rustColor.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'BIENVENIDO',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Título principal
                          Text(
                            'Una cocina\ncon alma propia',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.15,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Divisor decorativo
                          Row(
                            children: [
                              Container(width: 32, height: 2, color: rustColor),
                              const SizedBox(width: 8),
                              Container(
                                width: 8,
                                height: 2,
                                color: Colors.white30,
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Descripción / resumen
                          Text(
                            'Cada plato es una historia. En Savor Atelier '
                            'combinamos ingredientes frescos con técnicas de '
                            'autor para ofrecerte una experiencia gastronómica '
                            'que va mucho más allá de lo que hay en el plato.',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                              height: 1.7,
                              letterSpacing: 0.2,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // ── Chips de características ──
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _buildChip(
                                Icons.eco_outlined,
                                'Ingredientes frescos',
                              ),
                              _buildChip(
                                Icons.schedule_outlined,
                                'Servicio rápido',
                              ),
                              _buildChip(
                                Icons.star_border_rounded,
                                'Alta calidad',
                              ),
                            ],
                          ),

                          const SizedBox(height: 40),

                          // ── Botón principal ──
                          SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: rustColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _goToMenu,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'VER MENÚ',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.8,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.arrow_forward, size: 18),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // ── Texto secundario ──
                          Center(
                            child: Text(
                              'Ordena desde tu mesa, sin esperas',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white38,
                                letterSpacing: 0.4,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
