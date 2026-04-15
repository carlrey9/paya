import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:async';
import 'firebase_options.dart';
import 'constants.dart';
import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await loadLocalOrders();
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Savor Atelier',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFA03215)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}

// Model for a Dish
class Dish {
  final String id;
  final String name;
  final double price;
  final IconData icon;
  final String description;
  final List<String> accompaniments;
  final String? imagePath;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
    this.description = '',
    this.accompaniments = const [],
    this.imagePath,
  });
}

// Local Tracking for Customer History
class LocalOrder {
  final String id;
  final double total;
  final List items;
  final int timestamp;

  LocalOrder({
    required this.id,
    required this.total,
    required this.items,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'total': total, 'items': items, 'timestamp': timestamp};
  }

  factory LocalOrder.fromMap(Map<String, dynamic> map) {
    return LocalOrder(
      id: map['id'],
      total: map['total'],
      items: List.from(map['items']),
      timestamp: map['timestamp'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalOrder.fromJson(String source) =>
      LocalOrder.fromMap(json.decode(source));
}

final List<LocalOrder> misPedidosLocales = [];

Future<void> saveLocalOrders() async {
  final prefs = await SharedPreferences.getInstance();
  List<String> ordersJson = misPedidosLocales.map((o) => o.toJson()).toList();
  await prefs.setStringList('local_orders', ordersJson);
}

Future<void> loadLocalOrders() async {
  final prefs = await SharedPreferences.getInstance();
  List<String>? ordersJson = prefs.getStringList('local_orders');
  if (ordersJson != null) {
    misPedidosLocales.clear();
    misPedidosLocales.addAll(ordersJson.map((o) => LocalOrder.fromJson(o)));
  }
}

// Model for an Ordered Item
class OrderItem {
  final Dish dish;
  final int quantity;

  OrderItem({required this.dish, required this.quantity});
}

// Helper for time formatting
String formatTime(int timestamp) {
  if (timestamp == 0) return '';
  final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
  final hour = date.hour.toString().padLeft(2, '0');
  final min = date.minute.toString().padLeft(2, '0');
  return '$hour:$min';
}

// Formatea un precio en pesos colombianos: $32.000
String formatCOP(double price) {
  final p = price.toInt();
  final s = p.toString();
  final buf = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('.');
    buf.write(s[i]);
  }
  return '\$${buf.toString()}';
}

// User Selection Screen
class UserSelectionScreen extends StatelessWidget {
  const UserSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFFCF9F5);
    const Color rustColor = Color(0xFFA03215);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_outlined, size: 64, color: rustColor),
                const SizedBox(height: 24),
                Text(
                  'Savor Atelier',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 42,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Selecciona tu perfil',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 64),
                _buildRoleButton(
                  context,
                  title: 'CLIENTE',
                  icon: Icons.person_outline,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CustomerMenuScreen(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildRoleButton(
                  context,
                  title: 'CHEF',
                  icon: Icons.outdoor_grill_outlined,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChefScreen()),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    const Color rustColor = Color(0xFFA03215);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: rustColor.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: rustColor.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: rustColor, size: 24),
            const SizedBox(width: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: rustColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Customer Menu Screen
class CustomerMenuScreen extends StatefulWidget {
  const CustomerMenuScreen({super.key});

  @override
  State<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends State<CustomerMenuScreen> {
  // Platos santandereanos
  final List<Dish> dishes = [
    Dish(
      id: '1',
      name: 'Arepa Santandereana',
      price: 8000,
      icon: Icons.breakfast_dining,
      imagePath: 'assets/arepa.jpeg',
      description:
          'Arepa de maíz pelado artesanal, dorada a la brasa con mantequilla de campo. '
          'De textura firme por fuera y suave por dentro, es el pan del santandereano de corazón.',
      accompaniments: [
        'Chicharrón crujiente',
        'Hogao casero',
        'Ají pepino',
        'Queso campesino',
      ],
    ),
    Dish(
      id: '2',
      name: 'Mute Santandereano',
      price: 22000,
      icon: Icons.soup_kitchen,
      imagePath: 'assets/mute.jpeg',
      description:
          'Sopa contundente cocinada a fuego lento durante horas. '
          'Mezcla de maíz pelado, fríjoles, trigo, garbanzos y costilla de cerdo con hierba buena.',
      accompaniments: ['Arroz blanco', 'Pan de bono', 'Aguacate', 'Ají casero'],
    ),
    Dish(
      id: '3',
      name: 'Carne Oreada',
      price: 32000,
      icon: Icons.set_meal,
      imagePath: 'assets/carne.jpeg',
      description:
          'Falda de res marinada con comino, naranja agria y sal gruesa, '
          'secada al sol colombiano por 24 horas y luego asada al carbón.',
      accompaniments: [
        'Yuca frita',
        'Papa criolla',
        'Ensalada de tomate',
        'Hogao',
      ],
    ),
    Dish(
      id: '4',
      name: 'Cabro Asado',
      price: 45000,
      icon: Icons.outdoor_grill,
      imagePath: 'assets/cabro.jpeg',
      description:
          'Chivo marinado con ajo, tomillo, laurel y chicha de maíz, '
          'asado lentamente sobre leña hasta lograr carne jugosa con piel dorada y crujiente.',
      accompaniments: [
        'Pepitoria de acompañamiento',
        'Yuca cocida',
        'Patacones',
        'Limón',
      ],
    ),
    Dish(
      id: '5',
      name: 'Chicharrón Crujiente',
      price: 15000,
      icon: Icons.lunch_dining,
      imagePath: 'assets/chicharron.jpeg',
      description:
          'Tocino de cerdo cocinado primero en su propia grasa y luego frito hasta alcanzar '
          'una textura imposiblemente crujiente. El snack por excelencia de la región.',
      accompaniments: [
        'Arepa santandereana',
        'Hogao',
        'Limón mandarina',
        'Ají pique',
      ],
    ),
    Dish(
      id: '6',
      name: 'Pepitoria de Cabro',
      price: 28000,
      icon: Icons.ramen_dining,
      imagePath: 'assets/pepitoria.jpeg',
      description:
          'Guiso ancestral de vísceras de chivo, sangre, maní tostado y especias secretas. '
          'Plato de fiesta con siglos de tradición en los fogones santandereanos.',
      accompaniments: [
        'Arroz con coco',
        'Patacones',
        'Ensalada de pepino',
        'Guarapo de caña',
      ],
    ),
    Dish(
      id: '7',
      name: 'Sancocho de Gallina',
      price: 23000,
      icon: Icons.soup_kitchen_outlined,
      imagePath: 'assets/gallina.jpeg',
      description:
          'Caldo espeso de gallina criolla cocinado con papa criolla, plátano verde, '
          'mazorca, cilantro y guascas. Reconfortante y completamente llenadero.',
      accompaniments: ['Arroz blanco', 'Aguacate', 'Arepa', 'Ají de maní'],
    ),
    Dish(
      id: '8',
      name: 'Hayaca Santandereana',
      price: 16000,
      icon: Icons.rice_bowl,
      imagePath: 'assets/ayaca.jpeg',
      description:
          'Masa de maíz trillado rellena con guiso de cerdo, garbanzos, papa y especias, '
          'envuelta en hoja de bijao y cocinada al vapor por varias horas.',
      accompaniments: [
        'Ensalada de repollo',
        'Ají casero',
        'Hogao',
        'Chicha de maíz',
      ],
    ),
    Dish(
      id: '9',
      name: 'Pepinos Rellenos',
      price: 18000,
      icon: Icons.eco,
      imagePath: 'assets/pepino.jpeg',
      description:
          'Pepinos de agua frescos vaciados y rellenos con carne molida guisada, '
          'tomate, cebolla y especias, horneados hasta que el pepino quede tierno.',
      accompaniments: [
        'Arroz blanco',
        'Ensalada verde',
        'Salsa de tomate casera',
        'Tostadas',
      ],
    ),
    Dish(
      id: '10',
      name: 'Hormigas Culonas Tostadas',
      price: 20000,
      icon: Icons.bug_report_outlined,
      imagePath: 'assets/hormiga.jpeg',
      description:
          'La delicadeza más famosa de Santander: hormigas reina cosechadas en abril, '
          'tostadas en tiesto de barro con sal. Crujientes, con sabor a mantequilla tostada.',
      accompaniments: [
        'Limón tahití',
        'Sal marina',
        'Aguardiente anisado',
        'Arepa tostada',
      ],
    ),
  ];

  // Bebidas — 10 opciones con típicas santandereanas
  final List<Dish> drinks = [
    Dish(
      id: 'b1',
      name: 'Masato Santandereano',
      price: 6000,
      icon: Icons.local_bar,
      imagePath: 'assets/masato.jpeg',
      description:
          'Bebida fermentada dulce a base de arroz, panela, canela y clavos de olor. Tradición pura.',
    ),
    Dish(
      id: 'b2',
      name: 'Chicha de Maíz',
      price: 5000,
      icon: Icons.sports_bar,
      imagePath: 'assets/chicha.jpeg',
      description:
          'Refrescante bebida ancestral de maíz fermentado artesanalmente, endulzada al punto justo.',
    ),
    Dish(
      id: 'b3',
      name: 'Guarapo de Caña',
      price: 4500,
      icon: Icons.grass,
      imagePath: 'assets/guarapo.jpeg',
      description:
          'Jugo de caña de azúcar recién exprimido, servido bien frío. Dulce y muy energético.',
    ),
    Dish(
      id: 'b4',
      name: 'Agua de Panela con Limón',
      price: 4000,
      icon: Icons.emoji_food_beverage,
      imagePath: 'assets/panela.jpeg',
      description:
          'La bebida clásica de la casa. Infusión de panela pura de la región con zumo de limones frescos.',
    ),
    Dish(
      id: 'b5',
      name: 'Jugo de Mora',
      price: 6000,
      icon: Icons.local_drink,
      imagePath: 'assets/mora.jpeg',
      description:
          'Jugo natural espeso y dulce, preparado con moras del páramo recién cosechadas.',
    ),
    Dish(
      id: 'b6',
      name: 'Jugo de Lulo',
      price: 6000,
      icon: Icons.local_drink,
      imagePath: 'assets/lulo.jpeg',
      description:
          'Jugo cítrico y tropical preparado con lulos maduros, el equilibrio ideal de acidez y dulzor.',
    ),
    Dish(
      id: 'b7',
      name: 'Jugo de Maracuyá',
      price: 6000,
      icon: Icons.local_drink,
      imagePath: 'assets/maracuya.jpeg',
      description:
          'Refrescante bebida preparada con la pulpa de la fruta de la pasión, de sabor intenso vibrante.',
    ),
    Dish(
      id: 'b8',
      name: 'Café Santandereano',
      price: 5000,
      icon: Icons.coffee,
      imagePath: 'assets/cafe.jpeg',
      description:
          'Tinto fuerte de aroma intenso, preparado con granos de la región tostados a la perfección.',
    ),
    Dish(
      id: 'b9',
      name: 'Limonada de Coco',
      price: 8000,
      icon: Icons.water_drop,
      imagePath: 'assets/coco.jpeg',
      description:
          'Mezcla suave y muy refrescante de crema elaborada con cocos frescos y zumo natural de limón.',
    ),
    Dish(
      id: 'b10',
      name: 'Té de Hierbas Aromáticas',
      price: 4000,
      icon: Icons.spa,
      imagePath: 'assets/te.jpeg',
      description:
          'Infusión caliente y relajante con una mezcla de hierbas frescas de nuestro huerto personal.',
    ),
  ];

  // Mapa de cantidades — cubre platos y bebidas
  late Map<String, int> quantities;

  // PageView / tab
  final PageController _pageController = PageController();
  int _currentTab = 0;

  List<Dish> get _allItems => [...dishes, ...drinks];

  @override
  void initState() {
    super.initState();
    quantities = {for (final item in _allItems) item.id: 0};
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _switchTab(int index) {
    setState(() => _currentTab = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _askForDishes() {
    int totalItems = quantities.values.fold(0, (sum, q) => sum + q);

    if (totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona al menos un ítem antes de pedir.',
          ),
        ),
      );
      return;
    }

    double totalPrice = quantities.entries.fold(0, (sum, entry) {
      final item = _allItems.firstWhere((i) => i.id == entry.key);
      return sum + (item.price * entry.value);
    });

    final orderedItems = quantities.entries.where((e) => e.value > 0).map((e) {
      final item = _allItems.firstWhere((i) => i.id == e.key);
      return OrderItem(dish: item, quantity: e.value);
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          orderedItems: orderedItems,
          totalPrice: totalPrice,
          onOrderConfirmed: () {
            setState(() {
              quantities = {for (final item in _allItems) item.id: 0};
            });
          },
        ),
      ),
    );
  }

  void _showDishDetail(BuildContext context, Dish item) {
    const Color bgColor = Color(0xFFFCF9F5);
    const Color rustColor = Color(0xFFA03215);
    const Color cardColor = Color(0xFFF6EFE8);
    int localQty = quantities[item.id] ?? 0;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 48,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Header con imagen o gradiente ──
                    SizedBox(
                      width: double.infinity,
                      height: 220,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Imagen real o gradiente de fallback
                          if (item.imagePath != null)
                            Image.asset(item.imagePath!, fit: BoxFit.cover)
                          else
                            Container(
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFF7B1D08),
                                    Color(0xFFA03215),
                                    Color(0xFFD4521F),
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  item.icon,
                                  size: 64,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            ),
                          // Overlay oscuro degradado abajo
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.55),
                                ],
                                stops: const [0.4, 1.0],
                              ),
                            ),
                          ),
                          // Badge precio arriba derecha
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Text(
                                formatCOP(item.price),
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFA03215),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Contenido del dialog ──
                    Container(
                      color: bgColor,
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Nombre
                          Text(
                            item.name,
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: rustColor,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Descripción
                          if (item.description.isNotEmpty) ...[
                            Text(
                              item.description,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black54,
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Acompañamientos
                          if (item.accompaniments.isNotEmpty) ...[
                            Text(
                              'Acompañado de',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: item.accompaniments.map((acc) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: cardColor,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: rustColor.withOpacity(0.15),
                                    ),
                                  ),
                                  child: Text(
                                    acc,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 20),
                          ],

                          // ── Stepper + botón agregar ──
                          Row(
                            children: [
                              // Stepper
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        if (localQty > 0) {
                                          setDialogState(() => localQty--);
                                          setState(
                                            () =>
                                                quantities[item.id] = localQty,
                                          );
                                        }
                                      },
                                      child: const Icon(
                                        Icons.remove,
                                        size: 20,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    SizedBox(
                                      width: 36,
                                      child: Center(
                                        child: Text(
                                          '$localQty',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        setDialogState(() => localQty++);
                                        setState(
                                          () => quantities[item.id] = localQty,
                                        );
                                      },
                                      child: const Icon(
                                        Icons.add,
                                        size: 20,
                                        color: rustColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Botón agregar
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: rustColor,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onPressed: () {
                                    if (localQty == 0) {
                                      setDialogState(() => localQty = 1);
                                      setState(() => quantities[item.id] = 1);
                                    }
                                    Navigator.of(ctx).pop();
                                  },
                                  child: Text(
                                    localQty == 0 ? 'AGREGAR' : 'CONFIRMAR',
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Tarjeta reutilizable para plato o bebida ──
  Widget _buildItemCard(Dish item, Color cardColor, Color rustColor) {
    final quantity = quantities[item.id]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Thumbnail — toca para ver detalle
          GestureDetector(
            onTap: () => _showDishDetail(context, item),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: item.imagePath != null
                  ? Image.asset(
                      item.imagePath!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 64,
                      height: 64,
                      color: Colors.white,
                      child: Icon(item.icon, size: 28, color: rustColor),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatCOP(item.price),
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: rustColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () {
                    if (quantity > 0) {
                      setState(() => quantities[item.id] = quantity - 1);
                    }
                  },
                  child: const Icon(
                    Icons.remove,
                    size: 20,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(
                  width: 32,
                  child: Center(
                    child: Text(
                      '$quantity',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => quantities[item.id] = quantity + 1);
                  },
                  child: Icon(Icons.add, size: 20, color: rustColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFFCF9F5);
    const Color cardColor = Color(0xFFF6EFE8);
    const Color rustColor = Color(0xFFA03215);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        /* leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: rustColor),
          onPressed: () => Navigator.of(context).pop(),
        ), */
        title: Text(
          'Menú',
          style: GoogleFonts.playfairDisplay(
            color: rustColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: misPedidosLocales.isNotEmpty,
              backgroundColor: rustColor,
              label: Text(
                '${misPedidosLocales.length}',
                style: const TextStyle(color: Colors.white),
              ),
              child: const Icon(Icons.receipt_long, color: rustColor),
            ),
            tooltip: 'Mis Pedidos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CustomerHistoryScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tab selector pill ──
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE3D8),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                children: [
                  _buildTab(
                    0,
                    'Platos',
                    Icons.restaurant_menu_outlined,
                    rustColor,
                  ),
                  _buildTab(
                    1,
                    'Bebidas',
                    Icons.local_drink_outlined,
                    rustColor,
                  ),
                ],
              ),
            ),
          ),
          // ── PageView ──
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentTab = index),
              children: [
                ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 4.0,
                  ),
                  itemCount: dishes.length,
                  itemBuilder: (context, index) =>
                      _buildItemCard(dishes[index], cardColor, rustColor),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 4.0,
                  ),
                  itemCount: drinks.length,
                  itemBuilder: (context, index) =>
                      _buildItemCard(drinks[index], cardColor, rustColor),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: quantities.values.any((q) => q > 0)
          ? FloatingActionButton.extended(
              backgroundColor: rustColor,
              foregroundColor: Colors.white,
              onPressed: _askForDishes,
              label: Text(
                'AÑADIR ORDEN',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
            )
          : null,
    );
  }

  Widget _buildTab(int index, String label, IconData icon, Color rustColor) {
    final bool isSelected = _currentTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFA03215) : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFA03215).withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.white : rustColor.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isSelected ? Colors.white : rustColor.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Order Summary Screen (Customer reviews their order before submitting)
class OrderSummaryScreen extends StatelessWidget {
  final List<OrderItem> orderedItems;
  final double totalPrice;
  final VoidCallback onOrderConfirmed;

  const OrderSummaryScreen({
    super.key,
    required this.orderedItems,
    required this.totalPrice,
    required this.onOrderConfirmed,
  });

  void _submitOrder(BuildContext context) {
    final dbRef = FirebaseDatabase.instance.ref('orders');

    final int currentTimestamp = DateTime.now().millisecondsSinceEpoch;
    final itemsList = orderedItems
        .map(
          (e) => {
            'id': e.dish.id,
            'name': e.dish.name,
            'price': e.dish.price,
            'quantity': e.quantity,
          },
        )
        .toList();

    final orderData = {
      'timestamp': currentTimestamp,
      'totalPrice': totalPrice,
      'items': itemsList,
      'status': 'preparing',
    };

    final newOrderRef = dbRef.push();

    newOrderRef
        .set(orderData)
        .then((_) {
          misPedidosLocales.add(
            LocalOrder(
              id: newOrderRef.key!,
              total: totalPrice,
              items: itemsList,
              timestamp: currentTimestamp,
            ),
          );
          saveLocalOrders();

          // Reset quantities on the previous screen
          onOrderConfirmed();

          // Navigate to History screen, replacing the summary
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CustomerHistoryScreen(),
            ),
          );
        })
        .catchError((error) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al enviar: $error')));
        });
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFFCF9F5);
    const Color cardColor = Color(0xFFF6EFE8);
    const Color rustColor = Color(0xFFA03215);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: rustColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Mi Orden',
          style: GoogleFonts.playfairDisplay(
            color: rustColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Text(
              'Revisa tu pedido antes\nde enviarlo',
              style: GoogleFonts.playfairDisplay(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: orderedItems.length,
              itemBuilder: (context, index) {
                final item = orderedItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: item.dish.imagePath != null
                            ? Image.asset(
                                item.dish.imagePath!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: cardColor,
                                child: Icon(item.dish.icon, color: rustColor),
                              ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.dish.name,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Cantidad: ${item.quantity}',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatCOP(item.dish.price * item.quantity),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL A PAGAR',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.2,
                          color: Colors.black54,
                        ),
                      ),
                      Text(
                        formatCOP(totalPrice),
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: rustColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => _submitOrder(context),
                      child: Text(
                        'ENVIAR A COCINA',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Customer History Screen
class CustomerHistoryScreen extends StatefulWidget {
  const CustomerHistoryScreen({super.key});

  @override
  State<CustomerHistoryScreen> createState() => _CustomerHistoryScreenState();
}

class _CustomerHistoryScreenState extends State<CustomerHistoryScreen> {
  static const Color bgColor = Color(0xFFFCF9F5);
  static const Color cardColor = Color(0xFFF6EFE8);
  static const Color rustColor = Color(0xFFA03215);

  Widget _buildOrderCard(
    LocalOrder order,
    String statusText,
    Color statusColor,
    Color statusTextColor,
    bool isPreparing,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'REFERENCIA DE PEDIDO',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#SA-${order.id.substring(order.id.length > 5 ? order.id.length - 5 : 0).toUpperCase()}',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      statusText.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: statusTextColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hoy, ${formatTime(order.timestamp)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Items
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.restaurant, color: Colors.black54),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'],
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cantidad: ${item['quantity']}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatCOP(double.parse(item['price'].toString())),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Action Button
              isPreparing
                  ? SizedBox()
                  : TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: rustColor,
                        alignment: Alignment.centerLeft,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              backgroundColor: const Color(0xFFFCF9F5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: Text(
                                'Pagar Pedido',
                                style: GoogleFonts.playfairDisplay(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFFA03215),
                                ),
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Escanea con tu billetera virtual',
                                    style: GoogleFonts.inter(
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => Scaffold(
                                            backgroundColor: Colors.black,
                                            appBar: AppBar(
                                              backgroundColor: Colors.black,
                                              iconTheme: const IconThemeData(
                                                color: Colors.white,
                                              ),
                                            ),
                                            body: Center(
                                              child: InteractiveViewer(
                                                child: Image.asset(
                                                  'assets/qr.jpeg',
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.asset(
                                        'assets/qr.jpeg',
                                        width: 200,
                                        height: 200,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Total: ${formatCOP(order.total)}',
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: Text(
                                    'Cerrar',
                                    style: GoogleFonts.inter(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.qr_code, size: 18),
                      label: Text(
                        'PAGAR CON QR',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'SALDO TOTAL',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: Colors.black54,
                    ),
                  ),
                  Text(
                    formatCOP(order.total),
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isPreparing ? rustColor : Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sort local orders newest first
    final List<LocalOrder> sortedOrders = List.from(misPedidosLocales)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: rustColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pedidos',
          style: GoogleFonts.playfairDisplay(
            color: rustColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 16.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mis Pedidos\nAnteriores',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Una retrospectiva de tu viaje culinario en Savor\nAtelier.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: sortedOrders.isEmpty
                ? Center(
                    child: Text(
                      'Aún no has hecho ningún pedido.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  )
                : StreamBuilder(
                    stream: FirebaseDatabase.instance.ref('orders').onValue,
                    builder: (context, snapshot) {
                      Map<dynamic, dynamic> activeOrders = {};
                      if (snapshot.hasData &&
                          snapshot.data!.snapshot.value != null) {
                        activeOrders =
                            snapshot.data!.snapshot.value
                                as Map<dynamic, dynamic>;
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 16.0,
                        ),
                        itemCount: sortedOrders.length,
                        itemBuilder: (context, index) {
                          final order = sortedOrders[index];
                          final bool isActive = activeOrders.containsKey(
                            order.id,
                          );
                          final String status = isActive
                              ? (activeOrders[order.id]['status'] ??
                                    'preparing')
                              : 'completed';

                          String statusText;
                          Color statusColor;
                          Color statusTextColor;
                          bool isPreparing = false;

                          if (status == 'preparing') {
                            statusText = 'En preparación';
                            statusColor = const Color(0xFFF5E0D8);
                            statusTextColor = rustColor;
                            isPreparing = true;
                          } else if (status == 'ready') {
                            statusText = '¡Listo!';
                            statusColor = const Color(0xFFD9F2FB);
                            statusTextColor = const Color(0xFF007BFF);
                          } else {
                            statusText = 'Entregado';
                            statusColor = const Color(0xFFDEE8DD);
                            statusTextColor = const Color(0xFF2B702B);
                          }

                          return _buildOrderCard(
                            order,
                            statusText,
                            statusColor,
                            statusTextColor,
                            isPreparing,
                            context,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      /*  bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 32, right: 32, bottom: 24),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.home_filled, 'INICIO', false),
              _buildNavItem(Icons.receipt_long, 'PEDIDOS', true),
              _buildNavItem(Icons.person, 'PERFIL', false),
            ],
          ),
        ),
      ), */
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFCF0ED) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isActive ? rustColor : Colors.grey.shade400,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: isActive ? rustColor : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// Chef Screen
class ChefScreen extends StatefulWidget {
  const ChefScreen({super.key});

  @override
  State<ChefScreen> createState() => _ChefScreenState();
}

class _ChefScreenState extends State<ChefScreen> {
  final DatabaseReference _ordersRef = FirebaseDatabase.instance.ref('orders');
  StreamSubscription<DatabaseEvent>? _newOrderSubscription;

  @override
  void initState() {
    super.initState();
    final startTime = DateTime.now().millisecondsSinceEpoch;

    _newOrderSubscription = _ordersRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        final timestamp = data['timestamp'] as int? ?? 0;

        // Si el pedido fue creado después de abrir la pantalla
        if (timestamp >= startTime) {
          FlutterRingtonePlayer().playNotification();
        }
      }
    });
  }

  @override
  void dispose() {
    _newOrderSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFFFCF9F5);
    const Color cardColor = Color(0xFFF6EFE8);
    const Color rustColor = Color(0xFFA03215);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        /*  leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: rustColor),
          onPressed: () => Navigator.of(context).pop(),
        ), */
        title: Text(
          'Consola del Chef',
          style: GoogleFonts.playfairDisplay(
            color: rustColor,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
          ),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder(
        stream: _ordersRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: rustColor),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final Map<dynamic, dynamic> ordersMap =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            final ordersList = ordersMap.entries.map((e) {
              return {
                'key': e.key,
                ...Map<String, dynamic>.from(e.value as Map),
              };
            }).toList();

            ordersList.sort(
              (a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0),
            );

            return ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16.0,
              ),
              itemCount: ordersList.length,
              itemBuilder: (context, index) {
                final order = ordersList[index];
                final String orderId = order['key'];
                final double total = (order['totalPrice'] ?? 0).toDouble();
                final List items = order['items'] ?? [];
                final int timestamp = (order['timestamp'] ?? 0) as int;
                final String status = order['status'] ?? 'preparing';

                String statusText;
                Color statusColor;
                Color statusTextColor;
                bool isPreparing = false;

                if (status == 'preparing') {
                  statusText = 'En preparación';
                  statusColor = const Color(0xFFF5E0D8);
                  statusTextColor = rustColor;
                  isPreparing = true;
                } else if (status == 'ready') {
                  statusText = '¡Listo!';
                  statusColor = const Color(0xFFD9F2FB);
                  statusTextColor = const Color(0xFF007BFF);
                } else {
                  statusText = 'Entregado';
                  statusColor = const Color(0xFFDEE8DD);
                  statusTextColor = const Color(0xFF2B702B);
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 24.0),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'REFERENCIA DE PEDIDO',
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '#SA-${orderId.substring(orderId.length > 5 ? orderId.length - 5 : 0).toUpperCase()}',
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  statusText.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.8,
                                    color: statusTextColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Hoy, ${formatTime(timestamp)}',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      ...items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: rustColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'],
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Cantidad: ${item['quantity']}',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isPreparing)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF007BFF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      backgroundColor: const Color(0xFFFCF9F5),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      title: Text(
                                        'Confirmar estado',
                                        style: GoogleFonts.playfairDisplay(
                                          fontWeight: FontWeight.w700,
                                          color: rustColor,
                                        ),
                                      ),
                                      content: Text(
                                        '¿Estás seguro de que este pedido está listo?',
                                        style: GoogleFonts.inter(
                                          color: Colors.black87,
                                        ),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.of(context).pop(),
                                          child: Text(
                                            'Cancelar',
                                            style: GoogleFonts.inter(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _ordersRef.child(orderId).update({
                                              'status': 'ready',
                                            });
                                            Navigator.of(context).pop();
                                          },
                                          child: Text(
                                            'Confirmar',
                                            style: GoogleFonts.inter(
                                              color: const Color(0xFF007BFF),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(
                                Icons.check_circle_outline,
                                size: 18,
                              ),
                              label: Text(
                                'MARCAR LISTO',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: const Color(0xFFFCF9F5),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Text(
                                      'Confirmar eliminación',
                                      style: GoogleFonts.playfairDisplay(
                                        fontWeight: FontWeight.w700,
                                        color: rustColor,
                                      ),
                                    ),
                                    content: Text(
                                      '¿Estás seguro de que deseas eliminar este pedido?',
                                      style: GoogleFonts.inter(
                                        color: Colors.black87,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: Text(
                                          'Cancelar',
                                          style: GoogleFonts.inter(
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _ordersRef.child(orderId).remove();
                                          Navigator.of(context).pop();
                                        },
                                        child: Text(
                                          'Eliminar',
                                          style: GoogleFonts.inter(
                                            color: Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: Text(
                              'TERMINAR',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          }

          return Center(
            child: Text(
              'No hay pedidos en curso',
              style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
            ),
          );
        },
      ),
    );
  }
}
