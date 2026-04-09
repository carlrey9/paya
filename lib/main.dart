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
    Widget initialScreen;
    switch (currentUserRole) {
      case UserType.customer:
        initialScreen = const CustomerMenuScreen();
        break;
      case UserType.chef:
        initialScreen = const ChefScreen();
        break;
      case UserType.selection:
      default:
        initialScreen = const UserSelectionScreen();
        break;
    }

    return MaterialApp(
      title: 'App de Restaurante',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}

// Model for a Dish
class Dish {
  final String id;
  final String name;
  final double price;
  final IconData icon;

  Dish({
    required this.id,
    required this.name,
    required this.price,
    required this.icon,
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
                Icon(
                  Icons.restaurant_outlined,
                  size: 64,
                  color: rustColor,
                ),
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
                    MaterialPageRoute(
                      builder: (context) => const ChefScreen(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, {required String title, required IconData icon, required VoidCallback onTap}) {
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
  // 3 random dishes
  final List<Dish> dishes = [
    Dish(
      id: '1',
      name: 'Pizza Margarita',
      price: 12.99,
      icon: Icons.local_pizza,
    ),
    Dish(
      id: '2',
      name: 'Hamburguesa con Queso',
      price: 8.99,
      icon: Icons.fastfood,
    ),
    Dish(id: '3', name: 'Ensalada Fresca', price: 7.50, icon: Icons.eco),
  ];

  // Map to store quantity of each dish
  Map<String, int> quantities = {'1': 0, '2': 0, '3': 0};

  void _askForDishes() {
    int totalItems = quantities.values.fold(
      0,
      (sum, quantity) => sum + quantity,
    );

    if (totalItems == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, selecciona al menos un plato antes de pedir.',
          ),
        ),
      );
      return;
    }

    double totalPrice = quantities.entries.fold(0, (sum, entry) {
      final dish = dishes.firstWhere((d) => d.id == entry.key);
      return sum + (dish.price * entry.value);
    });

    // Get list of actual ordered items
    final orderedDishes = quantities.entries.where((e) => e.value > 0).map((e) {
      final dish = dishes.firstWhere((d) => d.id == e.key);
      return OrderItem(dish: dish, quantity: e.value);
    }).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderSummaryScreen(
          orderedItems: orderedDishes,
          totalPrice: totalPrice,
          onOrderConfirmed: () {
            setState(() {
              quantities = {'1': 0, '2': 0, '3': 0};
            });
          },
        ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: rustColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
              label: Text('${misPedidosLocales.length}', style: const TextStyle(color: Colors.white)),
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
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          final dish = dishes[index];
          final quantity = quantities[dish.id]!;

          return Container(
            margin: const EdgeInsets.only(bottom: 16.0),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    dish.icon,
                    size: 28,
                    color: rustColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dish.name,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${dish.price.toStringAsFixed(2)}',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
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
                            setState(() {
                              quantities[dish.id] = quantity - 1;
                            });
                          }
                        },
                        child: const Icon(Icons.remove, size: 20, color: Colors.black54),
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
                          setState(() {
                            quantities[dish.id] = quantity + 1;
                          });
                        },
                        child: const Icon(Icons.add, size: 20, color: rustColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.dish.icon, color: rustColor),
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
                        '\$${(item.dish.price * item.quantity).toStringAsFixed(2)}',
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
                        '\$${totalPrice.toStringAsFixed(2)}',
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
                    '\$${double.parse(item['price'].toString()).toStringAsFixed(2)}',
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
                              title: const Text('Pagar Pedido'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'Escanea con tu billetera virtual',
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
                                    child: Image.asset(
                                      'assets/qr.jpeg',
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Total: \$${order.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('Cerrar'),
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
                    '\$${order.total.toStringAsFixed(2)}',
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
      bottomNavigationBar: SafeArea(
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
      ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: rustColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
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
            return const Center(child: CircularProgressIndicator(color: rustColor));
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
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                                child: const Icon(Icons.restaurant, color: rustColor),
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
                                      title: const Text('Confirmar estado'),
                                      content: const Text('¿Estás seguro de que este pedido está listo?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: const Text('Cancelar'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            _ordersRef.child(orderId).update({'status': 'ready'});
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Confirmar', style: TextStyle(color: Colors.blue)),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 18),
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
                                    title: const Text('Confirmar eliminación'),
                                    content: const Text('¿Estás seguro de que deseas eliminar este pedido?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
                                        child: const Text('Cancelar'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _ordersRef.child(orderId).remove();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
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
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          );
        },
      ),
    );
  }
}
