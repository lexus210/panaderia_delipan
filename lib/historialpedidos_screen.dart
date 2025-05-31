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
  final user = FirebaseAuth.instance.currentUser;

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

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final pedido = docs[index];
              final fechaTimestamp = pedido['fecha'] as Timestamp?;
              final fecha = fechaTimestamp != null
                  ? DateFormat('dd/MM/yyyy HH:mm').format(fechaTimestamp.toDate())
                  : 'Fecha desconocida';

              final productos = List<Map<String, dynamic>>.from(pedido['productos'] ?? []);
              final total = pedido['total'] ?? 0;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ExpansionTile(
                  title: Text('Pedido - $fecha'),
                  subtitle: Text('Total: S/ ${total.toStringAsFixed(2)}'),
                  children: productos.map((prod) {
                    final nombre = prod['nombre'] ?? 'Producto';
                    final precio = double.tryParse(prod['precio'].toString()) ?? 0.0;
                    return ListTile(
                      title: Text(nombre),
                      trailing: Text('S/ ${precio.toStringAsFixed(2)}'),
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
