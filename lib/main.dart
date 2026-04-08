import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const RestaurantApp());
}

class RestaurantApp extends StatelessWidget {
  const RestaurantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Restaurante',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const UserSelectionScreen(),
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
}

final List<LocalOrder> misPedidosLocales = [];

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
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenidos al Restaurante')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '¿Quién eres?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CustomerMenuScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.person),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                child: Text('Cliente', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ChefScreen()),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                child: Text('Chef', style: TextStyle(fontSize: 18)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuestro Menú'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: misPedidosLocales.isNotEmpty,
              label: Text('${misPedidosLocales.length}'),
              child: const Icon(Icons.receipt_long),
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
        itemCount: dishes.length,
        itemBuilder: (context, index) {
          final dish = dishes[index];
          final quantity = quantities[dish.id]!;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    dish.icon,
                    size: 30,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  dish.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('\$${dish.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: Colors.red,
                      onPressed: () {
                        if (quantity > 0) {
                          setState(() {
                            quantities[dish.id] = quantity - 1;
                          });
                        }
                      },
                    ),
                    SizedBox(
                      width: 20,
                      child: Center(
                        child: Text(
                          '$quantity',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      color: Colors.green,
                      onPressed: () {
                        setState(() {
                          quantities[dish.id] = quantity + 1;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      // Floating Action Button
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _askForDishes,
        label: const Text('Pedir'),
        icon: const Icon(Icons.send),
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
          // Save locally for history
          misPedidosLocales.add(
            LocalOrder(
              id: newOrderRef.key!,
              total: totalPrice,
              items: itemsList,
              timestamp: currentTimestamp,
            ),
          );

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
    return Scaffold(
      appBar: AppBar(title: const Text('Resumen del Pedido')),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Revisa tu pedido antes de enviarlo:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: orderedItems.length,
              itemBuilder: (context, index) {
                final item = orderedItems[index];
                return ListTile(
                  leading: Icon(item.dish.icon),
                  title: Text(item.dish.name),
                  subtitle: Text('Cantidad: ${item.quantity}'),
                  trailing: Text(
                    '\$${(item.dish.price * item.quantity).toStringAsFixed(2)}',
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total a pagar:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '\$${totalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: () => _submitOrder(context),
                    child: const Text(
                      'Confirmar y Enviar a Cocina',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Customer History Screen
class CustomerHistoryScreen extends StatelessWidget {
  const CustomerHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sort local orders newest first
    final List<LocalOrder> sortedOrders = List.from(misPedidosLocales)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Scaffold(
      appBar: AppBar(title: const Text('Mis Pedidos Anteriores')),
      body: sortedOrders.isEmpty
          ? const Center(
              child: Text(
                'Aún no has hecho ningún pedido.',
                style: TextStyle(fontSize: 18),
              ),
            )
          : StreamBuilder(
              stream: FirebaseDatabase.instance.ref('orders').onValue,
              builder: (context, snapshot) {
                Map<dynamic, dynamic> activeOrders = {};
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  activeOrders =
                      snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                }

                return ListView.builder(
                  itemCount: sortedOrders.length,
                  itemBuilder: (context, index) {
                    final order = sortedOrders[index];
                    final bool isActive = activeOrders.containsKey(order.id);
                    final String status = isActive
                        ? (activeOrders[order.id]['status'] ?? 'preparing')
                        : 'completed';

                    String statusText;
                    Color statusColor;
                    if (status == 'preparing') {
                      statusText = 'En preparación';
                      statusColor = Colors.orange;
                    } else if (status == 'ready') {
                      statusText = '¡Listo!';
                      statusColor = Colors.blue;
                    } else {
                      statusText = 'Terminado';
                      statusColor = Colors.green;
                    }

                    return Card(
                      margin: const EdgeInsets.all(12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Pedido #${order.id.substring(order.id.length > 4 ? order.id.length - 4 : 0).toUpperCase()} - ${formatTime(order.timestamp)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Chip(
                                  label: Text(
                                    statusText,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  backgroundColor: statusColor,
                                ),
                              ],
                            ),
                            const Divider(),
                            ...order.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${item['quantity']}x ${item['name']}',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    Text(
                                      '\$${item['price']} c/u',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(),
                            Text(
                              'Total: \$${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consola del Chef (En Vivo)')),
      body: StreamBuilder(
        stream: _ordersRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final Map<dynamic, dynamic> ordersMap =
                snapshot.data!.snapshot.value as Map<dynamic, dynamic>;

            // Convert to list and sort by timestamp
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
              itemCount: ordersList.length,
              itemBuilder: (context, index) {
                final order = ordersList[index];
                final String orderId = order['key'];
                final double total = (order['totalPrice'] ?? 0).toDouble();
                final List items = order['items'] ?? [];
                final int timestamp = (order['timestamp'] ?? 0) as int;
                final String status = order['status'] ?? 'preparing';

                return Card(
                  margin: const EdgeInsets.all(12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Pedido #${orderId.substring(orderId.length > 4 ? orderId.length - 4 : 0).toUpperCase()} - ${formatTime(timestamp)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Row(
                              children: [
                                if (status == 'preparing')
                                  IconButton(
                                    icon: const Icon(
                                      Icons.notifications_active,
                                      color: Colors.blue,
                                      size: 30,
                                    ),
                                    tooltip: 'Avisar que está listo',
                                    onPressed: () {
                                      _ordersRef.child(orderId).update({
                                        'status': 'ready',
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Notificado al cliente',
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 30,
                                  ),
                                  tooltip: 'Finalizar y eliminar',
                                  onPressed: () {
                                    _ordersRef.child(orderId).remove();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Pedido completado'),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const Divider(),
                        ...items.map((item) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${item['quantity']}x ${item['name']}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Text(
                                  '\$${item['price']} c/u',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          );
                        }),
                        const Divider(),
                        Text(
                          'Total: \$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const Center(
            child: Text(
              'No hay pedidos activos',
              style: TextStyle(fontSize: 18),
            ),
          );
        },
      ),
    );
  }
}
