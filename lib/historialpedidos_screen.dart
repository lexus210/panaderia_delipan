import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HistorialPedidosScreen extends StatefulWidget {
  const HistorialPedidosScreen({super.key});

  @override
  State<HistorialPedidosScreen> createState() => _HistorialPedidosScreenState();
}

class _HistorialPedidosScreenState extends State<HistorialPedidosScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final NumberFormat currencyFormat = NumberFormat.currency(locale: 'es_PE', symbol: 'S/');

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Debe iniciar sesión para ver el historial')),
      );
    }

    final historialRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user!.uid)
        .collection('historial')
        .orderBy('fecha', descending: true);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: historialRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(child: Text('No hay pedidos en el historial'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final pedido = docs[index];
              final data = pedido.data() as Map<String, dynamic>? ?? {};

              final fechaTimestamp = data['fecha'] as Timestamp?;
              final fecha = fechaTimestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(fechaTimestamp.toDate())
                  : 'Fecha desconocida';

              final productos = data.containsKey('productos')
                  ? List<Map<String, dynamic>>.from(data['productos'] ?? [])
                  : <Map<String, dynamic>>[];

              final total = data.containsKey('total') ? (data['total'] as num?) ?? 0 : 0;

              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ExpansionTile(
                  title: Text('Pedido - $fecha'),
                  subtitle: Text('Total: ${currencyFormat.format(total)}'),
                  children: productos.map((prod) {
                    final nombre = prod['nombre'] ?? 'Producto';
                    final precio = double.tryParse(prod['precio'].toString()) ?? 0.0;
                    return ListTile(
                      leading: const Icon(Icons.shopping_bag_outlined),
                      title: Text(nombre),
                      trailing: Text(currencyFormat.format(precio)),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}