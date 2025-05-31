import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'historialpedidos_screen.dart'; // <-- importa la pantalla

class CarritoScreen extends StatefulWidget {
  final List<Map<String, dynamic>> carrito;

  const CarritoScreen({super.key, required this.carrito});

  @override
  State<CarritoScreen> createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  late List<Map<String, dynamic>> carrito;

  @override
  void initState() {
    super.initState();
    carrito = List<Map<String, dynamic>>.from(widget.carrito);
  }

  void eliminarProducto(int index) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final id = carrito[index]['id'];

    await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user.uid)
        .collection('carrito')
        .doc(id)
        .delete();

    setState(() {
      carrito.removeAt(index);
    });
  }

  double calcularTotal() {
    return carrito.fold(0, (total, prod) {
      double precio = double.tryParse(prod['precio'].toString()) ?? 0.0;
      return total + precio;
    });
  }

  void guardarCambiosYSalir() {
    widget.carrito
      ..clear()
      ..addAll(carrito);
    Navigator.pop(context, true);
  }

  Future<void> finalizarCompra() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || carrito.isEmpty) return;

    final firestore = FirebaseFirestore.instance;

    // Guardar historial de compra
    final historialRef = firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('historial')
        .doc();

    await historialRef.set({
      'fecha': FieldValue.serverTimestamp(),
      'productos': carrito,
      'total': calcularTotal(),
    });

    // Vaciar carrito en Firestore
    final carritoRef = firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('carrito');

    final docs = await carritoRef.get();
    for (var doc in docs.docs) {
      await doc.reference.delete();
    }

    setState(() {
      carrito.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Compra registrada con éxito")),
    );

    guardarCambiosYSalir();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: guardarCambiosYSalir,
        ),
        actions: [
          if (carrito.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check_circle),
              tooltip: 'Finalizar compra',
              onPressed: finalizarCompra,
            ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Ver historial de pedidos',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HistorialPedidosScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: carrito.isEmpty
          ? const Center(child: Text('El carrito está vacío'))
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: carrito.length,
                    itemBuilder: (context, index) {
                      final producto = carrito[index];
                      return ListTile(
                        title: Text(producto['nombre']),
                        subtitle:
                            Text('S/ ${producto['precio'] ?? '0.00'}'),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => eliminarProducto(index),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Total: S/ ${calcularTotal().toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
